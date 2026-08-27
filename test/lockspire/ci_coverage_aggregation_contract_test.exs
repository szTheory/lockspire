defmodule Lockspire.CiCoverageAggregationContractTest do
  use ExUnit.Case, async: true

  @runner Path.expand("../../scripts/ci/run_test_matrix.sh", __DIR__)
  @aggregator Path.expand("../../scripts/ci/aggregate_coverage.sh", __DIR__)

  test "partitions export native coverage once and keep clean-room evidence separate" do
    runner = File.read!(@runner)

    assert runner =~ "--cover --export-coverage ${partition}"
    assert runner =~ ~s(run_coverage_partition fast "MIX_ENV=test mix do test.setup + test")

    assert runner =~
             ~s(run_coverage_partition integration "MIX_ENV=test mix do test.setup + test --only integration")

    assert runner =~ ~s(run_partition clean_room "MIX_ENV=test mix test.clean-room.e2e")
    refute runner =~ "mix test.coverage"
  end

  test "aggregator treats artifacts as same-SHA data and never executes tests" do
    script = File.read!(@aggregator)

    assert script =~ ~s(expected = {"fast", "integration"})
    assert script =~ "len(all_coverdata) != 2"
    assert script =~ "coverage checksum mismatch"
    assert script =~ "LOCKSPIRE_COVERAGE_AGGREGATE=true"
    assert script =~ "LOCKSPIRE_COMPLETE_COVERAGE=true"
    assert script =~ "mix test.coverage"
    refute script =~ "mix test --"
    refute script =~ "eval"
    refute script =~ "\nsource \""
  end

  test "missing and foreign-SHA evidence fails before Mix is invoked" do
    root =
      Path.join(
        System.tmp_dir!(),
        "lockspire-coverage-contract-#{System.unique_integer([:positive])}"
      )

    input = Path.join(root, "input")
    output = Path.join(root, "output")
    File.mkdir_p!(input)
    on_exit(fn -> File.rm_rf!(root) end)

    assert {message, 1} =
             System.cmd(
               "bash",
               [
                 @aggregator,
                 "--expected-sha",
                 String.duplicate("a", 40),
                 "--input",
                 input,
                 "--output",
                 output
               ],
               stderr_to_stdout: true
             )

    assert message =~ "exactly one fast and one integration manifest"
    refute message =~ "Cover compiling modules"

    File.rm_rf!(output)
    write_partition!(input, "fast", String.duplicate("b", 40))
    write_partition!(input, "integration", String.duplicate("b", 40))

    assert {message, 1} =
             System.cmd(
               "bash",
               [
                 @aggregator,
                 "--expected-sha",
                 String.duplicate("a", 40),
                 "--input",
                 input,
                 "--output",
                 output
               ],
               stderr_to_stdout: true
             )

    assert message =~ "coverage source mismatch"
    refute message =~ "Cover compiling modules"
  end

  defp write_partition!(root, partition, source_sha) do
    directory = Path.join(root, partition)
    File.mkdir_p!(directory)
    coverdata = Path.join(directory, "#{partition}.coverdata")
    File.write!(coverdata, "#{partition}-coverage")

    manifest = %{
      schema_version: 1,
      partition: partition,
      source_sha: source_sha,
      coverdata: "#{partition}.coverdata",
      sha256: :crypto.hash(:sha256, File.read!(coverdata)) |> Base.encode16(case: :lower)
    }

    File.write!(Path.join(directory, "#{partition}.json"), Jason.encode!(manifest))
  end
end
