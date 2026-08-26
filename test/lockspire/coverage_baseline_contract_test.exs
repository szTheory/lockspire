defmodule Lockspire.CoverageBaselineContractTest do
  use ExUnit.Case, async: true

  @mixfile Path.expand("../../mix.exs", __DIR__)
  @ci Path.expand("../../.github/workflows/ci.yml", __DIR__)

  test "built-in coverage preserves the ordinary fast-suite denominator at 73 percent" do
    config = Mix.Project.config()
    mixfile = File.read!(@mixfile)

    assert config[:test_coverage] == [summary: [threshold: 73]]
    assert mixfile =~ "73.11%"
    assert mixfile =~ "\"test.coverage\": [\"test.setup\", \"test --cover\"]"

    assert Mix.Project.config()[:deps]
           |> Enum.all?(fn dependency ->
             elem(dependency, 0) not in [:excoveralls, :coveralls]
           end)

    refute mixfile =~ "ignore_modules:"
  end

  test "Fast Checks runs the test suite once under built-in coverage" do
    fast_job = ci_job!(File.read!(@ci), "fast")

    assert fast_job =~ "run: mix test.coverage"
    refute fast_job =~ "run: mix test.fast"
    assert fast_job =~ "mix test.coverage"
  end

  defp ci_job!(workflow, name) do
    [_, job] = Regex.run(~r/  #{name}:\n(.*?)(?=\n  [a-z][\w-]*:|\z)/s, workflow)
    job
  end
end
