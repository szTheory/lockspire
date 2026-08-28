defmodule Lockspire.CiTestMatrixContractTest do
  use ExUnit.Case, async: true

  @mix Path.expand("../../mix.exs", __DIR__)
  @ci Path.expand("../../.github/workflows/ci.yml", __DIR__)
  @runner Path.expand("../../scripts/ci/run_test_matrix.sh", __DIR__)

  test "default CI owns each test partition once and keeps focused aliases" do
    mix = File.read!(@mix)
    ci = File.read!(@ci)
    runner = File.read!(@runner)

    assert mix =~
             ~s("test.fast": ["test.setup", "test test/lockspire test/mix test/integration"])

    assert mix =~
             ~s("test --cover test/lockspire test/mix test/integration")

    assert mix =~
             ~s("test.integration": ["test.setup", "test --only integration test/integration"])

    refute mix =~ ~s("test.fast": ["test.setup", "test"])
    assert mix =~ ~s("test.phase3": [)
    refute ci =~ "Run Phase 3 protocol gate"
    assert ci =~ "scripts/ci/run_test_matrix.sh --fast"
    assert ci =~ "scripts/ci/run_test_matrix.sh --integration"
    assert length(Regex.scan(~r/CLEAN_ROOM_DB_USER: lockspire/, ci)) == 2
    assert runner =~ "mix test.phase3"
    assert runner =~ "exit_status"
    assert runner =~ "elapsed_seconds"
    assert runner =~ "overall_status=0"
    assert runner =~ "overall_status=$status"
    assert runner =~ "return 0"
    assert runner =~ ~s(exit "$overall_status")

    {artifact_offset, _} = :binary.match(runner, ~s(> "$output"))
    {exit_offset, _} = :binary.match(runner, ~s(exit "$overall_status"))
    assert artifact_offset < exit_offset
  end
end
