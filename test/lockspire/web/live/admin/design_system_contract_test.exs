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
  @operator_admin_doc_path Path.expand("../../../../../docs/operator-admin.md", __DIR__)
  @adoption_demo_seeds_path Path.expand(
                              "../../../../../examples/adoption_demo/priv/repo/seeds.exs",
                              __DIR__
                            )
  @phase_110_dir Path.expand(
                   "../../../../../.planning/phases/110-demo-state-screenshots-docs-and-regression-proof",
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

  test "reduced motion neutralizes animation duration, transition duration, and active transforms" do
    css = File.read!(@admin_css_path)

    assert css =~ "@media (prefers-reduced-motion: reduce)"
    assert css =~ "transition-duration: 0.01ms !important"
    assert css =~ "animation-duration: 0.01ms !important"

    for selector <- [
          ".lockspire-admin-btn-primary:active",
          ".lockspire-admin-btn-secondary:active",
          ".lockspire-admin-btn-danger:active"
        ] do
      assert css =~ selector
    end

    assert css =~ "transform: none;"
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
          "lockspire-admin-long-value",
          "lockspire-admin-status-cluster",
          "lockspire-admin-badge-group",
          "lockspire-admin-action-group"
        ] do
      assert css =~ "." <> class
    end
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

    for heading <- ["Coverage Matrix", "Journey", "Route", "Desktop", "Mobile", "Demo state", "Browser note"] do
      assert screenshots =~ heading
    end

    for phrase <- ["Orient", "Configure", "Support", "Operate", "tmp/admin-ui-polish/", "Not captured -"] do
      assert screenshots =~ phrase
    end

    for phrase <- ["overview", "read-only", "390px", "no-page-overflow", "copy-once", "confirmation"] do
      assert browser =~ phrase
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

  defp source_for(suffix) do
    @phase_109_sources
    |> Enum.find(fn path -> String.ends_with?(path, suffix) end)
    |> File.read!()
  end

  defp phase_110_path(filename) do
    Path.join(@phase_110_dir, filename)
  end

  defp component_declaration_block(source, function_name) do
    index = :binary.match(source, "def #{function_name}") |> elem(0)
    start = max(index - 700, 0)

    source
    |> String.slice(start, 1_400)
  end
end
