# MobusDataview

Settings management for directory views — columns, filters, sorting, and pagination.

Provides a structured way to define default view configurations, persist user
preferences via a pluggable store, and update settings at runtime. String-keyed
maps throughout for JSON compatibility.

## Installation

```elixir
def deps do
  [
    {:mobus_dataview, "~> 0.1"}
  ]
end
```

## Usage

### 1. Define a default view config

```elixir
config = %{
  columns: [:name, :status, :created_at],
  sorting: [%{field: :name, direction: :asc}],
  page_size: 25,
  fixed_filters: [%{field: :active, value: true}]
}

settings = Mobus.Dataview.settings_from_config(config)
# => %{
#   "columns" => ["name", "status", "created_at"],
#   "sorting" => [%{"field" => "name", "direction" => "asc"}],
#   "page_size" => 25,
#   "current_page" => 1,
#   "fixed_filters" => [%{"field" => "active", "value" => true}],
#   "selected_filters" => []
# }
```

### 2. Persist user preferences (optional)

Implement the `Mobus.Dataview.Store` behaviour:

```elixir
defmodule MyApp.DataviewStore do
  @behaviour Mobus.Dataview.Store

  @impl true
  def get(scope_key, module_id) do
    MyApp.Repo.get_settings(scope_key, module_id)
  end

  @impl true
  def put(scope_key, module_id, settings) do
    MyApp.Repo.save_settings(scope_key, module_id, settings)
    :ok
  end
end
```

Retrieve with fallback to defaults:

```elixir
settings = Mobus.Dataview.get(defaults, store: MyApp.DataviewStore,
                                         scope_key: "contacts",
                                         module_id: "directory")
```

### 3. Update settings at runtime

```elixir
# Toggle column visibility
settings = Mobus.Dataview.update_column_visibility(settings, "email", true)

# Change sort
settings = Mobus.Dataview.update_sorting(settings, "status", "desc")

# Change page
settings = Mobus.Dataview.update_page(settings, 2)

# Merge user overrides (deep merge, preserves unspecified nested keys)
settings = Mobus.Dataview.merge_settings(settings, %{"page_size" => 50})
```

## API

| Function | Description |
|---|---|
| `settings_from_config/2` | Build initial string-keyed settings from atom-keyed config |
| `get/2` | Retrieve settings with store fallback |
| `merge_settings/2` | Deep merge overrides into base settings |
| `update_column_visibility/3` | Add or remove a column |
| `update_sorting/3` | Set sort field and direction |
| `update_page/2` | Set current page number |

## License

MIT
