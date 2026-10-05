defmodule Lockspire.Release.Phase140ReadOnlyClosureContractTest do
  use ExUnit.Case, async: false

  @tag :phase140_closure_tracer
  test "the committed closure command exposes independent signed-review inputs" do
    repo_root = Path.expand("../../..", __DIR__)
    script = Path.join(repo_root, "scripts/maintainer/verify_phase140_read_only_closure.py")

    {output, status} = System.cmd("python3", [script, "--help"], cd: repo_root)

    assert status == 0
    assert output =~ "--verify-review-only"
    assert output =~ "--review-statement"
    assert output =~ "--review-signature"
    assert output =~ "--allowed-signers"
    assert output =~ "--reviewer-principal"
    assert output =~ "--trusted-fingerprint"
  end
end
