defmodule CleanRoomProvider.MixProject do
  use Mix.Project

  def project do
    [
      app: :clean_room_provider,
      version: "0.1.0",
      elixir: "~> 1.18",
      deps: deps()
    ]
  end

  def application, do: [mod: {CleanRoomProvider.Application, []}, extra_applications: [:logger]]

  defp deps do
    [
      {:lockspire, path: "vendor/lockspire", runtime: false},
      {:phoenix, "== 1.8.13"},
      {:phoenix_live_view, "== 1.2.10"},
      {:ecto_sql, "== 3.13.5"},
      {:postgrex, "== 0.22.4"},
      {:bandit, "== 1.12.5"}
    ]
  end
end
