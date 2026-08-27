defmodule Lockspire.Integration.Phase133CleanRoomSaasJourneyTest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @moduletag :phase133

  @runner Path.expand("../../scripts/acceptance/clean_room_saas_journey.py", __DIR__)

  @tag :happy_path
  test "E2E-02 and E2E-03 cross distinct origins through PKCE, OIDC, and billing" do
    assert {output, 0} = System.cmd("python3", [@runner, "--only", "happy_path"], stderr_to_stdout: true)

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
end
