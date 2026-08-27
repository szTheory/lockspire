defmodule Lockspire.CiWorkflowEvidenceContractTest do
  use ExUnit.Case, async: true

  @workflow Path.expand("../../.github/workflows/ci.yml", __DIR__)

  test "coverage artifacts are SHA-bound and aggregate exactly the two producer jobs" do
    workflow = File.read!(@workflow)
    aggregate_job = aggregate_job(workflow)

    assert workflow =~ "coverage-aggregate:"
    assert workflow =~ "needs: [fast, integration]"
    assert workflow =~ "lockspire-coverage-fast-${{ github.sha }}"
    assert workflow =~ "lockspire-coverage-integration-${{ github.sha }}"

    assert aggregate_job =~
             "scripts/ci/aggregate_coverage.sh --expected-sha \"${{ github.sha }}\""

    assert aggregate_job =~ "actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c"
    assert aggregate_job =~ "path: .artifacts/ci/coverage/fast"
    assert aggregate_job =~ "path: .artifacts/ci/coverage/integration"
    refute aggregate_job =~ "mix test --"
    refute aggregate_job =~ "run_test_matrix.sh"
  end

  test "required CI keeps explicit security and immutable fixture boundaries" do
    workflow = File.read!(@workflow)

    assert workflow =~ "bash scripts/ci/check_sobelow_routers.sh"
    assert workflow =~ "bash scripts/ci/check_dependency_truth.sh"
    assert workflow =~ "Verify compatibility fixture lock stayed unchanged"
    assert workflow =~ "Verify adoption demo lock stayed unchanged"
    refute workflow =~ "continue-on-error"
  end

  defp aggregate_job(workflow) do
    [_before, aggregate_and_after] = String.split(workflow, "\n  coverage-aggregate:\n", parts: 2)
    [aggregate_job | _rest] = String.split(aggregate_and_after, "\n  adoption-demo:", parts: 2)
    aggregate_job
  end
end
