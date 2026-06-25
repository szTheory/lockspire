defmodule Lockspire.Web.Live.Admin.DesignSystemComponentStressTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Lockspire.Web.AdminLab.Fixtures
  alias Lockspire.Web.AdminLab.StressSurface

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
          :copy_once
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
          "redacted"
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
          "lockspire-admin-summary-stat",
          "lockspire-admin-card",
          "lockspire-admin-resource-list__item",
          "lockspire-admin-long-value",
          "lockspire-admin-error-summary",
          "lockspire-admin-field-error",
          "lockspire-admin-copy-once-secret",
          "lockspire-admin-confirmation-panel-danger",
          "lockspire-admin-action-group",
          "lockspire-admin-btn",
          "lockspire-admin-empty"
        ] do
      assert html =~ class
    end

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
    refute html =~ "tenant-with-a-long-name.example.invalid"
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
end
