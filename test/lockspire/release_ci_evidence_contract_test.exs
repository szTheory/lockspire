defmodule Lockspire.ReleaseCiEvidenceContractTest do
  use ExUnit.Case, async: true

  @automerge Path.expand("../../.github/workflows/release-please-automerge.yml", __DIR__)
  @release Path.expand("../../.github/workflows/release.yml", __DIR__)

  test "release automation dispatches post-merge CI and carries its exact evidence" do
    workflow = File.read!(@automerge)

    assert workflow =~ "CI_EVENT"
    assert workflow =~ ~S([[ "$ci_event" == "push" || "$ci_event" == "workflow_dispatch" ]])
    assert workflow =~ "test \"$CI_EVENT\" = \"$ci_event\""
    assert workflow =~ "gh workflow run ci.yml --ref main"
    assert workflow =~ "dispatched canonical CI for exact commit $merged_sha"
    assert workflow =~ ~s|gh pr view "$pr_number" --json mergeCommit --jq '.mergeCommit.oid'|
    assert workflow =~ "source_ci_run_id=\"$CI_RUN_ID\""
    assert workflow =~ "recovery_ref=\"$CI_HEAD_SHA\""
    assert workflow =~ "mergeCommit.oid == $sha"
    assert workflow =~ "workflow_dispatch:"
    assert workflow =~ "actions/runs/$CI_RUN_ID"
    assert workflow =~ "test \"$(jq -r '.head_sha' <<< \"$ci_run\")\" = \"$CI_HEAD_SHA\""
    assert workflow =~ "test \"$(jq -r '.path' <<< \"$ci_run\")\" = \".github/workflows/ci.yml\""

    assert workflow =~
             "test \"$actual_files\" = \".planning/RELEASE-TRAIN.md,.release-please-manifest.json,CHANGELOG.md,mix.exs\""

    assert workflow =~
             "test \"$(jq -r '.workflow_id' <<< \"$ci_run\")\" = \"$canonical_ci_workflow_id\""

    assert workflow =~ "No eligible or just-merged Release Please PR"
  end

  test "publish validator accepts only an exact current main head with matching successful CI metadata" do
    workflow = File.read!(@release)

    assert workflow =~ "source_ci_run_id:"
    assert workflow =~ "actions: read"
    assert workflow =~ "[[ \"$RECOVERY_REF\" =~ ^[0-9a-f]{40}$ ]]"
    assert workflow =~ "git rev-parse origin/main"
    assert workflow =~ "git merge-base --is-ancestor \"$verified_sha\" origin/main"
    assert workflow =~ "actions/runs/$SOURCE_CI_RUN_ID"
    assert workflow =~ "test \"$(jq -r '.path' <<< \"$ci_run\")\" = \".github/workflows/ci.yml\""

    assert workflow =~
             "test \"$(jq -r '.workflow_id' <<< \"$ci_run\")\" = \"$canonical_ci_workflow_id\""

    assert workflow =~ "'.event'"
    assert workflow =~ "'.head_branch'"
    assert workflow =~ "'.conclusion'"
    assert workflow =~ "'.repository.full_name'"
    assert workflow =~ ~S([[ "$ci_event" == "push" || "$ci_event" == "workflow_dispatch" ]])
    assert workflow =~ "verified_sha=$verified_sha"
    refute workflow =~ "recovery_ref: ${{ inputs.recovery_ref }}"
  end
end
