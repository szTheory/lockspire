defmodule Lockspire.CoverageBaselineContractTest do
  use ExUnit.Case, async: true

  @mixfile Path.expand("../../mix.exs", __DIR__)
  @ci Path.expand("../../.github/workflows/ci.yml", __DIR__)

  test "built-in coverage preserves the ordinary fast-suite denominator at 73 percent" do
    config = Mix.Project.config()
    mixfile = File.read!(@mixfile)

    expected_threshold =
      if System.get_env("LOCKSPIRE_COMPLETE_COVERAGE") == "true", do: 84, else: 73

    expected_output = System.get_env("LOCKSPIRE_COVERAGE_OUTPUT", "cover")

    assert config[:test_coverage] ==
             [summary: [threshold: expected_threshold], output: expected_output]

    assert mixfile =~ "73.11%"
    assert mixfile =~ "\"test.coverage\": [\"test.setup\", \"test --cover\"]"
    assert mixfile =~ "LOCKSPIRE_COMPLETE_COVERAGE"
    assert mixfile =~ "do: 84, else: 73"

    assert Mix.Project.config()[:deps]
           |> Enum.all?(fn dependency ->
             elem(dependency, 0) not in [:excoveralls, :coveralls]
           end)

    refute mixfile =~ "ignore_modules:"
  end

  test "Fast Checks runs the test suite once under built-in coverage" do
    fast_job = ci_job!(File.read!(@ci), "fast")

    assert fast_job =~ "scripts/ci/run_test_matrix.sh --fast"
    refute fast_job =~ "run: mix test.fast"

    runner = File.read!(Path.expand("../../scripts/ci/run_test_matrix.sh", __DIR__))
    assert runner =~ "--cover --export-coverage ${partition}"
    refute runner =~ "mix test.coverage"
  end

  defp ci_job!(workflow, name) do
    [_, job] = Regex.run(~r/  #{name}:\n(.*?)(?=\n  [a-z][\w-]*:|\z)/s, workflow)
    job
  end
end
