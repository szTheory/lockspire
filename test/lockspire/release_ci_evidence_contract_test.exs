defmodule Lockspire.ReleaseCiEvidenceContractTest do
  use ExUnit.Case, async: true

  @automerge Path.expand("../../.github/workflows/release-please-automerge.yml", __DIR__)
  @release Path.expand("../../.github/workflows/release.yml", __DIR__)

  test "release automation waits for a post-merge CI push run and carries its exact evidence" do
    workflow = File.read!(@automerge)

    assert workflow =~ "CI_EVENT"
    assert workflow =~ "test \"$CI_EVENT\" = \"push\""
    assert workflow =~ "Publication deliberately waits for that merge commit's own CI push run"
    assert workflow =~ "source_ci_run_id=\"$CI_RUN_ID\""
    assert workflow =~ "recovery_ref=\"$CI_HEAD_SHA\""
    assert workflow =~ "mergeCommit.oid == $sha"
  end

  test "publish validator accepts only an exact current main head with matching successful CI metadata" do
    workflow = File.read!(@release)

    assert workflow =~ "source_ci_run_id:"
    assert workflow =~ "actions: read"
    assert workflow =~ "[[ \"$RECOVERY_REF\" =~ ^[0-9a-f]{40}$ ]]"
    assert workflow =~ "git rev-parse origin/main"
    assert workflow =~ "git merge-base --is-ancestor \"$verified_sha\" origin/main"
    assert workflow =~ "actions/runs/$SOURCE_CI_RUN_ID"
    assert workflow =~ "'.event'"
    assert workflow =~ "'.head_branch'"
    assert workflow =~ "'.conclusion'"
    assert workflow =~ "'.repository.full_name'"
    assert workflow =~ "verified_sha=$verified_sha"
    refute workflow =~ "recovery_ref: ${{ inputs.recovery_ref }}"
  end
end
