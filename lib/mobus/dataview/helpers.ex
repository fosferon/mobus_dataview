defmodule Mobus.Dataview.Helpers do
  @moduledoc """
  Key conversion utilities for dataview settings.

  Provides recursive conversion between atom-keyed and string-keyed maps,
  commonly needed when settings flow between Elixir config (atom keys) and
  JSON/browser storage (string keys).
  """

  @doc """
  Recursively converts atom-keyed maps to string-keyed maps.

  Handles nested maps and lists of maps.

  ## Examples

      iex> Mobus.Dataview.Helpers.atom_keys_to_binaries(%{foo: "bar", nested: %{baz: 1}})
      %{"foo" => "bar", "nested" => %{"baz" => 1}}

      iex> Mobus.Dataview.Helpers.atom_keys_to_binaries([%{a: 1}, %{b: 2}])
      [%{"a" => 1}, %{"b" => 2}]
  """
  @spec atom_keys_to_binaries(map() | list()) :: map() | list()
  def atom_keys_to_binaries(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) ->
        {Atom.to_string(key), atom_keys_to_binaries(value)}

      {key, value} ->
        {key, atom_keys_to_binaries(value)}
    end)
  end

  def atom_keys_to_binaries(list) when is_list(list) do
    Enum.map(list, &atom_keys_to_binaries/1)
  end

  def atom_keys_to_binaries(value), do: value

  @doc """
  Recursively converts string-keyed maps to atom-keyed maps.

  Handles nested maps and lists of maps. Uses `String.to_existing_atom/1`
  when possible, falling back to `String.to_atom/1` for new keys.

  ## Examples

      iex> Mobus.Dataview.Helpers.binary_keys_to_atoms(%{"foo" => "bar", "nested" => %{"baz" => 1}})
      %{foo: "bar", nested: %{baz: 1}}

      iex> Mobus.Dataview.Helpers.binary_keys_to_atoms([%{"a" => 1}, %{"b" => 2}])
      [%{a: 1}, %{b: 2}]
  """
  @spec binary_keys_to_atoms(map() | list()) :: map() | list()
  def binary_keys_to_atoms(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_binary(key) ->
        atom_key =
          try do
            String.to_existing_atom(key)
          rescue
            ArgumentError -> String.to_atom(key)
          end

        {atom_key, binary_keys_to_atoms(value)}

      {key, value} ->
        {key, binary_keys_to_atoms(value)}
    end)
  end

  def binary_keys_to_atoms(list) when is_list(list) do
    Enum.map(list, &binary_keys_to_atoms/1)
  end

  def binary_keys_to_atoms(value), do: value
end
