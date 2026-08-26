defmodule Lockspire.AdminContractHelpers do
  @moduledoc false

  defmacro __using__(_opts) do
    contract_dir = Path.expand("../lockspire/web/live/admin", __DIR__)

    quote bind_quoted: [contract_dir: contract_dir] do
      @contract_dir contract_dir

      alias Lockspire.Web.AdminProof.{BrowserEvidence, HtmlAssertions, RouteScorecards}

      @admin_live_glob Path.expand(
                         "../../../../../lib/lockspire/web/live/admin/**/*.{ex,heex}",
                         @contract_dir
                       )
      @admin_css_path Path.expand("../../../../../lib/lockspire/web/admin_css.ex", @contract_dir)
      @admin_components_path Path.expand(
                               "../../../../../lib/lockspire/web/components/admin_components.ex",
                               @contract_dir
                             )
      @admin_router_path Path.expand(
                           "../../../../../lib/lockspire/web/admin_router.ex",
                           @contract_dir
                         )
      @admin_layout_path Path.expand(
                           "../../../../../lib/lockspire/web/live/admin_layout_live.ex",
                           @contract_dir
                         )
      @brandbook_tokens_path Path.expand(
                               "../../../../../brandbook/tokens/tokens.json",
                               @contract_dir
                             )
      @operator_admin_doc_path Path.expand("../../../../../docs/operator-admin.md", @contract_dir)
      @supported_surface_doc_path Path.expand(
                                    "../../../../../docs/supported-surface.md",
                                    @contract_dir
                                  )
      @mix_path Path.expand("../../../../../mix.exs", @contract_dir)
      @adoption_demo_seeds_path Path.expand(
                                  "../../../../../examples/adoption_demo/priv/repo/seeds.exs",
                                  @contract_dir
                                )
      @phase_110_dir Path.expand(
                       "../../../../../.planning/milestones/v1.29-phases/110-demo-state-screenshots-docs-and-regression-proof",
                       @contract_dir
                     )
      @phase_116_dir Path.expand(
                       "../../../../../.planning/milestones/v1.31-phases/116-inventory-rubric-lab-contract",
                       @contract_dir
                     )
      @route_contract_path Path.expand(
                             "../../../../../.planning/milestones/v1.29-phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md",
                             @contract_dir
                           )
      @phase_121_scorecards_path Path.expand(
                                   "../../../../../.planning/milestones/v1.32-phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md",
                                   @contract_dir
                                 )
      @phase_125_proof_path Path.expand(
                              "../../../../../.planning/milestones/v1.32-phases/125-browser-proof-docs-adversarial-ratchet/125-V1.32-PROOF.md",
                              @contract_dir
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
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/tokens_live/index.ex",
          @contract_dir
        ),
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/tokens_live/show.ex",
          @contract_dir
        ),
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/consents_live/index.ex",
          @contract_dir
        ),
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/consents_live/show.ex",
          @contract_dir
        )
      ]
      @phase_109_operations_sources [
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/logout_deliveries_live/index.ex",
          @contract_dir
        ),
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/device_authorizations_live/index.ex",
          @contract_dir
        ),
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/interactions_live/index.ex",
          @contract_dir
        )
      ]
      @phase_109_configure_sources [
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/dcr_live/index.ex",
          @contract_dir
        ),
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/iat_live/index.ex",
          @contract_dir
        ),
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/iat_live/index.html.heex",
          @contract_dir
        ),
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/iat_live/new.html.heex",
          @contract_dir
        ),
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/keys_live/index.ex",
          @contract_dir
        ),
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/keys_live/show.ex",
          @contract_dir
        ),
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/keys_live/action_component.ex",
          @contract_dir
        ),
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/clients_live/show.ex",
          @contract_dir
        )
      ]
      @phase_109_focused_tests [
        Path.expand(
          "../../../../../test/lockspire/web/live/admin/tokens_live_test.exs",
          @contract_dir
        ),
        Path.expand(
          "../../../../../test/lockspire/web/live/admin/consents_live_test.exs",
          @contract_dir
        ),
        Path.expand(
          "../../../../../test/lockspire/web/live/admin/logout_deliveries_live_test.exs",
          @contract_dir
        ),
        Path.expand(
          "../../../../../test/lockspire/web/live/admin/device_authorizations_live_test.exs",
          @contract_dir
        ),
        Path.expand(
          "../../../../../test/lockspire/web/live/admin/interactions_live_test.exs",
          @contract_dir
        ),
        Path.expand(
          "../../../../../test/lockspire/web/live/admin/iat_live_test.exs",
          @contract_dir
        ),
        Path.expand(
          "../../../../../test/lockspire/web/live/admin/keys_live_test.exs",
          @contract_dir
        ),
        Path.expand(
          "../../../../../test/lockspire/web/live/admin/clients_live/show_test.exs",
          @contract_dir
        )
      ]
      @phase_109_sources @phase_109_support_sources ++
                           @phase_109_operations_sources ++ @phase_109_configure_sources
      @phase_119_client_sources [
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/clients_live/show.ex",
          @contract_dir
        )
      ]
      @phase_119_dcr_sources [
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/policies_live/dcr.html.heex",
          @contract_dir
        )
      ]
      @phase_119_iat_sources [
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/iat_live/index.html.heex",
          @contract_dir
        ),
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/iat_live/new.html.heex",
          @contract_dir
        )
      ]
      @phase_119_support_sources [
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/tokens_live/show.ex",
          @contract_dir
        ),
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/consents_live/show.ex",
          @contract_dir
        )
      ]
      @phase_119_operate_sources [
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/device_authorizations_live/index.ex",
          @contract_dir
        ),
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/interactions_live/index.ex",
          @contract_dir
        ),
        Path.expand(
          "../../../../../lib/lockspire/web/live/admin/logout_deliveries_live/index.ex",
          @contract_dir
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
            @contract_dir
          ),
        device_authorizations:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/device_authorizations_live/index.ex",
            @contract_dir
          ),
        logouts:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/logout_deliveries_live/index.ex",
            @contract_dir
          )
      }
      @phase_123_route_contracts %{
        "/interactions" => %{
          module: Lockspire.Web.Live.Admin.InteractionsLive.Index,
          title: "Authorization interaction queue",
          pane: "Review interactions",
          read_path: "Admin.list_interactions"
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
          read_path: "Admin.list_logout_deliveries"
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
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/clients_live/index.ex",
            @contract_dir
          ),
        clients_show:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/clients_live/show.ex",
            @contract_dir
          ),
        clients_form:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/clients_live/form_component.ex",
            @contract_dir
          ),
        clients_rotate_secret:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex",
            @contract_dir
          ),
        dcr_index:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/dcr_live/index.ex",
            @contract_dir
          ),
        iat_index:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/iat_live/index.ex",
            @contract_dir
          ),
        iat_index_template:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/iat_live/index.html.heex",
            @contract_dir
          ),
        iat_new:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/iat_live/new.ex",
            @contract_dir
          ),
        iat_new_template:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/iat_live/new.html.heex",
            @contract_dir
          ),
        keys_index:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/keys_live/index.ex",
            @contract_dir
          ),
        keys_show:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/keys_live/show.ex",
            @contract_dir
          ),
        keys_action_component:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/keys_live/action_component.ex",
            @contract_dir
          ),
        policies_index:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/policies_live/index.ex",
            @contract_dir
          ),
        policies_par:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/policies_live/par.ex",
            @contract_dir
          ),
        policies_dpop:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/policies_live/dpop.ex",
            @contract_dir
          ),
        policies_security_profile:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/policies_live/security_profile.ex",
            @contract_dir
          ),
        policies_dcr:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/policies_live/dcr.ex",
            @contract_dir
          ),
        policies_dcr_template:
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/policies_live/dcr.html.heex",
            @contract_dir
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

      def phase_123_source_for("/interactions"),
        do: File.read!(Map.fetch!(@phase_123_operate_sources, :interactions))

      def phase_123_source_for("/device_authorizations"),
        do: File.read!(Map.fetch!(@phase_123_operate_sources, :device_authorizations))

      def phase_123_source_for("/logouts"),
        do: File.read!(Map.fetch!(@phase_123_operate_sources, :logouts))

      def valid_browser_evidence_markdown do
        """
        ## Evidence Rows

        | Route / Surface | Journey | Viewport | Theme | Motion | Focus path | State | scrollWidth | clientWidth | Result | Scrubbed notes | Sensitive evidence check | Gap note | Deterministic command outcome |
        |---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|
        | `/admin/tokens` | Support | 390px | dark | reduced-motion | token filters -> revoked row | dense support | 390 | 390 | pass | local maintainer note; no screenshots retained | passed denylist | none | focused route proof pass |
        """
      end

      def phase_125_contract_sources do
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

      def assert_phase_125_route_scorecard_contract! do
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

      def assert_phase_125_public_surface_boundary!(%{
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
              "not part of `docs/supported-surface.md`",
              "scorecard -> page change -> deterministic guardrails -> browser/manual notes -> adversarial signoff",
              "Deterministic ExUnit, LiveViewTest, LazyHTML, source, and rendered HTML proof is the blocking path",
              "Browser/manual notes are supplemental maintainer proof",
              "internal lab and stress surfaces are test/support infrastructure",
              "AI/persona judge prompts are advisory maintainer input with human signoff only",
              "`docs/supported-surface.md` remains the public support ceiling"
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

        package_files = package_files_contract_text()

        for required <- [
              "lib/lockspire.ex",
              "lib/lockspire/web/admin_router.ex",
              "priv/repo/migrations/",
              "priv/templates/lockspire.install/router.ex",
              "docs/supported-surface.md",
              "mix.exs",
              "README.md",
              "CHANGELOG.md",
              "SECURITY.md",
              "LICENSE"
            ] do
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

        assert Path.wildcard(Path.expand("../../../../../package*.json", @contract_dir)) == []

        assert Path.wildcard(Path.expand("../../../../../playwright.config.*", @contract_dir)) ==
                 []
      end

      def assert_phase_125_copy_and_redaction_boundary!(%{
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

      def assert_phase_125_css_and_responsive_contract!(%{css: css, admin_sources: admin_sources}) do
        refute css =~ ~r/transition(?:-property)?\s*:\s*all\b/
        refute admin_sources =~ ~r/\sstyle=/

        assert css_rule(css, ".lockspire-admin-long-value") =~ "overflow-wrap: anywhere"
        assert css_rule(css, ".lockspire-admin-long-value") =~ "word-break: break-word"

        assert css_rule(css, ".lockspire-admin-copy-once-secret__value") =~
                 "overflow-wrap: anywhere"

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

      def phase_125_unsupported_action_labels do
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

      def phase_124_configure_sources do
        Map.new(@phase_124_configure_source_paths, fn {key, path} -> {key, File.read!(path)} end)
      end

      def phase_124_configure_source_blob do
        phase_124_configure_sources()
        |> Map.values()
        |> Enum.join("\n")
      end

      def phase_124_denied_action_labels do
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

      def assert_configure_route_boundary! do
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

      def assert_no_phase_124_public_surface! do
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

        package_files = package_files_contract_text()

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

        assert Path.wildcard(
                 Path.expand("../../../../../priv/repo/migrations/*124*", @contract_dir)
               ) == []

        refute File.exists?(Path.expand("../../../../../package.json", @contract_dir))
      end

      def phase_124_configure_route?(route) do
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

      def phase_124_primitive_present?(source, primitive) do
        primitive = Atom.to_string(primitive)

        source =~ "AdminComponents.#{primitive}" or
          source =~ "Lockspire.Web.Components.AdminComponents.#{primitive}"
      end

      def phase_124_action_label_pattern(label) do
        ~r/(?:^|>|\n|")\s*#{Regex.escape(label)}\s*(?:<|\n|"|$)/i
      end

      def phase_123_operate_source_blob do
        @phase_123_operate_sources
        |> Map.values()
        |> Enum.map_join("\n", &File.read!/1)
      end

      def phase_121_scorecards_markdown do
        File.read!(@phase_121_scorecards_path)
      end

      def phase_121_scorecards do
        @phase_121_scorecards_path
        |> File.read!()
        |> RouteScorecards.parse!()
      end

      def non_final_scorecard_value?(value) do
        value
        |> trimmed_backtick_value()
        |> String.downcase()
        |> then(&(&1 in @phase_121_non_final_values))
      end

      def generic_cta?(value) do
        value
        |> trimmed_backtick_value()
        |> String.downcase()
        |> then(&(&1 in @phase_121_generic_ctas))
      end

      def trimmed_backtick_value(value) do
        value
        |> to_string()
        |> String.trim()
        |> String.trim_leading("`")
        |> String.trim_trailing("`")
        |> String.trim()
      end

      def phase_121_rubric_questions(markdown, scope) do
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

      def explicit_non_route_follow_up?(value) do
        value =
          value
          |> trimmed_backtick_value()
          |> String.downcase()

        not String.starts_with?(value, "/admin") and
          (value in ["none", "absent"] or
             Regex.match?(~r/\b(external|documentation-only|docs-only)\b/, value))
      end

      def phase_121_proof_blob do
        [
          "test/support/lockspire/web/admin_proof/route_scorecards.ex",
          "test/support/lockspire/web/admin_proof/html_assertions.ex"
        ]
        |> Enum.map_join("\n", fn path ->
          File.read!(Path.expand("../../../../../#{path}", @contract_dir))
        end)
      end

      def assert_no_phase_121_secret_evidence(source) do
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

      def assert_phase_121_supported_surface_ceiling(supported_surface) do
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

      def assert_phase_121_package_boundary(mix) do
        package_files = package_files_contract_text()

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

      def package_files_contract_text do
        Mix.Project.config()
        |> Keyword.fetch!(:package)
        |> Keyword.fetch!(:files)
        |> Enum.join("\n")
      end

      def phase_120_contract_sources do
        %{
          css: File.read!(@admin_css_path),
          tokens: @brandbook_tokens_path |> File.read!() |> Jason.decode!(),
          admin_sources:
            [@admin_components_path | Path.wildcard(@admin_live_glob)]
            |> Enum.map_join("\n", &File.read!/1),
          operation_sources: @phase_119_operate_sources |> Enum.map_join("\n", &File.read!/1),
          operator_doc: File.read!(@operator_admin_doc_path),
          supported_surface:
            File.read!(Path.expand("../../../../../docs/supported-surface.md", @contract_dir)),
          mix: File.read!(Path.expand("../../../../../mix.exs", @contract_dir))
        }
      end

      def assert_phase_120_brand_token_anchors(%{css: css, tokens: tokens}) do
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

        assert css =~
                 "--ls-focus-ring-width: #{get_in(tokens, ["focus", "ring-width", "value"])};"

        assert css =~
                 "--ls-focus-ring-offset: #{get_in(tokens, ["focus", "ring-offset", "value"])};"

        assert css =~
                 "--ls-motion-duration-fast: #{get_in(tokens, ["motion", "duration-fast", "value"])};"

        assert css =~
                 "--ls-motion-duration-medium: #{get_in(tokens, ["motion", "duration-medium", "value"])};"
      end

      def assert_phase_120_raw_color_allowlist(%{css: css, tokens: tokens}) do
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

      def assert_phase_120_contrast_token_pairs(%{css: css, tokens: tokens}) do
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

      def assert_phase_120_responsive_focus_theme_motion(%{css: css}) do
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

      def assert_phase_120_public_boundary(%{
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

      def assert_phase_120_operator_docs_proof(%{operator_doc: operator_doc}) do
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

      def assert_phase_120_supported_surface_ceiling(%{supported_surface: supported_surface}) do
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

      def assert_phase_120_package_dx_boundary(%{mix: mix}) do
        package_files = package_files_contract_text()

        for required <- [
              "lib/lockspire.ex",
              "lib/lockspire/web/admin_router.ex",
              "priv/repo/migrations/",
              "priv/templates/lockspire.install/router.ex",
              "docs/supported-surface.md",
              "mix.exs",
              "README.md",
              "CHANGELOG.md",
              "SECURITY.md",
              "LICENSE"
            ] do
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

      def assert_phase_120_copy_boundaries(%{
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

      def css_token_value("{" <> reference) do
        reference =
          reference
          |> String.trim_trailing("}")
          |> String.replace_prefix("color.neutral.", "color.gray.")
          |> String.replace(".", "-")

        "var(--ls-#{reference})"
      end

      def css_token_value(value), do: value

      def brandbook_hex_values(value) when is_map(value) do
        value
        |> Map.values()
        |> Enum.flat_map(&brandbook_hex_values/1)
        |> Enum.map(&String.downcase/1)
      end

      def brandbook_hex_values(value) when is_list(value) do
        Enum.flat_map(value, &brandbook_hex_values/1)
      end

      def brandbook_hex_values(value) when is_binary(value) do
        if Regex.match?(~r/^#[0-9a-fA-F]{3,8}$/, value), do: [value], else: []
      end

      def brandbook_hex_values(_value), do: []

      def phase_120_dark_vars(css) do
        case Regex.run(~r/@dark_vars\s+\"\"\"\n(?<vars>.*?)\n\s+\"\"\"/s, css, capture: [:vars]) do
          [vars] -> vars
          nil -> flunk("missing embedded @dark_vars CSS contract")
        end
      end

      def inventory_row!(inventory, route) do
        row_prefix = "| `#{route}` |"

        inventory
        |> String.split("\n")
        |> Enum.find(&String.starts_with?(&1, row_prefix))
        |> case do
          nil -> flunk("missing inventory row for #{route}")
          row -> row
        end
      end

      def mounted_admin_routes(router_source) do
        ~r/live\(\s*"([^"]+)"/
        |> Regex.scan(router_source, capture: :all_but_first)
        |> List.flatten()
        |> Enum.map(&mounted_admin_route/1)
      end

      def mounted_admin_route("/"), do: "/admin"
      def mounted_admin_route(route), do: "/admin" <> route

      def phase_109_source_blob do
        @phase_109_sources
        |> Enum.map_join("\n", &File.read!/1)
      end

      def phase_109_test_blob do
        @phase_109_focused_tests
        |> Enum.map_join("\n", &File.read!/1)
      end

      def phase_119_source_blob do
        @phase_119_sources
        |> Enum.map_join("\n", &File.read!/1)
      end

      def source_for_phase_119(suffix) do
        @phase_119_sources
        |> Enum.find(fn path -> String.ends_with?(path, suffix) end)
        |> File.read!()
      end

      def occurrence_count(source, needle) do
        source
        |> String.split(needle)
        |> length()
        |> Kernel.-(1)
      end

      def phase_110_artifact_blob do
        [
          phase_110_path("110-CONTEXT.md"),
          phase_110_path("110-SCREENSHOTS.md"),
          phase_110_path("110-BROWSER-EVIDENCE.md")
        ]
        |> Enum.map_join("\n", &File.read!/1)
      end

      def screenshot_cell_present?(cell) do
        cell = String.trim(cell, "`")

        String.starts_with?(cell, "tmp/admin-ui-polish/") or
          String.starts_with?(cell, "Not captured -")
      end

      def source_for(suffix) do
        @phase_109_sources
        |> Enum.find(fn path -> String.ends_with?(path, suffix) end)
        |> File.read!()
      end

      def phase_110_path(filename) do
        Path.join(@phase_110_dir, filename)
      end

      def phase_116_path(filename) do
        Path.join(@phase_116_dir, filename)
      end

      def css_rule(css, selector) do
        pattern = ~r/#{Regex.escape(selector)}\s*\{(?<body>.*?)\}/s

        case Regex.named_captures(pattern, css) do
          %{"body" => body} -> body
          nil -> flunk("missing CSS selector #{selector}")
        end
      end

      def css_media_rule(css, media_query) do
        case :binary.match(css, media_query) do
          {start, _length} ->
            rest = String.slice(css, start..-1//1)

            end_offset =
              case :binary.match(rest, "\n  @media", [
                     {:scope,
                      {String.length(media_query),
                       String.length(rest) - String.length(media_query)}}
                   ]) do
                {offset, _length} -> offset
                :nomatch -> String.length(rest)
              end

            String.slice(rest, 0, end_offset)

          :nomatch ->
            flunk("missing CSS media query #{media_query}")
        end
      end

      def declaration_block(css, selector) do
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

      def component_declaration_block(source, function_name) do
        index = :binary.match(source, "def #{function_name}") |> elem(0)
        start = max(index - 700, 0)

        source
        |> String.slice(start, 1_400)
      end

      def public_component_defs(source) do
        ~r/^\s{2}def\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(/m
        |> Regex.scan(source, capture: :all_but_first)
        |> List.flatten()
        |> Enum.sort()
      end
    end
  end
end
