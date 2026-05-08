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
end
