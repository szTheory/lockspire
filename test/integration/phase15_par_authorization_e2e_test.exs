defmodule Lockspire.Integration.Phase15ParAuthorizationE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.SigningKey
  alias Lockspire.JarTestHelpers
  alias Lockspire.Security.Policy
  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult
  alias Lockspire.Storage.Ecto.Repository

  defmodule GeneratedHostResolver do
    @behaviour Lockspire.Host.AccountResolver

    @impl true
    def resolve_current_account(_conn_or_socket, _context),
      do: {:ok, %{id: "phase15-host-user"}}

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
           "name" => "Phase 15 Host User"
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
        client_id: "phase15-par-public",
        client_secret_hash: nil,
        client_type: :public,
        name: "PAR Browser Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email", "profile", "openid"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{client: client}
  end

  test "required-PAR rejects direct authorize but still completes the canonical PAR auth-code plus PKCE flow",
       %{
         client: client
       } do
    put_server_policy!(:required)
    signing_key = publish_signing_key("phase15-onboarding-kid")
    code_verifier = "phase15-onboarding-verifier"

    direct_authorize_conn =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "redirect_uri" => "https://client.example.com/callback",
        "scope" => "openid email profile",
        "state" => "phase15-state",
        "nonce" => "phase15-nonce",
        "prompt" => "consent",
        "code_challenge" => code_challenge(code_verifier),
        "code_challenge_method" => "S256"
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert direct_authorize_conn.status in [302, 303]

    direct_error_uri =
      direct_authorize_conn
      |> get_resp_header("location")
      |> List.first()
      |> URI.parse()

    direct_error_params = URI.decode_query(direct_error_uri.query || "")

    assert direct_error_uri.host == "client.example.com"
    assert direct_error_params["error"] == "invalid_request"

    assert direct_error_params["error_description"] ==
             "request_uri from the PAR endpoint is required"

    assert direct_error_params["state"] == "phase15-state"

    par_conn =
      build_conn(:post, "/par", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "redirect_uri" => "https://client.example.com/callback",
        "scope" => "openid email profile",
        "state" => "phase15-state",
        "nonce" => "phase15-nonce",
        "prompt" => "consent",
        "code_challenge" => code_challenge(code_verifier),
        "code_challenge_method" => "S256"
      })
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert par_conn.status == 201

    par_response = Jason.decode!(par_conn.resp_body)
    assert request_uri = par_response["request_uri"]
    assert is_integer(par_response["expires_in"])
    assert String.starts_with?(request_uri, "urn:ietf:params:oauth:request_uri:")

    authorize_conn =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "request_uri" => request_uri
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
    assert callback_params["state"] == "phase15-state"
    assert code = callback_params["code"]

    token_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "code" => code,
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => code_verifier
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

    assert id_token_claims["sub"] == "phase15-host-user"
    assert id_token_claims["nonce"] == "phase15-nonce"

    replay_conn =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "request_uri" => request_uri
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert replay_conn.status == 400
    assert replay_conn.resp_body =~ "request_uri is invalid, expired, or already used"
  end

  test "client signs JAR, posts to /par with Basic auth, completes /authorize + /token via the issued request_uri (Phase 22 JAR-via-PAR-via-Lockspire end-to-end)",
       %{
         client: _client
       } do
    put_server_policy!(:required)
    signing_key = publish_signing_key("phase22-jar-onboarding-kid")

    %{pub_jwk_map: pub_jwk_map, private_jwk: private_jwk} = JarTestHelpers.generate_keys()

    suffix = System.unique_integer([:positive])
    client_id = "phase22-jar-confidential-#{suffix}"
    secret = "phase22-jar-confidential-secret-#{suffix}"

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: client_id,
        client_secret_hash: Policy.hash_client_secret(secret),
        client_type: :confidential,
        name: "Phase 22 JAR Confidential Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email", "profile", "openid"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        jwks: pub_jwk_map,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    code_verifier = "phase22-jar-verifier-#{suffix}"
    nonce = "phase22-jar-nonce-#{suffix}"
    state = "phase22-jar-state-#{suffix}"

    claims = %{
      "iss" => client.client_id,
      "aud" => Lockspire.Config.issuer!(),
      "exp" => DateTime.utc_now() |> DateTime.add(300, :second) |> DateTime.to_unix(),
      "redirect_uri" => "https://client.example.com/callback",
      "response_type" => "code",
      "scope" => "openid",
      "prompt" => "consent",
      "code_challenge" => code_challenge(code_verifier),
      "code_challenge_method" => "S256",
      "nonce" => nonce,
      "state" => state
    }

    signed_jar = JarTestHelpers.sign_jar(private_jwk, claims)

    par_conn =
      build_conn(:post, "/par", %{
        "client_id" => client.client_id,
        "request" => signed_jar
      })
      |> put_req_header("accept", "application/json")
      |> put_req_header(
        "authorization",
        "Basic " <>
          Base.encode64("#{URI.encode_www_form(client.client_id)}:#{URI.encode_www_form(secret)}")
      )
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert par_conn.status == 201

    par_response = Jason.decode!(par_conn.resp_body)
    assert request_uri = par_response["request_uri"]
    assert is_integer(par_response["expires_in"])

    assert String.starts_with?(
             request_uri,
             Lockspire.Domain.PushedAuthorizationRequest.request_uri_prefix()
           )

    authorize_conn =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "request_uri" => request_uri
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

    token_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "code" => code,
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => code_verifier
      })
      |> put_req_header("accept", "application/json")
      |> put_req_header(
        "authorization",
        "Basic " <>
          Base.encode64("#{URI.encode_www_form(client.client_id)}:#{URI.encode_www_form(secret)}")
      )
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert token_conn.status == 200

    token_response = Jason.decode!(token_conn.resp_body)

    assert Map.has_key?(token_response, "access_token")
    assert Map.has_key?(token_response, "id_token")
    assert token_response["token_type"] == "Bearer"

    assert {true, %JOSE.JWT{fields: claims_verified}, _jws} =
             JOSE.JWT.verify_strict(signing_key, ["RS256"], token_response["id_token"])

    assert claims_verified["iss"] == Lockspire.Config.issuer!()
    assert claims_verified["sub"] == "phase15-host-user"
    assert claims_verified["aud"] == client.client_id
    assert claims_verified["nonce"] == nonce
  end

  test "optional-PAR clients keep the direct authorization-code plus PKCE browser flow", %{
    client: client
  } do
    put_server_policy!(:required)
    client = update_client_par_policy!(client, :optional)
    signing_key = publish_signing_key("phase15-optional-direct-kid")
    code_verifier = "phase15-optional-direct-verifier"

    authorize_conn =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "redirect_uri" => "https://client.example.com/callback",
        "scope" => "openid email profile",
        "state" => "phase15-optional-state",
        "nonce" => "phase15-optional-nonce",
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
    assert callback_params["state"] == "phase15-optional-state"
    assert code = callback_params["code"]

    token_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "code" => code,
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => code_verifier
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

    assert id_token_claims["sub"] == "phase15-host-user"
    assert id_token_claims["nonce"] == "phase15-optional-nonce"
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

  defp update_client_par_policy!(client, mode) do
    assert {:ok, %Client{} = updated_client} =
             Repository.update_client(client, %{par_policy: mode})

    updated_client
  end
end
