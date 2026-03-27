defmodule Mobus.Dataview.Store do
  @moduledoc """
  Pluggable persistence behaviour for dataview settings.

  Consuming projects implement this behaviour to choose their persistence
  strategy -- ETS for in-memory session state, database for cross-session
  persistence, or a no-op implementation for stateless views.

  ## Example

      defmodule MyApp.DataviewStore do
        @behaviour Mobus.Dataview.Store

        @impl true
        def get(scope_key, module_id) do
          # Retrieve from your preferred storage
          MyApp.Repo.get_settings(scope_key, module_id)
        end

        @impl true
        def put(scope_key, module_id, settings) do
          MyApp.Repo.save_settings(scope_key, module_id, settings)
          :ok
        end
      end
  """

  @doc """
  Retrieve persisted settings for a given scope and module.

  Returns the settings map if found, or `nil` if no settings are persisted.
  """
  @callback get(scope_key :: term(), module_id :: String.t()) :: map() | nil

  @doc """
  Persist settings for a given scope and module.

  Returns `:ok` on success.
  """
  @callback put(scope_key :: term(), module_id :: String.t(), settings :: map()) :: :ok
end
