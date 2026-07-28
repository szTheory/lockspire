defmodule Lockspire.Maintainer.AdopterWalkContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../../..", __DIR__)
  @walk_script_path Path.join(@repo_root, "scripts/maintainer/adopter_path_walk.sh")
  @mix_exs_path Path.join(@repo_root, "mix.exs")
  @gitignore_path Path.join(@repo_root, ".gitignore")

  test "walk script exists and uses FAIL-tolerant strict mode" do
    assert File.regular?(@walk_script_path)

    source = File.read!(@walk_script_path)

    assert source =~ "set -uo pipefail"
    refute source =~ "set -euo pipefail"
  end

  test "walk script defines the accumulator and report/verdict lines" do
    source = File.read!(@walk_script_path)

    assert source =~ "record_result"
    assert source =~ ~r/Summary:/
    assert source =~ "Result: adopter path is"
  end

  test "walk script implements the ADOPT-03 resume contract" do
    source = File.read!(@walk_script_path)

    assert source =~ ".walk/steps"
    assert source =~ "--from-step"
    assert source =~ "--workdir"
    assert source =~ "--keep"
    assert source =~ "--port"
  end

  test "walk script isolates the Mix archive directory" do
    source = File.read!(@walk_script_path)

    assert source =~ "MIX_ARCHIVES"
  end

  test "walk script never strips generator capabilities" do
    source = File.read!(@walk_script_path)

    refute source =~ ~r/--no-(ecto|html|assets|mailer)/
  end

  test "walk script preserves the evidence tree unconditionally" do
    source = File.read!(@walk_script_path)

    refute source =~ ~r/trap[^\n]*rm -rf/
    refute source =~ "mktemp -d"
  end

  test "mix.exs wires the adopter.walk alias and keeps it out of ci" do
    source = File.read!(@mix_exs_path)

    assert source =~
             ~s("adopter.walk": ["cmd bash scripts/maintainer/adopter_path_walk.sh"])

    ci_alias =
      source
      |> String.split(~r/\n\s*ci:\s*\[/, parts: 2)
      |> List.last()
      |> String.split(~r/\n\s*\]/, parts: 2)
      |> List.first()

    refute ci_alias =~ "adopter_path_walk"
  end

  test ".gitignore ignores the harness-local Mix archive directory" do
    source = File.read!(@gitignore_path)

    assert source =~ ".harness"
  end
end
