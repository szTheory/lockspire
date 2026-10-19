defmodule Mix.Tasks.Lockspire.Client.CreateColdTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Ecto.Query
  import Lockspire.MixRepoHelpers

  alias Lockspire.Storage.Ecto.ClientRecord

  @task "lockspire.client.create"
  @prefix_root "mix-cold-create-"

  setup do
    assert_repo_stopped!()

    assert foreign_client_count(@prefix_root) == 0,
           "the test database holds clients this test did not create; reset the committed test database"

    Mix.Task.reenable(@task)

    on_exit(fn ->
      Mix.Task.reenable(@task)
      cleanup_clients_by_prefix!(@prefix_root)
    end)

    {:ok, prefix: @prefix_root <> Base.url_encode64(:crypto.strong_rand_bytes(6), padding: false)}
  end

  defp args(client_id) do
    [
      "--client-type",
      "confidential",
      "--client-id",
      client_id,
      "--redirect-uri",
      "https://client.example.com/callback",
      "--scope",
      "profile",
      "--grant-type",
      "authorization_code"
    ]
  end

  defp fetch_row(client_id) do
    with_temp_repo(fn ->
      Lockspire.TestRepo.all(from(c in ClientRecord, where: c.client_id == ^client_id))
    end)
  end

  test "creates a confidential client with the repo stopped and prints the secret once",
       %{prefix: prefix} do
    client_id = prefix <> "-ok"

    {output, result} = run_task(@task, args(client_id))

    assert result == :ok
    assert output =~ "client_id=#{client_id}"
    assert length(String.split(output, "client_secret=")) - 1 == 1
    assert_repo_stopped!()

    assert [row] = fetch_row(client_id)
    refute output =~ row.client_secret_hash
  end

  test "a duplicate client id fails with a domain error and no secret", %{prefix: prefix} do
    client_id = prefix <> "-dup"

    assert {_output, :ok} = run_task(@task, args(client_id))
    assert_repo_stopped!()

    {output, result} = run_task(@task, args(client_id))

    refute output =~ "client_secret="
    assert {:error, %Mix.Error{message: message}} = result
    refute message =~ "could not start the repo"
    assert length(fetch_row(client_id)) == 1
    assert_repo_stopped!()
  end
end
