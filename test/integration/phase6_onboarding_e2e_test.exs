defmodule Lockspire.Integration.Phase6OnboardingE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint GeneratedHostAppWeb.Endpoint

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, GeneratedHostAppWeb.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false
    )

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "email", "profile"])

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
      build_conn()
      |> put_req_header("accept", "application/json")
      |> get("/lockspire/.well-known/openid-configuration")

    assert discovery_conn.status == 200

    discovery = Jason.decode!(discovery_conn.resp_body)

    assert discovery["issuer"] == "https://example.test/lockspire"
    assert discovery["authorization_endpoint"] == "https://example.test/lockspire/authorize"
    assert discovery["jwks_uri"] == "https://example.test/lockspire/jwks"

    authorize_conn =
      build_conn()
      |> get("/lockspire/authorize", %{
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

    assert authorize_conn.status in [302, 303]

    login_uri =
      authorize_conn
      |> redirected_to()
      |> URI.parse()

    assert login_uri.path == "/login"

    login_params = URI.decode_query(login_uri.query || "")
    assert %{"interaction_id" => interaction_id, "return_to" => return_to} = login_params
    assert return_to == "/lockspire/consent/#{interaction_id}"

    login_page_conn =
      build_conn()
      |> get("/login", login_params)

    assert login_page_conn.status == 200
    assert login_page_conn.resp_body =~ "Generated host login"

    login_complete_conn =
      submit_from(login_page_conn, "/login", %{
        "return_to" => return_to,
        "interaction_id" => interaction_id,
        "login" => "generated-host-user",
        "auth_time_seconds_ago" => "30"
      })

    assert login_complete_conn.status in [302, 303]

    resume_uri =
      login_complete_conn
      |> redirected_to()
      |> URI.parse()

    assert resume_uri.path == "/lockspire/interactions/#{interaction_id}"

    resumed_consent_conn =
      signed_in_conn("generated-host-user", 30)
      |> get(URI.to_string(resume_uri))

    assert resumed_consent_conn.status in [302, 303]
    assert redirected_to(resumed_consent_conn) == "/lockspire/consent/#{interaction_id}"

    consent_complete_conn =
      signed_in_conn("generated-host-user", 30)
      |> post("/lockspire/interactions/#{interaction_id}/complete", %{
        "decision" => "approve",
        "remember" => "true"
      })

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
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/lockspire/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "code" => code,
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => code_verifier
      })

    assert token_conn.status == 200

    token_response = Jason.decode!(token_conn.resp_body)

    assert Map.has_key?(token_response, "access_token")
    assert Map.has_key?(token_response, "id_token")
    assert token_response["token_type"] == "Bearer"

    assert {true, %JOSE.JWT{fields: id_token_claims}, _jws} =
             JOSE.JWT.verify_strict(signing_key, ["RS256"], token_response["id_token"])

    assert id_token_claims["sub"] == "generated-host-user"
    assert id_token_claims["nonce"] == "phase6-nonce"
    assert id_token_claims["email"] == "generated-host-user@example.test"

    jwks_conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> get("/lockspire/jwks")

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

  defp submit_from(conn, path, params) do
    csrf_token = extract_csrf_token(conn.resp_body)

    conn
    |> recycle()
    |> post(path, Map.put(params, "_csrf_token", csrf_token))
  end

  defp extract_csrf_token(body) do
    ~r/name="_csrf_token" value="([^"]+)"/
    |> Regex.run(body, capture: :all_but_first)
    |> case do
      [token] -> token
      _ -> raise "expected CSRF token in response body"
    end
  end

  defp signed_in_conn(login, auth_time_seconds_ago) do
    auth_time_unix =
      DateTime.utc_now()
      |> DateTime.add(-auth_time_seconds_ago, :second)
      |> DateTime.to_unix()

    build_conn()
    |> init_test_session(%{
      "current_account_id" => login,
      "current_account_email" => "#{login}@example.test",
      "current_account_name" => "Generated Host User",
      "current_auth_time_unix" => auth_time_unix
    })
  end
end
