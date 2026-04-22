defmodule Lockspire.MixProject do
  use Mix.Project

  def project do
    [
      app: :lockspire,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:opentelemetry_api, "~> 1.6"},
      {:telemetry, "~> 1.3"}
    ]
  end
end
