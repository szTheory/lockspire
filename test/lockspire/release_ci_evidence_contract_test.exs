defmodule Lockspire.ReleaseCiEvidenceContractTest do
  use ExUnit.Case, async: true

  @automerge Path.expand("../../.github/workflows/release-please-automerge.yml", __DIR__)
  @release Path.expand("../../.github/workflows/release.yml", __DIR__)
  @release_freeze Path.expand("../../scripts/publish/release_main_freeze.sh", __DIR__)

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
    assert workflow =~ "test \"$GITHUB_REF\" = \"refs/heads/main\""
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

  test "release push is no-publish while protected dispatch retains the publication graph" do
    graph = @release |> File.read!() |> release_job_graph()

    assert graph |> Map.keys() |> Enum.sort() == [
             "post-publish-install-truth",
             "prepublish-proof",
             "publish",
             "recovery-validation",
             "release-please"
           ]

    release_please = graph["release-please"]
    recovery_validation = graph["recovery-validation"]
    prepublish_proof = graph["prepublish-proof"]
    publish = graph["publish"]
    post_publish_install_truth = graph["post-publish-install-truth"]

    assert release_please =~ "name: Maintain Release Please PR"
    assert release_please =~ ~S(if: ${{ github.event_name == 'push' }})
    refute release_please =~ "workflow_dispatch"
    refute release_please =~ ~r/^    needs:/m
    refute release_please =~ "publish_hex_idempotently.sh"
    refute release_please =~ "gh release create"
    refute release_please =~ "release-package-"

    assert recovery_validation =~ "name: Validate exact main head and CI evidence"
    assert recovery_validation =~ ~S(if: ${{ github.event_name == 'workflow_dispatch' }})
    refute recovery_validation =~ ~S(github.event_name == 'push')

    assert prepublish_proof =~ "name: Prove exact package before publication"
    assert prepublish_proof =~ "needs: recovery-validation"
    assert prepublish_proof =~ ~S(if: ${{ needs.recovery-validation.result == 'success' }})

    assert publish =~ "name: Publish verified release to Hex"
    assert publish =~ "needs: [recovery-validation, prepublish-proof]"

    assert publish =~
             ~S(if: ${{ needs.recovery-validation.result == 'success' && needs.prepublish-proof.result == 'success' }})

    assert publish =~ "name: Download clean-room-proven package data"

    assert publish =~
             "name: release-package-${{ needs.recovery-validation.outputs.verified_sha }}"

    assert :binary.match(publish, "- name: Publish package") <
             :binary.match(publish, "- name: Create matching GitHub release")

    assert post_publish_install_truth =~ "name: Verify public install truth"
    assert post_publish_install_truth =~ "needs: [recovery-validation, publish]"
    assert post_publish_install_truth =~ ~S(if: ${{ needs.publish.result == 'success' }})
  end

  test "release automation requires explicit opt-in and current-main recovery authorization" do
    automerge = File.read!(@automerge)
    graph = @release |> File.read!() |> release_job_graph()
    recovery_validation = graph["recovery-validation"]
    publish = graph["publish"]

    assert automerge =~ "vars.LOCKSPIRE_RELEASE_AUTOMERGE_ENABLED == 'true'"
    assert recovery_validation =~ "LOCKSPIRE_PHASE143_AUTHORIZED_SHA"
    assert recovery_validation =~ "test -n \"$AUTHORIZED_SHA\""
    assert recovery_validation =~ "test \"$RECOVERY_REF\" = \"$AUTHORIZED_SHA\""
    assert recovery_validation =~ "test \"$verified_sha\" = \"$AUTHORIZED_SHA\""

    assert publish =~
             "uses: actions/create-github-app-token@bcd2ba49218906704ab6c1aa796996da409d3eb1"

    assert publish =~ "permission-administration: write"
    assert publish =~ "permission-actions: read"
    assert publish =~ "LOCKSPIRE_RELEASE_FREEZE_APP_ID"
    assert publish =~ "LOCKSPIRE_RELEASE_FREEZE_APP_PRIVATE_KEY"
    assert publish =~ "name: Freeze main updates for the protected publish window"
    assert publish =~ "name: Publish exact package while main is frozen"
    assert publish =~ "name: Remove temporary main freeze"
    refute publish =~ "name: Recheck exact current main before Hex upload"

    assert :binary.match(publish, "name: Freeze main updates for the protected publish window") <
             :binary.match(publish, "name: Publish exact package while main is frozen")

    assert :binary.match(publish, "name: Mark the merged release PR as tagged") <
             :binary.match(publish, "name: Remove temporary main freeze")

    freeze_script = File.read!(@release_freeze)
    assert freeze_script =~ "bypass_actors == []"
    assert freeze_script =~ "enforcement == \"active\""
    assert freeze_script =~ "update_allows_fetch_and_merge == false"
    assert freeze_script =~ "ruleset_source_type == \"Repository\""
    assert freeze_script =~ "actions/variables/LOCKSPIRE_PHASE143_AUTHORIZED_SHA"
    assert freeze_script =~ "git fetch --no-tags origin refs/heads/main"
    assert freeze_script =~ "[[ \"$remote_main_sha\" == \"$authorized_sha_from_api\" ]]"
    assert freeze_script =~ "bypass_actors: []"
    assert freeze_script =~ "publish_with_freeze \"$2\" \"$3\" \"$4\" \"$5\" \"$6\" \"$7\""

    assert freeze_script =~
             "preflight \"$ruleset_id\" \"$authorized_sha\" \"$recovery_ref\" \"$verified_sha\""

    assert freeze_script =~ "unset HEX_API_KEY"
    assert freeze_script =~ "unset GH_TOKEN"

    assert :binary.match(freeze_script, "preflight \"$ruleset_id\"") <
             :binary.match(freeze_script, "bash scripts/publish/publish_hex_idempotently.sh")
  end

  defp release_job_graph(workflow) do
    [_, jobs] = String.split(workflow, "\njobs:\n", parts: 2)

    ~r/^  ([a-z0-9-]+):\n(.*?)(?=^  [a-z0-9-]+:\n|\z)/ms
    |> Regex.scan(jobs, capture: :all_but_first)
    |> Map.new(fn [id, region] -> {id, region} end)
  end
end
