defmodule Lockspire.Web.Live.Admin.DesignSystem.CssContractTest do
  use ExUnit.Case, async: true

  alias Lockspire.Web.AdminProof.CssAssertions

  test "admin source uses only namespaced controls and has no inline layout styles" do
    CssAssertions.assert_namespaced_controls!()
  end

  test "CSS covers the active admin component primitives" do
    CssAssertions.assert_component_primitives!()
  end

  test "semantic tokens remain aligned with the brandbook" do
    CssAssertions.assert_semantic_tokens!()
  end

  test "theme, focus, and motion contracts remain explicit" do
    CssAssertions.assert_theme_focus_and_motion!()
  end

  test "responsive layouts preserve long-value safety" do
    CssAssertions.assert_responsive_layout!()
  end

  test "client detail identity and edit action span the summary grid" do
    assert Lockspire.Web.Admin.CSS.get() =~
             ~r/\.lockspire-admin-client-workspace\s*>\s*:first-child\s*\{\s*grid-column:\s*1\s*\/\s*-1;/
  end

  test "shared components preserve redaction-safe long-value presentation" do
    CssAssertions.assert_redaction_safe_presentation!()
  end

  test "the admin shell exposes system, light, and dark themes" do
    CssAssertions.assert_theme_control!()
  end
end
