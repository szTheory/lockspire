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
  @route_contract_path Path.expand(
                         "../../../../../.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md",
                         __DIR__
                       )

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

  defp component_declaration_block(source, function_name) do
    index = :binary.match(source, "def #{function_name}") |> elem(0)
    start = max(index - 700, 0)

    source
    |> String.slice(start, 1_400)
  end
end
