defmodule Lockspire.Integration.Phase133CleanRoomSaasJourneyTest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @moduletag :phase133

  @runner Path.expand("../../scripts/acceptance/clean_room_saas_journey.py", __DIR__)

  @tag :happy_path
  test "E2E-02 and E2E-03 cross distinct origins through PKCE, OIDC, and billing" do
    assert {output, 0} =
             System.cmd("python3", [@runner, "--only", "happy_path"], stderr_to_stdout: true)

    assert output =~ "readiness complete"
    assert output =~ "discovery complete"
    assert output =~ "authorization complete"
    assert output =~ "callback complete"
    assert output =~ "oidc complete"
    assert output =~ "userinfo complete"
    assert output =~ "resource complete"
    refute output =~ "phase133-access-token-sentinel"
    refute output =~ "phase133-bearer-client-secret-sentinel"
  end

  @tag :boundary
  test "completed callback is terminal and host billing policy remains separate" do
    assert {output, 0} =
             System.cmd("python3", [@runner, "--only", "happy_path", "--only", "boundary"],
               stderr_to_stdout: true
             )

    assert output =~ "callback reuse rejected"
    assert output =~ "host policy boundary complete"
  end

  @tag :lifecycle
  test "refresh family containment and revocation report authorization-server lifecycle truth" do
    assert {output, 0} =
             System.cmd("python3", [@runner, "--only", "lifecycle"], stderr_to_stdout: true)

    assert output =~ "refresh rotation complete"
    assert output =~ "refresh reuse contained"
    assert output =~ "family introspection inactive"
    assert output =~ "idempotent revocation complete"
    refute output =~ "phase133-access-token-sentinel"
    refute output =~ "phase133-bearer-client-secret-sentinel"
  end

  @tag :negative
  test "real HTTP negatives reject redirect, callback, code, nonce, token, audience, and scope drift" do
    assert {output, 0} =
             System.cmd("python3", [@runner, "--only", "negative"], stderr_to_stdout: true)

    for receipt <- [
          "redirect drift rejected",
          "code reuse rejected",
          "callback state rejected before exchange",
          "nonce mismatch rejected by client validation",
          "missing token rejected",
          "wrong audience rejected",
          "insufficient scope rejected"
        ] do
      assert output =~ receipt
    end

    refute output =~ "phase133-access-token-sentinel"
    refute output =~ "phase133-bearer-client-secret-sentinel"
  end
end
