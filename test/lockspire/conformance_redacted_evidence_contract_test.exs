defmodule Lockspire.ConformanceRedactedEvidenceContractTest do
  use ExUnit.Case, async: true

  @phase37 Path.expand("../../scripts/conformance/run_phase37_suite.sh", __DIR__)
  @fapi2 Path.expand("../../scripts/conformance/run_fapi2_suite.sh", __DIR__)
  @profile Path.expand("../../scripts/conformance/run_oidf_profile.sh", __DIR__)
  @evidence Path.expand("../../scripts/conformance/build_redacted_evidence.py", __DIR__)
  @diagnostics Path.expand("../../scripts/conformance/summarize_oidf_failure.py", __DIR__)

  test "both profiles use the verified preparation and allowlisted evidence boundary" do
    for runner <- [@phase37, @fapi2] do
      source = File.read!(runner)

      assert source =~ "run_oidf_profile.sh"
      refute source =~ "latest"
      refute source =~ "master"
      refute source =~ "fallback"
      refute source =~ "provider-config.json"
      refute source =~ "logs"
    end

    profile = File.read!(@profile)
    assert profile =~ "prepare_oidf_suite.sh"
    assert profile =~ "invoke_oidf_plan.py"
    assert profile =~ "build_redacted_evidence.py"
    assert profile =~ "integration_only"
    assert profile =~ "suite_failure"
    assert profile =~ "suite-output.log"
    assert profile =~ "summarize_oidf_failure.py"
    assert profile =~ "chown -R"
    refute profile =~ "cp -R"

    invocation = File.read!(Path.expand("../../scripts/conformance/invoke_oidf_plan.py", __DIR__))
    assert invocation =~ ~s|str(runner_path), "--verbose", "--export-dir"|

    preparation =
      File.read!(Path.expand("../../scripts/conformance/prepare_oidf_suite.sh", __DIR__))

    assert preparation =~ ~s(mkdir -m 700 -p "$output_dir/mongo/data")
  end

  test "failure diagnostics retain only module outcomes and condition identifiers" do
    fixture =
      Path.join(System.tmp_dir!(), "lockspire-oidf-diagnostics-#{System.unique_integer()}")

    File.write!(fixture, """
    Test [0:1] oidcc-prompt-none-not-logged-in abcdef12-abcd FINISHED - result FAILED. 20 log entries
    Block name: 'Authorization endpoint response' - Condition: 'OIDCCEnsureErrorResponse'
    Overall totals: ran 1 test modules. Conditions: 19 successes, 1 failures, 0 warnings.
    authorization: Bearer must-never-appear
    https://provider.example.invalid/private
    """)

    on_exit(fn -> File.rm(fixture) end)

    assert {output, 0} = System.cmd("python3", [@diagnostics, fixture])
    assert output =~ "OIDF_SAFE_DIAGNOSTICS"
    assert output =~ "oidcc-prompt-none-not-logged-in"
    assert output =~ "OIDCCEnsureErrorResponse"
    refute output =~ "must-never-appear"
    refute output =~ "provider.example.invalid"
  end

  test "evidence builder records only bounded receipt fields and refuses secrets or raw paths" do
    source = File.read!(@evidence)

    assert source =~ "schema_version"
    assert source =~ "allowlisted"
    assert source =~ "provider-config"
    assert source =~ "authorization"
    assert source =~ "raw log"
    refute source =~ "copytree"
  end
end
