defmodule Lockspire.MixProject do
  use Mix.Project

  @package_excluded_files ~w(
    lib/lockspire/test_repo.ex
    lib/mix/tasks/lockspire.test.setup.ex
  )

  def project do
    [
      app: :lockspire,
      version: "1.4.0",
      description: "Embedded OAuth/OIDC authorization server library for Phoenix applications",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_load_filters: [
        fn path ->
          String.ends_with?(path, "_test.exs") and
            not String.starts_with?(path, "test/clean_room/")
        end
      ],
      test_ignore_filters: [fn path -> String.starts_with?(path, "test/clean_room/") end],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      # The non-integration suite measured 73.11% on 2026-08-26. Keep the
      # rounded-down floor stable so ordinary feature work can only ratchet it up.
      test_coverage: test_coverage(),
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
      # Range, not a pin: Lockspire mounts inside a host Phoenix app, so a hard
      # `~> 1.2.x` requirement would force every adopter to upgrade LiveView in
      # lockstep with Lockspire. Hosts on 1.1.x stay supported; CI resolves 1.2.x.
      {:phoenix_live_view, ">= 1.1.28 and < 2.0.0"},
      {:ecto_sql, "~> 3.13.5"},
      {:postgrex, ">= 0.0.0"},
      {:bandit, "~> 1.11"},
      {:oban, "~> 2.21.0"},
      {:req, "~> 0.5"},
      {:jose, "~> 1.11"},
      {:jason, "~> 1.4"},
      {:jcs, "~> 0.2"},
      {:nimble_options, "~> 1.1"},
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

  defp test_coverage do
    threshold =
      if System.get_env("LOCKSPIRE_COMPLETE_COVERAGE") == "true", do: 84, else: 73

    output = System.get_env("LOCKSPIRE_COVERAGE_OUTPUT", "cover")
    [summary: [threshold: threshold], output: output]
  end

  defp aliases do
    aliases = [
      "test.setup": ["lockspire.test.setup"],
      "test.fast": ["test.setup", "test"],
      "test.coverage": ["test.setup", "test --cover"],
      "test.integration": ["test.setup", "test --only integration"],
      "test.clean-room.e2e": [
        "cmd python3 scripts/acceptance/clean_room_saas_journey.py --only happy_path --only boundary --only lifecycle --only negative --only dpop"
      ],
      "test.phase6.e2e": [
        "test.setup",
        "test --include integration test/integration/phase6_onboarding_e2e_test.exs"
      ],
      "test.phase3.e2e": [
        "test.setup",
        "test --include integration test/integration/phase3_oidc_token_lifecycle_e2e_test.exs"
      ],
      "test.phase100.e2e": [
        "test.setup",
        "test --include integration test/integration/phase100_sender_constraint_e2e_test.exs"
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
        "cmd sh -lc 'MIX_ENV=test mix qa.architecture'",
        "cmd bash scripts/ci/run_credo.sh",
        "cmd bash scripts/ci/check_sobelow_routers.sh"
      ],
      "qa.architecture": [
        "cmd sh scripts/ci/check_architecture_topology.sh",
        "test test/lockspire/architecture_fitness_test.exs test/lockspire/compatibility_baseline_contract_test.exs"
      ],
      "qa.dialyzer": [
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
        "cmd sh -lc 'MIX_ENV=test mix test.integration'"
      ]
    ]

    if System.get_env("LOCKSPIRE_COVERAGE_AGGREGATE") == "true" do
      Keyword.delete(aliases, :"test.coverage")
    else
      aliases
    end
  end

  defp preferred_envs do
    [
      "lockspire.test.setup": :test,
      "test.setup": :test,
      "test.fast": :test,
      "test.coverage": :test,
      "test.integration": :test,
      "test.clean-room.e2e": :test,
      "test.phase6.e2e": :test,
      "test.phase3.e2e": :test,
      "test.phase100.e2e": :test,
      "test.phase30": :test,
      "conformance.phase37": :test,
      "test.phase3": :test,
      qa: :dev,
      "qa.architecture": :test,
      "qa.dialyzer": :dev,
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
      favicon: "brandbook/logo/lockspire-favicon.svg",
      before_closing_head_tag: &docs_before_closing_head_tag/1,
      before_closing_body_tag: &docs_before_closing_body_tag/1,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "SECURITY.md",
        "docs/ecosystem-overview.md",
        "docs/oauth-oidc-for-phoenix-adopters.md",
        "docs/architecture.md",
        "docs/code-walkthrough.md",
        "docs/getting-started.md",
        "docs/saas-adoption-recipe.md",
        "docs/adoption-demo.md",
        "docs/install-and-onboard.md",
        "docs/protect-phoenix-api-routes.md",
        "docs/device-flow-host-guide.md",
        "docs/private-key-jwt-host-guide.md",
        "docs/client-secret-jwt-host-guide.md",
        "docs/rar-consent-host-guide.md",
        "docs/operator-admin.md",
        "docs/dynamic-registration.md",
        "docs/telemetry.md",
        "docs/supported-surface.md",
        "docs/maintainer-conformance.md",
        "docs/maintainer-release.md",
        "docs/upgrading/v1.27.md",
        "docs/upgrading/storage-prefix.md",
        "docs/sigra-companion-host.md"
      ],
      groups_for_extras: [
        Guides: [
          "docs/ecosystem-overview.md",
          "docs/oauth-oidc-for-phoenix-adopters.md",
          "docs/architecture.md",
          "docs/code-walkthrough.md",
          "docs/getting-started.md",
          "docs/saas-adoption-recipe.md",
          "docs/adoption-demo.md",
          "docs/install-and-onboard.md",
          "docs/protect-phoenix-api-routes.md",
          "docs/device-flow-host-guide.md",
          "docs/private-key-jwt-host-guide.md",
          "docs/client-secret-jwt-host-guide.md",
          "docs/rar-consent-host-guide.md",
          "docs/operator-admin.md",
          "docs/dynamic-registration.md",
          "docs/telemetry.md",
          "docs/supported-surface.md",
          "docs/sigra-companion-host.md"
        ],
        Upgrading: [
          "docs/upgrading/v1.27.md",
          "docs/upgrading/storage-prefix.md"
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
        "Docs" => "https://hexdocs.pm/lockspire",
        "Supported surface" => "https://hexdocs.pm/lockspire/supported-surface.html"
      },
      files: package_files()
    ]
  end

  defp docs_before_closing_head_tag(:html) do
    ~S"""
    <style>
      .lockspire-mermaid {
        margin: 1.5rem 0;
        overflow-x: auto;
        text-align: center;
      }

      .lockspire-mermaid svg {
        display: block;
        height: auto;
        margin-inline: auto;
        max-width: 100% !important;
      }

      .lockspire-mermaid svg[data-lockspire-wide="true"] {
        min-width: 52rem;
      }

      .lockspire-mermaid svg:not([data-lockspire-wide="true"]) {
        max-width: 36rem !important;
      }
    </style>
    """
  end

  defp docs_before_closing_head_tag(_format), do: ""

  defp docs_before_closing_body_tag(:html) do
    ~S"""
    <script defer src="https://cdn.jsdelivr.net/npm/mermaid@11.16.0/dist/mermaid.min.js" onload="window.mermaid.initialize({startOnLoad: false}); window.dispatchEvent(new Event('lockspire:mermaid-ready'))"></script>
    <script>
      (() => {
        const diagramSelector = "pre > code.mermaid, pre > code.language-mermaid";
        const state = {
          assetReady: Boolean(window.mermaid),
          contentReady: document.readyState !== "loading",
          frame: null,
          generation: 0,
          theme: null
        };

        const captureSources = () => {
          document.querySelectorAll(diagramSelector).forEach((code) => {
            if (!code.dataset.lockspireMermaidSource && !code.querySelector("svg")) {
              code.dataset.lockspireMermaidSource = code.textContent;
            }
          });
        };

        captureSources();

        const themeVariables = {
          light: {
            background: "#ffffff",
            primaryColor: "#ecfeff",
            primaryTextColor: "#0f172a",
            primaryBorderColor: "#0e7490",
            lineColor: "#334155",
            secondaryColor: "#f8fafc",
            tertiaryColor: "#eef2ff",
            textColor: "#0f172a",
            noteBkgColor: "#f0fdfa",
            noteTextColor: "#0f172a",
            actorBkg: "#ecfeff",
            actorBorder: "#0e7490",
            actorTextColor: "#0f172a",
            signalColor: "#334155",
            signalTextColor: "#0f172a",
            labelBoxBkgColor: "#ffffff",
            labelBoxBorderColor: "#0e7490",
            labelTextColor: "#0f172a",
            loopTextColor: "#0f172a",
            activationBkgColor: "#cffafe",
            activationBorderColor: "#0e7490",
            fontFamily: "Inter, ui-sans-serif, system-ui, sans-serif"
          },
          dark: {
            background: "#111827",
            primaryColor: "#164e63",
            primaryTextColor: "#ecfeff",
            primaryBorderColor: "#22d3ee",
            lineColor: "#a5f3fc",
            secondaryColor: "#1f2937",
            tertiaryColor: "#0f172a",
            textColor: "#ecfeff",
            noteBkgColor: "#164e63",
            noteTextColor: "#ecfeff",
            actorBkg: "#0f172a",
            actorBorder: "#22d3ee",
            actorTextColor: "#ecfeff",
            signalColor: "#a5f3fc",
            signalTextColor: "#ecfeff",
            labelBoxBkgColor: "#1f2937",
            labelBoxBorderColor: "#22d3ee",
            labelTextColor: "#ecfeff",
            loopTextColor: "#ecfeff",
            activationBkgColor: "#164e63",
            activationBorderColor: "#67e8f9",
            fontFamily: "Inter, ui-sans-serif, system-ui, sans-serif"
          }
        };

        const currentTheme = () => document.body.classList.contains("dark") ? "dark" : "light";

        const fallbackFor = (code) => code.closest("pre");

        const sourceFor = (code) => code.dataset.lockspireMermaidSource || code.textContent;

        const containerFor = (fallback) => {
          const sibling = fallback.nextElementSibling;

          if (sibling && sibling.classList.contains("lockspire-mermaid")) {
            return sibling;
          }

          const container = document.createElement("div");
          container.className = "lockspire-mermaid";
          container.hidden = true;
          fallback.insertAdjacentElement("afterend", container);
          return container;
        };

        const renderDiagram = async (code, index, generation) => {
          const fallback = fallbackFor(code);
          if (!fallback) return;

          const container = containerFor(fallback);
          const diagramId = `lockspire-mermaid-${generation}-${index}`;

          try {
            const {svg, bindFunctions} = await window.mermaid.render(diagramId, sourceFor(code));

            if (generation !== state.generation || !document.contains(code)) return;

            container.innerHTML = svg;
            const renderedSvg = container.querySelector("svg");
            const viewBox = renderedSvg && renderedSvg.viewBox.baseVal;

            if (viewBox && viewBox.width / viewBox.height > 1.45) {
              renderedSvg.dataset.lockspireWide = "true";
            }

            container.hidden = false;
            fallback.hidden = true;
            if (bindFunctions) bindFunctions(container);
          } catch (error) {
            if (generation !== state.generation || !document.contains(code)) return;

            container.replaceChildren();
            container.hidden = true;
            code.textContent = sourceFor(code);
            code.removeAttribute("data-processed");
            fallback.hidden = false;
            console.warn("Lockspire Mermaid render failed; showing source fallback.", error);
          }
        };

        const renderAll = () => {
          if (!state.assetReady || !state.contentReady || !window.mermaid) return;

          state.generation += 1;
          const generation = state.generation;
          const theme = currentTheme();
          state.theme = theme;
          captureSources();

          window.mermaid.initialize({
            flowchart: {
              diagramPadding: 8,
              nodeSpacing: 24,
              rankSpacing: 32,
              useMaxWidth: true
            },
            securityLevel: "strict",
            sequence: {
              actorMargin: 24,
              diagramMarginX: 10,
              diagramMarginY: 10,
              height: 50,
              messageMargin: 24,
              useMaxWidth: true,
              width: 120
            },
            startOnLoad: false,
            theme: "base",
            themeVariables: themeVariables[theme]
          });

          document.querySelectorAll(diagramSelector).forEach((code, index) => {
            renderDiagram(code, index, generation);
          });
        };

        const scheduleRender = () => {
          if (!state.assetReady || !state.contentReady) return;
          if (state.frame) cancelAnimationFrame(state.frame);
          state.frame = requestAnimationFrame(() => {
            state.frame = null;
            renderAll();
          });
        };

        window.addEventListener("exdoc:loaded", () => {
          state.contentReady = true;
          scheduleRender();
        });

        window.addEventListener("lockspire:mermaid-ready", () => {
          state.assetReady = true;
          scheduleRender();
        });

        new MutationObserver((mutations) => {
          if (
            mutations.some((mutation) => mutation.attributeName === "class") &&
            currentTheme() !== state.theme
          ) {
            scheduleRender();
          }
        }).observe(document.body, {attributes: true, attributeFilter: ["class"]});

        scheduleRender();
      })();
    </script>
    """
  end

  defp docs_before_closing_body_tag(_format), do: ""

  defp package_files do
    [
      Path.wildcard("lib/**/*.ex"),
      Path.wildcard("lib/**/*.heex"),
      Path.wildcard("priv/repo/migrations/*.exs"),
      Path.wildcard("priv/templates/**/*.{ex,exs,heex}"),
      Path.wildcard("docs/**/*.md"),
      ~w(.formatter.exs mix.exs README.md CHANGELOG.md SECURITY.md LICENSE brandbook/logo/lockspire-favicon.svg)
    ]
    |> List.flatten()
    |> Enum.reject(&(&1 in @package_excluded_files))
    |> Enum.sort()
  end
end
