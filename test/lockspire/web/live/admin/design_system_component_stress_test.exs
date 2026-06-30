defmodule Lockspire.Web.Live.Admin.DesignSystemComponentStressTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Lockspire.Web.AdminLab.Fixtures
  alias Lockspire.Web.AdminLab.StressSurface
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Components.AdminComponents

  @admin_css_path Path.expand("../../../../../lib/lockspire/web/admin_css.ex", __DIR__)
  @admin_router_path Path.expand("../../../../../lib/lockspire/web/admin_router.ex", __DIR__)
  @mix_path Path.expand("../../../../../mix.exs", __DIR__)
  @supported_surface_path Path.expand("../../../../../docs/supported-surface.md", __DIR__)
  @phase_125_required_states [
    :empty,
    :one_item,
    :many_items,
    :dense_data,
    :high_count,
    :zero_count,
    :long_value,
    :missing_optional,
    :warning,
    :incident,
    :disabled,
    :expired,
    :revoked,
    :reuse_detected,
    :copy_once,
    :stale_read_only,
    :light,
    :dark,
    :system,
    :reduced_motion,
    :focus,
    :mobile_width,
    :orient,
    :configure,
    :support,
    :operate,
    :internal_lab
  ]
  @phase_125_required_classes [
    :cardinality_layout,
    :string_pressure,
    :optionality,
    :lifecycle_security,
    :visual_accessibility,
    :journey_boundary
  ]
  @phase_124_configure_source_paths [
    Path.expand("../../../../../lib/lockspire/web/live/admin/clients_live/index.ex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/clients_live/show.ex", __DIR__),
    Path.expand(
      "../../../../../lib/lockspire/web/live/admin/clients_live/form_component.ex",
      __DIR__
    ),
    Path.expand("../../../../../lib/lockspire/web/live/admin/dcr_live/index.ex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/iat_live/index.html.heex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/iat_live/new.html.heex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/keys_live/index.ex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/keys_live/show.ex", __DIR__),
    Path.expand(
      "../../../../../lib/lockspire/web/live/admin/keys_live/action_component.ex",
      __DIR__
    ),
    Path.expand("../../../../../lib/lockspire/web/live/admin/policies_live/index.ex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/policies_live/par.ex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/policies_live/dpop.ex", __DIR__),
    Path.expand(
      "../../../../../lib/lockspire/web/live/admin/policies_live/security_profile.ex",
      __DIR__
    ),
    Path.expand(
      "../../../../../lib/lockspire/web/live/admin/policies_live/dcr.html.heex",
      __DIR__
    )
  ]

  test "fixtures expose required lab keys and scenario states without forbidden values" do
    assert Fixtures.fixture_keys() == [
             :clients,
             :tokens,
             :consents,
             :keys,
             :dcr_iat,
             :operations,
             :structural_rows,
             :status_matrix,
             :proof_matrix,
             :theme_modes,
             :motion_modes
           ]

    for state <- [
          :normal,
          :empty,
          :error,
          :disabled,
          :destructive,
          :long_value,
          :dense_data,
          :light,
          :dark,
          :system,
          :reduced_motion,
          :healthy,
          :warning,
          :incident,
          :self_registered,
          :expired,
          :revoked,
          :reuse_detected,
          :copy_once,
          :one_item,
          :many_items,
          :high_count,
          :zero_count,
          :missing_optional,
          :stale_read_only,
          :focus,
          :mobile_width,
          :orient,
          :configure,
          :support,
          :operate,
          :internal_lab,
          :waiting,
          :completed,
          :provenance
        ] do
      assert state in Fixtures.scenario_states()
    end

    fixture_blob = inspect(Fixtures.all())

    for forbidden <- Fixtures.forbidden_substrings() do
      refute fixture_blob =~ forbidden
    end
  end

  test "PROOF-01 D-04 D-05 D-06 D-16 shared fixtures expose complete redaction-safe ugly-state matrix" do
    scenario_states = MapSet.new(Fixtures.scenario_states())
    fixtures = Fixtures.all()
    proof_matrix = Map.fetch!(fixtures, :proof_matrix)

    for state <- @phase_125_required_states do
      assert MapSet.member?(scenario_states, state),
             "D-05 PROOF-01 missing scenario state #{inspect(state)} in Fixtures.scenario_states/0"
    end

    matrix_states = proof_matrix |> Enum.map(& &1.state) |> MapSet.new()

    for state <- @phase_125_required_states do
      assert MapSet.member?(matrix_states, state),
             "D-04/D-05 shared fixture matrix must expose #{inspect(state)} without public lab surface"
    end

    matrix_classes = proof_matrix |> Enum.map(& &1.class) |> MapSet.new()

    for class <- @phase_125_required_classes do
      assert MapSet.member?(matrix_classes, class),
             "D-05 fixture matrix must include #{inspect(class)} coverage"
    end

    assert Enum.any?(proof_matrix, &(&1[:count] == 0)),
           "D-05 cardinality coverage must include zero-count state"

    assert Enum.any?(proof_matrix, &(&1[:count] > 100)),
           "D-05 cardinality coverage must include dense/high-count state"

    assert Enum.any?(proof_matrix, &(&1[:display_value] == "Not recorded")),
           "D-05 optionality coverage must include missing optional fields rendered as Not recorded"

    assert Enum.any?(
             proof_matrix,
             &String.contains?(to_string(&1[:long_url]), ".example.invalid")
           ),
           "D-16 string-pressure URLs must stay synthetic and non-production-looking"

    matrix_blob = inspect(proof_matrix)

    HtmlAssertions.assert_no_text(matrix_blob, Fixtures.forbidden_substrings())

    refute matrix_blob =~
             ~r/(sk_live_|pk_live_|BEGIN PRIVATE KEY|eyJhbGci|prod-access-token|prod-refresh-token)/
  end

  test "stress surface renders real admin components across required states" do
    html = render_component(&StressSurface.render/1, fixture_set: Fixtures.all())

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_describedby_targets_exist(html)
    HtmlAssertions.assert_label_targets_exist(html)

    HtmlAssertions.assert_no_text(html, [
      "Click here",
      "Learn more",
      "Read more",
      "Submit"
    ])

    HtmlAssertions.assert_no_text(html, Fixtures.forbidden_substrings())

    for phrase <- [
          "Render stress surface",
          "No lab scenarios rendered",
          "Component lab proof drifted from the design-system contract",
          "Revoke token family",
          "normal",
          "empty",
          "error",
          "disabled",
          "destructive",
          "long-value",
          "dense-data",
          "light",
          "dark",
          "system",
          "reduced-motion",
          "healthy",
          "warning",
          "incident",
          "self-registered",
          "expired",
          "revoked",
          "reuse-detected",
          "copy-once",
          "redacted",
          "Acme Ledger client",
          "Registration gate",
          "IAT-gated",
          "Decision summaries must keep dense policy state readable",
          "Dense queue row with generated identifier",
          "Token family incident",
          "Responsive table and list alternative",
          "Empty table/list alternative",
          "Workflow shell validation proof",
          "Approved, waiting",
          "Initial access token",
          "Unknown lab only"
        ] do
      assert html =~ phrase
    end

    for marker <- [
          ~s(data-lab-surface="component-stress"),
          ~s(data-theme-mode="light dark system"),
          ~s(data-motion-mode="default reduced-motion")
        ] do
      assert html =~ marker
    end

    for class <- [
          "lockspire-admin-page-hero",
          "lockspire-admin-badge-group",
          "lockspire-admin-badge-healthy",
          "lockspire-admin-badge-waiting",
          "lockspire-admin-badge-warning",
          "lockspire-admin-badge-danger",
          "lockspire-admin-badge-disabled",
          "lockspire-admin-badge-completed",
          "lockspire-admin-badge-provenance",
          "lockspire-admin-pane",
          "lockspire-admin-entity-header",
          "lockspire-admin-workflow-shell",
          "lockspire-admin-decision-summary",
          "lockspire-admin-status-cluster",
          "lockspire-admin-lifecycle-row",
          "lockspire-admin-dense-resource-row",
          "lockspire-admin-responsive-table",
          "lockspire-admin-responsive-table__list",
          "lockspire-admin-summary-stat",
          "lockspire-admin-card",
          "lockspire-admin-resource-list__item",
          "lockspire-admin-long-value",
          "lockspire-admin-error-summary",
          "lockspire-admin-field-error",
          "lockspire-admin-copy-once-secret",
          "lockspire-admin-confirmation-panel-danger",
          "lockspire-admin-action-group",
          "lockspire-admin-action-group__destructive",
          "lockspire-admin-btn",
          "lockspire-admin-empty"
        ] do
      assert html =~ class
    end

    for marker <- [
          ~s(role="link" aria-disabled="true"),
          ~s(id="stress-redirect-uri-help"),
          ~s(id="stress-redirect-uri-error"),
          ~s(aria-invalid="true"),
          ~s(aria-describedby="stress-redirect-uri-help stress-redirect-uri-error")
        ] do
      assert html =~ marker
    end

    for phrase <- [
          "Approved, waiting",
          "Reuse detected",
          "Revoked",
          "Completed",
          "Initial access token",
          "Unknown lab only",
          "Family-wide revocation is required when reuse is detected.",
          "Revoking this family invalidates all active refresh tokens",
          "Copy this value now. Lockspire stores only the hash after this response.",
          "Stored hash is shown for correlation only."
        ] do
      assert html =~ phrase
    end

    refute html =~ ~r/<a[^>]*aria-disabled="true"/
    refute html =~ ~r/<a[^>]*>\s*Disabled link action\s*<\/a>/s

    for forbidden <- Fixtures.forbidden_substrings() do
      refute html =~ forbidden
    end
  end

  test "PROOF-01 D-06 D-16 stress surface renders shared fixture matrix as internal lab evidence" do
    html = render_component(&StressSurface.render/1, fixture_set: Fixtures.all())

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_describedby_targets_exist(html)
    HtmlAssertions.assert_label_targets_exist(html)
    HtmlAssertions.assert_no_text(html, Fixtures.forbidden_substrings())

    assert html =~ ~s(data-phase="125-proof-matrix")
    assert html =~ "PROOF-01 shared fixture matrix"
    assert html =~ "Not recorded"
    assert html =~ "Internal lab boundary"
    assert html =~ "Mobile width"
    assert html =~ "Keyboard focus"
    assert html =~ "phase-125-long-fixture.example.invalid"

    for class <- @phase_125_required_classes do
      assert html =~ ~s(data-fixture-class="#{class}"),
             "rendered D-05 proof matrix must expose #{inspect(class)} class markers"
    end

    for state <- @phase_125_required_states do
      assert html =~ ~s(data-fixture-state="#{state}"),
             "rendered D-05 proof matrix must expose #{inspect(state)} state markers"
    end

    refute html =~ ~r/(package\.json|playwright\.config|storybook|browser-proof)/
  end

  test "stress surface renders its empty-state proof with empty fixture groups" do
    html =
      render_component(&StressSurface.render/1,
        fixture_set: %{
          clients: [],
          tokens: [],
          operations: [],
          dcr_iat: []
        }
      )

    assert html =~ "No lab scenarios rendered"
    assert html =~ "0"
    assert html =~ "Redacted"
    assert html =~ "lockspire-admin-responsive-table__list"
    refute html =~ "tenant-with-a-long-name.example.invalid"
  end

  test "Phase 124 CONFIG-01 CONFIG-02 CONFIG-03 Configure primitive stress proof covers copy-once confirmation grouping and long values" do
    html = phase_124_configure_stress_html()

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_describedby_targets_exist(html)
    HtmlAssertions.assert_label_targets_exist(html)

    assert html =~ "Initial access token minted"
    assert html =~ "phase-124-copy-once-value"
    assert html =~ "I have copied this secret"
    assert html =~ "name=\"revoke[confirm]\""
    assert html =~ "Revoke initial access token"
    assert html =~ "Review initial access tokens"
    assert html =~ "Keep token active"
    assert html =~ "lockspire-admin-action-group__primary"
    assert html =~ "lockspire-admin-action-group__secondary"
    assert html =~ "lockspire-admin-action-group__destructive"
    assert html =~ "redacted_handle_iat_01JZ2Z6GZ8T3D8QPMTZZZZZZZZ_wraps_anywhere"
    assert html =~ "https://configure-long.example.invalid/oauth/callbacks/configure"
    assert html =~ "Decision summary detail text stays visible before risky actions."

    HtmlAssertions.assert_no_text(html, Fixtures.forbidden_substrings())
  end

  test "Phase 124 UI-SPEC stress proof keeps semantic palette typography and visible Configure action labels" do
    css = File.read!(@admin_css_path)
    html = phase_124_configure_stress_html()
    source_blob = phase_124_configure_source_blob() <> "\n" <> html

    for token <- [
          "--ls-surface-page",
          "--ls-surface-panel",
          "--ls-surface-muted",
          "--ls-text-accent",
          "--ls-status-danger-bg",
          "--ls-status-info-bg",
          "--ls-focus-ring-color"
        ] do
      assert css =~ token
    end

    for token <- [
          "--ls-type-label-size",
          "--ls-type-body-size",
          "--ls-type-heading-size",
          "--ls-type-display-size"
        ] do
      assert css =~ token
    end

    assert css =~ "--ls-type-weight-regular: 400;"
    assert css =~ "--ls-type-weight-semibold: 600;"

    raw_color_offenders =
      source_blob
      |> String.split("\n")
      |> Enum.filter(&Regex.match?(~r/#[0-9a-fA-F]{3,8}/, &1))

    assert raw_color_offenders == []
    refute source_blob =~ ~r/style=/

    assert_phase_124_visible_action_labels!(html)
  end

  test "HTML proof helper fails blank ARIA references" do
    html = ~s(<p id="help">Help</p><input id="client-name" aria-describedby="">)

    assert_raise ExUnit.AssertionError, ~r/aria-describedby values to be non-empty/, fn ->
      HtmlAssertions.assert_describedby_targets_exist(html)
    end
  end

  test "HTML proof helper fails form controls that lose IDs and labels" do
    html =
      ~s(<form><label for="client-name">Client name</label><input id="client-name" name="client_name"><input name="redirect_uri" type="url"></form>)

    assert_raise ExUnit.AssertionError, ~r/every rendered form control to have a label/, fn ->
      HtmlAssertions.assert_label_targets_exist(html)
    end
  end

  test "component lab stays internal, test-only, and outside package/public routes" do
    router = File.read!(@admin_router_path)
    mix = File.read!(@mix_path)
    supported_surface = File.read!(@supported_surface_path)

    assert Path.expand("../../../../support/lockspire/web/admin_lab/fixtures.ex", __DIR__) =~
             "/test/support/lockspire/web/admin_lab/fixtures.ex"

    refute mix =~ ~r/files:\s+~w\([^)]*test\/support/

    for forbidden <- [
          "component-lab",
          "component_lab",
          "design-system-lab",
          "design_system_lab",
          "storybook",
          "Storybook",
          "browser-proof",
          "browser_proof",
          "public theming",
          "theme engine",
          "package.json",
          "playwright.config"
        ] do
      refute router =~ forbidden
      refute mix =~ forbidden
      refute supported_surface =~ forbidden
    end

    refute File.exists?(Path.expand("../../../../../package.json", __DIR__))
  end

  defp phase_124_configure_stress_html do
    assigns = %{
      copy_once_value:
        "phase-124-copy-once-value-redacted_handle_iat_01JZ2Z6GZ8T3D8QPMTZZZZZZZZ_wraps_anywhere",
      long_iat: "redacted_handle_iat_01JZ2Z6GZ8T3D8QPMTZZZZZZZZ_wraps_anywhere",
      long_url:
        "https://configure-long.example.invalid/oauth/callbacks/configure/self-registration/partner-handoff/with-long-path"
    }

    rendered_to_string(~H"""
    <section data-phase="124-configure-stress" aria-label="Phase 124 Configure stress proof">
      <AdminComponents.copy_once_secret_panel
        title="Initial access token minted"
        body="Plaintext is shown once. Copy before acknowledging; Lockspire stores only the hash and redacted durable state after this response."
        label="Initial access token"
        value={@copy_once_value}
        class="phase-124-copy-once-value"
      />
      <p id="phase-124-copy-ack">I have copied this secret</p>

      <AdminComponents.decision_summary>
        <:item
          label="Registration gate"
          value="IAT-gated"
          tone={:success}
          detail="Decision summary detail text stays visible before risky actions."
        >
        </:item>
        <:item
          label="Next safe action"
          value="Review initial access tokens"
          tone={:info}
          detail="Operators see posture and the next route before destructive controls."
        >
        </:item>
      </AdminComponents.decision_summary>

      <ul class="lockspire-admin-resource-list">
        <AdminComponents.dense_resource_row
          title={@long_iat}
          subtitle="DCR onboarding intake token"
        >
          <:meta>
            <AdminComponents.long_value kind={:id} value={@long_iat} />
            <AdminComponents.long_value kind={:url} value={@long_url} />
          </:meta>
          <:status>
            <AdminComponents.status_badge status={:active} domain={:configure} />
          </:status>
          <:actions>
            <AdminComponents.admin_button>Review initial access tokens</AdminComponents.admin_button>
          </:actions>
        </AdminComponents.dense_resource_row>
      </ul>

      <AdminComponents.confirmation_panel
        title="Revoke initial access token"
        variant={:danger}
        errors={["Confirm before revoking this intake token."]}
      >
        <:body>
          <form class="lockspire-admin-form-stack" phx-submit="confirm_revoke_iat">
            <input type="hidden" name="revoke[id]" value={@long_iat} />
            <div class="lockspire-admin-field">
              <input
                id="phase-124-revoke-confirm"
                type="checkbox"
                name="revoke[confirm]"
                value="true"
                aria-describedby="phase-124-revoke-consequence"
              />
              <label for="phase-124-revoke-confirm">
                Partners using this intake token can no longer dynamically register clients with it.
              </label>
              <p id="phase-124-revoke-consequence">
                Visible consequence copy stays adjacent to the confirmation checkbox.
              </p>
            </div>
            <AdminComponents.action_group>
              <:primary>
                <AdminComponents.admin_button>Review initial access tokens</AdminComponents.admin_button>
              </:primary>
              <:secondary>
                <AdminComponents.admin_button>Keep token active</AdminComponents.admin_button>
              </:secondary>
              <:destructive>
                <AdminComponents.admin_button variant={:danger} type="submit">
                  Revoke initial access token
                </AdminComponents.admin_button>
              </:destructive>
            </AdminComponents.action_group>
          </form>
        </:body>
      </AdminComponents.confirmation_panel>
    </section>
    """)
  end

  defp phase_124_configure_source_blob do
    @phase_124_configure_source_paths
    |> Enum.map_join("\n", &File.read!/1)
  end

  defp assert_phase_124_visible_action_labels!(html) do
    action_blocks =
      Regex.scan(
        ~r/<(?:button|a|span)[^>]*(?:class="[^"]*lockspire-admin-btn[^"]*"|role="link")[^>]*>(.*?)<\/(?:button|a|span)>/s,
        html,
        capture: :all_but_first
      )

    assert action_blocks != []

    for [inner] <- action_blocks do
      visible_text =
        inner
        |> String.replace(~r/<[^>]+>/, "")
        |> String.replace(~r/\s+/, " ")
        |> String.trim()

      assert visible_text != "", "Configure actions must expose visible text labels"
    end

    refute html =~
             ~r/<(?:button|a)[^>]*(?:aria-label|title)="[^"]+"[^>]*>\s*(?:<svg|<span[^>]*icon)/s
  end
end
