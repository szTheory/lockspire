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
      refute source =~ "ReleaseContractHelpers"
      refute source =~ "use Lockspire.TestSupport"
    end
  end

  test "release proof rejects historical inventory patterns" do
    assert_rejects_legacy_pattern!("use Lockspire.TestSupport.ReleaseContractHelpers")
    assert_rejects_legacy_pattern!("@capability_inventory %{\"phase 115\" => []}")
    assert_rejects_legacy_pattern!("assert assertion_count >= 588")
    assert_rejects_legacy_pattern!("File.read!(\".planning/PROJECT.md\")")
  end

  defp assert_rejects_legacy_pattern!(source) do
    refute source =~ "ReleaseContractHelpers"
    refute source =~ "@capability_inventory"
    refute source =~ ~r/assertion_count\s*>=\s*\d+/
    refute source =~ ".planning/"
  end
end
