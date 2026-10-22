defmodule Lockspire.Integration.ClientLifetimePackagedJourneyTest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @moduletag :lifetime_package
  @moduletag timeout: 900_000

  @runner Path.expand("../../scripts/acceptance/clean_room_saas_journey.py", __DIR__)

  test "a packaged candidate registers and redeems an S256 authorization code over HTTP" do
    root =
      Path.join(
        System.tmp_dir!(),
        "lockspire-lifetime-journey-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)
    File.chmod!(root, 0o700)
    receipt_path = Path.join(root, "receipt.json")
    on_exit(fn -> File.rm_rf!(root) end)

    runner =
      Task.async(fn ->
        System.cmd(
          "python3",
          [@runner, "--only", "dcr_lifetime", "--receipt", receipt_path] ++ package_arguments(),
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
    scenarios = Map.new(receipt["scenarios"], &{&1["id"], &1})

    assert Map.keys(scenarios) |> Enum.sort() == [
             "fresh.app_expiry_disabled",
             "fresh.management_put_recover",
             "fresh.register_use",
             "fresh.secret_expiry_rotate"
           ]

    assert receipt["counts"]["executed"] > 0
    assert receipt["counts"]["passed"] == receipt["counts"]["executed"]
    assert receipt["counts"]["failed"] == 0
    assert receipt["counts"]["skipped"] == 0
    assert scenarios["fresh.register_use"]["observations"]["access_token_issued"]
    assert scenarios["fresh.register_use"]["observations"]["pkce_method"] == "S256"

    for identifier <- [
          "fresh.secret_expiry_rotate",
          "fresh.management_put_recover",
          "fresh.app_expiry_disabled"
        ] do
      assert scenarios[identifier]["outcome"] == "passed"
      assert scenarios[identifier]["counts"]["executed"] > 0
      assert scenarios[identifier]["event_counts"] |> Map.values() |> Enum.all?(&(&1 > 0))
      assert scenarios[identifier]["audit_counts"] |> Map.values() |> Enum.all?(&(&1 > 0))
    end

    assert scenarios["fresh.secret_expiry_rotate"]["observations"]["expiry_rejected"]
    assert scenarios["fresh.secret_expiry_rotate"]["observations"]["rotation_restored_auth"]

    assert scenarios["fresh.secret_expiry_rotate"]["observations"][
             "unrelated_deadlines_preserved"
           ]

    assert scenarios["fresh.management_put_recover"]["observations"]["old_credential_rejected"]
    assert scenarios["fresh.management_put_recover"]["observations"]["host_authorized_recovery"]
    assert scenarios["fresh.app_expiry_disabled"]["observations"]["expired_put_rejected"]
    assert scenarios["fresh.app_expiry_disabled"]["observations"]["disabled_management_denied"]

    assert receipt["cleanup"] == %{
             "processes_stopped" => true,
             "databases_removed" => true,
             "temporary_roots_removed" => true
           }

    persist_lifetime_receipt(receipt_path, "fresh")
  end

  test "the package-shipped adapter example and configured PostgreSQL adapter execute in a host" do
    root =
      Path.join(
        System.tmp_dir!(),
        "lockspire-lifetime-custom-journey-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)
    File.chmod!(root, 0o700)
    receipt_path = Path.join(root, "receipt.json")
    on_exit(fn -> File.rm_rf!(root) end)

    runner =
      Task.async(fn ->
        System.cmd(
          "python3",
          [
            @runner,
            "--only",
            "dcr_lifetime",
            "--lifetime-leg",
            "custom",
            "--receipt",
            receipt_path
          ] ++ package_arguments(),
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

    assert unsupported["counts"] == %{
             "executed" => 1,
             "passed" => 1,
             "failed" => 0,
             "skipped" => 0
           }

    assert unsupported["observations"]["unsupported_rejected"]
    assert unsupported["observations"]["example_executed"]

    assert receipt["cleanup"] == %{
             "processes_stopped" => true,
             "databases_removed" => true,
             "temporary_roots_removed" => true
           }

    persist_lifetime_receipt(receipt_path, "custom")
  end

  defp package_arguments do
    case {System.get_env("LOCKSPIRE_LIFETIME_PACKAGE_TAR"),
          System.get_env("LOCKSPIRE_LIFETIME_PACKAGE_SHA256")} do
      {tar, sha} when is_binary(tar) and is_binary(sha) ->
        ["--package-tar", tar, "--package-sha256", sha]

      _ ->
        []
    end
  end

  defp persist_lifetime_receipt(source, name) do
    case System.get_env("LOCKSPIRE_LIFETIME_RECEIPT_DIR") do
      nil ->
        :ok

      directory ->
        File.mkdir_p!(directory)
        File.cp!(source, Path.join(directory, "#{name}.json"))
    end
  end
end
