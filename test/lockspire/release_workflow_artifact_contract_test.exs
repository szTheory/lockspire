defmodule Lockspire.ReleaseWorkflowArtifactContractTest do
  use ExUnit.Case, async: true

  @workflow Path.expand("../../.github/workflows/release.yml", __DIR__)
  @guide Path.expand("../../docs/maintainer-release.md", __DIR__)

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

    assert publish =~ "environment: hex-publish"
    assert publish =~ "needs: [recovery-validation, prepublish-proof]"
    assert publish =~ "git checkout --detach \"$VERIFIED_SHA\""
    assert publish =~ "actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c"
    assert publish =~ "test \"$(find release-input -type f | wc -l | tr -d ' ')\" = \"3\""
    assert publish =~ "release_artifact.py verify-local"
    assert publish =~ "publish_hex_idempotently.sh"
    assert publish =~ "release-input/release-manifest.json"
    assert publish =~ "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}"
    refute publish =~ "run: release-input/"
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
end
