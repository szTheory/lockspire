defmodule Lockspire.Web.Live.Admin.DesignSystem.InventoryContractTest do
  use ExUnit.Case, async: true

  @contract_dir __DIR__
  @legacy_contract Path.expand("../design_system_contract_test.exs", __DIR__)
  @helper_path Path.expand("../../../../../support/admin_contract_helpers.ex", __DIR__)
  @capability_files %{
    css: Path.join(__DIR__, "css_contract_test.exs"),
    proof_artifact: Path.join(__DIR__, "proof_artifact_contract_test.exs"),
    route: Path.join(__DIR__, "route_contract_test.exs")
  }
  @historical_test_counts %{css: 27, proof_artifact: 20, route: 23}

  test "admin design contracts are physically split without wrapper loading" do
    refute File.exists?(@legacy_contract)

    for {_capability, path} <- @capability_files do
      source = File.read!(path)

      assert source =~ "use Lockspire.AdminContractHelpers"
      refute source =~ "Code.require_file"
      refute source =~ "design_system_contract_test.exs"
      refute source =~ ~r/^\s*describe "Phase /m
    end
  end

  test "capability suites preserve the historical test and assertion inventory" do
    sources =
      Map.new(@capability_files, fn {capability, path} -> {capability, File.read!(path)} end)

    test_counts =
      Map.new(sources, fn {capability, source} ->
        {capability, ~r/^\s*test "/m |> Regex.scan(source) |> length()}
      end)

    test_names =
      sources
      |> Map.values()
      |> Enum.flat_map(&Regex.scan(~r/^\s*test "([^"]+)"/m, &1, capture: :all_but_first))
      |> List.flatten()

    assertion_count =
      [File.read!(@helper_path) | Map.values(sources)]
      |> Enum.map(
        &Regex.scan(~r/\b(?:assert|refute|assert_raise|assert_receive|refute_receive)\b/, &1)
      )
      |> Enum.map(&length/1)
      |> Enum.sum()

    assert test_counts == @historical_test_counts
    assert Enum.sum(Map.values(test_counts)) == 70
    assert length(Enum.uniq(test_names)) == 70
    assert assertion_count == 462
  end

  test "shared support owns source, HTML, route, scorecard, and evidence helpers" do
    helper_source = File.read!(@helper_path)

    assert helper_source =~ "defmodule Lockspire.AdminContractHelpers"
    assert helper_source =~ "BrowserEvidence"
    assert helper_source =~ "HtmlAssertions"
    assert helper_source =~ "RouteScorecards"
    assert helper_source =~ "def mounted_admin_routes"
    assert helper_source =~ "def css_rule"
    refute Path.wildcard(Path.join(@contract_dir, "*.exs")) == []
  end
end
