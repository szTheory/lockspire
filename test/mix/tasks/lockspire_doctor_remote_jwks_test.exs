defmodule Mix.Tasks.Lockspire.Doctor.RemoteJwksTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Lockspire.JarTestHelpers
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.ClientAuth.PrivateKeyJwt
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Mix.Task.reenable("lockspire.doctor")
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

  defmodule RemoteJwksFetcher do
    def get_keys(_uri, _opts), do: {:error, {:jwks_fetch_failed, {:http_status, 503}}}
    def refresh_keys(_uri, _opts), do: {:error, {:jwks_fetch_failed, {:http_status, 503}}}
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

  test "dispatcher task exposes the documented doctor command spelling" do
    output =
      capture_io(fn ->
        Mix.Task.run("lockspire.doctor", ["remote-jwks", "--help"])
      end)

    assert output =~ "mix lockspire.doctor remote-jwks --client CLIENT_ID"
  end

  test "prints shared incident class, safe facts, and remediation for a degraded client" do
    {:ok, client} = Repository.fetch_client_by_id("doctor-remote-jwks-client")
    keys = JarTestHelpers.generate_keys()
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    assertion =
      signed_assertion(keys.private_jwk, client.client_id,
        now: now,
        jti: "doctor-runtime-failure"
      )

    assert {:error, :client_jwks_fetch_failed} =
             PrivateKeyJwt.verify(client, assertion,
               client_store: Repository,
               jwks_fetcher: RemoteJwksFetcher
             )

    output =
      capture_io(fn ->
        Mix.Task.run("lockspire.doctor", ["remote-jwks", "--client", "doctor-remote-jwks-client"])
      end)

    assert output =~ "Client: doctor-remote-jwks-client"
    assert output =~ "Status: incident"
    assert output =~ "Incident class: remote_jwks_fetch_failed"
    assert output =~ "Stage: network"
    assert output =~ "Subreason: http_status"
    assert output =~ "HTTP status: 503"
    assert output =~ "forced_refresh=false"
    assert output =~ "cache_preserved=true"
    assert output =~ "retry with one fresh JWT"
    assert output =~ "Lockspire owns the guarded fetch, cache, refresh, and verify path."
    assert output =~ "mix lockspire.verify"
    refute output =~ "client_secret_hash"
    refute output =~ "jwks_body"
  end

  test "prints bounded reactive support truth when no incident metadata is present" do
    output =
      capture_io(fn ->
        Mix.Task.run("lockspire.doctor", ["remote-jwks", "--client", "doctor-remote-jwks-client"])
      end)

    assert output =~ "Status: supported"
    assert output =~ "bounded reactive rollover support"
    assert output =~ "forces one refresh"
    assert output =~ "fails the current request closed"
    assert output =~ "Next step:"
    assert output =~ "If rotation is planned, publish the new key before first use"
  end

  defp signed_assertion(private_jwk, client_id, opts) do
    now = Keyword.fetch!(opts, :now)

    claims = %{
      "iss" => client_id,
      "sub" => client_id,
      "aud" => Lockspire.Config.issuer!(),
      "iat" => DateTime.to_unix(now),
      "exp" => DateTime.to_unix(DateTime.add(now, 300, :second)),
      "jti" => Keyword.fetch!(opts, :jti)
    }

    {_, jwt} =
      private_jwk
      |> JOSE.JWT.sign(%{"alg" => "RS256", "typ" => "JWT"}, claims)
      |> JOSE.JWS.compact()

    jwt
  end
end
