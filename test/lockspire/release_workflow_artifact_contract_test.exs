defmodule Lockspire.ReleaseWorkflowArtifactContractTest do
  use ExUnit.Case, async: true

  @workflow Path.expand("../../.github/workflows/release.yml", __DIR__)
  @guide Path.expand("../../docs/maintainer-release.md", __DIR__)
  @freeze_script Path.expand("../../scripts/publish/release_main_freeze.sh", __DIR__)
  @artifact_tool Path.expand("../../scripts/publish/release_artifact.py", __DIR__)
  @tag_target_verifier Path.expand(
                         "../../scripts/publish/verify_github_release_target.sh",
                         __DIR__
                       )
  @tag_guard Path.expand("../../scripts/publish/release_tag_guard.sh", __DIR__)

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
    assert prepublish =~ ".runtime.publisher_hex"
    assert prepublish =~ ".runtime.hex"
    assert prepublish =~ "test \"$HEX_VERSION\" = \"$BUILDER_HEX_VERSION\""
    assert prepublish =~ "mix local.hex \"$HEX_VERSION\" --force"
    assert prepublish =~ "Hex.version()"
    assert prepublish =~ "Hex.API.Release, :publish, 5"
    assert prepublish =~ "mix test test/lockspire/release_artifact_chain_contract_test.exs"
    assert prepublish =~ "--publisher-hex-version \"$HEX_VERSION\""
    assert prepublish =~ "--publisher-api-export \"$API_EXPORT\""
    assert prepublish =~ "--exact-byte-fixture true"

    artifact_tool = File.read!(@artifact_tool)
    assert artifact_tool =~ "\"publisher_compatibility\""
    assert artifact_tool =~ "\"hex_version\": args.publisher_hex_version"
    assert artifact_tool =~ "\"api_export\": True"
    assert artifact_tool =~ "\"exact_byte_fixture\": True"

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

    publisher_step =
      step!(
        publish,
        "Install and verify manifest-bound Hex publisher",
        "Install build tools and locked dependencies"
      )

    assert publisher_step =~ ".runtime.publisher_hex"
    assert publisher_step =~ ".runtime.hex"
    assert publisher_step =~ "test \"$HEX_VERSION\" = \"$BUILDER_HEX_VERSION\""
    assert publisher_step =~ "mix local.hex \"$HEX_VERSION\" --force"
    assert publisher_step =~ "Hex.version()"
    assert publisher_step =~ "Hex.API.Release, :publish, 5"

    assert index!(publish, "Download clean-room-proven package data") <
             index!(publish, "Install and verify manifest-bound Hex publisher")

    assert index!(publish, "Hex.API.Release, :publish, 5") < index!(publish, "HEX_API_KEY")
    refute publish =~ "mix release.preflight"
  end

  test "GitHub release target is checked before Release Please tag bookkeeping" do
    workflow = File.read!(@workflow)
    publish = job!(workflow, "publish", "post-publish-install-truth")

    preflight_step =
      step!(
        publish,
        "Preflight existing GitHub tag target before publication",
        "Mint scoped release freeze token"
      )

    release_step =
      step!(publish, "Create matching GitHub release", "Mark the merged release PR as tagged")

    verifier = File.read!(@tag_target_verifier)

    assert release_step =~ "gh release view \"$tag_name\""
    assert release_step =~ "gh release create \"$tag_name\" --target \"$VERIFIED_SHA\""
    assert release_step =~ "scripts/publish/verify_github_release_target.sh"
    assert release_step =~ "\"${GITHUB_SERVER_URL}/${GH_REPO}.git\""
    assert release_step =~ "\"$VERIFIED_SHA\""
    refute release_step =~ "--if-present"

    assert preflight_step =~ "jq -er '.version' release-input/release-manifest.json"
    assert preflight_step =~ "scripts/publish/verify_github_release_target.sh"
    assert preflight_step =~ "--if-present"

    assert verifier =~ "git ls-remote \"$remote_url\" \"$tag_ref\" \"$tag_ref^{}\""
    assert verifier =~ "resolved_sha=\"${peeled_sha:-$direct_sha}\""

    assert index!(publish, "Preflight existing GitHub tag target before publication") <
             index!(publish, "name: Publish exact package while main is frozen")

    assert index!(publish, "verify_github_release_target.sh") <
             index!(publish, "gh pr edit \"$pull_request\"")
  end

  test "exact release tag is frozen and verified before Hex publication" do
    workflow = File.read!(@workflow)
    publish = job!(workflow, "publish", "post-publish-install-truth")
    tag_guard = File.read!(@tag_guard)
    freeze_script = File.read!(@freeze_script)

    freeze_step =
      step!(
        publish,
        "Freeze updates and deletion for the exact release tag",
        "Create or verify the exact release tag"
      )

    ensure_step =
      step!(
        publish,
        "Create or verify the exact release tag",
        "Publish exact package while main is frozen"
      )

    tag_cleanup =
      step!(
        publish,
        "Remove temporary release tag freeze",
        "Remove temporary main freeze"
      )

    assert freeze_step =~ "release_tag_guard.sh create"
    assert freeze_step =~ "GH_TOKEN: ${{ steps.release-freeze-token.outputs.token }}"
    assert ensure_step =~ "release_tag_guard.sh ensure"
    assert ensure_step =~ "GH_TOKEN: ${{ steps.release-freeze-token.outputs.token }}"
    assert ensure_step =~ "REF_CREATE_TOKEN: ${{ github.token }}"
    assert ensure_step =~ "VERIFIED_SHA: ${{ needs.recovery-validation.outputs.verified_sha }}"

    assert ensure_step =~
             "TAG_FREEZE_RULESET_ID: ${{ steps.release-tag-freeze.outputs.ruleset_id }}"

    assert tag_cleanup =~ "always()"
    assert tag_cleanup =~ "release_tag_guard.sh delete"

    assert tag_guard =~ "target: \"tag\""
    assert tag_guard =~ "bypass_actors: []"
    assert tag_guard =~ "type: \"update\""
    assert tag_guard =~ "type: \"deletion\""
    assert tag_guard =~ "repos/$expected_repo/git/refs"
    assert tag_guard =~ "verify_github_release_target.sh"
    assert freeze_script =~ "release_tag_guard.sh preflight"

    assert index!(publish, "Preflight existing GitHub tag target before publication") <
             index!(publish, "Freeze updates and deletion for the exact release tag")

    assert index!(publish, "Freeze updates and deletion for the exact release tag") <
             index!(publish, "Create or verify the exact release tag")

    assert index!(publish, "Create or verify the exact release tag") <
             index!(publish, "Publish exact package while main is frozen")

    assert index!(publish, "Publish exact package while main is frozen") <
             index!(publish, "Create matching GitHub release")
  end

  test "postpublish verifies exact public behavior and retains only bounded JSON" do
    workflow = File.read!(@workflow)
    postpublish = job!(workflow, "post-publish-install-truth", "terminal-outcome")

    assert postpublish =~ "permissions:\n      contents: read"
    assert postpublish =~ "verify_install_truth.sh"
    assert postpublish =~ "docs_state: ${{ steps.public-truth.outputs.docs_state }}"
    assert postpublish =~ "install_state: ${{ steps.public-truth.outputs.install_state }}"
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
    assert guide =~ "Hex.API.Release.publish/5"
    assert guide =~ "undocumented, version-bound internal API"
    assert guide =~ "exact-byte fixture"
    assert guide =~ "public on Hex"
    assert guide =~ "`release_verified` is false"
    assert guide =~ "passed`, `failed`,"
    assert guide =~ "`not_run`, or `unknown`"
    assert guide =~ "`.workflow_run_id`"
    assert guide =~ "`.manifest.sha256`"
    assert guide =~ "`.artifact.sha256`"
    assert guide =~ "`.observations` records `hex_presence`"
    assert guide =~ "30 days"
    assert guide =~ "90 days"
    assert guide =~ "same authorized source SHA"
    assert guide =~ "manifest-verified tar bytes"
    assert guide =~ "whole-tar checksum"
    assert guide =~ "current public version"
    assert guide =~ "matching CI run"
    assert guide =~ "`tag_target_sha`"
    assert guide =~ "next safe action"
    assert guide =~ "no raw logs or"
  end

  test "terminal outcome is collected after failed or skipped publish stages" do
    workflow = File.read!(@workflow)
    collector = final_job!(workflow, "terminal-outcome")

    assert collector =~
             "needs: [recovery-validation, prepublish-proof, publish, post-publish-install-truth]"

    assert collector =~ "if: ${{ always() && github.event_name == 'workflow_dispatch' }}"
    assert collector =~ "permissions:\n      actions: read\n      contents: read"
    assert collector =~ "continue-on-error: true"
    assert collector =~ "terminal-receipt --input terminal-state.json"
    assert collector =~ "--workflow-run-id \"$GITHUB_RUN_ID\""
    assert collector =~ "https://hex.pm/api/packages/lockspire/releases/$version"
    assert collector =~ "https://hexdocs.pm/lockspire/$version/supported-surface.html"
    assert collector =~ "git ls-remote"
    assert collector =~ "needs.publish.result"
    assert collector =~ "needs.post-publish-install-truth.result"
    assert collector =~ "case \"$docs_presence\" in"
    assert collector =~ "present) docs_stage=passed ;;"
    assert collector =~ "absent) docs_stage=failed ;;"
    assert collector =~ "unknown) docs_stage=unknown ;;"
    assert collector =~ "--arg docs \"$docs_stage\""
    assert collector =~ "docs_presence: $docs_presence"
    refute collector =~ "--arg docs \"$docs_presence\""
    refute collector =~ "HEX_API_KEY"

    upload = final_step!(collector, "Upload the terminal outcome receipt")
    assert upload =~ "if: always()"
    assert upload =~ "name: lockspire-release-terminal-receipt-${{ github.run_id }}"
    assert upload =~ "path: release-terminal-receipt.json"
    assert upload =~ "if-no-files-found: error"
    assert upload =~ "retention-days: 90"
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

  defp final_step!(job, name) do
    [_, step] = Regex.run(~r/^      - name: #{Regex.escape(name)}\n(.*)\z/ms, job)
    step
  end

  defp index!(text, substring) do
    {index, _length} = :binary.match(text, substring)
    index
  end
end
