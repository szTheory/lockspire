defmodule Lockspire.CiWorkflowEvidenceContractTest do
  use ExUnit.Case, async: true

  @workflow Path.expand("../../.github/workflows/ci.yml", __DIR__)
  @mixfile Path.expand("../../mix.exs", __DIR__)

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
    mixfile = File.read!(@mixfile)

    assert workflow =~ "run: mix qa"
    assert mixfile =~ "cmd bash scripts/ci/check_sobelow_routers.sh"
    refute mixfile =~ ~s("sobelow --config")
    assert workflow =~ "bash scripts/ci/check_dependency_truth.sh"
    assert workflow =~ "Verify compatibility fixture lock stayed unchanged"
    assert workflow =~ "Verify adoption demo lock stayed unchanged"
    refute workflow =~ "continue-on-error"
  end

  test "lifetime proof retains only validated SHA-bound receipts for fourteen days" do
    workflow = File.read!(@workflow)
    integration_job = integration_job(workflow)

    assert integration_job =~ "timeout-minutes: 30"
    assert integration_job =~ "bash scripts/ci/run_test_matrix.sh --integration"
    assert integration_job =~ "Run integration suite including onboarding and OIDC E2E proof"
    validation_step = step_block(integration_job, "Validate client lifetime receipt")
    upload_step = step_block(integration_job, "Upload SHA-bound client lifetime receipts")

    assert validation_step =~ "if: always()"
    assert validation_step =~ "test -s .artifacts/ci/client-lifetimes/receipt.json"
    assert validation_step =~ "test -s .artifacts/ci/client-lifetimes/validation.json"
    assert validation_step =~ "EXPECTED_SOURCE_REVISION: ${{ github.sha }}"
    assert validation_step =~ "validation[\"valid\"] is True"
    assert validation_step =~ "receipt[\"source_revision\"] == expected"

    assert upload_step =~
             "if: always() && steps.validate-client-lifetime-receipt.outcome == 'success'"

    assert upload_step =~ "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a"
    assert upload_step =~ "lockspire-client-lifetimes-${{ github.sha }}"
    assert upload_step =~ "retention-days: 14"
    assert upload_step =~ "if-no-files-found: error"

    assert upload_step =~
             "path: |\n            .artifacts/ci/client-lifetimes/receipt.json\n            .artifacts/ci/client-lifetimes/validation.json"

    refute upload_step =~ "tmp/"
    refute upload_step =~ "raw/"
  end

  defp aggregate_job(workflow) do
    [_before, aggregate_and_after] = String.split(workflow, "\n  coverage-aggregate:\n", parts: 2)
    [aggregate_job | _rest] = String.split(aggregate_and_after, "\n  adoption-demo:", parts: 2)
    aggregate_job
  end

  defp integration_job(workflow) do
    [_before, integration_and_after] = String.split(workflow, "\n  integration:\n", parts: 2)

    [integration_job | _rest] =
      String.split(integration_and_after, "\n  coverage-aggregate:", parts: 2)

    integration_job
  end

  defp step_block(job, name) do
    [_before, step_and_after] = String.split(job, "- name: #{name}\n", parts: 2)
    [step | _rest] = String.split(step_and_after, "\n      - name:", parts: 2)
    step
  end
end
