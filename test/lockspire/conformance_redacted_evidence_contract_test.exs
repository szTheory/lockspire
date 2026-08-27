defmodule Lockspire.ConformanceRedactedEvidenceContractTest do
  use ExUnit.Case, async: true

  @phase37 Path.expand("../../scripts/conformance/run_phase37_suite.sh", __DIR__)
  @fapi2 Path.expand("../../scripts/conformance/run_fapi2_suite.sh", __DIR__)
  @profile Path.expand("../../scripts/conformance/run_oidf_profile.sh", __DIR__)
  @evidence Path.expand("../../scripts/conformance/build_redacted_evidence.py", __DIR__)

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
    refute profile =~ "cp -R"
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
