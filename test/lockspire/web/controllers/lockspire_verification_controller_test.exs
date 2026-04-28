defmodule Lockspire.Web.LockspireVerificationControllerTemplateTest do
  use ExUnit.Case, async: true

  @controller_template Path.expand(
                         "../../../../priv/templates/lockspire.install/verification_controller.ex",
                         __DIR__
                       )
  @html_template Path.expand(
                   "../../../../priv/templates/lockspire.install/verification_html/index.html.heex",
                   __DIR__
                 )

  test "show remains prefill-only and GET-safe" do
    contents = File.read!(@controller_template)
    [show_block | _rest] = String.split(contents, "def lookup", parts: 2)

    assert show_block =~ "def show"
    assert show_block =~ ~s(params["user_code"])
    assert show_block =~ "prefill-only"
    refute show_block =~ "lookup_pending_device_authorization("
    refute show_block =~ "approve_device_authorization("
    refute show_block =~ "deny_device_authorization("
  end

  test "controller template wires lookup and explicit approve or deny mutations" do
    contents = File.read!(@controller_template)

    assert contents =~ "def lookup"
    assert contents =~
             "Lockspire.Protocol.DeviceVerification.lookup_pending_device_authorization"
    assert contents =~ ~s({:error, :not_found})
    assert contents =~ ~s({:error, :expired})
    assert contents =~ "invalid or expired code"
    assert contents =~ "def approve"
    assert contents =~ "def deny"
    assert contents =~ "Lockspire.account_resolver!()"
    assert contents =~ "resolver.resolve_current_account"
    assert contents =~ "resolver.build_claims"
    assert contents =~ "subject_id: claims.subject"
    assert contents =~ "approve_device_authorization"
    assert contents =~ "deny_device_authorization"
    assert contents =~ "Do not auto-submit"
    assert contents =~ "alias Lockspire.Protocol.DeviceVerification"
  end

  test "html template shows visible code confirmation and explicit review actions" do
    contents = File.read!(@html_template)

    assert contents =~ "confirm the code matches"
    assert contents =~ "Review device request"
    assert contents =~ "Approve device"
    assert contents =~ "Deny request"
    assert contents =~ "Client"
    assert contents =~ "Requested scopes"
    assert contents =~ ~s(name="_csrf_token")
    assert contents =~ "Plug.CSRFProtection.get_csrf_token()"
  end

  test "generated verification seam stays free of auto-submit markers" do
    assert_no_auto_submit!(File.read!(@controller_template))
    assert_no_auto_submit!(File.read!(@html_template))
  end

  defp assert_no_auto_submit!(contents) do
    refute contents =~ "window.onload"
    refute contents =~ "phx-mounted"
    refute contents =~ ~s(type="hidden" name="auto_submit")
    refute contents =~ "submit()"
  end
end
