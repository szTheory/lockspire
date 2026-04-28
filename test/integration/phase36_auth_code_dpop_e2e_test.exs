defmodule Lockspire.Integration.Phase36AuthCodeDpopE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.SigningKey
  alias Lockspire.JarTestHelpers
  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult
  alias Lockspire.Storage.Ecto.Repository

  defmodule GeneratedHostResolver do
    @behaviour Lockspire.Host.AccountResolver

    @impl true
    def resolve_current_account(_conn_or_socket, _context),
      do: {:ok, %{id: "phase36-host-user"}}

    @impl true
    def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

    @impl true
    def build_claims(account, _context) do
      {:ok,
       %Claims{
         subject: to_string(account.id),
         id_token: %{"email" => "#{account.id}@example.test"},
         userinfo: %{
           "email" => "#{account.id}@example.test",
           "email_verified" => true,
           "name" => "Phase 36 Host User"
         }
       }}
    end

    @impl true
    def redirect_for_login(_conn_or_socket, context) do
      %InteractionResult{
        login_path: "/login",
        return_to: Map.get(context, :return_to) || Map.get(context, "return_to"),
        params: %{
          "interaction_id" =>
            Map.get(context, :interaction_id) || Map.get(context, "interaction_id")
        }
      }
    end
  end

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "email", "profile"])
    Application.put_env(:lockspire, :account_resolver, GeneratedHostResolver)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "phase36-dpop-public",
        client_secret_hash: nil,
        client_type: :public,
        name: "DPoP Browser Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email", "profile", "openid"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        subject_type: :public,
        dpop_policy: :dpop,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{client: client}
  end

  test "DPoP auth-code flow completes with real interactions, issues DPoP token, and works on userinfo",
       %{
         client: client
       } do
    put_server_policy!(:optional)
    signing_key = publish_signing_key("phase36-dpop-kid")
    code_verifier = "phase36-dpop-verifier"
    nonce = "phase36-dpop-nonce"
    state = "phase36-dpop-state"

    authorize_conn =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "redirect_uri" => "https://client.example.com/callback",
        "scope" => "openid email profile",
        "state" => state,
        "nonce" => nonce,
        "prompt" => "consent",
        "code_challenge" => code_challenge(code_verifier),
        "code_challenge_method" => "S256"
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert authorize_conn.status in [302, 303]

    consent_path =
      authorize_conn
      |> get_resp_header("location")
      |> List.first()

    assert consent_path =~ "/lockspire/consent/"

    interaction_id =
      consent_path
      |> URI.parse()
      |> Map.fetch!(:path)
      |> String.split("/")
      |> List.last()

    consent_complete_conn =
      build_conn(:post, "/interactions/#{interaction_id}/complete", %{
        "decision" => "approve",
        "remember" => "true"
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert consent_complete_conn.status in [302, 303]

    callback_uri =
      consent_complete_conn
      |> get_resp_header("location")
      |> List.first()
      |> URI.parse()

    callback_params = URI.decode_query(callback_uri.query || "")

    assert callback_uri.host == "client.example.com"
    assert callback_params["state"] == state
    assert code = callback_params["code"]

    keys = JarTestHelpers.generate_ec_keys()

    token_proof =
      JarTestHelpers.sign_dpop_proof(keys.private_jwk, %{
        "htm" => "POST",
        "htu" => "https://example.test/lockspire/token",
        "iat" => DateTime.utc_now() |> DateTime.to_unix(),
        "jti" => Ecto.UUID.generate()
      })

    token_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "code" => code,
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => code_verifier
      })
      |> put_req_header("accept", "application/json")
      |> put_req_header("dpop", token_proof)
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert token_conn.status == 200

    token_response = Jason.decode!(token_conn.resp_body)

    assert Map.has_key?(token_response, "access_token")
    assert Map.has_key?(token_response, "id_token")
    assert token_response["token_type"] == "DPoP"

    assert {true, %JOSE.JWT{fields: id_token_claims}, _jws} =
             JOSE.JWT.verify_strict(signing_key, ["RS256"], token_response["id_token"])

    assert id_token_claims["sub"] == "phase36-host-user"
    assert id_token_claims["nonce"] == nonce

    # userinfo success with DPoP
    ath =
      :sha256
      |> :crypto.hash(token_response["access_token"])
      |> Base.url_encode64(padding: false)

    userinfo_proof =
      JarTestHelpers.sign_dpop_proof(keys.private_jwk, %{
        "htm" => "GET",
        "htu" => "https://example.test/lockspire/userinfo",
        "iat" => DateTime.utc_now() |> DateTime.to_unix(),
        "jti" => Ecto.UUID.generate(),
        "ath" => ath
      })

    userinfo_conn =
      build_conn(:get, "/userinfo")
      |> put_req_header("authorization", "DPoP " <> token_response["access_token"])
      |> put_req_header("dpop", userinfo_proof)
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert userinfo_conn.status == 200

    userinfo = Jason.decode!(userinfo_conn.resp_body)
    assert userinfo["sub"] == "phase36-host-user"
    assert userinfo["email"] == "phase36-host-user@example.test"
  end

  test "auth-code negative paths for missing/invalid DPoP proof", %{
    client: client
  } do
    put_server_policy!(:optional)
    publish_signing_key("phase36-dpop-kid-neg")
    code_verifier = "phase36-dpop-verifier-neg"
    nonce = "phase36-dpop-nonce-neg"
    state = "phase36-dpop-state-neg"

    authorize_conn =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "redirect_uri" => "https://client.example.com/callback",
        "scope" => "openid email profile",
        "state" => state,
        "nonce" => nonce,
        "prompt" => "consent",
        "code_challenge" => code_challenge(code_verifier),
        "code_challenge_method" => "S256"
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert authorize_conn.status in [302, 303]

    consent_path =
      authorize_conn
      |> get_resp_header("location")
      |> List.first()

    interaction_id =
      consent_path
      |> URI.parse()
      |> Map.fetch!(:path)
      |> String.split("/")
      |> List.last()

    consent_complete_conn =
      build_conn(:post, "/interactions/#{interaction_id}/complete", %{
        "decision" => "approve",
        "remember" => "true"
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    callback_uri =
      consent_complete_conn
      |> get_resp_header("location")
      |> List.first()
      |> URI.parse()

    callback_params = URI.decode_query(callback_uri.query || "")
    assert code = callback_params["code"]

    # Missing DPoP proof on /token
    missing_proof_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "code" => code,
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => code_verifier
      })
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert missing_proof_conn.status == 400
    missing_response = Jason.decode!(missing_proof_conn.resp_body)
    assert missing_response["error"] == "invalid_dpop_proof"

    # Do authorize flow again to get a fresh code
    authorize_conn2 =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "redirect_uri" => "https://client.example.com/callback",
        "scope" => "openid email profile",
        "state" => "phase36-dpop-state-neg2",
        "nonce" => "phase36-dpop-nonce-neg2",
        "prompt" => "consent",
        "code_challenge" => code_challenge(code_verifier),
        "code_challenge_method" => "S256"
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    consent_path2 =
      authorize_conn2
      |> get_resp_header("location")
      |> List.first()

    interaction_id2 =
      consent_path2
      |> URI.parse()
      |> Map.fetch!(:path)
      |> String.split("/")
      |> List.last()

    consent_complete_conn2 =
      build_conn(:post, "/interactions/#{interaction_id2}/complete", %{
        "decision" => "approve",
        "remember" => "true"
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    callback_uri2 =
      consent_complete_conn2
      |> get_resp_header("location")
      |> List.first()
      |> URI.parse()

    callback_params2 = URI.decode_query(callback_uri2.query || "")
    assert code2 = callback_params2["code"]

    keys = JarTestHelpers.generate_ec_keys()

    token_proof =
      JarTestHelpers.sign_dpop_proof(keys.private_jwk, %{
        "htm" => "POST",
        "htu" => "https://example.test/lockspire/token",
        "iat" => DateTime.utc_now() |> DateTime.to_unix(),
        "jti" => Ecto.UUID.generate()
      })

    # Success to get token
    token_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "code" => code2,
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => code_verifier
      })
      |> put_req_header("accept", "application/json")
      |> put_req_header("dpop", token_proof)
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert token_conn.status == 200
    token_response = Jason.decode!(token_conn.resp_body)

    # Negative path: wrong auth scheme (Bearer) on userinfo
    wrong_scheme_conn =
      build_conn(:get, "/userinfo")
      |> put_req_header("authorization", "Bearer " <> token_response["access_token"])
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert wrong_scheme_conn.status == 401

    www_auth = get_resp_header(wrong_scheme_conn, "www-authenticate") |> List.first()
    assert www_auth =~ "DPoP"
    assert www_auth =~ "error=\"invalid_token\""

    # Negative path: DPoP auth scheme but no proof
    no_proof_userinfo_conn =
      build_conn(:get, "/userinfo")
      |> put_req_header("authorization", "DPoP " <> token_response["access_token"])
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert no_proof_userinfo_conn.status == 401

    www_auth2 = get_resp_header(no_proof_userinfo_conn, "www-authenticate") |> List.first()
    assert www_auth2 =~ "DPoP"
    assert www_auth2 =~ "error=\"invalid_token\""
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

    key
  end

  defp code_challenge(verifier) do
    :sha256
    |> :crypto.hash(verifier)
    |> Base.url_encode64(padding: false)
  end

  defp put_server_policy!(mode) do
    assert {:ok, %ServerPolicy{} = _policy} =
             Repository.put_server_policy(%ServerPolicy{par_policy: mode})
  end
end
