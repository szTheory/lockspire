defmodule Lockspire.Web.Live.Admin.DesignSystemComponentStressTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Lockspire.Web.AdminLab.Fixtures
  alias Lockspire.Web.AdminLab.StressSurface
  alias Lockspire.Web.AdminProof.HtmlAssertions

  @admin_router_path Path.expand("../../../../../lib/lockspire/web/admin_router.ex", __DIR__)
  @mix_path Path.expand("../../../../../mix.exs", __DIR__)
  @supported_surface_path Path.expand("../../../../../docs/supported-surface.md", __DIR__)

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
    assert html =~ "https://tenant-with-a-long-name.example.invalid/oauth/callbacks/configure"
    assert html =~ "Decision summary detail text stays visible before risky actions."

    HtmlAssertions.assert_no_text(html, Fixtures.forbidden_substrings())
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

    for forbidden <- ["component-lab", "component_lab", "design-system-lab", "design_system_lab"] do
      refute router =~ forbidden
      refute supported_surface =~ forbidden
    end
  end

  defp phase_124_configure_stress_html do
    render_component(&StressSurface.render/1, fixture_set: Fixtures.all())
  end
end
