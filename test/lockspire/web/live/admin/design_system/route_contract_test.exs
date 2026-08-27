defmodule Lockspire.Web.Live.Admin.DesignSystem.RouteContractTest do
  use ExUnit.Case, async: true

  alias Lockspire.Web.AdminProof.RouteAssertions

  test "mounted admin routes cover current operator capabilities" do
    RouteAssertions.assert_mounted_routes!()
  end

  test "operator documentation keeps the host and embedded-library boundary explicit" do
    RouteAssertions.assert_operator_boundary!()
  end

  test "operate routes are read-only and deny unsupported queue commands" do
    RouteAssertions.assert_read_only_operate_surfaces!()
  end

  test "configure routes retain their supported action vocabulary" do
    RouteAssertions.assert_configure_actions!()
  end

  test "operator source and documentation redact sensitive credential material" do
    RouteAssertions.assert_redaction_boundary!()
  end

  test "public package inputs exclude internal proof surfaces" do
    RouteAssertions.assert_public_package_ceiling!()
  end
end
