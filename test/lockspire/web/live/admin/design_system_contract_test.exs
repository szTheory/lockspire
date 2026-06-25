defmodule Lockspire.Web.Live.Admin.DesignSystemContractTest do
  use ExUnit.Case, async: true

  @admin_live_glob Path.expand(
                     "../../../../../lib/lockspire/web/live/admin/**/*.{ex,heex}",
                     __DIR__
                   )
  @admin_css_path Path.expand("../../../../../lib/lockspire/web/admin_css.ex", __DIR__)
  @admin_components_path Path.expand(
                           "../../../../../lib/lockspire/web/components/admin_components.ex",
                           __DIR__
                         )
  @admin_router_path Path.expand("../../../../../lib/lockspire/web/admin_router.ex", __DIR__)
  @admin_layout_path Path.expand(
                       "../../../../../lib/lockspire/web/live/admin_layout_live.ex",
                       __DIR__
                     )
  @brandbook_tokens_path Path.expand("../../../../../brandbook/tokens/tokens.json", __DIR__)
  @operator_admin_doc_path Path.expand("../../../../../docs/operator-admin.md", __DIR__)
  @adoption_demo_seeds_path Path.expand(
                              "../../../../../examples/adoption_demo/priv/repo/seeds.exs",
                              __DIR__
                            )
  @phase_110_dir Path.expand(
                   "../../../../../.planning/phases/110-demo-state-screenshots-docs-and-regression-proof",
                   __DIR__
                 )
  @phase_116_dir Path.expand(
                   "../../../../../.planning/phases/116-inventory-rubric-lab-contract",
                   __DIR__
                 )
  @route_contract_path Path.expand(
                         "../../../../../.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md",
                         __DIR__
                       )
  @phase_109_support_sources [
    Path.expand("../../../../../lib/lockspire/web/live/admin/tokens_live/index.ex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/tokens_live/show.ex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/consents_live/index.ex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/consents_live/show.ex", __DIR__)
  ]
  @phase_109_operations_sources [
    Path.expand(
      "../../../../../lib/lockspire/web/live/admin/logout_deliveries_live/index.ex",
      __DIR__
    ),
    Path.expand(
      "../../../../../lib/lockspire/web/live/admin/device_authorizations_live/index.ex",
      __DIR__
    ),
    Path.expand("../../../../../lib/lockspire/web/live/admin/interactions_live/index.ex", __DIR__)
  ]
  @phase_109_configure_sources [
    Path.expand("../../../../../lib/lockspire/web/live/admin/dcr_live/index.ex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/iat_live/index.ex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/iat_live/index.html.heex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/iat_live/new.html.heex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/keys_live/index.ex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/keys_live/show.ex", __DIR__),
    Path.expand(
      "../../../../../lib/lockspire/web/live/admin/keys_live/action_component.ex",
      __DIR__
    ),
    Path.expand("../../../../../lib/lockspire/web/live/admin/clients_live/show.ex", __DIR__)
  ]
  @phase_109_focused_tests [
    Path.expand("../../../../../test/lockspire/web/live/admin/tokens_live_test.exs", __DIR__),
    Path.expand("../../../../../test/lockspire/web/live/admin/consents_live_test.exs", __DIR__),
    Path.expand(
      "../../../../../test/lockspire/web/live/admin/logout_deliveries_live_test.exs",
      __DIR__
    ),
    Path.expand(
      "../../../../../test/lockspire/web/live/admin/device_authorizations_live_test.exs",
      __DIR__
    ),
    Path.expand(
      "../../../../../test/lockspire/web/live/admin/interactions_live_test.exs",
      __DIR__
    ),
    Path.expand("../../../../../test/lockspire/web/live/admin/iat_live_test.exs", __DIR__),
    Path.expand("../../../../../test/lockspire/web/live/admin/keys_live_test.exs", __DIR__),
    Path.expand(
      "../../../../../test/lockspire/web/live/admin/clients_live/show_test.exs",
      __DIR__
    )
  ]
  @phase_109_sources @phase_109_support_sources ++
                       @phase_109_operations_sources ++ @phase_109_configure_sources

  test "admin LiveViews use namespaced Lockspire admin button classes" do
    offenders =
      @admin_live_glob
      |> Path.wildcard()
      |> Enum.filter(fn path ->
        content = File.read!(path)

        Regex.match?(~r/class="(?:button|[^"]*\sbutton(?:\s|"))/, content)
      end)

    assert offenders == []
  end

  test "shared CSS defines the admin utility classes used by LiveViews" do
    css = File.read!(@admin_css_path)

    live_content =
      [@admin_components_path | Path.wildcard(@admin_live_glob)]
      |> Enum.map_join("\n", &File.read!/1)

    for class <- [
          "lockspire-admin-alert-warning",
          "lockspire-admin-action-bar",
          "lockspire-admin-btn",
          "lockspire-admin-btn-danger",
          "lockspire-admin-confirmation-panel",
          "lockspire-admin-detail-section",
          "lockspire-admin-empty-notice",
          "lockspire-admin-resource-list",
          "lockspire-admin-resource-list__item",
          "lockspire-admin-description-list",
          "lockspire-admin-table-wrap"
        ] do
      assert live_content =~ class
      assert css =~ "." <> class
    end
  end

  test "final v1.28 admin CSS primitives exist when used by admin surfaces" do
    css = File.read!(@admin_css_path)

    surface_content =
      [@admin_components_path | Path.wildcard(@admin_live_glob)]
      |> Enum.map_join("\n", &File.read!/1)

    for class <- [
          "lockspire-admin-hero",
          "lockspire-admin-dashboard-grid",
          "lockspire-admin-secondary-nav",
          "lockspire-admin-table",
          "lockspire-admin-form-shell",
          "lockspire-admin-field",
          "lockspire-admin-checkbox-field",
          "lockspire-admin-code-block",
          "lockspire-admin-secret-reveal"
        ] do
      if surface_content =~ class do
        assert css =~ "." <> class
      end
    end
  end

  test "semantic token categories are covered by the embedded admin CSS contract" do
    css = File.read!(@admin_css_path)

    for token <- [
          "--ls-surface-page",
          "--ls-surface-panel",
          "--ls-text-strong",
          "--ls-text-body",
          "--ls-text-accent",
          "--ls-surface-inverse",
          "--ls-border-subtle",
          "--ls-border-strong",
          "--ls-status-success-bg",
          "--ls-status-warning-border",
          "--ls-space-4",
          "--ls-control-height",
          "--ls-radius-md",
          "--ls-shadow-sm",
          "--ls-type-body-size",
          "--ls-font-sans",
          "--ls-focus-ring-color",
          "--ls-z-nav",
          "--ls-motion-duration-fast",
          "--ls-motion-ease-standard"
        ] do
      assert css =~ token
    end
  end

  test "embedded admin CSS stays aligned with canonical brandbook token values" do
    css = File.read!(@admin_css_path)
    tokens = @brandbook_tokens_path |> File.read!() |> Jason.decode!()

    expected_tokens = %{
      "--ls-color-brand-50" => get_in(tokens, ["color", "brand", "50", "value"]),
      "--ls-color-brand-100" => get_in(tokens, ["color", "brand", "100", "value"]),
      "--ls-color-brand-500" => get_in(tokens, ["color", "brand", "500", "value"]),
      "--ls-color-brand-600" => get_in(tokens, ["color", "brand", "600", "value"]),
      "--ls-color-brand-700" => get_in(tokens, ["color", "brand", "700", "value"]),
      "--ls-color-gray-50" => get_in(tokens, ["color", "neutral", "50", "value"]),
      "--ls-color-gray-100" => get_in(tokens, ["color", "neutral", "100", "value"]),
      "--ls-color-gray-200" => get_in(tokens, ["color", "neutral", "200", "value"]),
      "--ls-color-gray-300" => get_in(tokens, ["color", "neutral", "300", "value"]),
      "--ls-color-gray-400" => get_in(tokens, ["color", "neutral", "400", "value"]),
      "--ls-color-gray-500" => get_in(tokens, ["color", "neutral", "500", "value"]),
      "--ls-color-gray-600" => get_in(tokens, ["color", "neutral", "600", "value"]),
      "--ls-color-gray-700" => get_in(tokens, ["color", "neutral", "700", "value"]),
      "--ls-color-gray-800" => get_in(tokens, ["color", "neutral", "800", "value"]),
      "--ls-color-gray-900" => get_in(tokens, ["color", "neutral", "900", "value"]),
      "--ls-color-gray-950" => get_in(tokens, ["color", "neutral", "950", "value"]),
      "--ls-color-info-bg" => get_in(tokens, ["status", "light", "info", "bg"]),
      "--ls-color-info-text" => get_in(tokens, ["status", "light", "info", "text"]),
      "--ls-color-info-border" => get_in(tokens, ["status", "light", "info", "border"]),
      "--ls-color-info-bg-dark" => get_in(tokens, ["status", "dark", "info", "bg"]),
      "--ls-color-info-text-dark" => get_in(tokens, ["status", "dark", "info", "text"]),
      "--ls-color-info-border-dark" => get_in(tokens, ["status", "dark", "info", "border"])
    }

    for {token, value} <- expected_tokens do
      assert css =~ "#{token}: #{value};"
    end
  end

  test "dark mode remaps semantic aliases without primitive color inversion" do
    css = File.read!(@admin_css_path)

    for token <- [
          "--ls-color-gray-50",
          "--ls-color-gray-100",
          "--ls-color-gray-200",
          "--ls-color-gray-300",
          "--ls-color-gray-400",
          "--ls-color-gray-500",
          "--ls-color-gray-600",
          "--ls-color-gray-700",
          "--ls-color-brand-600",
          "--ls-color-success-bg"
        ] do
      assert ~r/#{Regex.escape(token)}:/ |> Regex.scan(css) |> length() == 1
    end

    assert css =~ "--ls-status-success-bg: var(--ls-color-success-bg-dark);"
    assert css =~ "--ls-text-accent: var(--ls-color-brand-500);"
  end

  test "admin CSS declares explicit light dark and system theme contracts" do
    css = File.read!(@admin_css_path)

    assert css =~ ":root {"
    assert css =~ "color-scheme: light;"
    assert css =~ ":root[data-theme=\"light\"]"
    assert css =~ ":root[data-theme=\"dark\"]"
    assert css =~ "@media (prefers-color-scheme: dark)"
    assert css =~ ":root:not([data-theme=\"light\"])"
    assert css =~ "--ls-text-accent: var(--ls-color-brand-600);"
    assert css =~ "--ls-text-accent: var(--ls-color-brand-500);"

    for body <- [
          declaration_block(css, ":root:not([data-theme=\"light\"])"),
          declaration_block(css, ":root[data-theme=\"dark\"]")
        ] do
      refute body =~ ~r/--ls-color-(?:brand|gray)-\d+:\s*#/
    end
  end

  test "admin CSS motion uses explicit transition properties without broad all behavior" do
    css = File.read!(@admin_css_path)

    refute css =~ ~r/transition(?:-property)?\s*:\s*all\b/
    refute css =~ ~r/transition\s*:/

    assert css =~ "--ls-motion-duration-fast: 150ms;"
    assert css =~ "--ls-motion-duration-medium: 220ms;"

    for selector <- [
          ".lockspire-admin-nav-item",
          ".lockspire-admin-field input[type=\"text\"]",
          ".lockspire-admin-secondary-nav a",
          ".lockspire-admin-btn-primary",
          ".lockspire-admin-btn-secondary",
          ".lockspire-admin-btn-danger"
        ] do
      assert declaration_block(css, selector) =~ "transition-property:"
      assert declaration_block(css, selector) =~ "transition-duration:"
      assert declaration_block(css, selector) =~ "transition-timing-function:"
    end
  end

  test "reduced motion neutralizes animation duration, transition duration, and active transforms" do
    css = File.read!(@admin_css_path)

    assert css =~ "@media (prefers-reduced-motion: reduce)"
    assert css =~ "transition-duration: 0.01ms !important"
    assert css =~ "animation-duration: 0.01ms !important"
    assert css =~ "scroll-behavior: auto !important"

    for selector <- [
          ".lockspire-admin-btn-primary:active",
          ".lockspire-admin-btn-secondary:active",
          ".lockspire-admin-btn-danger:active"
        ] do
      assert css =~ selector
    end

    assert css =~ "transform: none;"
  end

  test "public docs and package boundaries do not promote lab or browser proof surfaces" do
    supported_surface =
      File.read!(Path.expand("../../../../../docs/supported-surface.md", __DIR__))

    mix = File.read!(Path.expand("../../../../../mix.exs", __DIR__))

    for forbidden <- ["component-lab", "design-system-lab", "Playwright proof", "axe proof"] do
      refute supported_surface =~ forbidden
    end

    for forbidden_path <- [
          "proof/browser",
          "scripts/browser-proof",
          "package.json",
          "playwright.config"
        ] do
      refute mix =~ forbidden_path
    end
  end

  test "raw hex colors are declared only on Lockspire admin token lines" do
    css = File.read!(@admin_css_path)

    offenders =
      css
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.filter(fn {line, _line_number} ->
        Regex.match?(~r/#[0-9a-fA-F]{3,8}/, line) and not String.contains?(line, "--ls-")
      end)

    assert offenders == []
  end

  test "shared component primitives are exposed and backed by namespaced CSS" do
    components = File.read!(@admin_components_path)
    css = File.read!(@admin_css_path)

    for function_name <- [
          "page_hero",
          "metric_grid",
          "task_card",
          "filter_bar",
          "copy_once_secret_panel",
          "action_group",
          "long_value",
          "empty_state",
          "confirmation_panel",
          "form_field",
          "error_summary",
          "resource_item",
          "status_badge"
        ] do
      assert components =~ "def #{function_name}"
    end

    for primitive <- [
          "page_hero",
          "metric_grid",
          "task_card",
          "filter_bar",
          "copy_once_secret_panel",
          "action_group",
          "long_value"
        ] do
      assert component_declaration_block(components, primitive) =~ "attr("
    end

    for primitive <- [
          "page_hero",
          "metric_grid",
          "task_card",
          "filter_bar",
          "action_group"
        ] do
      assert component_declaration_block(components, primitive) =~ "slot("
    end

    for class <- [
          "lockspire-admin-hero",
          "lockspire-admin-page-hero",
          "lockspire-admin-metric-grid",
          "lockspire-admin-summary-stat",
          "lockspire-admin-task-card",
          "lockspire-admin-filter-bar",
          "lockspire-admin-resource-list__item",
          "lockspire-admin-empty",
          "lockspire-admin-confirmation-panel",
          "lockspire-admin-copy-once-secret",
          "lockspire-admin-error-summary",
          "lockspire-admin-field-errors",
          "lockspire-admin-long-value",
          "lockspire-admin-status-cluster",
          "lockspire-admin-badge-group",
          "lockspire-admin-action-group"
        ] do
      assert css =~ "." <> class
    end
  end

  test "admin shell exposes progressive system light dark theme control" do
    source = File.read!(@admin_layout_path)
    css = File.read!(@admin_css_path)

    assert source =~ "data-lockspire-theme-select"
    assert source =~ "lockspire-admin-theme"
    assert source =~ ~s(<option value="system">System</option>)
    assert source =~ ~s(<option value="light">Light</option>)
    assert source =~ ~s(<option value="dark">Dark</option>)
    assert css =~ ".lockspire-admin-theme-control"
    assert css =~ ":root[data-theme=\"dark\"]"
    assert css =~ ":root:not([data-theme=\"light\"])"
  end

  test "behavior-neutral migrations use shared primitives without inline styles" do
    page_hero_sources = [
      Path.expand("../../../../../lib/lockspire/web/live/admin/overview_live/index.ex", __DIR__),
      Path.expand("../../../../../lib/lockspire/web/live/admin/dcr_live/index.ex", __DIR__)
    ]

    filter_bar_sources = [
      Path.expand("../../../../../lib/lockspire/web/live/admin/clients_live/index.ex", __DIR__),
      Path.expand("../../../../../lib/lockspire/web/live/admin/tokens_live/index.ex", __DIR__),
      Path.expand("../../../../../lib/lockspire/web/live/admin/consents_live/index.ex", __DIR__)
    ]

    copy_once_sources = [
      Path.expand("../../../../../lib/lockspire/web/live/admin/clients_live/index.ex", __DIR__),
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex",
        __DIR__
      ),
      Path.expand("../../../../../lib/lockspire/web/live/admin/clients_live/show.ex", __DIR__)
    ]

    for path <- page_hero_sources do
      source = File.read!(path)

      assert source =~ "AdminComponents.page_hero"
      refute source =~ ~s(class="lockspire-admin-hero")
    end

    for path <- filter_bar_sources do
      source = File.read!(path)

      assert source =~ "AdminComponents.filter_bar"
    end

    for path <- copy_once_sources do
      source = File.read!(path)

      assert source =~ "AdminComponents.copy_once_secret_panel"
      refute source =~ ~s(class="lockspire-admin-secret-reveal")
    end

    for path <- Path.wildcard(@admin_live_glob) do
      refute File.read!(path) =~ ~r/\sstyle=/
    end
  end

  test "admin route surface and operator docs stay aligned to journey model" do
    router = File.read!(@admin_router_path)
    guide = File.read!(@operator_admin_doc_path)

    for route <- [
          ~s("/"),
          ~s("/clients"),
          ~s("/policies"),
          ~s("/keys"),
          ~s("/dcr"),
          ~s("/consents"),
          ~s("/tokens"),
          ~s("/interactions"),
          ~s("/device_authorizations"),
          ~s("/logouts")
        ] do
      assert router =~ route
    end

    for journey <- ["Overview", "Clients", "Security", "Keys", "DCR", "Support", "Operations"] do
      assert guide =~ "**#{journey}**"
    end
  end

  test "phase 107 route journey contract covers admin routes and locked vocabulary" do
    router = File.read!(@admin_router_path)
    contract = File.read!(@route_contract_path)
    guide = File.read!(@operator_admin_doc_path)

    expected_routes =
      router
      |> mounted_admin_routes()
      |> Kernel.++(["/admin/clients/:client_id/edit?workflow=logout-propagation"])
      |> Enum.sort()

    for route <- expected_routes do
      assert contract =~ "| `#{route}` |"
    end

    for field <- [
          "Route",
          "Primary journey",
          "Persona",
          "JTBD",
          "Entry point",
          "Primary decision",
          "Primary action",
          "Empty state",
          "Risk state",
          "Follow-up route",
          "Evidence"
        ] do
      assert contract =~ field
    end

    for journey <- ["Orient", "Configure", "Support", "Operate"] do
      assert contract =~ "| #{journey} |"
      assert guide =~ journey
    end

    for phrase <- [
          "DCR onboarding",
          "DCR policy",
          "post-logout redirect URIs",
          "logout propagation URIs"
        ] do
      assert contract =~ phrase
      assert guide =~ phrase
    end

    for assessment <- ["strong", "adequate", "weak"] do
      assert contract =~ "| #{assessment} |"
    end
  end

  test "phase 109 routes use approved journey labels, shared primitives, and style fences" do
    for path <- @phase_109_support_sources do
      source = File.read!(path)

      assert source =~ "Support"
      assert source =~ "AdminComponents.long_value"
    end

    for path <- [
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/tokens_live/index.ex",
            __DIR__
          ),
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/consents_live/index.ex",
            __DIR__
          )
        ] do
      source = File.read!(path)

      assert source =~ "AdminComponents.filter_bar"
      assert source =~ "AdminComponents.resource_item"
    end

    for path <- @phase_109_operations_sources do
      source = File.read!(path)

      assert source =~ "Operate"
      assert source =~ "AdminComponents.metric_grid"
      assert source =~ "AdminComponents.summary_stat"
      assert source =~ "AdminComponents.resource_item"
      assert source =~ "AdminComponents.long_value"
    end

    for path <- [
          Path.expand("../../../../../lib/lockspire/web/live/admin/dcr_live/index.ex", __DIR__),
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/iat_live/index.html.heex",
            __DIR__
          ),
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/iat_live/new.html.heex",
            __DIR__
          ),
          Path.expand("../../../../../lib/lockspire/web/live/admin/keys_live/index.ex", __DIR__),
          Path.expand("../../../../../lib/lockspire/web/live/admin/keys_live/show.ex", __DIR__),
          Path.expand("../../../../../lib/lockspire/web/live/admin/clients_live/show.ex", __DIR__)
        ] do
      assert File.read!(path) =~ "Configure"
    end

    assert source_for("iat_live/new.html.heex") =~
             "Lockspire.Web.Components.AdminComponents.copy_once_secret_panel"

    assert source_for("clients_live/show.ex") =~ "AdminComponents.action_group"
    assert source_for("keys_live/action_component.ex") =~ "AdminComponents.confirmation_panel"
    assert source_for("tokens_live/show.ex") =~ "AdminComponents.confirmation_panel"
    assert source_for("consents_live/show.ex") =~ "AdminComponents.confirmation_panel"

    for path <- @phase_109_sources do
      source = File.read!(path)

      refute source =~ ~r/\sstyle=/
      refute Regex.match?(~r/class="(?:button|[^"]*\sbutton(?:\s|"))/, source)
      refute Regex.match?(~r/class="(?![^"]*lockspire-admin-)[^"]*admin[^"]*"/, source)
    end
  end

  test "phase 109 routes fence generic CTAs, redaction, and risky action copy" do
    sources = phase_109_source_blob()
    tests = phase_109_test_blob()

    refute Regex.match?(
             ~r/(?:^|>|\n)\s*(Apply|Submit|OK|Cancel|Open|Revoke|Mint IAT|Rotate secret|Rotate RAT)\s*(?:<|\n|$)/,
             sources
           )

    for phrase <- [
          "redacted_handle",
          "plaintext",
          "copy_once_secret_panel",
          "not stored or shown again as plaintext",
          "user code material",
          "verifier material",
          "current credential",
          "redacted",
          "client_secret_hash",
          "token material",
          "token-ui-refresh-hash"
        ] do
      assert sources <> tests =~ phrase
    end

    for phrase <- [
          "Revoke token family",
          "Revoke consent grant",
          "Revoke initial access token",
          "Review key lifecycle",
          "Rotate registration access token",
          "Rotate client secret",
          "Disable client",
          "Enable client"
        ] do
      assert sources =~ phrase
    end

    for path <- [
          "tokens_live/show.ex",
          "consents_live/show.ex",
          "keys_live/action_component.ex"
        ] do
      source = source_for(path)

      assert source =~ "AdminComponents.confirmation_panel"
      assert source =~ "variant={:danger}"
      assert source =~ "confirm"
    end

    assert source_for("iat_live/index.html.heex") =~ "data-confirm="
    assert source_for("iat_live/index.html.heex") =~ "Revoke initial access token"
    assert source_for("clients_live/show.ex") =~ "<:destructive>"
    assert source_for("clients_live/show.ex") =~ "phx-click=\"toggle_client\""

    refute sources =~ "Playwright"
    refute sources =~ "screenshot"
    refute sources =~ "demo seed"
    refute sources =~ "visual regression"
  end

  test "phase 110 demo seeds cover required proof states with artificial data" do
    seeds = File.read!(@adoption_demo_seeds_path)

    for phrase <- [
          "healthy",
          "warning",
          "incident",
          "disabled",
          "self-registered",
          "retryable",
          "revoked",
          "expired",
          "long-value",
          "copy-once"
        ] do
      assert seeds =~ phrase
    end

    for phrase <- [
          "acme-ledger-public",
          "acme-tv-device",
          "acme-ledger-backend",
          "northstar-dcr-self-registered",
          "legacy-disabled-reporter"
        ] do
      assert seeds =~ phrase
    end

    for phrase <- [
          "status: :denied",
          "status: :consumed",
          "status: :discarded",
          "interaction-expired",
          "demo-iat-expired"
        ] do
      assert seeds =~ phrase
    end
  end

  test "phase 110 demo seeds keep secret and token proof values redaction-safe" do
    seeds = File.read!(@adoption_demo_seeds_path)

    for helper <- [
          "Lockspire.Security.Policy.hash_client_secret",
          "Lockspire.Security.Policy.hash_token"
        ] do
      assert seeds =~ helper
    end

    for forbidden <- [
          "real-client-secret",
          "production-secret",
          "prod-access-token",
          "prod-refresh-token",
          "customer.example.com",
          "tenant.example.com"
        ] do
      refute seeds =~ forbidden
    end

    assert seeds =~ "copy-once"
    assert seeds =~ "not stored or shown again as plaintext"
  end

  test "phase 110 operator docs preserve final journey model and host boundary" do
    guide = File.read!(@operator_admin_doc_path)

    for phrase <- [
          "Orient",
          "Configure",
          "Support",
          "Operate",
          "docs/supported-surface.md",
          "DCR onboarding",
          "DCR policy",
          "post-logout redirect URIs",
          "logout propagation URIs",
          "staff sessions",
          "MFA",
          "role checks",
          "tenant policy",
          "layouts",
          "branding",
          "product-specific authorization"
        ] do
      assert guide =~ phrase
    end
  end

  test "phase 110 screenshot and browser evidence inventories cover route proof fields" do
    router = File.read!(@admin_router_path)
    screenshots = File.read!(phase_110_path("110-SCREENSHOTS.md"))
    browser = File.read!(phase_110_path("110-BROWSER-EVIDENCE.md"))

    expected_routes =
      router
      |> mounted_admin_routes()
      |> Kernel.++(["/admin/clients/:client_id/edit?workflow=logout-propagation"])
      |> Enum.sort()

    for route <- expected_routes do
      assert screenshots =~ route
    end

    for heading <- [
          "Coverage Matrix",
          "Journey",
          "Route",
          "Desktop",
          "Mobile",
          "Demo state",
          "Browser note"
        ] do
      assert screenshots =~ heading
    end

    for phrase <- [
          "Orient",
          "Configure",
          "Support",
          "Operate",
          "tmp/admin-ui-polish/",
          "390px no-page-overflow returned false"
        ] do
      assert screenshots =~ phrase
    end

    for phrase <- [
          "overview",
          "read-only",
          "390px",
          "no-page-overflow",
          "copy-once",
          "confirmation"
        ] do
      assert browser =~ phrase
    end
  end

  test "phase 110 screenshot inventory rows contain explicit desktop and mobile proof cells" do
    screenshots = File.read!(phase_110_path("110-SCREENSHOTS.md"))

    rows =
      screenshots
      |> String.split("\n")
      |> Enum.filter(&String.starts_with?(&1, "| "))
      |> Enum.reject(&String.contains?(&1, "---"))
      |> Enum.drop(1)

    assert length(rows) >= 29

    for row <- rows do
      cells =
        row
        |> String.trim("|")
        |> String.split("|")
        |> Enum.map(&String.trim/1)

      assert [journey, route, desktop, mobile, demo_state, browser_note] = cells
      assert journey in ["Orient", "Configure", "Support", "Operate"]
      assert route |> String.trim("`") |> String.starts_with?("/admin")
      assert screenshot_cell_present?(desktop)
      assert screenshot_cell_present?(mobile)
      assert demo_state != ""
      assert browser_note != ""
    end
  end

  test "phase 110 client workspace CSS prevents 390px page overflow regressions" do
    css = File.read!(@admin_css_path)

    assert css_rule(css, ".lockspire-admin-client-workspace") =~
             "grid-template-columns: repeat(auto-fit, minmax(260px, 1fr))"

    assert css_rule(css, ".lockspire-admin-client-workspace") =~ "min-width: 0"
    assert css_rule(css, ".lockspire-admin-client-workspace > *") =~ "min-width: 0"
    assert css_rule(css, ".lockspire-admin-card") =~ "min-width: 0"

    assert css_rule(
             css,
             ".lockspire-admin-card code,\n  .lockspire-admin-detail-section code,\n  .lockspire-admin-form-shell code"
           ) =~
             "overflow-wrap: anywhere"

    assert css_rule(css, ".lockspire-admin-form-shell") =~ "min-width: 0"

    mobile_css = css_media_rule(css, "@media (max-width: 720px)")

    assert css_rule(mobile_css, ".lockspire-admin-client-workspace") =~
             "grid-template-columns: minmax(0, 1fr)"

    assert css_rule(mobile_css, ".lockspire-admin-form-shell") =~ "max-width: 100%"

    assert css_rule(css, ".lockspire-admin-copy-once-secret__value") =~
             "overflow-wrap: anywhere"

    assert css_rule(css, ".lockspire-admin-code-block") =~ "max-width: 100%"
    assert css_rule(css, ".lockspire-admin-action-group") =~ "min-width: 0"
    assert css_rule(css, ".lockspire-admin-description-list dd") =~ "overflow-wrap: anywhere"
  end

  test "phase 110 proof artifacts fence runtime dependencies, generic labels, and redaction notes" do
    artifacts = phase_110_artifact_blob()

    for path <- Path.wildcard(@admin_live_glob) ++ [@admin_css_path, @admin_components_path] do
      refute File.read!(path) =~ "tmp/admin-ui-polish"
    end

    refute Regex.match?(
             ~r/(?:^|>|\n|\|)\s*(Submit|OK|Cancel|Apply|Open)\s*(?:<|\n|\||$)/,
             artifacts
           )

    for phrase <- [
          "Do not persist plaintext IATs",
          "RATs",
          "client secrets",
          "user codes",
          "verifier material",
          "access tokens",
          "refresh tokens",
          "token hashes",
          "Keep screenshot files under `tmp/admin-ui-polish/` as milestone evidence only"
        ] do
      assert artifacts =~ phrase
    end
  end

  test "phase 103 migrated screens do not reintroduce inline layout styling" do
    for path <- [
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/clients_live/index.ex",
            __DIR__
          ),
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/iat_live/index.html.heex",
            __DIR__
          ),
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/iat_live/new.html.heex",
            __DIR__
          )
        ] do
      refute File.read!(path) =~ ~r/\sstyle=/
    end
  end

  test "phase 104 client workspace does not reintroduce inline layout styling" do
    for path <- [
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/clients_live/show.ex",
            __DIR__
          ),
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex",
            __DIR__
          )
        ] do
      refute File.read!(path) =~ ~r/\sstyle=/
    end
  end

  test "admin LiveViews do not reintroduce raw inline styles or unnamespaced button markup" do
    for path <- Path.wildcard(@admin_live_glob) do
      content = File.read!(path)

      refute content =~ ~r/\sstyle=/
      refute Regex.match?(~r/class="lockspire-admin-btn-(primary|secondary|danger)"/, content)
      refute Regex.match?(~r/<button(?![^>]*lockspire-admin-btn)/, content)
    end
  end

  @tag :phase_116_route_inventory
  test "phase 116 route workflow inventory is source-derived and classified" do
    router = File.read!(@admin_router_path)
    inventory = File.read!(phase_116_path("116-ROUTE-WORKFLOW-INVENTORY.md"))

    expected_routes =
      router
      |> mounted_admin_routes()
      |> Kernel.++(["/admin/clients/:client_id/edit?workflow=logout-propagation"])
      |> Enum.sort()

    for route <- expected_routes do
      assert inventory =~ "| `#{route}` |"
    end

    for field <- [
          "Route",
          "Source truth",
          "Primary journey",
          "Persona",
          "JTBD",
          "Entry point",
          "Primary decision",
          "Primary action",
          "Empty state",
          "Risk state",
          "Follow-up route",
          "Evidence",
          "Surface classification"
        ] do
      assert inventory =~ field
    end

    assert inventory =~ "/admin/clients/:client_id/edit?workflow=logout-propagation"
    assert inventory =~ "URL/query workflow truth"
    assert inventory =~ "not a Phoenix route or router expansion"

    for route <- ["/admin/interactions", "/admin/device_authorizations", "/admin/logouts"] do
      row = inventory_row!(inventory, route)

      assert row =~ "read-only support truth"
      refute row =~ ~r/\b(Retry|Discard|Logout now|Requeue)\b/
    end

    assert inventory =~ "admin_supported"
    assert inventory =~ "demo_only"
    assert inventory =~ "test_only"
    assert inventory =~ "internal_lab"
    refute inventory =~ "retry/discard controls"
  end

  @tag :phase_116_visual_rubric
  test "phase 116 visual ux rubric is brandbook-derived and admin-specific" do
    rubric = File.read!(phase_116_path("116-VISUAL-UX-RUBRIC.md"))

    for phrase <- [
          "brandbook/",
          "Signal Cyan `#22d3ee`",
          "Deep Cyan `#0e7490`",
          "semantic alias dark-mode remapping",
          "light/dark/system parity",
          "visible focus",
          "reduced-motion safety",
          "non-color status cues",
          "no generic security tropes",
          "no secret evidence",
          "no page-level overflow",
          "PhoenixStorybook",
          "rejected/default-deferred"
        ] do
      assert rubric =~ phrase
    end

    for journey <- ["Orient", "Configure", "Support", "Operate"] do
      assert rubric =~ journey
    end

    refute rubric =~ "npm install"
    refute rubric =~ "mix archive.install"
  end

  @tag :phase_116_component_inventory
  test "phase 116 component group inventory covers primitives, usage, and pressure" do
    inventory = File.read!(phase_116_path("116-COMPONENT-GROUP-INVENTORY.md"))
    components = File.read!(@admin_components_path)

    for function_name <- public_component_defs(components) do
      assert inventory =~ "`#{function_name}`"
    end

    for phrase <- [
          "Phoenix function components with attrs/slots",
          "Production usage points",
          "direct-markup exceptions",
          "Missing states",
          "Phase 118 candidates",
          "status fallback pressure",
          "form primitive pressure",
          "architectural panes",
          "entity headers",
          "workflow shells",
          "status/action clusters",
          "lifecycle rows",
          "dense resource rows",
          "table/list alternatives"
        ] do
      assert inventory =~ phrase
    end
  end

  @tag :phase_116_lab_contract
  test "phase 116 lab contract keeps maintainer proof out of supported routes" do
    contract = File.read!(phase_116_path("116-LAB-CONTRACT.md"))
    router = File.read!(@admin_router_path)

    supported_surface =
      File.read!(Path.expand("../../../../../docs/supported-surface.md", __DIR__))

    for phrase <- [
          "maintainer/demo/test-only",
          "not a supported admin route",
          "public API",
          "not mount through Lockspire.Web.AdminRouter",
          "PhoenixStorybook",
          "rejected/default-deferred",
          "React/JS Storybook",
          "host-editable component registry",
          "internal_lab",
          "test_only",
          "demo_only",
          "never `admin_supported`",
          "client secrets",
          "registration access token plaintext",
          "initial access token plaintext after creation",
          "refresh/access token plaintext",
          "authorization codes",
          "cookies",
          "private keys",
          "verifier material",
          "user codes",
          "unredacted sensitive values",
          "ExUnit/source contracts"
        ] do
      assert contract =~ phrase
    end

    refute router =~ "component_lab"
    refute router =~ "design_system_lab"

    supported_surface = String.downcase(supported_surface)

    for forbidden <- ["component lab", "design system lab", "design-system lab"] do
      refute supported_surface =~ forbidden
    end
  end

  defp inventory_row!(inventory, route) do
    row_prefix = "| `#{route}` |"

    inventory
    |> String.split("\n")
    |> Enum.find(&String.starts_with?(&1, row_prefix))
    |> case do
      nil -> flunk("missing inventory row for #{route}")
      row -> row
    end
  end

  defp mounted_admin_routes(router_source) do
    ~r/live\(\s*"([^"]+)"/
    |> Regex.scan(router_source, capture: :all_but_first)
    |> List.flatten()
    |> Enum.map(&mounted_admin_route/1)
  end

  defp mounted_admin_route("/"), do: "/admin"
  defp mounted_admin_route(route), do: "/admin" <> route

  defp phase_109_source_blob do
    @phase_109_sources
    |> Enum.map_join("\n", &File.read!/1)
  end

  defp phase_109_test_blob do
    @phase_109_focused_tests
    |> Enum.map_join("\n", &File.read!/1)
  end

  defp phase_110_artifact_blob do
    [
      phase_110_path("110-CONTEXT.md"),
      phase_110_path("110-SCREENSHOTS.md"),
      phase_110_path("110-BROWSER-EVIDENCE.md")
    ]
    |> Enum.map_join("\n", &File.read!/1)
  end

  defp screenshot_cell_present?(cell) do
    cell = String.trim(cell, "`")

    String.starts_with?(cell, "tmp/admin-ui-polish/") or
      String.starts_with?(cell, "Not captured -")
  end

  defp source_for(suffix) do
    @phase_109_sources
    |> Enum.find(fn path -> String.ends_with?(path, suffix) end)
    |> File.read!()
  end

  defp phase_110_path(filename) do
    Path.join(@phase_110_dir, filename)
  end

  defp phase_116_path(filename) do
    Path.join(@phase_116_dir, filename)
  end

  defp css_rule(css, selector) do
    pattern = ~r/#{Regex.escape(selector)}\s*\{(?<body>.*?)\}/s

    case Regex.named_captures(pattern, css) do
      %{"body" => body} -> body
      nil -> flunk("missing CSS selector #{selector}")
    end
  end

  defp css_media_rule(css, media_query) do
    case :binary.match(css, media_query) do
      {start, _length} ->
        rest = String.slice(css, start..-1//1)

        end_offset =
          case :binary.match(rest, "\n  @media", [
                 {:scope,
                  {String.length(media_query), String.length(rest) - String.length(media_query)}}
               ]) do
            {offset, _length} -> offset
            :nomatch -> String.length(rest)
          end

        String.slice(rest, 0, end_offset)

      :nomatch ->
        flunk("missing CSS media query #{media_query}")
    end
  end

  defp declaration_block(css, selector) do
    match =
      case :binary.match(css, selector <> " {") do
        :nomatch -> :binary.match(css, selector)
        exact -> exact
      end

    case match do
      {start, _length} ->
        candidate = String.slice(css, start, 900)
        brace_start = :binary.match(candidate, "{") |> elem(0)

        candidate
        |> String.slice(brace_start, 900)
        |> String.split("}", parts: 2)
        |> hd()

      :nomatch ->
        flunk("missing CSS selector #{selector}")
    end
  end

  defp component_declaration_block(source, function_name) do
    index = :binary.match(source, "def #{function_name}") |> elem(0)
    start = max(index - 700, 0)

    source
    |> String.slice(start, 1_400)
  end

  defp public_component_defs(source) do
    ~r/^\s{2}def\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(/m
    |> Regex.scan(source, capture: :all_but_first)
    |> List.flatten()
    |> Enum.sort()
  end
end
