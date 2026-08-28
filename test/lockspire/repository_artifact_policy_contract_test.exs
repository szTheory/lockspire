defmodule Lockspire.RepositoryArtifactPolicyContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @release_guide Path.join(@repo_root, "docs/maintainer-release.md")
  @scratch ~w(mix_test_output.txt patch.exs test_inspect.exs test_jwe.exs test_mix.exs test_mix2.exs update_docs.py)

  test "approved scratch is absent and retained screenshots have an explicit policy" do
    Enum.each(@scratch, fn path -> refute File.exists?(Path.join(@repo_root, path)) end)

    screenshots = Path.wildcard(Path.join(@repo_root, "tmp/admin-ui-polish/*.png"))
    assert screenshots != []

    guide = File.read!(@release_guide)
    assert guide =~ "tmp/admin-ui-polish/*.png"
    assert guide =~ "demo data or be redaction-safe"
    assert guide =~ "must never be imported by runtime code"
    assert guide =~ "or package inputs"
  end
end
