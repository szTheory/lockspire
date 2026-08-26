defmodule Lockspire.PublishVerificationTest do
  use ExUnit.Case, async: true

  @maintainer_guide_path Path.expand("../../docs/maintainer-release.md", __DIR__)

  test "maintainer guide explicitly outlines running the post-publish verification script" do
    guide = File.read!(@maintainer_guide_path)

    assert guide =~ "## Post-Publish Verification"
    assert guide =~ "scripts/publish/verify_install_truth.sh"
    assert guide =~ "Install Truth"
    assert guide =~ "verifies the published Hex artifact and docs"
  end

  test "install truth script is CI-safe and release workflow keeps it unprivileged" do
    script = File.read!(Path.expand("../../scripts/publish/verify_install_truth.sh", __DIR__))
    workflow = File.read!(Path.expand("../../.github/workflows/release.yml", __DIR__))

    assert script =~ "EXPECTED_VERSION=\"${EXPECTED_VERSION:-$DECLARED_VERSION}\""
    assert script =~ "[ \"$EXPECTED_VERSION\" != \"$DECLARED_VERSION\" ]"
    assert script =~ "lockspire-install-truth"
    assert script =~ "--retry-all-errors"
    assert workflow =~ "post-publish-install-truth:"
    assert workflow =~ "permissions:\n      contents: read"
    assert workflow =~ "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a"
    refute workflow =~ "post-publish-install-truth:\n    environment: hex-publish"
  end
end
