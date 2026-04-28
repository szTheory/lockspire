defmodule Lockspire.Web.LockspireVerificationControllerTemplateTest do
  use ExUnit.Case, async: true

  @controller_template Path.expand(
                         "../../../priv/templates/lockspire.install/verification_controller.ex",
                         __DIR__
                       )
  @html_template Path.expand(
                   "../../../priv/templates/lockspire.install/verification_html/index.html.heex",
                   __DIR__
                 )

  test "show remains prefill-only and GET-safe" do
    contents = File.read!(@controller_template)

    assert contents =~ "def show"
    assert contents =~ ~s(params["user_code"])
    assert contents =~ "prefill-only"
    refute contents =~ "lookup_pending_device_authorization("
    refute contents =~ "approve_device_authorization("
    refute contents =~ "deny_device_authorization("
  end

  test "generated verification seam stays free of auto-submit markers" do
    assert_no_auto_submit!(File.read!(@controller_template))
    assert_no_auto_submit!(File.read!(@html_template))
  end

  defp assert_no_auto_submit!(contents) do
    refute contents =~ "window.onload"
    refute contents =~ "phx-mounted"
    refute contents =~ ~s(type="hidden")
    refute contents =~ "submit()"
  end
end
