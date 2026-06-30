defmodule Lockspire.Web.Live.Admin.DesignSystemContractTest do
  use ExUnit.Case, async: true

  alias Lockspire.Web.AdminProof.{BrowserEvidence, HtmlAssertions, RouteScorecards}

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
  @supported_surface_doc_path Path.expand("../../../../../docs/supported-surface.md", __DIR__)
  @mix_path Path.expand("../../../../../mix.exs", __DIR__)
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
  @phase_121_scorecards_path Path.expand(
                               "../../../../../.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md",
                               __DIR__
                             )
  @phase_125_proof_path Path.expand(
                          "../../../../../.planning/phases/125-browser-proof-docs-adversarial-ratchet/125-V1.32-PROOF.md",
                          __DIR__
                        )
  @phase_121_journeys ["Orient", "Configure", "Support", "Operate"]
  @phase_121_rubric_scopes ["Page", "Section", "Action", "Component Group"]
  @phase_121_rubric_questions [
    "redundant?",
    "least-surprising?",
    "user-flow-oriented?",
    "visually intentional?",
    "on-brand?"
  ]
  @phase_121_generic_ctas ["click here", "learn more", "read more", "submit", "ok"]
  @phase_121_non_final_values ["", "tbd", "todo", "fixme", "placeholder", "coming soon"]
  @phase_121_unearned_fit_values ["decorative", "placeholder", "nice-to-have", "later"]
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
  @phase_119_client_sources [
    Path.expand("../../../../../lib/lockspire/web/live/admin/clients_live/show.ex", __DIR__)
  ]
  @phase_119_dcr_sources [
    Path.expand(
      "../../../../../lib/lockspire/web/live/admin/policies_live/dcr.html.heex",
      __DIR__
    )
  ]
  @phase_119_iat_sources [
    Path.expand("../../../../../lib/lockspire/web/live/admin/iat_live/index.html.heex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/iat_live/new.html.heex", __DIR__)
  ]
  @phase_119_support_sources [
    Path.expand("../../../../../lib/lockspire/web/live/admin/tokens_live/show.ex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/consents_live/show.ex", __DIR__)
  ]
  @phase_119_operate_sources [
    Path.expand(
      "../../../../../lib/lockspire/web/live/admin/device_authorizations_live/index.ex",
      __DIR__
    ),
    Path.expand(
      "../../../../../lib/lockspire/web/live/admin/interactions_live/index.ex",
      __DIR__
    ),
    Path.expand(
      "../../../../../lib/lockspire/web/live/admin/logout_deliveries_live/index.ex",
      __DIR__
    )
  ]
  @phase_119_sources @phase_119_client_sources ++
                       @phase_119_dcr_sources ++
                       @phase_119_iat_sources ++
                       @phase_119_support_sources ++ @phase_119_operate_sources
  @phase_123_operate_sources %{
    interactions:
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/interactions_live/index.ex",
        __DIR__
      ),
    device_authorizations:
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/device_authorizations_live/index.ex",
        __DIR__
      ),
    logouts:
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/logout_deliveries_live/index.ex",
        __DIR__
      )
  }
  @phase_123_route_contracts %{
    "/interactions" => %{
      module: Lockspire.Web.Live.Admin.InteractionsLive.Index,
      title: "Authorization interaction queue",
      pane: "Review interactions",
      read_path: "Repository.list_interactions"
    },
    "/device_authorizations" => %{
      module: Lockspire.Web.Live.Admin.DeviceAuthorizationsLive.Index,
      title: "Device authorization queue",
      pane: "Review device authorizations",
      read_path: "Admin.list_device_authorizations"
    },
    "/logouts" => %{
      module: Lockspire.Web.Live.Admin.LogoutDeliveriesLive.Index,
      title: "Logout propagation queue",
      pane: "Review logout deliveries",
      read_path: "Repository.list_all_logout_deliveries"
    }
  }
  @phase_123_unsupported_command_labels [
    "Retry now",
    "Discard now",
    "Approve now",
    "Deny now",
    "Logout now",
    "Requeue",
    "Run worker",
    "Worker control",
    "Pause worker",
    "Resume worker"
  ]
  @phase_123_required_primitives [
    "AdminComponents.page_hero",
    "AdminComponents.pane",
    "AdminComponents.metric_grid",
    "AdminComponents.resource_list",
    "AdminComponents.dense_resource_row",
    "AdminComponents.status_badge",
    "AdminComponents.long_value",
    "AdminComponents.empty_state"
  ]
  @phase_123_sensitive_render_patterns %{
    "/interactions" => [
      "interaction.authorization_code",
      "interaction.request_object",
      "interaction.session_token",
      "interaction.cookie",
      "interaction.nonce",
      "interaction.state",
      "interaction.code_challenge",
      "interaction.code_verifier",
      "interaction.raw_params",
      "interaction.return_value"
    ],
    "/device_authorizations" => [
      "auth.device_code",
      "auth.user_code",
      "auth.device_code_hash",
      "auth.user_code_hash",
      "value={auth.verification_handle}",
      "auth.authorization_code",
      "auth.token",
      "auth.code_challenge",
      "auth.code_verifier",
      "auth.state",
      "auth.nonce",
      "auth.raw_params",
      "auth.updated_at"
    ],
    "/logouts" => [
      "delivery.logout_token_jti",
      "delivery.oban",
      "delivery.job_id",
      "delivery.raw_response",
      "delivery.response_body",
      "delivery.cookie",
      "delivery.endpoint_secret",
      "delivery.sql",
      "delivery.session_data"
    ]
  }
  @phase_123_public_boundary_forbidden [
    "component-lab",
    "component_lab",
    "browser-proof",
    "browser_proof",
    "storybook",
    "phoenixstorybook",
    "design-system route",
    "design_system route",
    "public theming api",
    "theme_lab"
  ]
  @phase_124_configure_source_paths %{
    clients_index:
      Path.expand("../../../../../lib/lockspire/web/live/admin/clients_live/index.ex", __DIR__),
    clients_show:
      Path.expand("../../../../../lib/lockspire/web/live/admin/clients_live/show.ex", __DIR__),
    clients_form:
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/clients_live/form_component.ex",
        __DIR__
      ),
    clients_rotate_secret:
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex",
        __DIR__
      ),
    dcr_index:
      Path.expand("../../../../../lib/lockspire/web/live/admin/dcr_live/index.ex", __DIR__),
    iat_index:
      Path.expand("../../../../../lib/lockspire/web/live/admin/iat_live/index.ex", __DIR__),
    iat_index_template:
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/iat_live/index.html.heex",
        __DIR__
      ),
    iat_new: Path.expand("../../../../../lib/lockspire/web/live/admin/iat_live/new.ex", __DIR__),
    iat_new_template:
      Path.expand("../../../../../lib/lockspire/web/live/admin/iat_live/new.html.heex", __DIR__),
    keys_index:
      Path.expand("../../../../../lib/lockspire/web/live/admin/keys_live/index.ex", __DIR__),
    keys_show:
      Path.expand("../../../../../lib/lockspire/web/live/admin/keys_live/show.ex", __DIR__),
    keys_action_component:
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/keys_live/action_component.ex",
        __DIR__
      ),
    policies_index:
      Path.expand("../../../../../lib/lockspire/web/live/admin/policies_live/index.ex", __DIR__),
    policies_par:
      Path.expand("../../../../../lib/lockspire/web/live/admin/policies_live/par.ex", __DIR__),
    policies_dpop:
      Path.expand("../../../../../lib/lockspire/web/live/admin/policies_live/dpop.ex", __DIR__),
    policies_security_profile:
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/policies_live/security_profile.ex",
        __DIR__
      ),
    policies_dcr:
      Path.expand("../../../../../lib/lockspire/web/live/admin/policies_live/dcr.ex", __DIR__),
    policies_dcr_template:
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/policies_live/dcr.html.heex",
        __DIR__
      )
  }
  @phase_124_expected_configure_routes [
    "/admin/clients",
    "/admin/clients/:client_id",
    "/admin/clients/:client_id/edit",
    "/admin/clients/:client_id/edit?workflow=logout-propagation",
    "/admin/clients/:client_id/logout-uris",
    "/admin/clients/:client_id/par-policy",
    "/admin/clients/:client_id/redirects",
    "/admin/clients/:client_id/rotate-registration-access-token",
    "/admin/clients/:client_id/rotate-secret",
    "/admin/clients/:client_id/security-profile",
    "/admin/dcr",
    "/admin/iats",
    "/admin/iats/new",
    "/admin/keys",
    "/admin/keys/:id",
    "/admin/policies",
    "/admin/policies/dcr",
    "/admin/policies/dpop",
    "/admin/policies/par",
    "/admin/policies/security-profile"
  ]
  @phase_124_required_primitives %{
    clients_index: [:page_hero, :copy_once_secret_panel, :status_badge],
    clients_show: [
      :page_hero,
      :action_group,
      :confirmation_panel,
      :copy_once_secret_panel,
      :long_value,
      :status_badge
    ],
    clients_rotate_secret: [:copy_once_secret_panel],
    dcr_index: [:page_hero, :decision_summary],
    iat_index_template: [
      :page_hero,
      :dense_resource_row,
      :long_value,
      :status_badge,
      :confirmation_panel
    ],
    iat_new_template: [:page_hero, :copy_once_secret_panel],
    keys_index: [:page_hero, :action_group, :long_value, :status_badge],
    keys_show: [:page_hero, :long_value, :status_badge],
    keys_action_component: [:confirmation_panel, :long_value],
    policies_index: [:page_hero],
    policies_par: [:page_hero, :decision_summary],
    policies_dpop: [:page_hero, :decision_summary],
    policies_security_profile: [:page_hero, :decision_summary],
    policies_dcr_template: [:page_hero, :decision_summary]
  }

  describe "Phase 125 rendered HTML assertion helper contracts" do
    test "disabled link helper rejects anchor-shaped disabled actions and accepts semantic links" do
      disabled_anchor =
        ~s(<a href="/admin/clients" class="lockspire-admin-btn lockspire-admin-btn-disabled">Disabled link action</a>)

      error =
        assert_raise ExUnit.AssertionError, fn ->
          HtmlAssertions.assert_disabled_links_have_semantics(disabled_anchor)
        end

      assert Exception.message(error) =~ "expected disabled link actions to expose"

      semantic_disabled_link =
        ~s(<span role="link" aria-disabled="true" class="lockspire-admin-btn lockspire-admin-btn-secondary">Disabled link action</span>)

      assert HtmlAssertions.assert_disabled_links_have_semantics(semantic_disabled_link) ==
               semantic_disabled_link
    end

    test "token-like text helper rejects rendered credential and private-key shapes" do
      denied_examples = [
        {"JWT-looking text",
         "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhY2NvdW50LTEyMyJ9.signaturevalue1234567890"},
        {"live-key-looking text", "sk_live_51JxExampleSecretValue"},
        {"cookie/auth-code-like text", "cookie=session_id%3Dabcdef1234567890"},
        {"cookie/auth-code-like text", "authorization_code=SplxlOBeZQQYbYS6WxSbIA"},
        {"private-key-like text", "-----BEGIN PRIVATE KEY-----"}
      ]

      for {label, value} <- denied_examples do
        error =
          assert_raise ExUnit.AssertionError, fn ->
            HtmlAssertions.assert_no_token_like_text("<p>#{value}</p>")
          end

        assert Exception.message(error) =~ "expected rendered HTML to omit #{label}"
      end

      safe_html = "<p>client_secret_jwt support is documented without sample keys.</p>"

      assert HtmlAssertions.assert_no_token_like_text(safe_html) == safe_html
    end
  end

  describe "Phase 125 browser evidence artifact contracts" do
    test "browser evidence parser accepts strict representative evidence rows" do
      markdown = """
      ## Evidence Rows

      | Route / Surface | Journey | Viewport | Theme | Motion | Focus path | State | scrollWidth | clientWidth | Result | Scrubbed notes | Sensitive evidence check | Gap note | Deterministic command outcome |
      |---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|
      | `/admin` | Orient | 320px | light | default | overview nav -> Configure link | dense cockpit | 320 | 320 | pass | local maintainer note; no screenshots retained | passed denylist | none | contract test pass |
      | `AdminLab.StressSurface` | Internal lab | 1440px | system | reduced-motion | stress fixture tab order | long-data fixture | 1440 | 1440 | pass | internal lab render only; values synthetic | passed denylist | none | component stress pass |
      """

      assert [
               %{
                 "Route / Surface" => "/admin",
                 "Journey" => "Orient",
                 "Viewport" => "320px",
                 "scrollWidth" => 320,
                 "clientWidth" => 320,
                 "Result" => "pass"
               },
               %{
                 "Route / Surface" => "AdminLab.StressSurface",
                 "Journey" => "Internal lab",
                 "Viewport" => "1440px",
                 "scrollWidth" => 1440,
                 "clientWidth" => 1440,
                 "Result" => "pass"
               }
             ] = BrowserEvidence.parse!(markdown)

      assert BrowserEvidence.required_columns() == [
               "Route / Surface",
               "Journey",
               "Viewport",
               "Theme",
               "Motion",
               "Focus path",
               "State",
               "scrollWidth",
               "clientWidth",
               "Result",
               "Scrubbed notes",
               "Sensitive evidence check",
               "Gap note",
               "Deterministic command outcome"
             ]

      assert BrowserEvidence.allowed_results() == ["pass", "fail", "gap", "blocked"]
    end

    test "browser evidence parser rejects malformed artifact rows" do
      missing_columns = """
      | Route / Surface | Journey | Viewport | Theme | Motion | Focus path | State | scrollWidth | Result | Scrubbed notes | Sensitive evidence check | Gap note | Deterministic command outcome |
      |---|---|---|---|---|---|---|---:|---|---|---|---|---|
      | `/admin` | Orient | 320px | light | default | overview nav | dense | 320 | pass | local note | passed denylist | none | contract test pass |
      """

      error = assert_raise ArgumentError, fn -> BrowserEvidence.parse!(missing_columns) end
      assert Exception.message(error) =~ "missing required evidence columns"
      assert Exception.message(error) =~ "clientWidth"

      invalid_result = String.replace(valid_browser_evidence_markdown(), "| pass |", "| maybe |")
      error = assert_raise ArgumentError, fn -> BrowserEvidence.parse!(invalid_result) end
      assert Exception.message(error) =~ ~s(invalid Result "maybe")

      invalid_width =
        String.replace(valid_browser_evidence_markdown(), "| 390 | 390 |", "| wide | 390 |")

      error = assert_raise ArgumentError, fn -> BrowserEvidence.parse!(invalid_width) end
      assert Exception.message(error) =~ ~s(nonnumeric scrollWidth "wide")

      malformed_route =
        String.replace(valid_browser_evidence_markdown(), "`/admin/tokens`", "`admin/tokens`")

      error = assert_raise ArgumentError, fn -> BrowserEvidence.parse!(malformed_route) end
      assert Exception.message(error) =~ ~s(malformed Route / Surface "admin/tokens")

      duplicate = valid_browser_evidence_markdown() <> valid_browser_evidence_markdown()
      error = assert_raise ArgumentError, fn -> BrowserEvidence.parse!(duplicate) end
      assert Exception.message(error) =~ "duplicate evidence row"
    end

    test "browser evidence redaction checks reject sensitive evidence text" do
      for forbidden <- [
            "cookie=session_id%3Dabcdef1234567890",
            "authorization_code=SplxlOBeZQQYbYS6WxSbIA",
            "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhY2NvdW50LTEyMyJ9.signaturevalue1234567890",
            "client_secret=plaintext-secret-value",
            "-----BEGIN PRIVATE KEY-----",
            "code_verifier=verifier-material-value",
            "device_code=ABCD-EFGH-IJKL",
            "user_code=WDJB-MJHT",
            "copy-once secret shown in screenshot",
            "https://accounts.lockspire.com/admin"
          ] do
        error =
          assert_raise ArgumentError, fn -> BrowserEvidence.assert_redaction_safe!(forbidden) end

        assert Exception.message(error) =~ "sensitive evidence"
      end

      safe_note =
        "local maintainer note with scrubbed route, numeric widths, no screenshots retained"

      assert BrowserEvidence.assert_redaction_safe!(safe_note) == safe_note
    end

    test "closeout proof artifact has required non-gap representative evidence rows" do
      artifact = File.read!(@phase_125_proof_path)
      BrowserEvidence.assert_redaction_safe!(artifact)

      rows = BrowserEvidence.parse!(artifact)

      required_rows = [
        {"/admin", "Orient", "320px", "light", "default"},
        {"/admin/clients", "Configure", "390px", "dark", "reduced-motion"},
        {"/admin/tokens", "Support", "768px", "system", "default"},
        {"/admin/logouts", "Operate", "1024px", "dark", "reduced-motion"},
        {"AdminLab.StressSurface", "Internal lab", "1440px", "system", "default"}
      ]

      for {route, journey, viewport, theme, motion} <- required_rows do
        row =
          Enum.find(rows, fn row ->
            row["Route / Surface"] == route and row["Journey"] == journey and
              row["Viewport"] == viewport and row["Theme"] == theme and
              row["Motion"] == motion
          end)

        assert row, "missing required proof row for #{route} #{viewport} #{theme} #{motion}"
        assert row["Result"] == "pass"
        assert row["scrollWidth"] <= row["clientWidth"]
        assert row["Gap note"] == "none"
        assert row["Sensitive evidence check"] == "passed denylist"
      end

      assert Enum.map(rows, & &1["Viewport"]) |> Enum.sort() == [
               "1024px",
               "1440px",
               "320px",
               "390px",
               "768px"
             ]

      assert Enum.uniq(Enum.map(rows, & &1["Theme"])) |> Enum.sort() == [
               "dark",
               "light",
               "system"
             ]

      assert Enum.uniq(Enum.map(rows, & &1["Motion"])) |> Enum.sort() == [
               "default",
               "reduced-motion"
             ]
    end

    test "closeout proof artifact records source truth, commands, and adversarial signoff" do
      artifact = File.read!(@phase_125_proof_path)

      for phrase <- [
            "Maintainer-only final proof artifact",
            "AdminRouter source truth",
            "`/admin/clients/:client_id/edit?workflow=logout-propagation`",
            "Deterministic commands are the blocking proof path",
            "Representative browser/manual evidence rows",
            "Sensitive evidence denylist",
            "Explicit gaps",
            "Final adversarial review",
            "aesthetic overfit",
            "accessibility",
            "generic admin-template drift",
            "backend implementation leakage",
            "host integration weight",
            "screenshot-only quality",
            "theme, motion, and focus regressions",
            "redaction failures",
            "unsupported action creep",
            "stale route evidence",
            "package/runtime creep",
            "support-surface expansion"
          ] do
        assert artifact =~ phrase
      end

      for forbidden <- [
            "package.json",
            "playwright.config",
            "node_modules",
            "CI browser gate",
            "public browser proof route",
            "WCAG certification"
          ] do
        refute artifact =~ forbidden
      end
    end
  end

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

  describe "Phase 120 source docs CSS contracts" do
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

  describe "Phase 121 route scorecard contracts" do
    test "phase 121 route scorecards cover AdminRouter route truth" do
      scorecards = phase_121_scorecards()

      assert Map.keys(scorecards) |> Enum.sort() == RouteScorecards.expected_routes()
      assert length(RouteScorecards.expected_routes()) == 29

      assert RouteScorecards.workflow_exceptions() == [
               "/admin/clients/:client_id/edit?workflow=logout-propagation"
             ]
    end

    test "phase 121 route scorecards enforce required judgment fields" do
      markdown = phase_121_scorecards_markdown()
      scorecards = RouteScorecards.parse!(markdown)

      assert Map.keys(scorecards) |> Enum.filter(&String.contains?(&1, "?workflow=")) ==
               RouteScorecards.workflow_exceptions()

      for {_route, fields} <- scorecards,
          required_field <- RouteScorecards.required_fields() do
        assert Map.has_key?(fields, required_field), "missing #{required_field}"
        refute non_final_scorecard_value?(fields[required_field])
      end

      for {route, fields} <- scorecards do
        assert trimmed_backtick_value(fields["Route"]) == route
        assert fields["Journey"] in @phase_121_journeys
        assert fields["Evidence class"] in RouteScorecards.allowed_evidence_classes()
        assert fields["Public support promise"] == RouteScorecards.support_promise()
        assert generic_cta?(fields["Primary action"]) == false

        for field <- ["Earned-place check", "Component/group fit"],
            unearned <- @phase_121_unearned_fit_values do
          refute Regex.match?(~r/\b#{Regex.escape(unearned)}\b/i, fields[field])
        end
      end

      rendered_primary_actions =
        scorecards
        |> Enum.map_join("\n", fn {_route, fields} ->
          "<button>#{fields["Primary action"]}</button>"
        end)

      HtmlAssertions.assert_no_generic_cta_text(rendered_primary_actions)

      for scope <- @phase_121_rubric_scopes do
        assert phase_121_rubric_questions(markdown, scope) == @phase_121_rubric_questions
      end
    end

    test "phase 121 route scorecard parser rejects duplicate field labels" do
      markdown = """
      ### Scorecard: `/admin`

      - **Route:** `/admin`
      - **Route:** duplicate value
      """

      error = assert_raise ArgumentError, fn -> RouteScorecards.parse!(markdown) end

      assert Exception.message(error) =~ ~s(duplicate field "Route" in scorecard "/admin")
    end

    test "phase 121 route scorecard follow-up routes stay inside known route truth" do
      scorecards = phase_121_scorecards()

      known_routes =
        scorecards
        |> Map.keys()
        |> MapSet.new()
        |> MapSet.union(MapSet.new(RouteScorecards.workflow_exceptions()))

      for {route, fields} <- scorecards do
        follow_up = String.trim(fields["Follow-up route"])

        assert MapSet.member?(known_routes, trimmed_backtick_value(follow_up)) or
                 explicit_non_route_follow_up?(follow_up),
               "invalid follow-up route #{inspect(follow_up)} in #{route}"
      end

      assert explicit_non_route_follow_up?("none")
      assert explicit_non_route_follow_up?("Documentation-only: operator runbook")
      refute explicit_non_route_follow_up?("/admin/nonexistent")
      refute explicit_non_route_follow_up?("/admin/none")
    end

    test "phase 121 scorecards preserve support boundary and deny public surface creep" do
      markdown = phase_121_scorecards_markdown()
      scorecards = RouteScorecards.parse!(markdown)
      operator_doc = File.read!(@operator_admin_doc_path)
      supported_surface = File.read!(@supported_surface_doc_path)
      router = File.read!(@admin_router_path)
      mix = File.read!(@mix_path)

      for {_route, fields} <- scorecards do
        assert fields["Public support promise"] == RouteScorecards.support_promise()

        assert fields["Runtime/package impact"] =~
                 "no router, runtime, browser package, docs support-surface, or Hex package change"
      end

      for source <- [
            markdown,
            operator_doc,
            supported_surface,
            mix,
            router,
            phase_121_proof_blob()
          ] do
        assert_no_phase_121_secret_evidence(source)
      end

      assert operator_doc =~
               "Lockspire owns protocol and operator state after the request reaches its LiveViews"

      assert operator_doc =~
               "the host owns staff sessions, MFA, role checks, tenant policy, layouts, branding, product-specific authorization"

      for forbidden <- ["component_lab", "design_system_lab", "scorecard", "storybook"] do
        refute String.downcase(router) =~ forbidden
      end

      assert_phase_121_supported_surface_ceiling(supported_surface)
      assert_phase_121_package_boundary(mix)
    end

    test "phase 121 secret evidence guard catches OAuth credential leak shapes" do
      for source <- [
            "Authorization: Bearer mF_9.B5f-4.1JqM2x3Y4z5a6b7c8d9e0",
            "client_secret=s3cr3t-value-123",
            "https://client.example/callback?access_token=abc1234567890DEF",
            ~s("refresh_token": "refresh-token-value-123"),
            "-----BEGIN EC PRIVATE KEY-----"
          ] do
        assert_raise ExUnit.AssertionError, fn -> assert_no_phase_121_secret_evidence(source) end
      end

      for source <- [
            "Authorization bearer token evidence is prohibited by policy.",
            "client_secret_jwt is documented as a narrow client-auth method.",
            "conn.assigns.access_token is host-owned enforcement context.",
            "device_code_test.exs is a file path reference."
          ] do
        assert_no_phase_121_secret_evidence(source)
      end
    end

    test "phase 121 operate scorecards preserve read-only support truth" do
      scorecards = phase_121_scorecards()

      for route <- ["/admin/interactions", "/admin/device_authorizations", "/admin/logouts"] do
        fields = Map.fetch!(scorecards, route)
        unsupported_action = fields["Unsupported action check"]

        assert unsupported_action =~ "Read-only support truth only"
        assert unsupported_action =~ "unless an existing backed domain API exists"

        refute unsupported_action =~
                 ~r/\b(Retry now|Discard now|Approve now|Deny now|Logout now|Run worker|Pause worker|Worker control)\b/i
      end
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
        __DIR__
      ),
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/policies_live/dcr.html.heex",
        __DIR__
      ),
      Path.expand("../../../../../lib/lockspire/web/live/admin/tokens_live/index.ex", __DIR__),
      Path.expand("../../../../../lib/lockspire/web/live/admin/consents_live/index.ex", __DIR__)
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
      source = File.read!(Path.expand("../../../../../#{path}", __DIR__))
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
      assert source =~ "AdminComponents.dense_resource_row"
      refute source =~ "AdminComponents.resource_item"
    end

    for path <- @phase_109_operations_sources do
      source = File.read!(path)

      assert source =~ "Operate"
      assert source =~ "AdminComponents.metric_grid"
      assert source =~ "AdminComponents.summary_stat"

      assert source =~ "AdminComponents.resource_item" or
               source =~ "AdminComponents.dense_resource_row"

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

    assert source_for("iat_live/index.html.heex") =~
             "Lockspire.Web.Components.AdminComponents.confirmation_panel"

    assert source_for("iat_live/index.html.heex") =~ "phx-submit=\"confirm_revoke_iat\""
    assert source_for("iat_live/index.html.heex") =~ "name=\"revoke[confirm]\""
    assert source_for("iat_live/index.html.heex") =~ "Revoke initial access token"
    refute source_for("iat_live/index.html.heex") =~ "data-confirm="
    assert source_for("clients_live/show.ex") =~ "AdminComponents.confirmation_panel"
    assert source_for("clients_live/show.ex") =~ "variant={if @client.active, do: :danger"
    assert source_for("clients_live/show.ex") =~ "phx-submit=\"toggle_client\""
    assert source_for("clients_live/show.ex") =~ "name=\"toggle[confirm]\""

    refute sources =~ "Playwright"
    refute sources =~ "screenshot"
    refute sources =~ "demo seed"
    refute sources =~ "visual regression"
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

  test "phase 119 DCR one-form semantics preserve policy fields and grouping" do
    dcr = source_for_phase_119("policies_live/dcr.html.heex")

    assert occurrence_count(dcr, ~s(phx-submit="save_policy")) == 1
    assert dcr =~ "Save global DCR policy"

    for heading <- [
          "Registration gate",
          "Allowlist decisions",
          "Lifetime defaults",
          "Token endpoint auth methods",
          "Risk and posture"
        ] do
      assert dcr =~ heading
    end

    for field_name <- [
          "policy[registration_policy]",
          "policy[dcr_allowed_scopes]",
          "policy[dcr_allowed_grant_types]",
          "policy[dcr_allowed_response_types]",
          "policy[dcr_allowed_redirect_uri_schemes]",
          "policy[dcr_allowed_redirect_uri_hosts]",
          "policy[dcr_allowed_token_endpoint_auth_methods]",
          "policy[dcr_default_client_lifetime_seconds]",
          "policy[dcr_default_client_secret_lifetime_seconds]",
          "policy[dcr_default_registration_access_token_lifetime_seconds]"
        ] do
      assert dcr =~ ~s(name="#{field_name}")
    end

    refute dcr =~ "phx-submit=\"mint\""
    refute dcr =~ "rotate_registration_access_token"
    refute dcr =~ "registration access token plaintext"
  end

  test "phase 119 operate queues stay read-only non-table and non-secret" do
    for source <- @phase_119_operate_sources |> Enum.map(&File.read!/1) do
      assert source =~ "Operate"
      assert source =~ "waiting for operator review"
      refute source =~ "lockspire-admin-table-wrap"
      refute source =~ ~r/phx-(click|submit)=/

      refute Regex.match?(
               ~r/\b(Retry now|Discard|Approve|Deny|Logout now|Worker control|Requeue|Run worker|Pause worker)\b/i,
               source
             )

      for forbidden <- [
            "device_code_hash",
            "user_code_hash",
            "client_secret_hash",
            "authorization_code",
            "refresh_token",
            "access_token",
            "private_key",
            "verifier_material"
          ] do
        refute source =~ forbidden
      end
    end

    assert source_for_phase_119("device_authorizations_live/index.ex") =~
             "without exposing device or user code material"

    assert source_for_phase_119("interactions_live/index.ex") =~
             "safe review context"

    assert source_for_phase_119("logout_deliveries_live/index.ex") =~
             "without adding worker controls"
  end

  test "phase 119 copy redaction and browser-boundary fences stay scoped" do
    sources = phase_119_source_blob()
    mix = File.read!(Path.expand("../../../../../mix.exs", __DIR__))

    for phrase <- [
          "DCR onboarding",
          "DCR policy",
          "post-logout redirect URIs",
          "logout propagation URIs",
          "Plaintext is shown once. Lockspire stores only the hash",
          "redacted_handle",
          "plaintext",
          "copy_once_secret_panel",
          "family-wide action",
          "remembered grant will no longer"
        ] do
      assert sources =~ phrase
    end

    refute Regex.match?(
             ~r/(?:^|>|\n)\s*(Submit|Continue|Go|Manage)\s*(?:<|\n|$)/,
             sources
           )

    for forbidden <- [
          "dangerous",
          "critical breach",
          "panic",
          "threat center",
          "attack map",
          "extreme caution",
          "Playwright",
          "playwright",
          "axe-core",
          "@axe-core",
          "screenshot",
          "browser proof",
          "visual regression"
        ] do
      refute sources =~ forbidden
    end

    for forbidden <- ["playwright", "axe-core", "@axe-core", "proof/browser", "package.json"] do
      refute mix =~ forbidden
    end
  end

  describe "Phase 123 operate queue contracts" do
    test "operate routes stay bounded to existing read-only queue pages" do
      router_source = File.read!(@admin_router_path)

      routes =
        Lockspire.Web.AdminRouter
        |> Phoenix.Router.routes()
        |> Enum.map(& &1.path)

      for {path, contract} <- @phase_123_route_contracts do
        assert path in routes
        assert router_source =~ ~s("#{path}")
        assert router_source =~ inspect(contract.module)
      end

      operate_paths =
        routes
        |> Enum.filter(fn path ->
          path in Map.keys(@phase_123_route_contracts) or
            String.starts_with?(path, "/operate") or
            String.starts_with?(path, "/interactions/") or
            String.starts_with?(path, "/device_authorizations/") or
            String.starts_with?(path, "/logouts/")
        end)

      assert Enum.sort(operate_paths) == Enum.sort(Map.keys(@phase_123_route_contracts))

      for forbidden <- [
            "component_lab",
            "component-lab",
            "browser_proof",
            "browser-proof",
            "storybook",
            "Storybook",
            "design_system",
            "design-system",
            "theme_lab",
            "theming"
          ] do
        refute router_source =~ forbidden
      end
    end

    test "Lockspire.Admin exposes no Operate queue mutation delegates" do
      admin_source = File.read!(Path.expand("../../../../../lib/lockspire/admin.ex", __DIR__))

      for forbidden_pattern <- [
            ~r/defdelegate\s+\w*(?:retry|discard|approve|deny|logout_now|requeue|pause|resume|worker)\w*_(?:interaction|device_authorization|logout_delivery|logout)/,
            ~r/defdelegate\s+(?:create|update|put|delete|retry|discard|approve|deny|logout_now|requeue|pause|resume|worker)\w*_(?:interaction|device_authorization|logout_delivery)/,
            ~r/defdelegate\s+(?:interaction|device_authorization|logout_delivery)\w*_(?:create|update|put|delete|retry|discard|approve|deny|logout_now|requeue|pause|resume|worker)\w*/
          ] do
        refute Regex.match?(forbidden_pattern, admin_source)
      end

      assert admin_source =~ "defdelegate list_device_authorizations"
      refute admin_source =~ "defdelegate list_interactions"
      refute admin_source =~ "defdelegate list_logout_deliveries"
    end

    test "operate LiveViews stay read-only non-table source surfaces with required primitives" do
      for {route, contract} <- @phase_123_route_contracts do
        source = phase_123_source_for(route)

        assert source =~ "Operate"
        assert source =~ contract.title
        assert source =~ contract.pane
        assert source =~ contract.read_path
        assert source =~ "Read-only"
        assert source =~ "redacted_handle"

        for primitive <- @phase_123_required_primitives do
          assert source =~ primitive
        end

        refute source =~ "def handle_event"
        refute source =~ "phx-click"
        refute source =~ "phx-submit"
        refute source =~ "<table"
        refute source =~ "responsive_table"
        refute source =~ "lockspire-admin-table-wrap"

        for label <- @phase_123_unsupported_command_labels do
          refute Regex.match?(~r/\b#{Regex.escape(label)}\b/i, source)
        end
      end
    end

    test "operate layout CSS preserves wrapping mobile focus theme and reduced motion contracts" do
      css = File.read!(@admin_css_path)

      assert Regex.match?(
               ~r/\.lockspire-admin-long-value\s*\{[^}]*overflow-wrap:\s*anywhere;[^}]*word-break:\s*break-word;/s,
               css
             )

      assert Regex.match?(
               ~r/\.lockspire-admin-lifecycle-row__meta,\s*\.lockspire-admin-dense-resource-row__meta\s*\{[^}]*display:\s*flex;[^}]*flex-wrap:\s*wrap;/s,
               css
             )

      assert Regex.match?(
               ~r/\.lockspire-admin-dense-resource-row__note\s*\{[^}]*flex:\s*1 1 100%;/s,
               css
             )

      assert Regex.match?(
               ~r/@media \(max-width: 720px\).*?\.lockspire-admin-dense-resource-row,[^{]*\{[^}]*flex-direction:\s*column;/s,
               css
             )

      assert css =~ ":focus-visible"
      assert css =~ "--ls-focus-ring-color"
      assert css =~ "outline: var(--ls-focus-ring-width) solid var(--ls-focus-ring-color);"
      assert css =~ ":root[data-theme=\"light\"]"
      assert css =~ ":root[data-theme=\"dark\"]"
      assert css =~ "@media (prefers-color-scheme: dark)"
      assert css =~ "--ls-color-info-bg-dark"
      assert css =~ "--ls-status-info-bg: var(--ls-color-info-bg-dark);"
      assert css =~ "@media (prefers-reduced-motion: reduce)"
      assert css =~ "transition-duration: 0.01ms !important"
      assert css =~ "transform: none;"
    end

    test "operate row components keep visible status text and wrapped long values" do
      components = File.read!(@admin_components_path)

      dense_row = component_declaration_block(components, "dense_resource_row")
      status_badge = component_declaration_block(components, "status_badge")
      long_value = component_declaration_block(components, "long_value")

      for slot <- ["slot(:meta)", "slot(:status)", "slot(:actions)"] do
        assert dense_row =~ slot
      end

      assert dense_row =~ "lockspire-admin-dense-resource-row__main"
      assert dense_row =~ "lockspire-admin-dense-resource-row__meta"
      assert dense_row =~ "render_slot(@status)"
      assert status_badge =~ "{@label}"
      assert status_badge =~ "data-status-tone"
      assert status_badge =~ "title={@title_text}"
      assert long_value =~ "{@value}"
      assert long_value =~ "Redacted"
      assert long_value =~ "lockspire-admin-redacted-value"
      assert components =~ "defp status_metadata(:approved, :device_authorization)"
      assert components =~ "defp status_label(:pending_login)"
      assert components =~ "defp status_label(:pending_consent)"
    end

    test "operate sources avoid raw protocol backend and worker field rendering" do
      for {route, forbidden_patterns} <- @phase_123_sensitive_render_patterns do
        source = phase_123_source_for(route)

        for forbidden <- forbidden_patterns do
          refute source =~ forbidden
        end
      end

      assert phase_123_source_for("/device_authorizations") =~
               "Redaction.handle(:device_authorization"

      assert phase_123_source_for("/logouts") =~ "delivery_failure_context"
      assert phase_123_source_for("/logouts") =~ "safe_failure_detail"
      refute phase_123_operate_source_blob() =~ "operate_queue_row"
      refute phase_123_operate_source_blob() =~ "operate_queue_page"
    end

    test "internal proof surfaces stay out of public routes docs and package inputs" do
      public_boundary =
        [
          File.read!(@admin_router_path),
          File.read!(@supported_surface_doc_path),
          File.read!(@mix_path)
        ]
        |> Enum.join("\n")
        |> String.downcase()

      for forbidden <- @phase_123_public_boundary_forbidden do
        refute public_boundary =~ forbidden
      end

      assert Path.expand("../../../../support/lockspire/web/admin_lab/fixtures.ex", __DIR__) =~
               "/test/support/lockspire/web/admin_lab/fixtures.ex"

      refute File.read!(@mix_path) =~ ~r/files:\s+~w\([^)]*test\/support/
    end
  end

  describe "Phase 124 Configure propagation contracts" do
    test "CONFIG-01 D-01 D-02 route truth stays AdminRouter and scorecard derived" do
      assert_configure_route_boundary!()
      assert_no_phase_124_public_surface!()
    end

    test "CONFIG-01 CONFIG-02 CONFIG-03 D-03 through D-10 Configure sources use approved primitives and action semantics" do
      sources = phase_124_configure_sources()
      source_blob = phase_124_configure_source_blob()

      visible_label_source =
        source_blob
        |> String.replace(~r/type="submit"/, "")
        |> String.replace(~r/"revoke"/, "")

      assert Map.keys(sources) |> Enum.sort() ==
               @phase_124_configure_source_paths |> Map.keys() |> Enum.sort()

      for group <- [:clients_index, :dcr_index, :iat_index_template, :keys_index, :policies_index] do
        assert Map.has_key?(sources, group), "missing Configure source group #{inspect(group)}"
      end

      for {source_key, primitives} <- @phase_124_required_primitives do
        source = Map.fetch!(sources, source_key)

        for primitive <- primitives do
          assert phase_124_primitive_present?(source, primitive),
                 "expected #{source_key} to use AdminComponents.#{primitive}"
        end
      end

      for label <- [
            "Filter clients",
            "Create client",
            "Review client configuration",
            "Edit client metadata",
            "Save metadata",
            "Save redirect URIs",
            "Save post-logout redirect URIs",
            "Save logout propagation",
            "Save PAR policy",
            "Save security profile",
            "Rotate client secret",
            "Rotate registration access token",
            "Review DCR onboarding",
            "Mint initial access token",
            "Review initial access tokens",
            "Review PAR policy",
            "Review security profile",
            "Review DPoP policy",
            "Review DCR policy",
            "Save global PAR policy",
            "Save global security profile",
            "Save global DPoP policy",
            "Save global DCR policy",
            "Generate signing key",
            "Generate encryption key",
            "Review key lifecycle",
            "Publish key",
            "Activate key",
            "Retire key"
          ] do
        assert source_blob =~ label, "missing approved Configure label #{inspect(label)}"
      end

      for denied <- phase_124_denied_action_labels() do
        refute Regex.match?(phase_124_action_label_pattern(denied), visible_label_source),
               "unexpected unsupported Configure action label #{inspect(denied)}"
      end

      for phrase <- [
            "Plaintext is shown once",
            "stores only the hash",
            "does not store or re-show",
            "redacted durable state",
            "name=\"toggle[confirm]\"",
            "name=\"revoke[confirm]\"",
            "AdminComponents.confirmation_panel",
            "AdminComponents.action_group"
          ] do
        assert source_blob =~ phrase, "missing Phase 124 copy/action contract #{inspect(phrase)}"
      end

      refute source_blob =~ "data-confirm="
    end
  end

  describe "Phase 125 PROOF-02 global guardrail contracts" do
    test "route scorecards remain source-derived with stable evidence and support promises" do
      assert_phase_125_route_scorecard_contract!()
    end

    test "source docs package and router boundaries reject public proof surface creep" do
      phase_125_contract_sources()
      |> assert_phase_125_public_surface_boundary!()
    end

    test "source and rendered contracts reject generic CTAs unsupported actions and redaction drift" do
      phase_125_contract_sources()
      |> assert_phase_125_copy_and_redaction_boundary!()
    end

    test "CSS source contracts preserve long value focus theme motion and responsive no-overflow claims" do
      phase_125_contract_sources()
      |> assert_phase_125_css_and_responsive_contract!()
    end
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

  defp phase_123_source_for("/interactions"),
    do: File.read!(Map.fetch!(@phase_123_operate_sources, :interactions))

  defp phase_123_source_for("/device_authorizations"),
    do: File.read!(Map.fetch!(@phase_123_operate_sources, :device_authorizations))

  defp phase_123_source_for("/logouts"),
    do: File.read!(Map.fetch!(@phase_123_operate_sources, :logouts))

  defp valid_browser_evidence_markdown do
    """
    ## Evidence Rows

    | Route / Surface | Journey | Viewport | Theme | Motion | Focus path | State | scrollWidth | clientWidth | Result | Scrubbed notes | Sensitive evidence check | Gap note | Deterministic command outcome |
    |---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|
    | `/admin/tokens` | Support | 390px | dark | reduced-motion | token filters -> revoked row | dense support | 390 | 390 | pass | local maintainer note; no screenshots retained | passed denylist | none | focused route proof pass |
    """
  end

  defp phase_125_contract_sources do
    %{
      css: File.read!(@admin_css_path),
      router: File.read!(@admin_router_path),
      mix: File.read!(@mix_path),
      operator_doc: File.read!(@operator_admin_doc_path),
      supported_surface: File.read!(@supported_surface_doc_path),
      admin_sources:
        [@admin_components_path | Path.wildcard(@admin_live_glob)]
        |> Enum.map_join("\n", &File.read!/1)
    }
  end

  defp assert_phase_125_route_scorecard_contract! do
    scorecards = phase_121_scorecards()
    expected_routes = RouteScorecards.expected_routes()

    assert Map.keys(scorecards) |> Enum.sort() == expected_routes
    assert length(expected_routes) == 29

    assert RouteScorecards.workflow_exceptions() == [
             "/admin/clients/:client_id/edit?workflow=logout-propagation"
           ]

    for {route, fields} <- scorecards do
      assert trimmed_backtick_value(fields["Route"]) == route
      assert fields["Evidence class"] in RouteScorecards.allowed_evidence_classes()
      assert fields["Public support promise"] == RouteScorecards.support_promise()

      assert fields["Runtime/package impact"] =~
               "no router, runtime, browser package, docs support-surface, or Hex package change"

      refute generic_cta?(fields["Primary action"])

      assert Regex.match?(
               ~r/\b(?:Do not|No |Only backed|Read-only|unless an existing backed domain API exists)\b/i,
               fields["Unsupported action check"]
             )
    end
  end

  defp assert_phase_125_public_surface_boundary!(%{
         router: router,
         mix: mix,
         operator_doc: operator_doc,
         supported_surface: supported_surface
       }) do
    canonical_public_surface = String.downcase(supported_surface)
    router_and_package = String.downcase(router <> "\n" <> mix)
    operator_doc_downcase = String.downcase(operator_doc)

    for forbidden <- [
          "component lab",
          "stress surface",
          "browser proof",
          "browser-proof",
          "route scorecard",
          "public design-system",
          "public theming",
          "theme engine",
          "playwright",
          "axe",
          "screenshot",
          "trace",
          "ai judge"
        ] do
      refute canonical_public_surface =~ forbidden
    end

    for forbidden <- [
          "component_lab",
          "component-lab",
          "browser_proof",
          "browser-proof",
          "storybook",
          "design_system",
          "design-system",
          "theme_lab",
          "public_theming",
          "playwright",
          "axe-core",
          "@axe-core",
          "screenshot",
          "trace",
          "browser binary"
        ] do
      refute router_and_package =~ forbidden
    end

    for phrase <- [
          "docs/supported-surface.md",
          "maintainer evidence only",
          "not a supported admin route",
          "not mounted through `Lockspire.Web.AdminRouter`",
          "not part of `docs/supported-surface.md`"
        ] do
      assert operator_doc =~ phrase
    end

    for forbidden <- [
          "public component lab",
          "public browser proof",
          "public browser-proof",
          "public design system",
          "public design-system",
          "public theming api",
          "browser-proof support",
          "playwright support",
          "required playwright",
          "axe support",
          "required axe",
          "screenshot support",
          "trace support",
          "ai judge gate",
          "ai judge release gate"
        ] do
      refute operator_doc_downcase =~ forbidden
    end

    [_, package_files] = Regex.run(~r/files:\s*~w\(([^)]*)\)/s, mix)

    for required <- ["lib", "priv", "docs", "mix.exs", "README.md", "CHANGELOG.md", "LICENSE"] do
      assert package_files =~ required
    end

    for forbidden <- [
          ".planning",
          "test/support",
          "test/lockspire",
          "125-V1.32-PROOF"
        ] do
      refute String.downcase(package_files) =~ String.downcase(forbidden)
    end

    for forbidden <- [
          "package.json",
          "package-lock.json",
          "node_modules",
          "playwright.config",
          "screenshots",
          "traces",
          "browser-proof"
        ] do
      refute String.downcase(package_files) =~ String.downcase(forbidden)
      refute String.downcase(mix) =~ String.downcase(forbidden)
    end

    assert Path.wildcard(Path.expand("../../../../../package*.json", __DIR__)) == []
    assert Path.wildcard(Path.expand("../../../../../playwright.config.*", __DIR__)) == []
  end

  defp assert_phase_125_copy_and_redaction_boundary!(%{
         admin_sources: admin_sources,
         operator_doc: operator_doc,
         supported_surface: supported_surface
       }) do
    source_and_docs = Enum.join([admin_sources, operator_doc, supported_surface], "\n")

    HtmlAssertions.assert_no_generic_cta_text(source_and_docs)
    HtmlAssertions.assert_no_token_like_text(source_and_docs)
    assert_no_phase_121_secret_evidence(source_and_docs)

    semantic_disabled_link =
      ~s(<span role="link" aria-disabled="true" class="lockspire-admin-btn lockspire-admin-btn-secondary">Disabled link action</span>)

    HtmlAssertions.assert_disabled_links_have_semantics(semantic_disabled_link)

    assert_raise ExUnit.AssertionError, fn ->
      HtmlAssertions.assert_disabled_links_have_semantics(
        ~s(<a href="/admin/logouts" class="lockspire-admin-btn lockspire-admin-btn-disabled">Disabled link action</a>)
      )
    end

    for label <- phase_125_unsupported_action_labels() do
      refute Regex.match?(~r/\b#{Regex.escape(label)}\b/i, admin_sources),
             "unexpected unsupported admin action label #{inspect(label)}"
    end
  end

  defp assert_phase_125_css_and_responsive_contract!(%{css: css, admin_sources: admin_sources}) do
    refute css =~ ~r/transition(?:-property)?\s*:\s*all\b/
    refute admin_sources =~ ~r/\sstyle=/

    assert css_rule(css, ".lockspire-admin-long-value") =~ "overflow-wrap: anywhere"
    assert css_rule(css, ".lockspire-admin-long-value") =~ "word-break: break-word"
    assert css_rule(css, ".lockspire-admin-copy-once-secret__value") =~ "overflow-wrap: anywhere"
    assert css_rule(css, ".lockspire-admin-description-list dd") =~ "overflow-wrap: anywhere"

    assert declaration_block(css, ".lockspire-admin-page-hero__main") =~ "min-width: 0"

    assert css_rule(
             css,
             ".lockspire-admin-pane__header,\n  .lockspire-admin-entity-header,\n  .lockspire-admin-lifecycle-row,\n  .lockspire-admin-dense-resource-row"
           ) =~ "min-width: 0"

    assert css_rule(
             css,
             ".lockspire-admin-pane__status,\n  .lockspire-admin-pane__actions,\n  .lockspire-admin-entity-header__actions,\n  .lockspire-admin-workflow-shell__actions,\n  .lockspire-admin-dense-resource-row__actions,\n  .lockspire-admin-lifecycle-row__actions"
           ) =~ "flex-wrap: wrap"

    assert css_rule(
             css,
             ".lockspire-admin-lifecycle-row__meta,\n  .lockspire-admin-dense-resource-row__meta"
           ) =~ "flex-wrap: wrap"

    assert css_rule(css, ".lockspire-admin-action-group") =~ "max-width: 100%"
    assert css_rule(css, ".lockspire-admin-action-group") =~ "min-width: 0"
    assert css_rule(css, ".lockspire-admin-responsive-table") =~ "min-width: 0"

    mobile_css = css_media_rule(css, "@media (max-width: 720px)")

    assert mobile_css =~ ".lockspire-admin-filter-bar"
    assert mobile_css =~ ".lockspire-admin-action-group"
    assert mobile_css =~ ".lockspire-admin-dense-resource-row"
    assert css_rule(mobile_css, ".lockspire-admin-responsive-table__list") =~ "display: grid"

    for selector <- [
          ".lockspire-admin-nav-item:focus-visible",
          ".lockspire-admin-theme-control select:focus-visible",
          ".lockspire-admin-field input:focus-visible",
          ".lockspire-admin-field select:focus-visible",
          ".lockspire-admin-field textarea:focus-visible",
          ".lockspire-admin-error-summary:focus-visible"
        ] do
      assert css =~ selector
    end

    assert css =~ "outline: var(--ls-focus-ring-width) solid var(--ls-focus-ring-color)"
    assert css =~ ":root[data-theme=\"light\"]"
    assert css =~ ":root[data-theme=\"dark\"]"
    assert css =~ "@media (prefers-color-scheme: dark)"
    assert phase_120_dark_vars(css) =~ "--ls-status-info-bg: var(--ls-color-info-bg-dark);"
    assert phase_120_dark_vars(css) =~ "--ls-focus-ring-color: var(--ls-color-brand-500);"
    assert css =~ "@media (prefers-reduced-motion: reduce)"
    assert css =~ "transition-duration: 0.01ms !important"
    assert css =~ "animation-duration: 0.01ms !important"
    assert css =~ "scroll-behavior: auto !important"
    assert css =~ "transform: none;"
  end

  defp phase_125_unsupported_action_labels do
    [
      "Retry now",
      "Discard now",
      "Approve now",
      "Deny now",
      "Logout now",
      "Run worker",
      "Worker control",
      "Pause worker",
      "Resume worker",
      "Reveal secret",
      "Reveal token",
      "Recover token",
      "Export credential",
      "Bulk revoke",
      "Force publish",
      "Debug token",
      "Fetch remote JWKS",
      "Developer portal",
      "Host tenant policy",
      "Public theming",
      "Component lab route",
      "Browser proof route",
      "Storybook"
    ]
  end

  defp phase_124_configure_sources do
    Map.new(@phase_124_configure_source_paths, fn {key, path} -> {key, File.read!(path)} end)
  end

  defp phase_124_configure_source_blob do
    phase_124_configure_sources()
    |> Map.values()
    |> Enum.join("\n")
  end

  defp phase_124_denied_action_labels do
    [
      "Apply",
      "Submit",
      "OK",
      "Open workflow",
      "Revoke",
      "Mint IAT",
      "Rotate secret",
      "Rotate RAT",
      "Reveal secret",
      "Reveal token",
      "Recover token",
      "Export credential",
      "Bulk revoke",
      "Force publish",
      "Retry logout delivery",
      "Discard queue item",
      "Approve DCR request",
      "Deny DCR request",
      "Reset nonce",
      "Debug token",
      "Fetch remote JWKS",
      "Developer portal",
      "Host tenant policy",
      "Public theming",
      "Component lab route",
      "Storybook"
    ]
  end

  defp assert_configure_route_boundary! do
    router_source = File.read!(@admin_router_path)
    scorecards = phase_121_scorecards()

    configure_routes =
      Lockspire.Web.AdminRouter
      |> Phoenix.Router.routes()
      |> Enum.map(&mounted_admin_route(&1.path))
      |> Kernel.++(RouteScorecards.workflow_exceptions())
      |> Enum.filter(&phase_124_configure_route?/1)
      |> Enum.sort()

    assert configure_routes == @phase_124_expected_configure_routes

    for route <- @phase_124_expected_configure_routes do
      assert Map.has_key?(scorecards, route), "missing scorecard for #{route}"
    end

    for forbidden <- [
          "component_lab",
          "component-lab",
          "design_system",
          "design-system",
          "storybook",
          "Storybook",
          "browser_proof",
          "browser-proof",
          "theme_lab",
          "theming"
        ] do
      refute router_source =~ forbidden
    end
  end

  defp assert_no_phase_124_public_surface! do
    mix = File.read!(@mix_path)
    supported_surface = File.read!(@supported_surface_doc_path)
    router = File.read!(@admin_router_path)

    public_boundary = String.downcase(Enum.join([mix, supported_surface, router], "\n"))

    for forbidden <- [
          "public configure api",
          "public component api",
          "public design-system",
          "public theming",
          "theme engine",
          "component lab route",
          "component-lab route",
          "storybook route",
          "browser proof route",
          "developer portal",
          "tenant policy editor",
          "host-owned policy editor",
          "playwright support",
          "required playwright",
          "axe support",
          "required axe"
        ] do
      refute public_boundary =~ forbidden
    end

    [_, package_files] = Regex.run(~r/files:\s*~w\(([^)]*)\)/s, mix)

    for forbidden <- [
          ".planning",
          "test/support/lockspire/web/admin_lab",
          "package.json",
          "package-lock.json",
          "node_modules",
          "playwright.config",
          "storybook",
          "stories",
          "browser-proof"
        ] do
      refute String.downcase(package_files) =~ String.downcase(forbidden)
      refute String.downcase(mix) =~ String.downcase(forbidden)
    end

    assert Path.wildcard(Path.expand("../../../../../priv/repo/migrations/*124*", __DIR__)) == []
    refute File.exists?(Path.expand("../../../../../package.json", __DIR__))
  end

  defp phase_124_configure_route?(route) do
    route in RouteScorecards.workflow_exceptions() or
      Enum.any?(
        [
          "/admin/clients",
          "/admin/dcr",
          "/admin/iats",
          "/admin/keys",
          "/admin/policies"
        ],
        &String.starts_with?(route, &1)
      )
  end

  defp phase_124_primitive_present?(source, primitive) do
    primitive = Atom.to_string(primitive)

    source =~ "AdminComponents.#{primitive}" or
      source =~ "Lockspire.Web.Components.AdminComponents.#{primitive}"
  end

  defp phase_124_action_label_pattern(label) do
    ~r/(?:^|>|\n|")\s*#{Regex.escape(label)}\s*(?:<|\n|"|$)/i
  end

  defp phase_123_operate_source_blob do
    @phase_123_operate_sources
    |> Map.values()
    |> Enum.map_join("\n", &File.read!/1)
  end

  defp phase_121_scorecards_markdown do
    File.read!(@phase_121_scorecards_path)
  end

  defp phase_121_scorecards do
    @phase_121_scorecards_path
    |> File.read!()
    |> RouteScorecards.parse!()
  end

  defp non_final_scorecard_value?(value) do
    value
    |> trimmed_backtick_value()
    |> String.downcase()
    |> then(&(&1 in @phase_121_non_final_values))
  end

  defp generic_cta?(value) do
    value
    |> trimmed_backtick_value()
    |> String.downcase()
    |> then(&(&1 in @phase_121_generic_ctas))
  end

  defp trimmed_backtick_value(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.trim_leading("`")
    |> String.trim_trailing("`")
    |> String.trim()
  end

  defp phase_121_rubric_questions(markdown, scope) do
    pattern =
      ~r/^### #{Regex.escape(scope)}\n\n(?<questions>(?:- .+\n)+)/m

    case Regex.named_captures(pattern, markdown) do
      %{"questions" => questions} ->
        questions
        |> String.split("\n", trim: true)
        |> Enum.map(&String.trim_leading(&1, "- "))

      nil ->
        flunk("missing Phase 121 rubric scope #{scope}")
    end
  end

  defp explicit_non_route_follow_up?(value) do
    value =
      value
      |> trimmed_backtick_value()
      |> String.downcase()

    not String.starts_with?(value, "/admin") and
      (value in ["none", "absent"] or
         Regex.match?(~r/\b(external|documentation-only|docs-only)\b/, value))
  end

  defp phase_121_proof_blob do
    [
      "test/support/lockspire/web/admin_proof/route_scorecards.ex",
      "test/support/lockspire/web/admin_proof/html_assertions.ex"
    ]
    |> Enum.map_join("\n", fn path ->
      File.read!(Path.expand("../../../../../#{path}", __DIR__))
    end)
  end

  defp assert_no_phase_121_secret_evidence(source) do
    for forbidden <- [
          "real-client-secret",
          "production-secret",
          "prod-access-token",
          "prod-refresh-token",
          "customer.example.com",
          "tenant.example.com",
          "sk_live_",
          "pk_live_",
          "eyJhbGci",
          "BEGIN PRIVATE KEY",
          "BEGIN RSA PRIVATE KEY"
        ] do
      refute source =~ forbidden
    end

    refute Regex.match?(~r/\beyJ[a-zA-Z0-9_-]{20,}\.[a-zA-Z0-9_-]{20,}/, source)

    for pattern <- [
          ~r/\bauthorization:\s*bearer\s+[a-z0-9._~+\/=-]{20,}/i,
          ~r/(?:^|[?&\s])(?:client_secret|access_token|refresh_token|id_token|device_code|user_code)=["']?[a-z0-9._~+\/=-]{8,}/i,
          ~r/"(?:client_secret|access_token|refresh_token|id_token|device_code|user_code)"\s*:\s*"[^"]{8,}"/i,
          ~r/-----BEGIN (?:RSA |EC )?PRIVATE KEY-----/
        ] do
      refute Regex.match?(pattern, source)
    end
  end

  defp assert_phase_121_supported_surface_ceiling(supported_surface) do
    supported_surface = String.downcase(supported_surface)

    for forbidden <- [
          "component lab",
          "stress surface",
          "route scorecard",
          "design system workflow",
          "design-system workflow",
          "public component api",
          "public design-system",
          "public theming",
          "theme engine",
          "playwright",
          "axe",
          "screenshot product",
          "browser proof"
        ] do
      refute supported_surface =~ forbidden
    end
  end

  defp assert_phase_121_package_boundary(mix) do
    [_, package_files] = Regex.run(~r/files:\s*~w\(([^)]*)\)/s, mix)

    for forbidden <- [
          ".planning",
          "121-ROUTE-SCORECARDS",
          "package.json",
          "package-lock.json",
          "node_modules",
          "playwright.config",
          "screenshots",
          "traces"
        ] do
      refute String.downcase(package_files) =~ String.downcase(forbidden)
      refute String.downcase(mix) =~ String.downcase(forbidden)
    end
  end

  defp phase_120_contract_sources do
    %{
      css: File.read!(@admin_css_path),
      tokens: @brandbook_tokens_path |> File.read!() |> Jason.decode!(),
      admin_sources:
        [@admin_components_path | Path.wildcard(@admin_live_glob)]
        |> Enum.map_join("\n", &File.read!/1),
      operation_sources: @phase_119_operate_sources |> Enum.map_join("\n", &File.read!/1),
      operator_doc: File.read!(@operator_admin_doc_path),
      supported_surface:
        File.read!(Path.expand("../../../../../docs/supported-surface.md", __DIR__)),
      mix: File.read!(Path.expand("../../../../../mix.exs", __DIR__))
    }
  end

  defp assert_phase_120_brand_token_anchors(%{css: css, tokens: tokens}) do
    expected_color_tokens = %{
      "--ls-color-brand-500" => get_in(tokens, ["color", "brand", "500", "value"]),
      "--ls-color-brand-600" => get_in(tokens, ["color", "brand", "600", "value"]),
      "--ls-color-brand-700" => get_in(tokens, ["color", "brand", "700", "value"]),
      "--ls-color-gray-50" => get_in(tokens, ["color", "neutral", "50", "value"]),
      "--ls-color-gray-950" => get_in(tokens, ["color", "neutral", "950", "value"]),
      "--ls-color-info-border-dark" => get_in(tokens, ["status", "dark", "info", "border"])
    }

    for {token, value} <- expected_color_tokens do
      assert css =~ "#{token}: #{value};"
    end

    for {token, token_path} <- [
          {"--ls-surface-page", ["semantic", "light", "surface-page", "value"]},
          {"--ls-surface-panel", ["semantic", "light", "surface-panel", "value"]},
          {"--ls-text-body", ["semantic", "light", "text-body", "value"]},
          {"--ls-text-accent", ["semantic", "light", "text-accent", "value"]},
          {"--ls-focus-ring-color", ["semantic", "light", "focus-ring", "value"]}
        ] do
      assert css =~ "#{token}: #{css_token_value(get_in(tokens, token_path))};"
    end

    dark_vars = phase_120_dark_vars(css)

    for {token, token_path} <- [
          {"--ls-surface-page", ["semantic", "dark", "surface-page", "value"]},
          {"--ls-surface-panel", ["semantic", "dark", "surface-panel", "value"]},
          {"--ls-text-body", ["semantic", "dark", "text-body", "value"]},
          {"--ls-text-accent", ["semantic", "dark", "text-accent", "value"]},
          {"--ls-focus-ring-color", ["semantic", "dark", "focus-ring", "value"]}
        ] do
      assert dark_vars =~ "#{token}: #{css_token_value(get_in(tokens, token_path))};"
    end

    assert css =~ "--ls-focus-ring-width: #{get_in(tokens, ["focus", "ring-width", "value"])};"
    assert css =~ "--ls-focus-ring-offset: #{get_in(tokens, ["focus", "ring-offset", "value"])};"

    assert css =~
             "--ls-motion-duration-fast: #{get_in(tokens, ["motion", "duration-fast", "value"])};"

    assert css =~
             "--ls-motion-duration-medium: #{get_in(tokens, ["motion", "duration-medium", "value"])};"
  end

  defp assert_phase_120_raw_color_allowlist(%{css: css, tokens: tokens}) do
    allowed_hex = tokens |> brandbook_hex_values() |> MapSet.new()

    offenders =
      ~r/#[0-9a-fA-F]{3,8}/
      |> Regex.scan(css)
      |> List.flatten()
      |> Enum.map(&String.downcase/1)
      |> Enum.uniq()
      |> Enum.reject(&MapSet.member?(allowed_hex, &1))

    assert offenders == [],
           "expected raw admin CSS hex colors to be backed by brandbook tokens, found #{inspect(offenders)}"
  end

  defp assert_phase_120_contrast_token_pairs(%{css: css, tokens: tokens}) do
    for mode <- ["light", "dark"],
        tone <- ["success", "warning", "danger", "info"],
        slot <- ["bg", "text", "border"] do
      assert get_in(tokens, ["status", mode, tone, slot])
      assert get_in(tokens, ["status", mode, tone, "wcag"]) in ["AA", "AAA"]
    end

    for tone <- ["success", "warning", "danger", "info"],
        slot <- ["bg", "text", "border"] do
      assert css =~
               "--ls-color-#{tone}-#{slot}: #{get_in(tokens, ["status", "light", tone, slot])};"

      assert css =~
               "--ls-color-#{tone}-#{slot}-dark: #{get_in(tokens, ["status", "dark", tone, slot])};"

      assert css =~ "--ls-status-#{tone}-#{slot}: var(--ls-color-#{tone}-#{slot});"
      assert css =~ "--ls-status-#{tone}-#{slot}: var(--ls-color-#{tone}-#{slot}-dark);"
    end

    for token <- [
          "--ls-surface-page",
          "--ls-surface-panel",
          "--ls-surface-muted",
          "--ls-text-strong",
          "--ls-text-body",
          "--ls-text-muted",
          "--ls-text-accent",
          "--ls-border-subtle",
          "--ls-border-strong",
          "--ls-focus-ring-color"
        ] do
      assert css =~ token <> ":"
      assert phase_120_dark_vars(css) =~ token <> ":"
    end
  end

  defp assert_phase_120_responsive_focus_theme_motion(%{css: css}) do
    assert css =~ "@media (max-width: 720px)"
    assert css =~ "grid-template-columns: minmax(0, 1fr)"
    assert css =~ "overflow-wrap: anywhere"
    assert css =~ "flex-wrap: wrap"
    assert css =~ "max-width: 100%"
    assert css =~ "min-width: 0"

    for selector <- [
          ".lockspire-admin-nav-item:focus-visible",
          ".lockspire-admin-theme-control select:focus-visible",
          ".lockspire-admin-field input:focus-visible",
          ".lockspire-admin-field select:focus-visible",
          ".lockspire-admin-field textarea:focus-visible",
          ".lockspire-admin-error-summary:focus-visible"
        ] do
      assert css =~ selector
    end

    assert css =~ "outline: var(--ls-focus-ring-width) solid var(--ls-focus-ring-color)"
    assert css =~ "outline-offset: var(--ls-focus-ring-offset)"
    assert css =~ "box-shadow: var(--ls-focus-ring-shadow)"

    for phrase <- [
          "color-scheme: light;",
          ":root[data-theme=\"light\"]",
          ":root[data-theme=\"dark\"]",
          "@media (prefers-color-scheme: dark)",
          ":root:not([data-theme=\"light\"])",
          "color-scheme: dark;"
        ] do
      assert css =~ phrase
    end

    assert css =~ "@media (prefers-reduced-motion: reduce)"
    assert css =~ "transition-duration: 0.01ms !important"
    assert css =~ "animation-duration: 0.01ms !important"
    assert css =~ "scroll-behavior: auto !important"
    assert css =~ "transform: none;"
  end

  defp assert_phase_120_public_boundary(%{
         operator_doc: operator_doc,
         supported_surface: supported_surface,
         mix: mix
       }) do
    public_blob = String.downcase(operator_doc <> "\n" <> supported_surface)

    for forbidden <- [
          "public component lab",
          "component lab route",
          "component-lab route",
          "design-system api",
          "design system api",
          "public design system",
          "public theming engine",
          "theme engine",
          "screenshot product",
          "screenshot support",
          "playwright support",
          "required playwright",
          "axe support",
          "required axe",
          "wcag certification",
          "wcag certified"
        ] do
      refute public_blob =~ forbidden
    end

    assert operator_doc =~
             "Lockspire owns protocol and operator state after the request reaches its LiveViews"

    assert operator_doc =~
             "the host owns staff sessions, MFA, role checks, tenant policy, layouts, branding, product-specific authorization"

    for forbidden <- [
          "playwright",
          "axe-core",
          "@axe-core",
          "playwright.config",
          "package.json",
          "browser proof",
          "visual regression"
        ] do
      refute String.downcase(mix) =~ forbidden
    end
  end

  defp assert_phase_120_operator_docs_proof(%{operator_doc: operator_doc}) do
    for phrase <- [
          "Design system workflow and proof boundary",
          "shared Phoenix components",
          "public component API",
          "component lab and stress surface are internal maintainer proof only",
          "not mounted through `Lockspire.Web.AdminRouter`",
          "not a supported admin route",
          "not part of `docs/supported-surface.md`",
          "**System** is the default",
          "**Light** and **Dark** are explicit admin-only choices",
          "Reduced-motion preferences",
          "Maintainer verification",
          "source contracts check shared primitives",
          "This section is maintainer-facing operator guidance",
          "Lockspire owns protocol and operator state after the request reaches its LiveViews",
          "host owns staff sessions, MFA, role checks, tenant policy, layouts, branding, product-specific authorization"
        ] do
      assert operator_doc =~ phrase
    end
  end

  defp assert_phase_120_supported_surface_ceiling(%{supported_surface: supported_surface}) do
    supported_surface = String.downcase(supported_surface)

    for forbidden <- [
          "component lab",
          "stress surface",
          "design system workflow",
          "design-system workflow",
          "public component api",
          "public design-system",
          "public theming",
          "theme engine",
          "playwright",
          "axe",
          "screenshot product",
          "browser proof"
        ] do
      refute supported_surface =~ forbidden
    end
  end

  defp assert_phase_120_package_dx_boundary(%{mix: mix}) do
    [_, package_files] = Regex.run(~r/files:\s*~w\(([^)]*)\)/s, mix)

    for required <- ["lib", "priv", "docs", "mix.exs", "README.md", "CHANGELOG.md", "LICENSE"] do
      assert package_files =~ required
    end

    for forbidden <- [
          ".planning",
          "120-BROWSER-PROOF",
          "package.json",
          "package-lock.json",
          "node_modules",
          "playwright.config",
          "screenshots",
          "traces",
          "tmp/admin-ui-polish"
        ] do
      refute String.downcase(package_files) =~ String.downcase(forbidden)
      refute String.downcase(mix) =~ String.downcase(forbidden)
    end
  end

  defp assert_phase_120_copy_boundaries(%{
         admin_sources: admin_sources,
         operation_sources: operation_sources,
         operator_doc: operator_doc,
         supported_surface: supported_surface
       }) do
    source_and_docs = admin_sources <> "\n" <> operator_doc <> "\n" <> supported_surface

    refute Regex.match?(
             ~r/(?:^|>|\n)\s*(Click here|Learn more|Read more|Submit|OK)\s*(?:<|\n|$)/i,
             source_and_docs
           )

    for forbidden <- [
          "critical breach",
          "panic",
          "threat center",
          "attack map",
          "extreme caution",
          "real-client-secret",
          "production-secret",
          "prod-access-token",
          "prod-refresh-token",
          "customer.example.com",
          "tenant.example.com",
          "sk_live_",
          "pk_live_",
          "eyJhbGci",
          "BEGIN PRIVATE KEY"
        ] do
      refute source_and_docs =~ forbidden
    end

    refute Regex.match?(~r/\beyJ[a-zA-Z0-9_-]{20,}\.[a-zA-Z0-9_-]{20,}/, source_and_docs)

    refute Regex.match?(
             ~r/\b(Retry now|Discard|Approve|Deny|Logout now|Worker control|Requeue|Run worker|Pause worker)\b/i,
             operation_sources
           )

    refute operation_sources =~ ~r/phx-(click|submit)=/
  end

  defp css_token_value("{" <> reference) do
    reference =
      reference
      |> String.trim_trailing("}")
      |> String.replace_prefix("color.neutral.", "color.gray.")
      |> String.replace(".", "-")

    "var(--ls-#{reference})"
  end

  defp css_token_value(value), do: value

  defp brandbook_hex_values(value) when is_map(value) do
    value
    |> Map.values()
    |> Enum.flat_map(&brandbook_hex_values/1)
    |> Enum.map(&String.downcase/1)
  end

  defp brandbook_hex_values(value) when is_list(value) do
    Enum.flat_map(value, &brandbook_hex_values/1)
  end

  defp brandbook_hex_values(value) when is_binary(value) do
    if Regex.match?(~r/^#[0-9a-fA-F]{3,8}$/, value), do: [value], else: []
  end

  defp brandbook_hex_values(_value), do: []

  defp phase_120_dark_vars(css) do
    case Regex.run(~r/@dark_vars\s+\"\"\"\n(?<vars>.*?)\n\s+\"\"\"/s, css, capture: [:vars]) do
      [vars] -> vars
      nil -> flunk("missing embedded @dark_vars CSS contract")
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

  defp phase_119_source_blob do
    @phase_119_sources
    |> Enum.map_join("\n", &File.read!/1)
  end

  defp source_for_phase_119(suffix) do
    @phase_119_sources
    |> Enum.find(fn path -> String.ends_with?(path, suffix) end)
    |> File.read!()
  end

  defp occurrence_count(source, needle) do
    source
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
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
