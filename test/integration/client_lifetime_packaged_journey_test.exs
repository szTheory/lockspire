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
end
