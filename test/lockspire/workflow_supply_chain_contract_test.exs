defmodule Lockspire.WorkflowSupplyChainContractTest do
  use ExUnit.Case, async: true

  test "all workflow jobs are bounded and external action and postgres references are immutable" do
    for path <- Path.wildcard(Path.expand("../../.github/workflows/*.yml", __DIR__)) do
      workflow = File.read!(path)
      assert workflow =~ "timeout-minutes:", "#{path} is missing a job timeout"

      for [reference] <- Regex.scan(~r/uses:\s+([^\s#]+)/, workflow, capture: :all_but_first) do
        assert String.starts_with?(reference, "./") or
                 Regex.match?(~r/@[0-9a-f]{40}$/, reference),
               "#{path} has mutable external action #{reference}"
      end

      for [image] <-
            Regex.scan(~r/image:\s+(postgres:[^\s#]+)/, workflow, capture: :all_but_first) do
        assert image =~ "@sha256:", "#{path} has mutable PostgreSQL service image #{image}"
      end
    end
  end

  test "dependency review fails when GitHub cannot provide the dependency graph" do
    workflow = File.read!(Path.expand("../../.github/workflows/dependency-review.yml", __DIR__))

    assert workflow =~ "refusing to skip dependency review"
    assert workflow =~ "exit 1"
    refute workflow =~ "skipping dependency review"
  end
end
