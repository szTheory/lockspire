defmodule AdoptionDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :adoption_demo,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: ["lib"],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {AdoptionDemo.Application, []},
      extra_applications: [:logger, :runtime_tools, :oban, :cachex],
      included_applications: [:lockspire]
    ]
  end

  defp deps do
    [
      {:lockspire, path: "../.."},
      {:phoenix, "~> 1.8.5"},
      {:phoenix_live_view, "~> 1.1.28"},
      {:ecto_sql, "~> 3.13.5"},
      {:postgrex, ">= 0.0.0"},
      {:bandit, "~> 1.11"},
      {:jason, "~> 1.4"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": [
        "ecto.create",
        "ecto.migrate --migrations-path ../../priv/repo/migrations",
        "run priv/repo/seeds.exs"
      ],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
    ]
  end
end
