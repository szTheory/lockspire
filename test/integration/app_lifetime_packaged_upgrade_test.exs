defmodule Lockspire.Integration.AppLifetimePackagedUpgradeTest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @moduletag timeout: 900_000

  Code.require_file("../clean_room/lifetime_upgrade_scenarios.exs", __DIR__)

  @runner Path.expand("../../scripts/acceptance/clean_room/client_lifetime_upgrade.py", __DIR__)

  test "pinned old and candidate packages complete the public and tenant_auth cutover" do
    root =
      Path.join(
        System.tmp_dir!(),
        "lockspire-lifetime-upgrade-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)
    File.chmod!(root, 0o700)
    receipt_path = Path.join(root, "receipt.json")
    on_exit(fn -> File.rm_rf!(root) end)

    runner =
      Task.async(fn ->
        System.cmd(
          "python3",
          [@runner, "--scenario", "all", "--receipt", receipt_path],
          stderr_to_stdout: true
        )
      end)

    result =
      case Task.yield(runner, 900_000) do
        {:ok, result} ->
          result

        nil ->
          Task.shutdown(runner, :brutal_kill)
          flunk("packaged upgrade child timed out after 900 seconds")
      end

    assert {output, 0} = result

    assert output =~ "provider provenance verified"
    assert File.regular?(receipt_path)

    assert {check_output, 0} =
             System.cmd("python3", [@runner, "--check-receipt", receipt_path],
               stderr_to_stdout: true
             )

    assert check_output =~ "lifetime upgrade receipt verified"
    receipt = receipt_path |> File.read!() |> Jason.decode!()
    scenarios = Map.new(receipt["scenarios"], &{&1["prefix"], &1})

    assert Map.keys(scenarios) |> Enum.sort() ==
             Lockspire.CleanRoom.LifetimeUpgradeScenarios.prefixes()

    assert Lockspire.CleanRoom.LifetimeUpgradeScenarios.legacy_date_kinds() ==
             ["nil", "creation", "past", "future"]

    for prefix <- ["public", "tenant_auth"] do
      scenario = scenarios[prefix]

      assert scenario["v0_legacy_rows_observation"]["output"] =~
               Lockspire.CleanRoom.LifetimeUpgradeScenarios.required_v0_observation()

      assert scenario["old_package"]["version"] == "1.6.1"

      assert scenario["old_package"]["sha256"] ==
               "629abdc1b6721620f3d9084dbbe78da1e254650da5c552d0cc0f5b0c00f1cc6d"

      assert scenario["old_read_write_count"] == 5
      assert scenario["old_writer_processes_stopped_before_v1"]
      assert scenario["v1_state_retained"]
      assert scenario["historical_migration_checksums_preserved"]
      assert scenario["database_cleanup_process"]["exit_code"] == 0
      assert scenario["old_binary_after_v1_traffic"] == false
    end
  end
end
