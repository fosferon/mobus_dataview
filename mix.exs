defmodule MobusDataview.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/fosferon/mobus_dataview"

  def project do
    [
      app: :mobus_dataview,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: @source_url,
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:deep_merge, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Column, filter, sort, and pagination settings management for directory views"
  end

  defp package do
    [
      name: "mobus_dataview",
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      maintainers: ["Leonidas"],
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
