defmodule Lockspire.CiWorkflowEvidenceContractTest do
  use ExUnit.Case, async: true

  @workflow Path.expand("../../.github/workflows/ci.yml", __DIR__)

  test "coverage artifacts are SHA-bound and aggregate exactly the two producer jobs" do
    workflow = File.read!(@workflow)

    assert workflow =~ "coverage-aggregate:"
    assert workflow =~ "needs: [fast, integration]"
    assert workflow =~ "lockspire-coverage-fast-${{ github.sha }}"
    assert workflow =~ "lockspire-coverage-integration-${{ github.sha }}"
    assert workflow =~ "scripts/ci/aggregate_coverage.sh --expected-sha \"${{ github.sha }}\""
    assert workflow =~ "actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c"
    refute workflow =~ "coverage-aggregate:\n    name: Complete Coverage\n    runs-on: ubuntu-latest\n    steps:\n      - name: Run tests"
  end

  test "required CI keeps explicit security and immutable fixture boundaries" do
    workflow = File.read!(@workflow)

    assert workflow =~ "bash scripts/ci/check_sobelow_routers.sh"
    assert workflow =~ "bash scripts/ci/check_dependency_truth.sh"
    assert workflow =~ "Verify compatibility fixture lock stayed unchanged"
    assert workflow =~ "Verify adoption demo lock stayed unchanged"
    refute workflow =~ "continue-on-error"
  end
end
