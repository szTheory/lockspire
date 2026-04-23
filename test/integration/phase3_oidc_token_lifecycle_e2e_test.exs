defmodule Lockspire.Integration.Phase3OidcTokenLifecycleE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult
  alias Lockspire.Protocol.AuthorizationRequest
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.Repository

  defmodule Resolver do
    @behaviour Lockspire.Host.AccountResolver

    @impl true
    def resolve_current_account(_conn_or_socket, _context), do: {:ok, %{id: "subject-e2e"}}

    @impl true
    def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

    @impl true
    def build_claims(account, _context) do
      {:ok,
       %Claims{
         subject: account.id,
         id_token: %{"email" => "#{account.id}@example.test"},
         userinfo: %{
           "email" => "#{account.id}@example.test",
           "email_verified" => true,
           "name" => "Subject #{account.id}",
           "nickname" => nil
         }
       }}
    end

    @impl true
    def redirect_for_login(_conn_or_socket, _context) do
      %InteractionResult{login_path: "/sign-in", return_to: "/authorize", params: %{}}
    end
  end

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    Application.put_env(:lockspire, :known_scopes, [
      "openid",
      "email",
      "profile",
      "offline_access"
    ])

    Application.put_env(:lockspire, :account_resolver, Resolver)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, public_client} =
      Repository.register_client(%Client{
        client_id: "phase3-e2e-public",
        client_secret_hash: nil,
        client_type: :public,
        name: "Phase 3 Public App",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email", "profile", "offline_access"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    confidential_secret = "phase3-e2e-secret"

    {:ok, confidential_client} =
      Repository.register_client(%Client{
        client_id: "phase3-e2e-confidential",
        client_secret_hash: client_secret_hash(confidential_secret),
        client_type: :confidential,
        name: "Phase 3 Confidential App",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email", "profile", "offline_access"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{
      public_client: public_client,
      confidential_client: confidential_client,
      confidential_secret: confidential_secret
    }
  end

  test "phase 03 HTTP surface works end to end", %{
    public_client: public_client,
    confidential_client: confidential_client,
    confidential_secret: confidential_secret
  } do
    signing_key = publish_signing_key("phase3-e2e-kid")

    discovery_conn =
      build_conn(:get, "/.well-known/openid-configuration")
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert discovery_conn.status == 200

    discovery = Jason.decode!(discovery_conn.resp_body)

    assert discovery["issuer"] == "https://example.test/lockspire"
    assert discovery["authorization_endpoint"] == "https://example.test/lockspire/authorize"
    assert discovery["token_endpoint"] == "https://example.test/lockspire/token"
    assert discovery["userinfo_endpoint"] == "https://example.test/lockspire/userinfo"
    assert discovery["jwks_uri"] == "https://example.test/lockspire/jwks"
    assert discovery["revocation_endpoint"] == "https://example.test/lockspire/revoke"
    assert discovery["introspection_endpoint"] == "https://example.test/lockspire/introspect"
    refute Map.has_key?(discovery, "registration_endpoint")

    jwks_conn =
      build_conn(:get, "/jwks")
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert jwks_conn.status == 200

    jwks = Jason.decode!(jwks_conn.resp_body)

    assert %{
             "keys" => [
               %{"kid" => "phase3-e2e-kid", "alg" => "RS256", "kty" => "RSA"} = public_jwk
             ]
           } = jwks

    refute Map.has_key?(public_jwk, "d")

    missing_nonce_params =
      authorization_params(public_client.client_id)
      |> Map.put("scope", "openid email profile")

    assert {:redirect_error, error} = AuthorizationRequest.validate(missing_nonce_params)
    assert error.reason_code == :missing_nonce

    assert {:ok, validated_request} =
             public_client.client_id
             |> authorization_params()
             |> Map.put("scope", "openid email profile")
             |> Map.put("nonce", "nonce-phase3")
             |> AuthorizationRequest.validate()

    assert validated_request.nonce == "nonce-phase3"

    create_openid_authorization_code(
      public_client,
      "phase3-openid-code",
      "phase3-openid-verifier",
      "nonce-phase3"
    )

    token_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => public_client.client_id,
        "code" => "phase3-openid-code",
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => "phase3-openid-verifier"
      })
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert token_conn.status == 200

    token_response = Jason.decode!(token_conn.resp_body)

    assert Map.has_key?(token_response, "access_token")
    assert Map.has_key?(token_response, "id_token")
    assert token_response["token_type"] == "Bearer"

    assert {true, %JOSE.JWT{fields: id_token_claims}, _jws} =
             JOSE.JWT.verify_strict(signing_key, ["RS256"], token_response["id_token"])

    assert id_token_claims["iss"] == "https://example.test/lockspire"
    assert id_token_claims["aud"] == public_client.client_id
    assert id_token_claims["sub"] == "subject-e2e"
    assert id_token_claims["nonce"] == "nonce-phase3"

    userinfo_conn =
      build_conn(:get, "/userinfo")
      |> put_req_header("authorization", "Bearer " <> token_response["access_token"])
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert userinfo_conn.status == 200

    userinfo = Jason.decode!(userinfo_conn.resp_body)

    assert userinfo["sub"] == "subject-e2e"
    assert userinfo["email"] == "subject-e2e@example.test"
    assert userinfo["name"] == "Subject subject-e2e"
    refute Map.has_key?(userinfo, "nickname")

    seed_refresh_token(confidential_client, "phase3-refresh-token", "phase3-refresh-family")

    refresh_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => "phase3-refresh-token"
      })
      |> put_req_header(
        "authorization",
        basic_auth(confidential_client.client_id, confidential_secret)
      )
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert refresh_conn.status == 200

    refresh_response = Jason.decode!(refresh_conn.resp_body)

    assert Map.has_key?(refresh_response, "access_token")
    assert Map.has_key?(refresh_response, "refresh_token")
    refute refresh_response["refresh_token"] == "phase3-refresh-token"

    introspect_active_conn =
      build_conn(:post, "/introspect", %{"token" => refresh_response["access_token"]})
      |> put_req_header(
        "authorization",
        basic_auth(confidential_client.client_id, confidential_secret)
      )
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert introspect_active_conn.status == 200

    introspection = Jason.decode!(introspect_active_conn.resp_body)

    assert introspection["active"] == true
    assert introspection["client_id"] == confidential_client.client_id
    assert introspection["token_type"] == "access_token"
    assert introspection["sub"] == "subject-e2e"

    revoke_unknown_conn =
      build_conn(:post, "/revoke", %{"token" => "phase3-unknown-token"})
      |> put_req_header(
        "authorization",
        basic_auth(confidential_client.client_id, confidential_secret)
      )
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert revoke_unknown_conn.status == 200
    assert Jason.decode!(revoke_unknown_conn.resp_body) == %{}

    revoke_conn =
      build_conn(:post, "/revoke", %{"token" => refresh_response["access_token"]})
      |> put_req_header(
        "authorization",
        basic_auth(confidential_client.client_id, confidential_secret)
      )
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert revoke_conn.status == 200
    assert Jason.decode!(revoke_conn.resp_body) == %{}

    introspect_revoked_conn =
      build_conn(:post, "/introspect", %{"token" => refresh_response["access_token"]})
      |> put_req_header(
        "authorization",
        basic_auth(confidential_client.client_id, confidential_secret)
      )
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert introspect_revoked_conn.status == 200
    assert Jason.decode!(introspect_revoked_conn.resp_body) == %{"active" => false}

    refresh_replay_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => "phase3-refresh-token"
      })
      |> put_req_header(
        "authorization",
        basic_auth(confidential_client.client_id, confidential_secret)
      )
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert refresh_replay_conn.status == 400

    replay_error = Jason.decode!(refresh_replay_conn.resp_body)
    assert replay_error["error"] == "invalid_grant"
    assert replay_error["error_description"] =~ "reuse detected"

    introspect_family_after_replay_conn =
      build_conn(:post, "/introspect", %{"token" => refresh_response["refresh_token"]})
      |> put_req_header(
        "authorization",
        basic_auth(confidential_client.client_id, confidential_secret)
      )
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert introspect_family_after_replay_conn.status == 200
    assert Jason.decode!(introspect_family_after_replay_conn.resp_body) == %{"active" => false}
  end

  defp authorization_params(client_id) do
    %{
      "client_id" => client_id,
      "response_type" => "code",
      "redirect_uri" => "https://client.example.com/callback",
      "scope" => "email profile",
      "state" => "state-phase3",
      "prompt" => "login consent",
      "code_challenge" => code_challenge("phase3-openid-verifier"),
      "code_challenge_method" => "S256"
    }
  end

  defp create_openid_authorization_code(client, raw_code, verifier, nonce) do
    now = DateTime.utc_now()
    interaction_id = "interaction-#{raw_code}"

    {:ok, _interaction} =
      Repository.put_interaction(%Interaction{
        interaction_id: interaction_id,
        client_id: client.client_id,
        account_id: "subject-e2e",
        scopes_requested: ["openid", "email", "profile"],
        nonce: nonce,
        redirect_uri: "https://client.example.com/callback",
        return_to: "/authorize",
        state: "state-phase3",
        code_challenge: code_challenge(verifier),
        code_challenge_method: :S256,
        status: :completed,
        completed_at: now,
        expires_at: DateTime.add(now, 300, :second)
      })

    {:ok, _code} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token(raw_code),
        token_type: :authorization_code,
        client_id: client.client_id,
        account_id: "subject-e2e",
        interaction_id: interaction_id,
        redirect_uri: "https://client.example.com/callback",
        scopes: ["openid", "email", "profile"],
        code_challenge: code_challenge(verifier),
        code_challenge_method: :S256,
        issued_at: now,
        expires_at: DateTime.add(now, 300, :second)
      })
  end

  defp seed_refresh_token(client, raw_refresh_token, family_id) do
    now = DateTime.utc_now()

    {:ok, _token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token(raw_refresh_token),
        token_type: :refresh_token,
        family_id: family_id,
        generation: 0,
        client_id: client.client_id,
        account_id: "subject-e2e",
        interaction_id: "interaction-#{family_id}",
        scopes: ["email", "offline_access"],
        audience: ["api.example.com"],
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      })
  end

  defp publish_signing_key(kid) do
    key = JOSE.JWK.generate_key({:rsa, 2048})
    {_fields, jwk} = JOSE.JWK.to_map(key)

    {:ok, _published_key} =
      Repository.publish_key(%SigningKey{
        kid: kid,
        kty: :RSA,
        alg: "RS256",
        use: :sig,
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

    key
  end

  defp code_challenge(verifier) do
    :crypto.hash(:sha256, verifier)
    |> Base.url_encode64(padding: false)
  end

  defp client_secret_hash(secret) do
    "sha256:static-salt:" <> Base.encode64(:crypto.hash(:sha256, "static-salt" <> secret))
  end

  defp basic_auth(client_id, client_secret) do
    "Basic " <> Base.encode64("#{client_id}:#{client_secret}")
  end
end
