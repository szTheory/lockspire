defmodule Lockspire.Web.Live.Admin.DesignSystem.InventoryContractTest do
  use ExUnit.Case, async: true

  @capabilities %{
    "css_contract_test.exs" => "Lockspire.Web.AdminProof.CssAssertions",
    "proof_artifact_contract_test.exs" => "Lockspire.Web.AdminProof.RedactionAssertions",
    "route_contract_test.exs" => "Lockspire.Web.AdminProof.RouteAssertions"
  }

  @forbidden_constructs [
    {:macro_injection, ~r/\b(?:use\s+Lockspire\.AdminContractHelpers|defmacro\s+__using__)\b/},
    {:phase_numbered_api, ~r/phase[_ -]?\d+/i},
    {:archived_milestone, ~r/\.planning\/milestones\/v\d+/},
    {:wrapper_loading, ~r/\bCode\.require_file\b|design_system_contract_test\.exs/},
    {:quantity_threshold, ~r/@historical_test_counts|assertion_count|test_counts\s*==/}
  ]

  test "each suite names a small capability helper without hidden loading" do
    for {file, helper} <- @capabilities do
      source = File.read!(Path.join(__DIR__, file))

      assert source =~ helper |> String.split(".") |> List.last()
      assert capability_violations(source) == []
    end
  end

  test "fitness predicates reject every retired architecture construct" do
    examples = [
      {:macro_injection, "use Lockspire.AdminContractHelpers"},
      {:phase_numbered_api, "assert_phase_125_boundary!()"},
      {:archived_milestone, ~s|File.read!(".planning/milestones/v1.32/proof.md")|},
      {:wrapper_loading, ~s|Code.require_file("design_system_contract_test.exs")|},
      {:quantity_threshold, "assert test_counts == %{css: 27}"}
    ]

    for {expected, source} <- examples do
      assert expected in capability_violations(source)
    end
  end

  test "legacy macro support has been removed" do
    refute File.exists?(Path.expand("../../../../../support/admin_contract_helpers.ex", __DIR__))
  end

  defp capability_violations(source) do
    for {name, pattern} <- @forbidden_constructs,
        Regex.match?(pattern, source),
        do: name
  end
end
