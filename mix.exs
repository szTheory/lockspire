defmodule Lockspire.MixProject do
  use Mix.Project

  def project do
    [
      app: :lockspire,
      version: "0.2.0",
      description: "Embedded OAuth/OIDC authorization server for Phoenix applications",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      docs: docs(),
      dialyzer: dialyzer(),
      hex: hex(),
      package: package(),
      homepage_url: "https://hexdocs.pm/lockspire",
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
      {:bandit, "~> 1.6"},
      {:oban, "~> 2.21"},
      {:req, "~> 0.5"},
      {:jose, "~> 1.11"},
      {:jason, "~> 1.4"},
      {:jcs, "~> 0.2"},
      {:opentelemetry_api, "~> 1.5"},
      {:phoenix_live_dashboard, "~> 0.8", optional: true},
      {:telemetry, "~> 1.3"},
      {:cachex, "~> 4.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38", only: [:dev, :test], runtime: false},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 1.0", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp aliases do
    [
      "test.setup": ["lockspire.test.setup"],
      "test.fast": ["test.setup", "test"],
      "test.integration": ["test.setup", "test --only integration"],
      "test.phase6.e2e": [
        "test.setup",
        "test --include integration test/integration/phase6_onboarding_e2e_test.exs"
      ],
      "test.phase3.e2e": [
        "test.setup",
        "test --include integration test/integration/phase3_oidc_token_lifecycle_e2e_test.exs"
      ],
      "test.phase30": [
        "test.setup",
        "test --include integration test/integration/phase30_device_authorization_e2e_test.exs test/lockspire/domain/device_authorization_test.exs test/lockspire/security/device_code_test.exs test/lockspire/protocol/device_authorization_test.exs test/lockspire/storage/ecto/repository_device_authorization_test.exs test/lockspire/web/controllers/device_authorization_controller_test.exs"
      ],
      "conformance.phase37": [
        "test.setup",
        "test --include integration test/integration/phase37_protocol_strictness_e2e_test.exs",
        "cmd bash scripts/conformance/run_phase37_suite.sh"
      ],
      "test.phase3": [
        "test.setup",
        "test --include integration test/integration/phase3_oidc_token_lifecycle_e2e_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/web/userinfo_controller_test.exs"
      ],
      qa: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "credo --strict",
        "sobelow --config",
        "dialyzer"
      ],
      "docs.verify": ["docs --warnings-as-errors"],
      "deps.audit": ["hex.audit", "deps.audit"],
      "package.build": ["hex.build"],
      "package.publish-dry-run": ["hex.publish --dry-run --yes"],
      "release.preflight": ["package.build", "package.publish-dry-run", "docs.verify"],
      ci: [
        "cmd sh -lc 'HEX_API_KEY= mix deps.get'",
        "cmd sh -lc 'mix qa'",
        "cmd sh -lc 'mix docs.verify'",
        "cmd sh -lc 'HEX_API_KEY= mix deps.audit'",
        "cmd sh -lc 'HEX_API_KEY= mix package.build'",
        "cmd sh -lc 'MIX_ENV=test mix test.fast'",
        "cmd sh -lc 'MIX_ENV=test mix test.integration'",
        "cmd sh -lc 'MIX_ENV=test mix test.phase3'"
      ]
    ]
  end

  defp preferred_envs do
    [
      "lockspire.test.setup": :test,
      "test.setup": :test,
      "test.fast": :test,
      "test.integration": :test,
      "test.phase6.e2e": :test,
      "test.phase3.e2e": :test,
      "test.phase30": :test,
      "conformance.phase37": :test,
      "test.phase3": :test,
      qa: :dev,
      "docs.verify": :dev,
      "deps.audit": :dev,
      "package.build": :dev,
      "package.publish-dry-run": :dev,
      "release.preflight": :dev,
      ci: :dev
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "SECURITY.md",
        "docs/ecosystem-overview.md",
        "docs/getting-started.md",
        "docs/install-and-onboard.md",
        "docs/private-key-jwt-host-guide.md",
        "docs/rar-consent-host-guide.md",
        "docs/operator-admin.md",
        "docs/dynamic-registration.md",
        "docs/supported-surface.md",
        "docs/maintainer-conformance.md",
        "docs/maintainer-release.md",
        "docs/sigra-companion-host.md"
      ],
      groups_for_extras: [
        Guides: [
          "docs/ecosystem-overview.md",
          "docs/getting-started.md",
          "docs/install-and-onboard.md",
          "docs/private-key-jwt-host-guide.md",
          "docs/rar-consent-host-guide.md",
          "docs/operator-admin.md",
          "docs/dynamic-registration.md",
          "docs/supported-surface.md",
          "docs/sigra-companion-host.md"
        ],
        Maintainers: [
          "CHANGELOG.md",
          "SECURITY.md",
          "docs/maintainer-conformance.md",
          "docs/maintainer-release.md"
        ]
      ]
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:mix],
      plt_local_path: "priv/plts/project.plt",
      plt_core_path: "priv/plts/core.plt"
    ]
  end

  defp hex do
    [
      api_key: System.get_env("HEX_API_KEY", "")
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "https://hexdocs.pm/lockspire/changelog.html",
        "Docs" => "https://hexdocs.pm/lockspire"
      },
      files: ~w(lib priv docs .formatter.exs mix.exs README.md CHANGELOG.md LICENSE)
    ]
  end
end
