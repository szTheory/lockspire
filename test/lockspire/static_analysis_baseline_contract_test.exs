defmodule Lockspire.StaticAnalysisBaselineContractTest do
  use ExUnit.Case, async: true

  @credo Path.expand("../../.credo.exs", __DIR__)
  @mixfile Path.expand("../../mix.exs", __DIR__)
  @wrapper Path.expand("../../scripts/ci/run_credo.sh", __DIR__)

  test "Credo analyzes the full source set with a bounded parse budget" do
    config = File.read!(@credo)

    assert config =~ "parse_timeout: 30_000"
    assert config =~ "included: [\"lib/\", \"test/\"]"
    refute config =~ "excluded: [\"lib/\""
    refute config =~ "excluded: [\"test/\""
  end

  test "qa reaches a fail-closed Credo wrapper" do
    assert File.read!(@mixfile) =~ "cmd bash scripts/ci/run_credo.sh"

    wrapper = File.read!(@wrapper)

    assert wrapper =~ "mktemp"
    assert wrapper =~ "trap 'rm -f"
    assert wrapper =~ "mix credo --strict"
    assert wrapper =~ "credo_status=${PIPESTATUS[0]}"
    assert wrapper =~ "if [ \"$credo_status\" -ne 0 ]"
    assert wrapper =~ "Some source files were not parsed in the time allotted"
    assert wrapper =~ "exit 1"
  end
end
