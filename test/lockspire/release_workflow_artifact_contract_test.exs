defmodule Lockspire.ReleaseWorkflowArtifactContractTest do
  use ExUnit.Case, async: true

  @workflow Path.expand("../../.github/workflows/release.yml", __DIR__)
  @guide Path.expand("../../docs/maintainer-release.md", __DIR__)
  @freeze_script Path.expand("../../scripts/publish/release_main_freeze.sh", __DIR__)
  @tag_target_verifier Path.expand(
                         "../../scripts/publish/verify_github_release_target.sh",
                         __DIR__
                       )

  test "unprivileged prepublish proof carries one SHA-bound package identity" do
    workflow = File.read!(@workflow)
    prepublish = job!(workflow, "prepublish-proof", "publish")

    assert prepublish =~ "permissions:\n      contents: read"
    assert prepublish =~ "git checkout --detach \"$VERIFIED_SHA\""
    assert prepublish =~ "mix release.preflight"
    assert prepublish =~ "release_artifact.py create"
    assert prepublish =~ "--package-tar \"release-input/$package_tar\""
    assert prepublish =~ "--package-sha256 \"$checksum\""
    assert prepublish =~ "--only happy_path"
    assert prepublish =~ "--stage prepublish"

    assert prepublish =~
             "name: release-package-${{ needs.recovery-validation.outputs.verified_sha }}"

    assert prepublish =~ "retention-days: 30"
    refute prepublish =~ "HEX_API_KEY"
    refute prepublish =~ "*.log"
  end

  test "protected publish validates downloaded data from a fresh exact-SHA checkout" do
    workflow = File.read!(@workflow)
    publish = job!(workflow, "publish", "post-publish-install-truth")
    freeze_script = File.read!(@freeze_script)

    assert publish =~ "environment: hex-publish"
    assert publish =~ "needs: [recovery-validation, prepublish-proof]"
    assert publish =~ "git checkout --detach \"$VERIFIED_SHA\""
    assert publish =~ "actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c"
    assert publish =~ "test \"$(find release-input -type f | wc -l | tr -d ' ')\" = \"3\""
    assert publish =~ "release_artifact.py verify-local"
    assert publish =~ "bash scripts/publish/release_main_freeze.sh create"
    assert publish =~ "bash scripts/publish/release_main_freeze.sh publish"
    assert publish =~ "bash scripts/publish/release_main_freeze.sh delete \"$FREEZE_RULESET_ID\""

    assert freeze_script =~
             "bash scripts/publish/publish_hex_idempotently.sh \"$package_tar\" \"$manifest\" \"$verified_sha\""

    assert publish =~ "release-input/release-manifest.json"
    assert publish =~ "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}"
    refute publish =~ "run: release-input/"
  end

  test "GitHub release target is checked before Release Please tag bookkeeping" do
    workflow = File.read!(@workflow)
    publish = job!(workflow, "publish", "post-publish-install-truth")

    release_step =
      step!(publish, "Create matching GitHub release", "Mark the merged release PR as tagged")

    verifier = File.read!(@tag_target_verifier)

    assert release_step =~ "gh release view \"$tag_name\""
    assert release_step =~ "gh release create \"$tag_name\" --target \"$VERIFIED_SHA\""
    assert release_step =~ "scripts/publish/verify_github_release_target.sh"
    assert release_step =~ "\"${GITHUB_SERVER_URL}/${GH_REPO}.git\""
    assert release_step =~ "\"$VERIFIED_SHA\""

    assert verifier =~ "git ls-remote \"$remote_url\" \"$tag_ref\" \"$tag_ref^{}\""
    assert verifier =~ "resolved_sha=\"${peeled_sha:-$direct_sha}\""

    assert index!(publish, "verify_github_release_target.sh") <
             index!(publish, "gh pr edit \"$pull_request\"")
  end

  test "postpublish verifies exact public behavior and retains only bounded JSON" do
    workflow = File.read!(@workflow)
    postpublish = final_job!(workflow, "post-publish-install-truth")

    assert postpublish =~ "permissions:\n      contents: read"
    assert postpublish =~ "verify_install_truth.sh"
    assert postpublish =~ "release-input/release-manifest.json"
    assert postpublish =~ "postpublish-receipt.json"
    assert postpublish =~ "retained-release-evidence"
    assert postpublish =~ "retention-days: 90"
    refute postpublish =~ "environment: hex-publish"
    refute postpublish =~ "HEX_API_KEY"
    refute postpublish =~ "tee "
    refute postpublish =~ "*.log"

    guide = File.read!(@guide)
    assert guide =~ "single-artifact chain"
    assert guide =~ "checksum mismatch"
    assert guide =~ "same verified SHA"
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

  defp step!(job, name, next_name) do
    [_, step] =
      Regex.run(
        ~r/^      - name: #{Regex.escape(name)}\n(.*?)^      - name: #{Regex.escape(next_name)}\n/ms,
        job
      )

    step
  end

  defp index!(text, substring) do
    {index, _length} = :binary.match(text, substring)
    index
  end
end
