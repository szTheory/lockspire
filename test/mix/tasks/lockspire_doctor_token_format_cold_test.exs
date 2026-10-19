defmodule Mix.Tasks.Lockspire.Doctor.TokenFormatColdTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Lockspire.MixRepoHelpers

  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository

  @task "lockspire.doctor"
  @leaf "lockspire.doctor.token_format"
  @prefix_root "mix-cold-tokfmt-"
  @unavailable "Could not inspect token formats: could not start the repo; check database connectivity and config :lockspire, :repo"

  setup do
    assert_repo_stopped!()

    assert foreign_client_count(@prefix_root) == 0,
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

  defp seed(client_id, format) do
    with_temp_repo(fn ->
      {:ok, _client} =
        Repository.register_client(%Client{
          client_id: client_id,
          client_secret_hash: "sha256:#{client_id}:hash",
          client_type: :confidential,
          name: "Cold Token Format #{client_id}",
          redirect_uris: ["https://client.example.com/callback"],
          allowed_scopes: ["openid"],
          allowed_grant_types: ["authorization_code"],
          allowed_response_types: ["code"],
          token_endpoint_auth_method: :client_secret_basic,
          pkce_required: true,
          subject_type: :public,
          access_token_format: format,
          created_at: DateTime.utc_now(),
          metadata: %{}
        })
    end)
  end

  test "reports seeded clients with the repo stopped and leaves it stopped", %{prefix: prefix} do
    seed(prefix <> "-nil", nil)
    seed(prefix <> "-opaque", :opaque)
    assert_repo_stopped!()

    {output, result} = run_task(@task, ["token_format"], [@leaf])

    assert result == :ok
    assert output =~ "#{prefix}-nil: jwt"
    assert output =~ "CHANGED"
    assert output =~ "#{prefix}-opaque: opaque"
    assert_repo_stopped!()
  end

  test "reports an empty registry calmly with the repo stopped" do
    {output, result} = run_task(@task, ["token_format"], [@leaf])

    assert result == :ok
    assert output =~ "(no clients registered)"
    assert_repo_stopped!()
  end

  test "a repo that cannot start prints a fixed phrase and does not raise" do
    Application.put_env(:lockspire, :repo, Lockspire.MixRepoHelpers.RaisingRepo)

    {output, result} = run_task(@task, ["token_format"], [@leaf])

    assert result == :ok
    assert output =~ @unavailable
    refute output =~ "%"
  end
end
