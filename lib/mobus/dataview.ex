defmodule Mobus.Dataview do
  @moduledoc """
  Settings management for directory views.

  Provides functions to build, merge, and update dataview settings that
  control columns, filters, sorting, and pagination in directory listings.

  Settings are represented as string-keyed maps for JSON compatibility.
  An optional `Mobus.Dataview.Store` implementation can be provided for
  persisting user-specific settings across sessions.

  ## Usage

      config = %{
        columns: [:name, :status, :created_at],
        sorting: [%{field: :name, direction: :asc}],
        page_size: 25
      }

      settings = Mobus.Dataview.settings_from_config(config)
      # => %{"columns" => ["name", "status", "created_at"], "page_size" => 25, ...}

      updated = Mobus.Dataview.update_sorting(settings, "status", "desc")
  """

  alias Mobus.Dataview.Helpers

  @default_page_size 20

  @doc """
  Build initial settings from a directory configuration map.

  Accepts a config map with atom keys (`:columns`, `:sorting`, `:page_size`,
  `:fixed_filters`, `:selected_filters`) and an optional `store_module` that
  implements `Mobus.Dataview.Store`.

  Returns a string-keyed settings map.

  ## Options

    * `:columns` -- list of column atoms (default: `[]`)
    * `:sorting` -- list of sorting maps with `:field` and `:direction` (default: `[]`)
    * `:page_size` -- integer page size (default: `#{@default_page_size}`)
    * `:fixed_filters` -- list of filter maps always applied (default: `[]`)
    * `:selected_filters` -- list of user-selected filter maps (default: `[]`)

  """
  @spec settings_from_config(map(), module() | nil) :: map()
  def settings_from_config(config, _store_module \\ nil) do
    columns =
      config
      |> Map.get(:columns, [])
      |> Enum.map(&to_string/1)

    sorting =
      config
      |> Map.get(:sorting, [])
      |> Helpers.atom_keys_to_binaries()

    fixed_filters =
      config
      |> Map.get(:fixed_filters, [])
      |> Helpers.atom_keys_to_binaries()

    selected_filters =
      config
      |> Map.get(:selected_filters, [])
      |> Helpers.atom_keys_to_binaries()

    page_size = Map.get(config, :page_size, @default_page_size)

    %{
      "columns" => columns,
      "page_size" => page_size,
      "current_page" => 1,
      "fixed_filters" => fixed_filters,
      "selected_filters" => selected_filters,
      "sorting" => sorting
    }
  end

  @doc """
  Retrieve settings, trying the store first (if provided), falling back to defaults.

  If `store_module` is `nil` or the store returns `nil`, returns `default_settings`.
  """
  @spec get(map(), keyword()) :: map()
  def get(default_settings, opts \\ []) do
    store_module = Keyword.get(opts, :store)
    scope_key = Keyword.get(opts, :scope_key)
    module_id = Keyword.get(opts, :module_id)

    case store_module do
      nil ->
        default_settings

      mod ->
        case mod.get(scope_key, module_id) do
          nil -> default_settings
          stored -> stored
        end
    end
  end

  @doc """
  Deep merge user overrides into base settings.

  Uses `DeepMerge.deep_merge/2` to preserve nested keys not present in
  the override map.
  """
  @spec merge_settings(map(), map()) :: map()
  def merge_settings(base_settings, overrides) do
    DeepMerge.deep_merge(base_settings, overrides)
  end

  @doc """
  Toggle column visibility in settings.

  If `visible` is `true`, adds the column to the columns list (if not present).
  If `false`, removes it.
  """
  @spec update_column_visibility(map(), String.t(), boolean()) :: map()
  def update_column_visibility(settings, column, visible) do
    columns = Map.get(settings, "columns", [])

    updated_columns =
      if visible do
        if column in columns, do: columns, else: columns ++ [column]
      else
        List.delete(columns, column)
      end

    Map.put(settings, "columns", updated_columns)
  end

  @doc """
  Update sort column and direction in settings.

  Replaces the sorting list with a single sort entry.
  """
  @spec update_sorting(map(), String.t(), String.t()) :: map()
  def update_sorting(settings, field, direction) do
    Map.put(settings, "sorting", [%{"field" => field, "direction" => direction}])
  end

  @doc """
  Update the current page in settings.
  """
  @spec update_page(map(), pos_integer()) :: map()
  def update_page(settings, page) when is_integer(page) and page > 0 do
    Map.put(settings, "current_page", page)
  end
end
