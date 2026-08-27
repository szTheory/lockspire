defmodule Lockspire.Integration.Phase133HarnessTest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @moduletag :phase133

  @runner Path.expand("../../scripts/acceptance/run_clean_room_saas_journey.sh", __DIR__)

  @tag :harness_processes
  test "one supervisor reaches two separate loopback probe origins and cleans up" do
    assert {output, 0} = System.cmd("bash", [@runner, "--probe"], stderr_to_stdout: true)

    assert output =~ "provider ready"
    assert output =~ "client ready"
    assert output =~ "cleanup complete"
  end

  @tag :harness_processes
  test "a startup failure reports only role, exit status, and safe log location" do
    assert {output, 1} =
             System.cmd("bash", [@runner, "--probe", "--fail-provider-startup"],
               stderr_to_stdout: true
             )

    assert output =~ "provider"
    assert output =~ "exit status"
    assert output =~ "log:"
    refute output =~ "phase133-client-secret-sentinel"
  end

  @tag :dependency_lock
  test "the two child manifests resolve Lockspire only from copied package contents" do
    script = Path.expand("../../scripts/acceptance/clean_room/package_input.py", __DIR__)

    assert {output, 0} = System.cmd("python3", [script, "--self-test"], stderr_to_stdout: true)

    assert output =~ "provider provenance verified"
    assert output =~ "client provenance verified"
    refute output =~ "/test/support"
  end

  @tag :harness_security
  test "redaction removes every OAuth secret sentinel before evidence is formatted" do
    script = Path.expand("../../scripts/acceptance/clean_room/redaction.py", __DIR__)

    assert {output, 0} = System.cmd("python3", [script, "--self-test"], stderr_to_stdout: true)

    assert output =~ "redaction verified"
    refute output =~ "phase133-access-token-sentinel"
    refute output =~ "phase133-dpop-client-secret-sentinel"
    refute output =~ "phase133-session-key-sentinel"
  end
end
