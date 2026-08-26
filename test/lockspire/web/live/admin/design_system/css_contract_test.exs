defmodule Lockspire.Web.Live.Admin.DesignSystem.CssContractTest do
  use ExUnit.Case, async: true
  use Lockspire.AdminContractHelpers

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

  describe "CSS source and documentation contracts" do
    test "brand tokens raw colors contrast pairs and motion contracts stay source-derived" do
      sources = phase_120_contract_sources()

      assert_phase_120_brand_token_anchors(sources)
      assert_phase_120_raw_color_allowlist(sources)
      assert_phase_120_contrast_token_pairs(sources)
      assert_phase_120_responsive_focus_theme_motion(sources)
    end

    test "public docs and package content do not claim lab browser or theming support" do
      sources = phase_120_contract_sources()

      assert_phase_120_public_boundary(sources)
    end

    test "operator docs support-boundary and package DX contracts stay bounded" do
      sources = phase_120_contract_sources()

      assert_phase_120_operator_docs_proof(sources)
      assert_phase_120_supported_surface_ceiling(sources)
      assert_phase_120_package_dx_boundary(sources)
    end

    test "source and docs copy rejects generic CTAs secret samples and unsupported queue controls" do
      sources = phase_120_contract_sources()

      assert_phase_120_copy_boundaries(sources)
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
          "status_badge",
          "pane",
          "entity_header",
          "workflow_shell",
          "status_cluster",
          "lifecycle_row",
          "dense_resource_row",
          "responsive_table"
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
          "action_group",
          "pane",
          "entity_header",
          "workflow_shell",
          "status_cluster",
          "lifecycle_row",
          "dense_resource_row",
          "responsive_table"
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
          "lockspire-admin-pane",
          "lockspire-admin-pane__header",
          "lockspire-admin-pane__body",
          "lockspire-admin-entity-header",
          "lockspire-admin-entity-header__main",
          "lockspire-admin-entity-header__identifier",
          "lockspire-admin-workflow-shell",
          "lockspire-admin-workflow-shell__body",
          "lockspire-admin-lifecycle-row",
          "lockspire-admin-dense-resource-row",
          "lockspire-admin-responsive-table",
          "lockspire-admin-responsive-table__list",
          "lockspire-admin-badge-group",
          "lockspire-admin-action-group"
        ] do
      assert css =~ "." <> class
    end
  end

  test "phase 118 status badge semantics cover real Configure Support and Operate statuses" do
    components = File.read!(@admin_components_path)
    css = File.read!(@admin_css_path)

    assert component_declaration_block(components, "status_badge") =~ "attr(:domain, :atom"
    assert components =~ "defp status_metadata"

    for status <- [
          :active,
          :open,
          :approved,
          :pending,
          :pending_login,
          :pending_consent,
          :enqueued,
          :attempted,
          :retiring,
          :retryable,
          :denied,
          :reuse_detected,
          :discarded,
          :disabled,
          :retired,
          :completed,
          :consumed,
          :used,
          :succeeded,
          :rendered,
          :skipped,
          :operator,
          :self_registered,
          :self_registered_client,
          :system,
          :host_app,
          :dcr,
          :one_time,
          :remembered,
          :initial_access_token,
          :upcoming,
          :revoked,
          :expired
        ] do
      assert components =~ inspect(status)
    end

    assert components =~ "status_metadata(:approved, :device_authorization)"

    for class <- [
          "lockspire-admin-badge-healthy",
          "lockspire-admin-badge-waiting",
          "lockspire-admin-badge-warning",
          "lockspire-admin-badge-danger",
          "lockspire-admin-badge-disabled",
          "lockspire-admin-badge-completed",
          "lockspire-admin-badge-provenance"
        ] do
      assert css =~ "." <> class
    end
  end

  test "phase 118 representative form adoption keeps explicit Phoenix controls and named exceptions" do
    adoption_paths = [
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/clients_live/form_component.ex",
        @contract_dir
      ),
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/policies_live/dcr.html.heex",
        @contract_dir
      ),
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/tokens_live/index.ex",
        @contract_dir
      ),
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/consents_live/index.ex",
        @contract_dir
      )
    ]

    for path <- adoption_paths do
      source = File.read!(path)

      assert source =~ "AdminComponents.form_field" or
               source =~ "Lockspire.Web.Components.AdminComponents.form_field"

      assert source =~ ~r/<(?:input|select|textarea)\b/
    end

    exception_inventory = %{
      "complex checkbox confirmations" => [
        "lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex"
      ],
      "lifecycle action forms" => ["lib/lockspire/web/live/admin/keys_live/action_component.ex"],
      "copy-once secret/RAT/IAT flows" => [
        "lib/lockspire/web/live/admin/tokens_live/show.ex",
        "lib/lockspire/web/live/admin/consents_live/show.ex"
      ]
    }

    assert Map.has_key?(exception_inventory, "complex checkbox confirmations")
    assert Map.has_key?(exception_inventory, "lifecycle action forms")
    assert Map.has_key?(exception_inventory, "copy-once secret/RAT/IAT flows")

    for paths <- Map.values(exception_inventory), path <- paths do
      source = File.read!(Path.expand("../../../../../#{path}", @contract_dir))
      assert source =~ ~r/(redacted|Redacted|copy-once|not stored|consequence|confirm|plaintext)/
    end
  end

  test "phase 118 automated UAT proof covers responsive primitive guardrails" do
    css = File.read!(@admin_css_path)
    components = File.read!(@admin_components_path)

    for selector <- [
          ".lockspire-admin-pane",
          ".lockspire-admin-workflow-shell",
          ".lockspire-admin-responsive-table"
        ] do
      assert declaration_block(css, selector) =~ "min-width: 0"
    end

    assert css_rule(
             css,
             ".lockspire-admin-pane__header,\n  .lockspire-admin-entity-header,\n  .lockspire-admin-lifecycle-row,\n  .lockspire-admin-dense-resource-row"
           ) =~ "min-width: 0"

    for selector <- [
          ".lockspire-admin-status-cluster",
          ".lockspire-admin-dense-resource-row__meta",
          ".lockspire-admin-action-group",
          ".lockspire-admin-action-group__destructive"
        ] do
      assert declaration_block(css, selector) =~ "flex-wrap: wrap"
    end

    for selector <- [
          ".lockspire-admin-entity-header__main",
          ".lockspire-admin-dense-resource-row__main",
          ".lockspire-admin-lifecycle-row__main",
          ".lockspire-admin-long-value"
        ] do
      assert declaration_block(css, selector) =~ "min-width: 0"
    end

    assert css_rule(css, ".lockspire-admin-long-value") =~ "overflow-wrap: anywhere"
    assert css_rule(css, ".lockspire-admin-responsive-table__list") =~ "display: none"

    mobile_css = css_media_rule(css, "@media (max-width: 720px)")

    assert css_rule(
             mobile_css,
             ".lockspire-admin-responsive-table .lockspire-admin-table-wrap"
           ) =~ "display: none"

    assert css_rule(mobile_css, ".lockspire-admin-responsive-table__list") =~ "display: grid"
    assert css_rule(mobile_css, ".lockspire-admin-action-group__destructive") =~ "border-top:"
    assert css_rule(mobile_css, ".lockspire-admin-action-group__destructive") =~ "padding-top:"

    assert css_rule(
             mobile_css,
             ".lockspire-admin-filter-bar__fields,\n    .lockspire-admin-filter-bar__actions,\n    .lockspire-admin-action-group,\n    .lockspire-admin-action-group__primary,\n    .lockspire-admin-action-group__secondary,\n    .lockspire-admin-action-group__destructive,\n    .lockspire-admin-pane__header,\n    .lockspire-admin-entity-header,\n    .lockspire-admin-lifecycle-row,\n    .lockspire-admin-dense-resource-row,\n    .lockspire-admin-task-card__header,\n    .lockspire-admin-task-card__actions"
           ) =~ "flex-direction: column"

    assert components =~ ~s(role="link")
    assert components =~ ~s(aria-disabled="true")
    refute components =~ "Phoenix.LiveComponent"
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
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/overview_live/index.ex",
        @contract_dir
      ),
      Path.expand("../../../../../lib/lockspire/web/live/admin/dcr_live/index.ex", @contract_dir)
    ]

    filter_bar_sources = [
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/clients_live/index.ex",
        @contract_dir
      ),
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/tokens_live/index.ex",
        @contract_dir
      ),
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/consents_live/index.ex",
        @contract_dir
      )
    ]

    copy_once_sources = [
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/clients_live/index.ex",
        @contract_dir
      ),
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex",
        @contract_dir
      ),
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/clients_live/show.ex",
        @contract_dir
      )
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

  test "phase 119 source inventory covers touched routes and shared primitive adoption" do
    for suffix <- [
          "clients_live/show.ex",
          "policies_live/dcr.html.heex",
          "iat_live/index.html.heex",
          "iat_live/new.html.heex",
          "tokens_live/show.ex",
          "consents_live/show.ex",
          "device_authorizations_live/index.ex",
          "interactions_live/index.ex",
          "logout_deliveries_live/index.ex"
        ] do
      assert source_for_phase_119(suffix)
    end

    client = source_for_phase_119("clients_live/show.ex")

    for primitive <- [
          "AdminComponents.entity_header",
          "AdminComponents.pane",
          "AdminComponents.action_group",
          "AdminComponents.long_value"
        ] do
      assert client =~ primitive
    end

    for copy <- [
          "Identity and current status",
          "Effective posture",
          "Credentials and assertion keys",
          "Endpoints and logout",
          "DCR and RAT context",
          "Support pivots",
          "Lifecycle and destructive actions"
        ] do
      assert client =~ copy
    end

    assert client =~ "post-logout redirect URIs"
    assert client =~ "logout propagation URIs"

    iat_index = source_for_phase_119("iat_live/index.html.heex")
    iat_new = source_for_phase_119("iat_live/new.html.heex")

    for primitive <- [
          "AdminComponents.pane",
          "AdminComponents.resource_list",
          "AdminComponents.dense_resource_row",
          "AdminComponents.long_value"
        ] do
      assert iat_index =~ primitive
    end

    for primitive <- [
          "AdminComponents.workflow_shell",
          "AdminComponents.form_field",
          "AdminComponents.copy_once_secret_panel"
        ] do
      assert iat_new =~ primitive
    end

    for source <- @phase_119_support_sources |> Enum.map(&File.read!/1) do
      assert source =~ "AdminComponents.entity_header"
      assert source =~ "AdminComponents.pane"
      assert source =~ "AdminComponents.confirmation_panel"
      assert source =~ "AdminComponents.long_value"
    end

    for source <- @phase_119_operate_sources |> Enum.map(&File.read!/1) do
      assert source =~ "AdminComponents.pane"
      assert source =~ "AdminComponents.resource_list"
      assert source =~ "AdminComponents.dense_resource_row"
      assert source =~ "AdminComponents.status_badge"
      assert source =~ "AdminComponents.long_value"
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

  test "phase 103 migrated screens do not reintroduce inline layout styling" do
    for path <- [
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/clients_live/index.ex",
            @contract_dir
          ),
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/iat_live/index.html.heex",
            @contract_dir
          ),
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/iat_live/new.html.heex",
            @contract_dir
          )
        ] do
      refute File.read!(path) =~ ~r/\sstyle=/
    end
  end

  test "phase 104 client workspace does not reintroduce inline layout styling" do
    for path <- [
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/clients_live/show.ex",
            @contract_dir
          ),
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex",
            @contract_dir
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
end
