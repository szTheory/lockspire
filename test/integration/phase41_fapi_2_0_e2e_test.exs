defmodule Lockspire.Integration.Phase41Fapi20E2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Security.Policy
  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult
  alias Lockspire.Storage.Ecto.Repository

  defmodule GeneratedHostResolver do
    @behaviour Lockspire.Host.AccountResolver

    @impl true
    def resolve_current_account(_conn_or_socket, _context),
      do: {:ok, %{id: "phase41-fapi-user"}}

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
           "name" => "Phase 41 FAPI User"
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

    secret = "phase41-client-secret"

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "phase41-fapi-client",
        client_secret_hash: Policy.hash_client_secret(secret),
        client_type: :confidential,
        name: "FAPI Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email", "profile", "openid"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{client: client, secret: secret}
  end

  test "FAPI 2.0 profile mandates PAR, S256 PKCE, and DPoP sender-constraining", %{
    client: client,
    secret: secret
  } do
    put_security_profile!(:fapi_2_0_security)
    publish_signing_key("phase41-fapi-kid")
    code_verifier = "phase41-fapi-verifier"

    # 1. Direct /authorize MUST be rejected
    authorize_conn =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "redirect_uri" => "https://client.example.com/callback",
        "scope" => "openid",
        "code_challenge" => code_challenge(code_verifier),
        "code_challenge_method" => "S256"
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert authorize_conn.status in [302, 303]
    location = get_resp_header(authorize_conn, "location") |> List.first()
    assert location =~ "error=invalid_request"
    assert location =~ "error_description=request_uri+from+the+PAR+endpoint+is+required"

    # 2. PAR with plain PKCE MUST be rejected
    par_plain_conn =
      build_conn(:post, "/par", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "redirect_uri" => "https://client.example.com/callback",
        "scope" => "openid",
        "nonce" => "phase41-nonce",
        "code_challenge" => code_verifier,
        "code_challenge_method" => "plain"
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert par_plain_conn.status == 400
    assert Jason.decode!(par_plain_conn.resp_body)["error_description"] =~ "PKCE S256 is required"

    # 3. Successful PAR
    par_conn =
      build_conn(:post, "/par", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "redirect_uri" => "https://client.example.com/callback",
        "scope" => "openid",
        "nonce" => "phase41-nonce",
        "code_challenge" => code_challenge(code_verifier),
        "code_challenge_method" => "S256"
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert par_conn.status == 201
    request_uri = Jason.decode!(par_conn.resp_body)["request_uri"]

    # 4. Complete Authorization
    authorize_conn =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "request_uri" => request_uri
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert authorize_conn.status in [302, 303]
    location = get_resp_header(authorize_conn, "location") |> List.first()
    assert location =~ "/consent/"

    interaction_id =
      List.last(String.split(location, "/"))

    authorize_complete_conn =
      build_conn(:post, "/interactions/#{interaction_id}/complete", %{"decision" => "approve"})
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert authorize_complete_conn.status in [302, 303], authorize_complete_conn.resp_body
    callback_uri = URI.parse(List.first(get_resp_header(authorize_complete_conn, "location")))
    code = URI.decode_query(callback_uri.query)["code"]

    # 5. Token request WITHOUT DPoP MUST be rejected
    token_bearer_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "code" => code,
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => code_verifier
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert token_bearer_conn.status == 400
    assert Jason.decode!(token_bearer_conn.resp_body)["error"] == "invalid_dpop_proof"

    # 6. Successful Token request WITH DPoP
    proof_key = JOSE.JWK.generate_key({:ec, "P-256"})
    proof = generate_dpop_proof(proof_key, "POST", "https://example.test/lockspire/token")

    token_dpop_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "code" => code,
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => code_verifier
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("dpop", proof)
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert token_dpop_conn.status == 200
    token_resp = Jason.decode!(token_dpop_conn.resp_body)
    assert token_resp["token_type"] == "DPoP"
    access_token = token_resp["access_token"]

    # 7. UserInfo request WITHOUT DPoP MUST be rejected
    userinfo_bearer_conn =
      build_conn(:get, "/userinfo")
      |> put_req_header("authorization", "Bearer #{access_token}")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert userinfo_bearer_conn.status == 401
    assert userinfo_bearer_conn.resp_body =~ "invalid_token"

    # 8. Successful UserInfo request WITH DPoP
    userinfo_proof =
      generate_dpop_proof(
        proof_key,
        "GET",
        "https://example.test/lockspire/userinfo",
        access_token
      )

    userinfo_dpop_conn =
      build_conn(:get, "/userinfo")
      |> put_req_header("authorization", "DPoP #{access_token}")
      |> put_req_header("dpop", userinfo_proof)
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert userinfo_dpop_conn.status == 200
    assert Jason.decode!(userinfo_dpop_conn.resp_body)["sub"] == "phase41-fapi-user"
  end

  test "per-client override opts into FAPI 2.0 even when global is none", %{client: client} do
    put_security_profile!(:none)

    assert {:ok, _client} =
             Repository.update_client(client, %{security_profile: :fapi_2_0_security})

    authorize_conn =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "redirect_uri" => "https://client.example.com/callback",
        "scope" => "openid",
        "code_challenge" => code_challenge("phase41-opt-in-verifier"),
        "code_challenge_method" => "S256"
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert authorize_conn.status in [302, 303]
    location = get_resp_header(authorize_conn, "location") |> List.first()
    assert location =~ "error=invalid_request"
    assert location =~ "error_description=request_uri+from+the+PAR+endpoint+is+required"
  end

  test "global message-signing strict mode enforces JWT PAR and JWT introspection negotiation", %{
    client: client,
    secret: secret
  } do
    put_security_profile!(:fapi_2_0_message_signing)
    publish_signing_key("phase41-message-signing-global-kid")

    assert {:ok, _client} =
             Repository.update_client(client, %{authorization_signed_response_alg: "ES256"})

    par_rejected_conn =
      build_conn(:post, "/par", base_par_params(client.client_id))
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert par_rejected_conn.status == 400

    assert Jason.decode!(par_rejected_conn.resp_body)["error_description"] =~
             "explicit JWT response mode"

    request_uri = strict_par_request_uri!(client, secret)

    authorize_conn =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "request_uri" => request_uri
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert authorize_conn.status in [302, 303]
    response = complete_strict_authorize_and_extract_jarm(authorize_conn)
    assert decode_jwt_payload(response)["code"]

    raw_access_token = "phase41-message-signing-global-access"
    store_access_token!(client, raw_access_token, "phase41-message-signing-global")

    strict_json_downgrade_conn =
      introspect_conn(client, secret, raw_access_token)
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert strict_json_downgrade_conn.status == 400

    assert Jason.decode!(strict_json_downgrade_conn.resp_body) == %{
             "error" => "invalid_request",
             "error_description" => "Accept must include application/token-introspection+jwt"
           }

    strict_jwt_conn =
      introspect_conn(client, secret, raw_access_token, [
        {"accept", "application/token-introspection+jwt"}
      ])
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert strict_jwt_conn.status == 200

    assert get_resp_header(strict_jwt_conn, "content-type") == [
             "application/token-introspection+jwt"
           ]
  end

  test "per-client message-signing strict mode enforces the same authorize and introspection requirements",
       %{client: client, secret: secret} do
    put_security_profile!(:none)
    publish_signing_key("phase41-message-signing-client-kid")

    assert {:ok, _client} =
             Repository.update_client(client, %{
               security_profile: :fapi_2_0_message_signing,
               authorization_signed_response_alg: "ES256"
             })

    par_rejected_conn =
      build_conn(:post, "/par", base_par_params(client.client_id))
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert par_rejected_conn.status == 400

    assert Jason.decode!(par_rejected_conn.resp_body)["error_description"] =~
             "explicit JWT response mode"

    request_uri = strict_par_request_uri!(client, secret)

    authorize_conn =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "request_uri" => request_uri
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert authorize_conn.status in [302, 303]
    response = complete_strict_authorize_and_extract_jarm(authorize_conn)
    assert decode_jwt_payload(response)["code"]

    raw_access_token = "phase41-message-signing-client-access"
    store_access_token!(client, raw_access_token, "phase41-message-signing-client")

    strict_json_downgrade_conn =
      introspect_conn(client, secret, raw_access_token)
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert strict_json_downgrade_conn.status == 400

    strict_jwt_conn =
      introspect_conn(client, secret, raw_access_token, [
        {"accept", "application/token-introspection+jwt"}
      ])
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert strict_jwt_conn.status == 200

    assert get_resp_header(strict_jwt_conn, "content-type") == [
             "application/token-introspection+jwt"
           ]
  end

  test "client none override under global message-signing strict mode preserves compatibility behavior",
       %{client: client, secret: secret} do
    put_security_profile!(:fapi_2_0_message_signing)
    publish_rs256_signing_key("phase41-message-signing-override-kid")

    assert {:ok, _client} = Repository.update_client(client, %{security_profile: :none})

    par_conn =
      build_conn(:post, "/par", base_par_params(client.client_id))
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert par_conn.status == 201
    request_uri = Jason.decode!(par_conn.resp_body)["request_uri"]

    authorize_conn =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "request_uri" => request_uri
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert authorize_conn.status in [302, 303]

    raw_access_token = "phase41-message-signing-override-access"
    store_access_token!(client, raw_access_token, "phase41-message-signing-override")

    json_introspection_conn =
      introspect_conn(client, secret, raw_access_token)
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert json_introspection_conn.status == 200

    assert get_resp_header(json_introspection_conn, "content-type") == [
             "application/json; charset=utf-8"
           ]

    assert Jason.decode!(json_introspection_conn.resp_body)["active"] == true
  end

  test "per-client override opts out of FAPI 2.0 under a global FAPI profile", %{client: client} do
    put_security_profile!(:fapi_2_0_security)
    assert {:ok, _client} = Repository.update_client(client, %{security_profile: :none})

    authorize_conn =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "redirect_uri" => "https://client.example.com/callback",
        "scope" => "openid",
        "code_challenge" => code_challenge("phase41-opt-out-verifier"),
        "code_challenge_method" => "S256"
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    evidence =
      case get_resp_header(authorize_conn, "location") do
        [location | _] -> location
        _other -> authorize_conn.resp_body || ""
      end

    assert authorize_conn.status in [302, 303, 400]
    refute evidence =~ "request_uri+from+the+PAR+endpoint+is+required"
  end

  test "/userinfo defense-in-depth rejects bearer access for a per-client FAPI opt-in under global none",
       %{client: client} do
    put_security_profile!(:none)

    assert {:ok, _client} =
             Repository.update_client(client, %{security_profile: :fapi_2_0_security})

    raw_access_token = "phase41-userinfo-bearer-optin-token"
    now = DateTime.utc_now()

    assert {:ok, _token} =
             Repository.store_token(%Token{
               token_hash: TokenFormatter.hash_token(raw_access_token),
               token_type: :access_token,
               client_id: client.client_id,
               account_id: "phase41-fapi-user",
               interaction_id: "phase41-userinfo-optin-negative",
               scopes: ["openid", "email", "profile"],
               issued_at: now,
               expires_at: DateTime.add(now, 3600, :second)
             })

    conn =
      build_conn(:get, "/userinfo")
      |> put_req_header("authorization", "Bearer #{raw_access_token}")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 401
    [challenge] = get_resp_header(conn, "www-authenticate")
    assert challenge =~ "DPoP realm=\"Lockspire Userinfo\""
    assert challenge =~ "error=\"invalid_token\""

    assert Jason.decode!(conn.resp_body) == %{
             "error" => "invalid_token",
             "error_description" => "DPoP-bound access token requires Authorization: DPoP"
           }
  end

  test "/userinfo defense-in-depth accepts DPoP-bound access for a per-client FAPI opt-in under global none",
       %{client: client} do
    put_security_profile!(:none)

    assert {:ok, _client} =
             Repository.update_client(client, %{security_profile: :fapi_2_0_security})

    raw_access_token = "phase41-userinfo-dpop-optin-token"
    now = DateTime.utc_now()
    proof_key = JOSE.JWK.generate_key({:ec, "P-256"})

    proof =
      generate_dpop_proof(
        proof_key,
        "GET",
        "https://example.test/lockspire/userinfo",
        raw_access_token
      )

    validated = validate_dpop_proof!(proof, "GET", "https://example.test/lockspire/userinfo", now)

    assert {:ok, _token} =
             Repository.store_token(%Token{
               token_hash: TokenFormatter.hash_token(raw_access_token),
               token_type: :access_token,
               client_id: client.client_id,
               account_id: "phase41-fapi-user",
               interaction_id: "phase41-userinfo-optin-positive",
               scopes: ["openid", "email", "profile"],
               cnf: %{"jkt" => validated.jkt},
               issued_at: now,
               expires_at: DateTime.add(now, 3600, :second)
             })

    conn =
      build_conn(:get, "/userinfo")
      |> put_req_header("authorization", "DPoP #{raw_access_token}")
      |> put_req_header("dpop", proof)
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body)["sub"] == "phase41-fapi-user"
  end

  test "/token defense-in-depth rejects basic-auth code exchange without DPoP for a per-client FAPI opt-in under global none",
       %{client: client, secret: secret} do
    put_security_profile!(:none)

    assert {:ok, _client} =
             Repository.update_client(client, %{security_profile: :fapi_2_0_security})

    code_verifier = "phase41-basic-no-dpop-verifier"
    raw_code = "phase41-basic-no-dpop-code"

    assert {:ok, _code} =
             create_completed_authorization_code(client, raw_code, code_verifier,
               account_id: "phase41-fapi-user",
               scopes: ["openid", "email", "profile"]
             )

    conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "code" => raw_code,
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => code_verifier
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 400

    assert Jason.decode!(conn.resp_body) == %{
             "error" => "invalid_dpop_proof",
             "error_description" => "A valid DPoP proof is required"
           }
  end

  test "FAPI 2.0 profile rejects RS256 for runtime operations like ID Token generation", %{
    client: client,
    secret: secret
  } do
    put_security_profile!(:fapi_2_0_security)
    publish_rs256_signing_key("phase41-rs256-kid")

    code_verifier = "phase41-rs256-verifier"
    raw_code = "phase41-rs256-code"

    assert {:ok, _code} =
             create_completed_authorization_code(client, raw_code, code_verifier,
               account_id: "phase41-fapi-user",
               scopes: ["openid", "email", "profile"]
             )

    proof_key = JOSE.JWK.generate_key({:ec, "P-256"})
    proof = generate_dpop_proof(proof_key, "POST", "https://example.test/lockspire/token")

    token_dpop_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "code" => raw_code,
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => code_verifier
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("dpop", proof)
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert token_dpop_conn.status == 500

    assert Jason.decode!(token_dpop_conn.resp_body) == %{
             "error" => "server_error",
             "error_description" => "Unable to issue id_token"
           }
  end

  defp put_security_profile!(profile) do
    {:ok, policy} = Repository.get_server_policy()
    Repository.put_server_policy(%{policy | security_profile: profile})
  end

  defp basic_auth(id, secret) do
    "Basic " <> Base.encode64("#{id}:#{secret}")
  end

  defp complete_strict_authorize_and_extract_jarm(authorize_conn) do
    location = get_resp_header(authorize_conn, "location") |> List.first()
    assert location =~ "/consent/"

    interaction_id =
      List.last(String.split(location, "/"))

    authorize_complete_conn =
      build_conn(:post, "/interactions/#{interaction_id}/complete", %{"decision" => "approve"})
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    unless authorize_complete_conn.status in [302, 303] do
      flunk(
        "unexpected consent completion response: #{authorize_complete_conn.status}\n" <>
          authorize_complete_conn.resp_body
      )
    end

    callback_uri = URI.parse(List.first(get_resp_header(authorize_complete_conn, "location")))
    params = URI.decode_query(callback_uri.query || "")
    response = params["response"]

    refute is_nil(response)
    refute params["error"]
    refute params["code"]
    assert length(String.split(response, ".")) == 3

    response
  end

  defp decode_jwt_payload(jwt) do
    [_header, payload, _signature] = String.split(jwt, ".")

    payload
    |> Base.url_decode64!(padding: false)
    |> Jason.decode!()
  end

  defp base_par_params(client_id) do
    %{
      "client_id" => client_id,
      "response_type" => "code",
      "redirect_uri" => "https://client.example.com/callback",
      "scope" => "openid",
      "nonce" => "phase41-nonce",
      "code_challenge" => code_challenge("phase41-message-signing-verifier"),
      "code_challenge_method" => "S256"
    }
  end

  defp strict_par_request_uri!(client, secret) do
    conn =
      build_conn(
        :post,
        "/par",
        Map.put(base_par_params(client.client_id), "response_mode", "jwt")
      )
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 201
    Jason.decode!(conn.resp_body)["request_uri"]
  end

  defp introspect_conn(client, secret, token, headers \\ []) do
    Enum.reduce(headers, build_conn(:post, "/introspect", %{"token" => token}), fn {key, value},
                                                                                   conn ->
      put_req_header(conn, key, value)
    end)
    |> put_req_header("authorization", basic_auth(client.client_id, secret))
  end

  defp code_challenge(verifier) do
    :sha256
    |> :crypto.hash(verifier)
    |> Base.url_encode64(padding: false)
  end

  defp generate_dpop_proof(key, method, url, access_token \\ nil) do
    iat = DateTime.utc_now() |> DateTime.to_unix()
    jti = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)

    payload = %{
      "htm" => method,
      "htu" => url,
      "iat" => iat,
      "jti" => jti
    }

    payload =
      if access_token,
        do: Map.put(payload, "ath", DPoP.access_token_ath(access_token)),
        else: payload

    {_alg, jwk} = JOSE.JWK.to_map(key)
    public_jwk = Map.take(jwk, ["kty", "crv", "x", "y"])

    header = %{
      "typ" => "dpop+jwt",
      "alg" => "ES256",
      "jwk" => public_jwk
    }

    JOSE.JWT.sign(key, header, payload) |> JOSE.JWS.compact() |> elem(1)
  end

  defp validate_dpop_proof!(proof, method, target_uri, now) do
    assert {:ok, validated} =
             DPoP.validate_proof(proof,
               method: method,
               target_uri: target_uri,
               now: now,
               max_age: 300,
               clock_skew: 30
             )

    validated
  end

  defp publish_signing_key(kid) do
    key = JOSE.JWK.generate_key({:ec, "P-256"})
    {_fields, jwk} = JOSE.JWK.to_map(key)

    {:ok, _published_key} =
      Repository.publish_key(%SigningKey{
        kid: kid,
        kty: :EC,
        alg: "ES256",
        use: "sig",
        public_jwk:
          jwk
          |> Map.take(["kty", "kid", "alg", "use", "crv", "x", "y"])
          |> Map.put("kid", kid)
          |> Map.put("alg", "ES256")
          |> Map.put("use", "sig"),
        private_jwk_encrypted: Jason.encode!(Map.put(jwk, "kid", kid)),
        status: :active,
        published_at: DateTime.utc_now(),
        activated_at: DateTime.utc_now(),
        metadata: %{}
      })

    key
  end

  defp publish_rs256_signing_key(kid) do
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
          |> Map.take(["kty", "kid", "alg", "use", "e", "n"])
          |> Map.put("kid", kid)
          |> Map.put("alg", "RS256")
          |> Map.put("use", "sig"),
        private_jwk_encrypted: Jason.encode!(Map.put(jwk, "kid", kid)),
        status: :active,
        published_at: DateTime.utc_now(),
        activated_at: DateTime.utc_now(),
        metadata: %{}
      })

    key
  end

  defp create_completed_authorization_code(client, raw_code, verifier, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    interaction_id = "interaction-#{raw_code}"

    assert {:ok, _interaction} =
             Repository.put_interaction(%Interaction{
               interaction_id: interaction_id,
               client_id: client.client_id,
               account_id: Keyword.get(opts, :account_id, "phase41-fapi-user"),
               scopes_requested: Keyword.get(opts, :scopes, ["openid"]),
               nonce: Keyword.get(opts, :nonce),
               auth_time: Keyword.get(opts, :auth_time),
               max_age: Keyword.get(opts, :max_age),
               auth_time_requested: Keyword.get(opts, :auth_time_requested, false),
               redirect_uri: "https://client.example.com/callback",
               return_to: "/authorize",
               state: "phase41-state",
               code_challenge: code_challenge(verifier),
               code_challenge_method: :S256,
               status: :completed,
               completed_at: now,
               expires_at: DateTime.add(now, 300, :second)
             })

    Repository.store_token(%Token{
      token_hash: TokenFormatter.hash_token(raw_code),
      token_type: :authorization_code,
      client_id: client.client_id,
      account_id: Keyword.get(opts, :account_id, "phase41-fapi-user"),
      interaction_id: interaction_id,
      redirect_uri: "https://client.example.com/callback",
      scopes: Keyword.get(opts, :scopes, ["openid"]),
      code_challenge: code_challenge(verifier),
      code_challenge_method: :S256,
      issued_at: now,
      expires_at: DateTime.add(now, 300, :second)
    })
  end

  defp store_access_token!(client, raw_access_token, interaction_id) do
    now = DateTime.utc_now()

    assert {:ok, _token} =
             Repository.store_token(%Token{
               token_hash: TokenFormatter.hash_token(raw_access_token),
               token_type: :access_token,
               client_id: client.client_id,
               account_id: "phase41-fapi-user",
               interaction_id: interaction_id,
               scopes: ["openid"],
               issued_at: now,
               expires_at: DateTime.add(now, 3600, :second)
             })
  end
end
