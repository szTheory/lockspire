defmodule Lockspire.CiSecurityDependencyContractTest do
  use ExUnit.Case, async: true

  @router_script Path.expand("../../scripts/ci/check_sobelow_routers.sh", __DIR__)
  @dependency_script Path.expand("../../scripts/ci/check_dependency_truth.sh", __DIR__)
  @topology_script Path.expand("../../scripts/ci/check_architecture_topology.sh", __DIR__)
  @sobelow_config Path.expand("../../.sobelow-conf", __DIR__)

  @routers ["lib/lockspire/web/router.ex", "lib/lockspire/web/admin_router.ex"]
  @required_sobelow_flags ["--config", "--private", "--threshold low", "--exit"]

  test "router scan policy covers both shipped routers with every fail-closed flag" do
    script = File.read!(@router_script)

    assert router_scan_violations(script) == []

    assert :missing_admin_router in router_scan_violations(scan_command(@routers |> List.first()))

    assert :missing_private in router_scan_violations(
             scan_command(@routers, ["--config", "--threshold low", "--exit"])
           )

    assert :missing_exit in router_scan_violations(
             scan_command(@routers, ["--private", "--threshold low"])
           )
  end

  test "Sobelow configuration keeps only named reviewable findings" do
    config = File.read!(@sobelow_config)

    assert sobelow_config_violations(config) == []
    assert :broad_ignore in sobelow_config_violations(~s(ignore: ["lib/lockspire/web"]))
    assert :unnamed_ignore_reason in sobelow_config_violations(~s(ignore: ["XSS.SendResp"]))
  end

  test "dependency policy is read-only and routes cycle failures through the compile-connected topology gate" do
    dependency_script = File.read!(@dependency_script)
    topology_script = File.read!(@topology_script)

    assert dependency_script =~ "mix deps.unlock --check-unused"
    assert dependency_script =~ "bash scripts/ci/check_architecture_topology.sh"
    refute dependency_script =~ "mix deps.unlock --unused"
    assert topology_script =~ "mix xref graph --format cycles --label compile-connected"
    refute topology_script =~ "--no-compile"
  end

  defp router_scan_violations(script) do
    missing_routers =
      for router <- @routers,
          not String.contains?(script, "--router #{router}"),
          do: router

    missing_flags =
      for flag <- @required_sobelow_flags,
          not String.contains?(script, flag),
          do: flag

    Enum.map(missing_routers, &router_violation/1) ++ Enum.map(missing_flags, &flag_violation/1)
  end

  defp sobelow_config_violations(config) do
    cond do
      String.contains?(config, ~s(ignore: ["lib/)) ->
        [:broad_ignore]

      String.contains?(config, "ignore:") and not String.contains?(config, "# Reason:") ->
        [:unnamed_ignore_reason]

      true ->
        []
    end
  end

  defp scan_command(routers, flags \\ @required_sobelow_flags)

  defp scan_command(router, flags) when is_binary(router), do: scan_command([router], flags)

  defp scan_command(routers, flags) do
    Enum.map_join(routers, "\n", fn router ->
      Enum.join(["mix sobelow", "--router #{router}" | flags], " ")
    end)
  end

  defp router_violation("lib/lockspire/web/router.ex"), do: :missing_public_router
  defp router_violation("lib/lockspire/web/admin_router.ex"), do: :missing_admin_router
  defp flag_violation("--private"), do: :missing_private
  defp flag_violation("--threshold low"), do: :missing_low_threshold
  defp flag_violation("--exit"), do: :missing_exit
  defp flag_violation("--config"), do: :missing_config
end
