defmodule Frontispiece.MixProject do
  use Mix.Project

  def project do
    [
      app: :frontispiece,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [plt_add_apps: [:mix]],
      listeners: [Phoenix.CodeReloader]
    ]
  end

  def cli do
    [preferred_envs: [lint: :test]]
  end

  def application do
    [
      mod: {Frontispiece.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8", only: :dev},
      {:ecto_sqlite3, "~> 0.17"},
      {:ecto, "~> 3.12"},
      {:jason, "~> 1.4"},
      {:bandit, "~> 1.5"},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:earmark, "~> 1.4"},
      {:yaml_elixir, "~> 2.11"},
      {:req, "~> 0.5"},
      {:telemetry, "~> 1.3"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:lazy_html, ">= 0.1.0", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind frontispiece", "esbuild frontispiece"],
      "assets.deploy": [
        "tailwind frontispiece --minify",
        "esbuild frontispiece --minify",
        "phx.digest"
      ],
      lint: ["format --check-formatted", "credo --strict", "test"]
    ]
  end
end
