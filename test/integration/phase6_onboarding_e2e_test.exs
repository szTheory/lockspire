defmodule Lockspire.Integration.Phase6OnboardingE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult
  alias Lockspire.Storage.Ecto.Repository

  defmodule GeneratedHostResolver do
    @behaviour Lockspire.Host.AccountResolver

    @impl true
    def resolve_current_account(_conn_or_socket, _context),
      do: {:ok, %{id: "generated-host-user"}}

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
           "name" => "Generated Host User"
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
        client_id: "phase6-onboarding-public",
        client_secret_hash: nil,
        client_type: :public,
        name: "Generated Host App",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email", "profile"],
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

  test "canonical onboarding path completes an auth-code flow and exposes discovery plus jwks", %{
    client: client
  } do
    signing_key = publish_signing_key("phase6-onboarding-kid")
    code_verifier = "phase6-onboarding-verifier"

    discovery_conn =
      build_conn(:get, "/.well-known/openid-configuration")
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert discovery_conn.status == 200

    discovery = Jason.decode!(discovery_conn.resp_body)

    assert discovery["issuer"] == "https://example.test/lockspire"
    assert discovery["authorization_endpoint"] == "https://example.test/lockspire/authorize"
    assert discovery["jwks_uri"] == "https://example.test/lockspire/jwks"

    authorize_conn =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "redirect_uri" => "https://client.example.com/callback",
        "scope" => "openid email profile",
        "state" => "phase6-state",
        "nonce" => "phase6-nonce",
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
    assert callback_params["state"] == "phase6-state"
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

    assert id_token_claims["sub"] == "generated-host-user"
    assert id_token_claims["nonce"] == "phase6-nonce"

    jwks_conn =
      build_conn(:get, "/jwks")
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert jwks_conn.status == 200

    assert %{"keys" => [public_jwk | _]} = Jason.decode!(jwks_conn.resp_body)
    assert public_jwk["kid"] == "phase6-onboarding-kid"
    assert public_jwk["alg"] == "RS256"
    refute Map.has_key?(public_jwk, "d")
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
end
