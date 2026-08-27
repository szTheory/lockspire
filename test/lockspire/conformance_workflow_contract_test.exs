defmodule Lockspire.ConformanceWorkflowContractTest do
  use ExUnit.Case, async: true

  @workflow Path.expand("../../.github/workflows/oidf-conformance.yml", __DIR__)
  @guide Path.expand("../../docs/maintainer-conformance.md", __DIR__)

  test "default-branch schedule and dispatch run both immutable supplemental profiles" do
    workflow = File.read!(@workflow)

    assert workflow =~ "name: Supplemental OIDF Conformance"
    assert workflow =~ "schedule:"
    assert workflow =~ ~r/cron: "\d+ \d+ \* \* \d+"/
    assert workflow =~ "workflow_dispatch:"
    assert workflow =~ "permissions:\n  contents: read"
    assert workflow =~ "concurrency:"
    assert workflow =~ "cancel-in-progress: true"
    assert workflow =~ "mix lockspire.oidf_conformance --check"
    assert workflow =~ "bash scripts/conformance/run_phase37_suite.sh"
    assert workflow =~ "bash scripts/conformance/run_fapi2_suite.sh"
  end

  test "scheduled jobs retain only bounded redacted receipts" do
    workflow = File.read!(@workflow)

    assert workflow =~ ".artifacts/conformance/phase37/receipt.json"
    assert workflow =~ ".artifacts/conformance/fapi2/receipt.json"
    assert length(Regex.scan(~r/if-no-files-found: error/, workflow)) == 3
    assert workflow =~ "retention-days: 30"
    assert workflow =~ "retention-days: 14"

    refute workflow =~ "path: .artifacts/conformance/phase37\n"
    refute workflow =~ "path: .artifacts/conformance/fapi2\n"
    refute workflow =~ "*.log"
    refute workflow =~ "docker-compose.locked.yml"
    refute workflow =~ "provider-config"
  end

  test "hosted credentials stay optional and claims remain supplemental" do
    workflow = File.read!(@workflow)
    hosted = final_job!(workflow, "hosted-maintainer-lane")
    guide = File.read!(@guide)

    assert hosted =~ "github.event_name == 'workflow_dispatch' && inputs.run_hosted_lane"
    assert hosted =~ "LOCKSPIRE_PHASE37_HOSTED_DISCOVERY_URL"
    assert hosted =~ "LOCKSPIRE_PHASE37_HOSTED_BASE_URL"
    refute job!(workflow, "repo-native-phase37", "repo-native-fapi2") =~ "secrets."
    refute job!(workflow, "repo-native-fapi2", "hosted-maintainer-lane") =~ "secrets."

    assert guide =~ "not OpenID certification"
    assert guide =~ "not a release gate"
    assert guide =~ "integration_only"
    assert guide =~ "infrastructure_failure"
    assert guide =~ "suite_failure"
    assert String.downcase(guide) =~ "scheduled runs do not request hosted credentials"
  end

  defp job!(workflow, name, next_name) do
    [_, job] =
      Regex.run(
        ~r/^  #{Regex.escape(name)}:\n(.*?)^  #{Regex.escape(next_name)}:/ms,
        workflow
      )

    job
  end

  defp final_job!(workflow, name) do
    [_, job] = Regex.run(~r/^  #{Regex.escape(name)}:\n(.*)\z/ms, workflow)
    job
  end
end
