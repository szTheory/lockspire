defmodule Lockspire.Web.Live.Admin.DesignSystem.RouteContractTest do
  use ExUnit.Case, async: true
  use Lockspire.AdminContractHelpers

  describe "Route scorecard contracts" do
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
            @contract_dir
          ),
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/consents_live/index.ex",
            @contract_dir
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
          Path.expand(
            "../../../../../lib/lockspire/web/live/admin/dcr_live/index.ex",
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
            "../../../../../lib/lockspire/web/live/admin/clients_live/show.ex",
            @contract_dir
          )
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

  describe "Read-only operate queue contracts" do
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
      admin_source =
        File.read!(Path.expand("../../../../../lib/lockspire/admin.ex", @contract_dir))

      for forbidden_pattern <- [
            ~r/defdelegate\s+\w*(?:retry|discard|approve|deny|logout_now|requeue|pause|resume|worker)\w*_(?:interaction|device_authorization|logout_delivery|logout)/,
            ~r/defdelegate\s+(?:create|update|put|delete|retry|discard|approve|deny|logout_now|requeue|pause|resume|worker)\w*_(?:interaction|device_authorization|logout_delivery)/,
            ~r/defdelegate\s+(?:interaction|device_authorization|logout_delivery)\w*_(?:create|update|put|delete|retry|discard|approve|deny|logout_now|requeue|pause|resume|worker)\w*/
          ] do
        refute Regex.match?(forbidden_pattern, admin_source)
      end

      assert admin_source =~ "defdelegate list_device_authorizations"
      assert admin_source =~ "defdelegate list_interactions"
      assert admin_source =~ "defdelegate list_logout_deliveries"
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

      assert Path.expand("../../../../support/lockspire/web/admin_lab/fixtures.ex", @contract_dir) =~
               "/test/support/lockspire/web/admin_lab/fixtures.ex"

      refute File.read!(@mix_path) =~ ~r/files:\s+~w\([^)]*test\/support/
    end
  end

  describe "Configure workflow propagation contracts" do
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
end
