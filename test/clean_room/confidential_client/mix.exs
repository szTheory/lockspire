defmodule CleanRoomConfidentialClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :clean_room_confidential_client,
      version: "0.1.0",
      elixir: "~> 1.18",
      deps: deps()
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:lockspire, path: "vendor/lockspire"},
      {:phoenix, "== 1.8.13"},
      {:ecto_sql, "== 3.13.5"},
      {:postgrex, "== 0.22.4"},
      {:bandit, "== 1.12.5"},
      {:jose, "== 1.11.12"},
      {:jason, "== 1.4.5"}
    ]
  end
end
