defmodule Lockspire.ReleaseReadinessContractTest do
  use ExUnit.Case, async: true

  @release_suites [
    "test/lockspire/release/release_automation_contract_test.exs",
    "test/lockspire/release/repository_hygiene_contract_test.exs",
    "test/lockspire/release/support_surface_contract_test.exs"
  ]

  test "release proof uses focused capability helpers" do
    for suite <- @release_suites do
      source = File.read!(suite)

      assert source =~ "Lockspire.TestSupport.ReleaseProof"
      assert_no_legacy_patterns!(source)
    end
  end

  test "release proof rejects historical inventory patterns" do
    for violating_source <- [
          "use Lockspire.TestSupport.ReleaseContractHelpers",
          "@capability_inventory %{\"legacy capability\" => []}",
          "assert assertion_count >= 1",
          "File.read!(\".planning/PROJECT.md\")"
        ] do
      assert_raise ExUnit.AssertionError, fn -> assert_no_legacy_patterns!(violating_source) end
    end
  end

  defp assert_no_legacy_patterns!(source) do
    refute source =~ "ReleaseContractHelpers"
    refute source =~ "@capability_inventory"
    refute source =~ ~r/assertion_count\s*>=\s*\d+/
    refute source =~ ".planning/"
  end
end
