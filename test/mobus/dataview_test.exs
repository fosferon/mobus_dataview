defmodule Mobus.DataviewTest do
  use ExUnit.Case, async: true

  alias Mobus.Dataview
  alias Mobus.Dataview.Helpers

  defmodule TestStore do
    @behaviour Mobus.Dataview.Store

    @impl true
    def get(_scope, _module_id), do: nil

    @impl true
    def put(_scope, _module_id, _settings), do: :ok
  end

  defmodule PopulatedStore do
    @behaviour Mobus.Dataview.Store

    @impl true
    def get(:user_1, "tenants"), do: %{"columns" => ["name"], "page_size" => 50}
    def get(_scope, _module_id), do: nil

    @impl true
    def put(_scope, _module_id, _settings), do: :ok
  end

  describe "settings_from_config/2" do
    test "returns well-formed map with all expected keys" do
      config = %{
        columns: [:name, :status, :created_at],
        sorting: [%{field: :name, direction: :asc}],
        page_size: 25,
        fixed_filters: [%{field: :active, value: true}],
        selected_filters: []
      }

      settings = Dataview.settings_from_config(config)

      assert settings["columns"] == ["name", "status", "created_at"]
      assert settings["page_size"] == 25
      assert settings["current_page"] == 1
      assert settings["sorting"] == [%{"field" => :name, "direction" => :asc}]
      assert settings["fixed_filters"] == [%{"field" => :active, "value" => true}]
      assert settings["selected_filters"] == []
    end

    test "uses defaults for missing config keys" do
      settings = Dataview.settings_from_config(%{})

      assert settings["columns"] == []
      assert settings["page_size"] == 20
      assert settings["current_page"] == 1
      assert settings["sorting"] == []
      assert settings["fixed_filters"] == []
      assert settings["selected_filters"] == []
    end
  end

  describe "get/2" do
    test "returns default settings when no store provided" do
      defaults = %{"columns" => ["a"], "page_size" => 10}
      assert Dataview.get(defaults) == defaults
    end

    test "returns default settings when store returns nil" do
      defaults = %{"columns" => ["a"], "page_size" => 10}

      result =
        Dataview.get(defaults, store: TestStore, scope_key: :user_1, module_id: "tenants")

      assert result == defaults
    end

    test "returns stored settings when store has data" do
      defaults = %{"columns" => ["a", "b"], "page_size" => 10}

      result =
        Dataview.get(defaults, store: PopulatedStore, scope_key: :user_1, module_id: "tenants")

      assert result == %{"columns" => ["name"], "page_size" => 50}
    end
  end

  describe "merge_settings/2" do
    test "deep merges overrides into base settings" do
      base = %{
        "columns" => ["name", "status"],
        "sorting" => [%{"field" => "name", "direction" => "asc"}],
        "page_size" => 20
      }

      overrides = %{"page_size" => 50}

      result = Dataview.merge_settings(base, overrides)

      assert result["columns"] == ["name", "status"]
      assert result["sorting"] == [%{"field" => "name", "direction" => "asc"}]
      assert result["page_size"] == 50
    end

    test "preserves nested keys not present in override" do
      base = %{"filters" => %{"active" => true, "role" => "admin"}}
      overrides = %{"filters" => %{"active" => false}}

      result = Dataview.merge_settings(base, overrides)

      assert result["filters"]["active"] == false
      assert result["filters"]["role"] == "admin"
    end
  end

  describe "update_column_visibility/3" do
    test "adds column when visible is true" do
      settings = %{"columns" => ["name"]}
      result = Dataview.update_column_visibility(settings, "status", true)
      assert result["columns"] == ["name", "status"]
    end

    test "does not duplicate existing column" do
      settings = %{"columns" => ["name", "status"]}
      result = Dataview.update_column_visibility(settings, "status", true)
      assert result["columns"] == ["name", "status"]
    end

    test "removes column when visible is false" do
      settings = %{"columns" => ["name", "status"]}
      result = Dataview.update_column_visibility(settings, "status", false)
      assert result["columns"] == ["name"]
    end
  end

  describe "update_sorting/3" do
    test "sets sort field and direction" do
      settings = %{"sorting" => []}
      result = Dataview.update_sorting(settings, "name", "desc")
      assert result["sorting"] == [%{"field" => "name", "direction" => "desc"}]
    end

    test "replaces existing sorting" do
      settings = %{"sorting" => [%{"field" => "name", "direction" => "asc"}]}
      result = Dataview.update_sorting(settings, "status", "desc")
      assert result["sorting"] == [%{"field" => "status", "direction" => "desc"}]
    end
  end

  describe "update_page/2" do
    test "updates current_page value" do
      settings = %{"current_page" => 1}
      result = Dataview.update_page(settings, 5)
      assert result["current_page"] == 5
    end
  end

  describe "Helpers.atom_keys_to_binaries/1" do
    test "converts atom-keyed map to string-keyed map" do
      assert Helpers.atom_keys_to_binaries(%{foo: "bar"}) == %{"foo" => "bar"}
    end

    test "handles nested maps" do
      input = %{outer: %{inner: "value"}}
      assert Helpers.atom_keys_to_binaries(input) == %{"outer" => %{"inner" => "value"}}
    end

    test "handles lists of maps" do
      input = [%{a: 1}, %{b: 2}]
      assert Helpers.atom_keys_to_binaries(input) == [%{"a" => 1}, %{"b" => 2}]
    end

    test "passes through non-map values" do
      assert Helpers.atom_keys_to_binaries("hello") == "hello"
      assert Helpers.atom_keys_to_binaries(42) == 42
    end
  end

  describe "Helpers.binary_keys_to_atoms/1" do
    test "converts string-keyed map to atom-keyed map" do
      assert Helpers.binary_keys_to_atoms(%{"foo" => "bar"}) == %{foo: "bar"}
    end

    test "handles nested maps" do
      input = %{"outer" => %{"inner" => "value"}}
      assert Helpers.binary_keys_to_atoms(input) == %{outer: %{inner: "value"}}
    end

    test "handles lists of maps" do
      input = [%{"a" => 1}, %{"b" => 2}]
      assert Helpers.binary_keys_to_atoms(input) == [%{a: 1}, %{b: 2}]
    end
  end
end
