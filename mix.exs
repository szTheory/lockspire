defmodule Lockspire.MixProject do
  use Mix.Project

  def project do
    [
      app: :lockspire,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def cli do
    [
      preferred_envs: preferred_envs()
    ]
  end

  def application do
    [
      mod: {Lockspire.Application, []},
      extra_applications: [:logger, :runtime_tools, :telemetry]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.8.5"},
      {:phoenix_live_view, "~> 1.1.28"},
      {:ecto_sql, "~> 3.13.5"},
      {:postgrex, ">= 0.0.0"},
      {:oban, "~> 2.21"},
      {:jose, "~> 1.11"},
      {:jason, "~> 1.4"},
      {:opentelemetry_api, "~> 1.5"},
      {:telemetry, "~> 1.3"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib"]
  defp elixirc_paths(_env), do: ["lib"]

  defp aliases do
    [
      "test.setup": ["lockspire.test.setup"],
      "test.fast": ["test"],
      "test.integration": ["test.setup", "test --only integration"],
      ci: [
        "deps.get",
        "format --check-formatted",
        "compile --warnings-as-errors",
        "test.fast",
        "cmd sh -lc 'MIX_ENV=test mix test.integration'"
      ]
    ]
  end

  defp preferred_envs do
    [
      "lockspire.test.setup": :test,
      "test.setup": :test,
      "test.fast": :test,
      "test.integration": :test,
      ci: :test
    ]
  end
end
