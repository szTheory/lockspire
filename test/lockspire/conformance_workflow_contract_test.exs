defmodule Lockspire.ConformanceWorkflowContractTest do
  use ExUnit.Case, async: true

  @workflow Path.expand("../../.github/workflows/oidf-conformance.yml", __DIR__)
  @guide Path.expand("../../docs/maintainer-conformance.md", __DIR__)
  @requirements Path.expand("../../scripts/conformance/runner-requirements.lock", __DIR__)
  @installer Path.expand("../../scripts/conformance/install_runner_dependencies.sh", __DIR__)

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
    assert workflow =~ ~s(PYTHON_VERSION: "3.13.15")
    assert workflow =~ ~s(PIP_VERSION: "26.2.1")

    assert length(
             Regex.scan(
               ~r/actions\/setup-python@e797f83bcb11b83ae66e0230d6156d7c80228e7c/,
               workflow
             )
           ) == 3

    assert length(Regex.scan(~r/install_runner_dependencies\.sh/, workflow)) == 3
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
    refute workflow =~ ~r/path: .*provider/i
  end

  test "each external profile receives only its private JSON secret" do
    workflow = File.read!(@workflow)
    phase37 = job!(workflow, "repo-native-phase37", "repo-native-fapi2")
    fapi2 = job!(workflow, "repo-native-fapi2", "hosted-maintainer-lane")
    hosted = final_job!(workflow, "hosted-maintainer-lane")
    guide = File.read!(@guide)

    assert hosted =~ "github.event_name == 'workflow_dispatch' && inputs.run_hosted_lane"
    assert phase37 =~ "secrets.LOCKSPIRE_OIDF_PHASE37_PROVIDER_CONFIG_JSON"
    assert fapi2 =~ "secrets.LOCKSPIRE_OIDF_FAPI2_PROVIDER_CONFIG_JSON"
    assert hosted =~ "secrets.LOCKSPIRE_OIDF_HOSTED_PROVIDER_CONFIG_JSON"
    refute phase37 =~ "FAPI2_PROVIDER_CONFIG"
    refute fapi2 =~ "PHASE37_PROVIDER_CONFIG"
    refute hosted =~ "FAPI2_PROVIDER_CONFIG"

    assert length(Regex.scan(~r/LOCKSPIRE_OIDF_PROVIDER_CONFIG_JSON:/, workflow)) == 3
    assert length(Regex.scan(~r/\$\{\{ secrets\./, workflow)) == 3

    assert guide =~ "not OpenID certification"
    assert guide =~ "not a release gate"
    assert guide =~ "integration_only"
    assert guide =~ "infrastructure_failure"
    assert guide =~ "suite_failure"
    assert guide =~ "LOCKSPIRE_OIDF_PHASE37_PROVIDER_CONFIG_JSON"
    assert guide =~ "LOCKSPIRE_OIDF_FAPI2_PROVIDER_CONFIG_JSON"
    assert guide =~ "LOCKSPIRE_OIDF_HOSTED_PROVIDER_CONFIG_JSON"
    assert String.downcase(guide) =~ "missing secret"
  end

  test "OIDF Python dependencies are exact, hash-locked, and installed without resolution" do
    requirements = File.read!(@requirements)
    installer = File.read!(@installer)

    assert length(Regex.scan(~r/^\w[\w-]*==[^ ]+ \\/m, requirements)) == 7
    assert length(Regex.scan(~r/--hash=sha256:[0-9a-f]{64}/, requirements)) == 7
    refute requirements =~ ">="
    refute requirements =~ "~="

    assert installer =~ "--require-hashes"
    assert installer =~ "--only-binary=:all:"
    assert installer =~ "--no-deps"
    assert installer =~ "--no-input"
    assert installer =~ "actual != expected"
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
