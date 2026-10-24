defmodule Lockspire.HostIntegrationCIContractTest do
  use ExUnit.Case, async: true

  @workflow Path.expand("../../.github/workflows/ci.yml", __DIR__)
  @runner Path.expand("../../scripts/ci/run_host_integration_proof.sh", __DIR__)
  @validator Path.expand("../../scripts/acceptance/clean_room/admin_receipts.py", __DIR__)

  test "existing required jobs invoke the bounded proof with distinct exact pairs" do
    workflow = File.read!(@workflow)
    integration = ci_job!(workflow, "integration")
    compatibility = ci_job!(workflow, "compatibility")

    assert integration =~ "name: Integration Checks"
    assert compatibility =~ "name: Minimum Supported Elixir/OTP"
    assert integration =~ "run_host_integration_proof.sh --pair locked --receipt-dir .artifacts/ci/host-integration/locked"
    assert compatibility =~ "run_host_integration_proof.sh --pair floor --receipt-dir .artifacts/ci/host-integration/floor"
    assert integration =~ "host-proof-locked-test-v1-${{ env.OTP_VERSION }}-${{ env.ELIXIR_VERSION }}-${{ hashFiles('test/clean_room/provider_host/mix.lock') }}"
    assert compatibility =~ "host-proof-floor-test-v1-${{ env.MIN_OTP_VERSION }}-${{ env.MIN_ELIXIR_VERSION }}-${{ hashFiles('compatibility/phoenix_1_8_live_view_1_1/mix.lock') }}"
    refute integration =~ "continue-on-error: true"
    refute compatibility =~ "continue-on-error: true"
  end

  test "only successful proof steps upload their validated SHA-bound receipt directories" do
    workflow = File.read!(@workflow)

    for {job_name, step_id, pair} <- [
          {"integration", "host-proof-locked", "locked"},
          {"compatibility", "host-proof-floor", "floor"}
        ] do
      job = ci_job!(workflow, job_name)
      assert job =~ "if: always() && steps.#{step_id}.outcome == 'success'"
      assert job =~ "name: lockspire-host-integration-${{ github.sha }}-#{pair}"
      assert job =~ "path: .artifacts/ci/host-integration/#{pair}/*.json"
      assert job =~ "if-no-files-found: error"
    end
  end

  test "wrapper strictly parses its two required arguments and enforces bounded failure" do
    runner = File.read!(@runner)
    assert runner =~ "usage: $0 --pair locked|floor --receipt-dir DIR"
    assert runner =~ "pair_budget=900"
    assert runner =~ "deadline=$((started + pair_budget))"
    assert runner =~ "LOCKSPIRE_PROOF_TEST_MODE"
    assert runner =~ "run_bounded 180"
    assert runner =~ "--package-tar"
    assert runner =~ "--package-sha256"
    assert runner =~ "--expected-run-id"
    assert runner =~ "--expected-source"
    assert runner =~ "--expected-version"
    assert runner =~ "--expected-tree"
    assert runner =~ "--expected-scenario-set full"
  end

  test "receipt CLI independently requires floor pair and exact candidate version" do
    validator = File.read!(@validator)
    assert validator =~ "choices=(\"locked\", \"floor\")"
    assert validator =~ "--expected-version"
    assert validator =~ "candidate version differs from the expected candidate"
    assert validator =~ "type(scenario[\"duration_ms\"]) is not int"
  end

  defp ci_job!(workflow, name) do
    [_, job] = Regex.run(~r/  #{name}:\n(.*?)(?=\n  [a-z][\w-]*:|\z)/s, workflow)
    job
  end
end
