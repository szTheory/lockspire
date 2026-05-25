defmodule Mix.Tasks.Lockspire.Doctor.RemoteJwksTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Mix.Task.reenable("lockspire.doctor.remote_jwks")

    {:ok, _client} =
      Repository.register_client(%Client{
        client_id: "doctor-remote-jwks-client",
        client_secret_hash: "sha256:doctor:hash",
        client_type: :confidential,
        name: "Doctor Remote JWKS Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["openid"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :private_key_jwt,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        jwks_uri: "https://client.example.com/.well-known/jwks.json",
        metadata: %{}
      })

    :ok
  end

  test "help text keeps runtime diagnosis separate from install verification" do
    output =
      capture_io(fn ->
        Mix.Tasks.Lockspire.Doctor.RemoteJwks.run(["--help"])
      end)

    assert output =~ "mix lockspire.doctor remote-jwks --client CLIENT_ID"
    assert output =~ "Runtime remote-JWKS incident diagnosis"
    assert output =~ "mix lockspire.verify"
    assert output =~ "install and onboarding diagnostic"
    assert output =~ "does not verify migrations, host seams, or router wiring"
  end

  test "prints shared incident class, safe facts, and remediation for a degraded client" do
    {:ok, client} = Repository.fetch_client_by_id("doctor-remote-jwks-client")

    {:ok, _client} =
      Repository.update_client(client, %{
        metadata: %{
          "remote_jwks_diagnostic" => %{
            "class" => "remote_jwks_key_unavailable",
            "consumer" => "private_key_jwt",
            "stage" => "select_key",
            "subreason" => "post_refresh_key_still_missing",
            "forced_refresh_attempted?" => true,
            "requested_kid_present_in_cached_set?" => false
          }
        }
      })

    output =
      capture_io(fn ->
        Mix.Tasks.Lockspire.Doctor.RemoteJwks.run(["--client", "doctor-remote-jwks-client"])
      end)

    assert output =~ "Client: doctor-remote-jwks-client"
    assert output =~ "Status: incident"
    assert output =~ "Incident class: remote_jwks_key_unavailable"
    assert output =~ "Stage: select_key"
    assert output =~ "Subreason: post_refresh_key_still_missing"
    assert output =~ "Publish the requested key alongside the previous key"
    assert output =~ "Lockspire owns the guarded fetch, cache, refresh, and verify path."
    assert output =~ "mix lockspire.verify"
    refute output =~ "client_secret_hash"
    refute output =~ "jwks_body"
  end

  test "prints bounded reactive support truth when no incident metadata is present" do
    output =
      capture_io(fn ->
        Mix.Tasks.Lockspire.Doctor.RemoteJwks.run(["--client", "doctor-remote-jwks-client"])
      end)

    assert output =~ "Status: supported"
    assert output =~ "bounded reactive rollover support"
    assert output =~ "forces one refresh"
    assert output =~ "fails the current request closed"
    assert output =~ "If rotation is planned, publish the new key before first use"
  end
end
