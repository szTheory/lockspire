defmodule Lockspire.Integration.Phase81GeneratedHostRouteProtectionE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint GeneratedHostAppWeb.Endpoint
  @issuer "https://example.test/lockspire"
  @protected_route "/api/billing/summary"
  @protected_target_uri "http://api.example.test/api/billing/summary"

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.SigningKey
  alias Lockspire.JarTestHelpers
  alias Lockspire.KeyCache
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, GeneratedHostAppWeb.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false
    )

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, @issuer)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "profile", "email", "read:billing"])

    Application.put_env(
      :lockspire,
      :account_resolver,
      GeneratedHostApp.Lockspire.TestAccountResolver
    )

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(GeneratedHostAppWeb.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, {:shared, self()})

    kid = "phase81-generated-host-kid-#{System.unique_integer()}"
    signing_key = publish_signing_key(kid)

    %{signing_key: signing_key, signing_kid: kid}
  end

  test "protected route returns 200 with the assigns contract for a valid bearer token", %{
    signing_key: signing_key,
    signing_kid: signing_kid
  } do
    token =
      issue_access_token(signing_key, signing_kid, %{
        "sub" => "generated-host-user",
        "scope" => "read:billing write:reports",
        "aud" => "billing-api"
      })

    conn =
      protected_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> get(@protected_route)

    assert conn.status == 200

    assert %{
             "access_token" => %{
               "client_id" => "generated-host-api-client",
               "subject" => "generated-host-user",
               "authorization_scheme" => "Bearer",
               "binding_type" => nil,
               "binding_requirements" => nil,
               "audience" => "billing-api",
               "scope" => "read:billing write:reports"
             }
           } = Jason.decode!(conn.resp_body)
  end

  test "protected route returns 401 invalid_token when the token is missing" do
    conn =
      protected_conn()
      |> get(@protected_route)

    assert conn.status == 401
    assert ["Bearer realm=\"Lockspire\""] = get_resp_header(conn, "www-authenticate")
    assert %{"error" => "invalid_token"} = Jason.decode!(conn.resp_body)
  end

  test "protected route returns 401 invalid_token for audience mismatch", %{
    signing_key: signing_key,
    signing_kid: signing_kid
  } do
    token =
      issue_access_token(signing_key, signing_kid, %{
        "sub" => "generated-host-user",
        "scope" => "read:billing",
        "aud" => "admin-api"
      })

    conn =
      protected_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> get(@protected_route)

    assert conn.status == 401

    assert [
             "Bearer realm=\"Lockspire\", error=\"invalid_token\", error_description=\"The access token audience is invalid for this route\""
           ] = get_resp_header(conn, "www-authenticate")

    assert %{
             "error" => "invalid_token",
             "error_description" => "The access token audience is invalid for this route"
           } = Jason.decode!(conn.resp_body)
  end

  test "protected route returns 403 insufficient_scope for a valid but under-scoped token", %{
    signing_key: signing_key,
    signing_kid: signing_kid
  } do
    token =
      issue_access_token(signing_key, signing_kid, %{
        "sub" => "generated-host-user",
        "scope" => "write:reports",
        "aud" => "billing-api"
      })

    conn =
      protected_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> get(@protected_route)

    assert conn.status == 403

    assert [
             "Bearer realm=\"Lockspire\", error=\"insufficient_scope\", error_description=\"The access token is missing a required scope\", scope=\"read:billing\""
           ] = get_resp_header(conn, "www-authenticate")

    assert %{
             "error" => "insufficient_scope",
             "error_description" => "The access token is missing a required scope"
           } = Jason.decode!(conn.resp_body)
  end

  test "protected route keeps sender-constraint enforcement active for DPoP-bound tokens", %{
    signing_key: signing_key,
    signing_kid: signing_kid
  } do
    dpop_keys = JarTestHelpers.generate_ec_keys()
    {:ok, jkt} = DPoP.thumbprint(dpop_keys.pub_jwk_map)

    token =
      issue_access_token(signing_key, signing_kid, %{
        "sub" => "generated-host-user",
        "scope" => "read:billing",
        "aud" => "billing-api",
        "cnf" => %{"jkt" => jkt}
      })

    failure_conn =
      protected_conn()
      |> put_req_header("authorization", "DPoP #{token}")
      |> get(@protected_route)

    assert failure_conn.status == 401
    [failure_challenge] = get_resp_header(failure_conn, "www-authenticate")
    assert failure_challenge =~ "DPoP realm=\"Lockspire\""
    assert failure_challenge =~ "error=\"invalid_token\""

    challenge_conn =
      protected_conn()
      |> put_req_header("authorization", "DPoP #{token}")
      |> put_req_header("dpop", generate_dpop_proof(dpop_keys.private_jwk, token, nil))
      |> get(@protected_route)

    assert challenge_conn.status == 401
    [nonce_challenge] = get_resp_header(challenge_conn, "www-authenticate")
    assert nonce_challenge =~ "error=\"use_dpop_nonce\""
    assert [retry_nonce] = get_resp_header(challenge_conn, "dpop-nonce")

    assert ["DPoP-Nonce, WWW-Authenticate"] =
             get_resp_header(challenge_conn, "access-control-expose-headers")

    proof = generate_dpop_proof(dpop_keys.private_jwk, token, retry_nonce)

    assert {:ok, _validated_proof} =
             DPoP.validate_proof(proof,
               method: "GET",
               target_uri: @protected_target_uri,
               now: DateTime.utc_now(),
               max_age: 300,
               clock_skew: 30
             )

    success_conn =
      protected_conn()
      |> put_req_header("authorization", "DPoP #{token}")
      |> put_req_header("dpop", proof)
      |> get(@protected_route)

    assert success_conn.status == 200

    assert %{
             "access_token" => %{
               "authorization_scheme" => "DPoP",
               "binding_type" => "dpop",
               "binding_requirements" => %{"dpop_jkt" => ^jkt}
             }
           } = Jason.decode!(success_conn.resp_body)
  end

  test "protected route keeps the insufficient_scope split for DPoP-bound under-scoped tokens",
       %{
         signing_key: signing_key,
         signing_kid: signing_kid
       } do
    dpop_keys = JarTestHelpers.generate_ec_keys()
    {:ok, jkt} = DPoP.thumbprint(dpop_keys.pub_jwk_map)

    token =
      issue_access_token(signing_key, signing_kid, %{
        "sub" => "generated-host-user",
        "scope" => "write:reports",
        "aud" => "billing-api",
        "cnf" => %{"jkt" => jkt}
      })

    scoped_failure_conn =
      protected_conn()
      |> put_req_header("authorization", "DPoP #{token}")
      |> get(@protected_route)

    assert scoped_failure_conn.status == 403

    assert [
             "DPoP realm=\"Lockspire\", error=\"insufficient_scope\", error_description=\"The access token is missing a required scope\", algs=\"RS256 ES256 PS256 EdDSA\""
           ] = get_resp_header(scoped_failure_conn, "www-authenticate")

    assert %{
             "error" => "insufficient_scope",
             "error_description" => "The access token is missing a required scope"
           } = Jason.decode!(scoped_failure_conn.resp_body)
  end

  defp protected_conn do
    build_conn()
    |> Map.put(:host, "api.example.test")
    |> Map.put(:port, 80)
    |> put_req_header("accept", "application/json")
  end

  defp publish_signing_key(kid) do
    key = JOSE.JWK.generate_key({:rsa, 2048})
    {_fields, jwk} = JOSE.JWK.to_map(key)

    {:ok, _published_key} =
      Repository.publish_key(%SigningKey{
        kid: kid,
        kty: :RSA,
        alg: "RS256",
        use: "sig",
        public_jwk:
          jwk
          |> Map.take(["kty", "kid", "alg", "use", "n", "e"])
          |> Map.put("kid", kid)
          |> Map.put("alg", "RS256")
          |> Map.put("use", "sig"),
        private_jwk_encrypted: :erlang.term_to_binary(Map.put(jwk, "kid", kid)),
        status: :active,
        published_at: DateTime.utc_now(),
        activated_at: DateTime.utc_now(),
        metadata: %{}
      })

    send(KeyCache, :refresh)
    :sys.get_state(KeyCache)
    key
  end

  defp issue_access_token(signing_key, signing_kid, claims) do
    now = DateTime.utc_now() |> DateTime.to_unix()

    default_claims = %{
      "iss" => @issuer,
      "sub" => "generated-host-user",
      "client_id" => "generated-host-api-client",
      "iat" => now,
      "exp" => now + 3600,
      "nbf" => now - 60
    }

    {_, token} =
      JOSE.JWT.sign(
        signing_key,
        %{"alg" => "RS256", "kid" => signing_kid, "typ" => "at+jwt"},
        Map.merge(default_claims, claims)
      )
      |> JOSE.JWS.compact()

    token
  end

  defp generate_dpop_proof(dpop_key, access_token, nonce) do
    claims =
      %{
        "htm" => "GET",
        "htu" => @protected_target_uri,
        "iat" => DateTime.utc_now() |> DateTime.to_unix(),
        "jti" => Ecto.UUID.generate(),
        "ath" => DPoP.access_token_ath(access_token),
        "nonce" => nonce
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    JarTestHelpers.sign_dpop_proof(dpop_key, claims)
  end
end
