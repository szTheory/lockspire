defmodule LockspireCompatibilityFixture.MixProject do
  use Mix.Project

  def project do
    [
      app: :lockspire_compatibility_fixture,
      version: "0.1.0",
      elixir: "~> 1.18",
      build_path: "../../tmp/lockspire-compatibility-fixture/_build",
      deps_path: "../../tmp/lockspire-compatibility-fixture/deps",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:lockspire, path: "../.."},
      {:phoenix, "== 1.8.5"},
      {:phoenix_live_view, "== 1.1.28"}
    ]
  end
end
