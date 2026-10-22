defmodule Lockspire.Integration.ClientLifetimePackagedJourneyTest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @moduletag timeout: 900_000

  @runner Path.expand("../../scripts/acceptance/clean_room_saas_journey.py", __DIR__)

  test "a packaged candidate registers and redeems an S256 authorization code over HTTP" do
    root = Path.join(System.tmp_dir!(), "lockspire-lifetime-journey-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    File.chmod!(root, 0o700)
    receipt_path = Path.join(root, "receipt.json")
    on_exit(fn -> File.rm_rf!(root) end)

    runner =
      Task.async(fn ->
        System.cmd("python3", [@runner, "--only", "dcr_lifetime", "--receipt", receipt_path],
          stderr_to_stdout: true
        )
      end)

    result =
      case Task.yield(runner, 900_000) do
        {:ok, result} ->
          result

        nil ->
          Task.shutdown(runner, :brutal_kill)
          flunk("packaged DCR lifetime child timed out after 900 seconds")
      end

    assert {output, 0} = result
    assert output =~ "package candidate built"
    assert output =~ "readiness complete"
    assert output =~ "cleanup complete"
    assert File.regular?(receipt_path)

    assert {check_output, 0} =
             System.cmd("python3", [@runner, "--check-lifetime-receipt", receipt_path],
               stderr_to_stdout: true
             )

    assert check_output =~ "lifetime receipt verified"
    {:ok, python} = File.read(receipt_path)
    {:ok, receipt} = Jason.decode(python)
    assert receipt["counts"] == %{"executed" => 1, "passed" => 1, "failed" => 0, "skipped" => 0}
    assert [scenario] = receipt["scenarios"]
    assert scenario["id"] == "fresh.register_use"
    assert scenario["outcome"] == "passed"
    assert scenario["observations"]["access_token_issued"]
    assert scenario["observations"]["pkce_method"] == "S256"
    assert scenario["counts"]["executed"] > 0
    assert scenario["counts"]["passed"] > 0
    assert receipt["cleanup"] == %{"processes_stopped" => true, "databases_removed" => true, "temporary_roots_removed" => true}
  end

  test "the package-shipped adapter example and configured PostgreSQL adapter execute in a host" do
    root = Path.join(System.tmp_dir!(), "lockspire-lifetime-custom-journey-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    File.chmod!(root, 0o700)
    receipt_path = Path.join(root, "receipt.json")
    on_exit(fn -> File.rm_rf!(root) end)

    runner =
      Task.async(fn ->
        System.cmd(
          "python3",
          [@runner, "--only", "dcr_lifetime", "--lifetime-leg", "custom", "--receipt", receipt_path],
          stderr_to_stdout: true
        )
      end)

    result =
      case Task.yield(runner, 900_000) do
        {:ok, result} ->
          result

        nil ->
          Task.shutdown(runner, :brutal_kill)
          flunk("packaged custom lifetime child timed out after 900 seconds")
      end

    assert {output, 0} = result
    assert output =~ "package candidate built"
    assert output =~ "readiness complete"
    assert output =~ "cleanup complete"
    assert File.regular?(receipt_path)

    assert {check_output, 0} =
             System.cmd(
               "python3",
               [@runner, "--check-lifetime-receipt", receipt_path, "--lifetime-leg", "custom"],
               stderr_to_stdout: true
             )

    assert check_output =~ "lifetime receipt verified"
    {:ok, receipt} = receipt_path |> File.read!() |> Jason.decode()
    scenarios = Map.new(receipt["scenarios"], &{&1["id"], &1})
    assert Map.keys(scenarios) |> Enum.sort() == [
             "custom.issue_replace",
             "custom.shared_rollback",
             "custom.unsupported"
           ]
    scenario = scenarios["custom.issue_replace"]
    assert scenario["outcome"] == "passed"
    assert scenario["observations"]["registration_http_status"] == 201
    assert scenario["observations"]["token_http_status"] == 200
    assert scenario["observations"]["replacement_http_status"] == 200
    assert scenario["observations"]["callbacks_executed"] > 0
    assert scenario["observations"]["callback_counts"]["register_client"] > 0
    assert scenario["observations"]["callback_counts"]["replace_client_registration"] > 0
    assert scenario["observations"]["callback_counts"]["transact"] > 0
    assert scenario["observations"]["authority_shared"]
    assert scenario["observations"]["example_executed"]
    assert scenario["counts"]["executed"] > 1
    rollback = scenarios["custom.shared_rollback"]
    assert rollback["outcome"] == "passed"
    assert rollback["counts"] == %{"executed" => 2, "passed" => 2, "failed" => 0, "skipped" => 0}
    assert rollback["observations"]["independent_observer"]
    assert rollback["observations"]["rollback_preserved"]
    assert rollback["observations"]["replacement_observed"]
    assert rollback["observations"]["issuance_observed"]
    unsupported = scenarios["custom.unsupported"]
    assert unsupported["outcome"] == "passed"
    assert unsupported["counts"] == %{"executed" => 1, "passed" => 1, "failed" => 0, "skipped" => 0}
    assert unsupported["observations"]["unsupported_rejected"]
    assert unsupported["observations"]["example_executed"]
    assert receipt["cleanup"] == %{
             "processes_stopped" => true,
             "databases_removed" => true,
             "temporary_roots_removed" => true
           }
  end
end
