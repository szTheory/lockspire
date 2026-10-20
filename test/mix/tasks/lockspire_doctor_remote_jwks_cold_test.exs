defmodule Mix.Tasks.Lockspire.Doctor.RemoteJwksColdTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Lockspire.MixRepoHelpers

  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository

  @task "lockspire.doctor"
  @leaf "lockspire.doctor.remote_jwks"
  @prefix_root "mix-cold-rjwks-"
  @unavailable "Could not inspect client: could not start the repo; check database connectivity and config :lockspire, :repo"

  setup do
    assert_repo_stopped!()

    sweep_stale_cold_clients!()

    assert foreign_client_count() == 0,
           "the test database holds clients this test did not create; reset the committed test database"

    original_repo = Application.get_env(:lockspire, :repo)
    Mix.Task.reenable(@task)
    Mix.Task.reenable(@leaf)

    on_exit(fn ->
      Application.put_env(:lockspire, :repo, original_repo)
      Mix.Task.reenable(@task)
      Mix.Task.reenable(@leaf)
      cleanup_clients_by_prefix!(@prefix_root)
    end)

    {:ok, prefix: @prefix_root <> Base.url_encode64(:crypto.strong_rand_bytes(6), padding: false)}
  end

  defp seed(client_id) do
    with_temp_repo(fn ->
      {:ok, _client} =
        Repository.register_client(%Client{
          lifetime_version: 0,
          client_id: client_id,
          client_secret_hash: "sha256:#{client_id}:hash",
          client_type: :confidential,
          name: "Cold Remote JWKS #{client_id}",
          redirect_uris: ["https://client.example.com/callback"],
          allowed_scopes: ["openid"],
          allowed_grant_types: ["authorization_code"],
          allowed_response_types: ["code"],
          token_endpoint_auth_method: :client_secret_basic,
          pkce_required: true,
          subject_type: :public,
          created_at: DateTime.utc_now(),
          metadata: %{}
        })
    end)
  end

  test "diagnoses a seeded client with the repo stopped and leaves it stopped", %{prefix: prefix} do
    client_id = prefix <> "-ok"
    seed(client_id)
    assert_repo_stopped!()

    {output, result} = run_task(@task, ["remote-jwks", "--client", client_id], [@leaf])

    assert result == :ok
    assert output =~ "Client: #{client_id}"
    assert output =~ "Status: not_applicable"
    assert_repo_stopped!()
  end

  test "an unknown client raises the domain error and leaves the repo stopped", %{prefix: prefix} do
    {_output, result} =
      run_task(@task, ["remote-jwks", "--client", prefix <> "-missing"], [@leaf])

    assert {:error, %Mix.Error{message: "Client not found."}} = result
    assert_repo_stopped!()
  end

  test "a repo that cannot start raises a fixed phrase" do
    Application.put_env(:lockspire, :repo, Lockspire.MixRepoHelpers.RaisingRepo)

    {_output, result} = run_task(@task, ["remote-jwks", "--client", "whatever"], [@leaf])

    assert {:error, %Mix.Error{message: message}} = result
    assert message == @unavailable
  end
end
