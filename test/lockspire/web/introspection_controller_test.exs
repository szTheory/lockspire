defmodule Lockspire.Web.IntrospectionControllerTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.SigningKeyRecord

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Lockspire.TestRepo.delete_all(SigningKeyRecord)

    secret = "introspection-controller-secret"

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client-introspection-controller",
        client_secret_hash: client_secret_hash(secret),
        client_type: :confidential,
        name: "Introspection Controller Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email", "offline_access"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    {:ok, public_client} =
      Repository.register_client(%Client{
        client_id: "client-introspection-controller-public",
        client_secret_hash: nil,
        client_type: :public,
        name: "Public Introspection Controller Client",
        redirect_uris: ["https://public.example.com/callback"],
        allowed_scopes: ["email"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    {:ok, other_client} =
      Repository.register_client(%Client{
        client_id: "client-introspection-controller-other",
        client_secret_hash: client_secret_hash("other-introspection-controller-secret"),
        client_type: :confidential,
        name: "Other Introspection Controller Client",
        redirect_uris: ["https://other.example.com/callback"],
        allowed_scopes: ["email", "offline_access"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    now = DateTime.utc_now()

    authorization_details = [
      %{
        "type" => "payment_initiation",
        "locations" => ["https://resource.example.com/payments"],
        "actions" => ["create"],
        "instructedAmount" => %{"currency" => "USD", "amount" => "12.34"}
      }
    ]

    {:ok, consent_grant} =
      Repository.grant_consent(%ConsentGrant{
        account_id: "subject-controller-introspection",
        client_id: client.client_id,
        scopes: ["email", "offline_access"],
        granted_at: now,
        status: :active,
        kind: :one_time,
        authorization_details: authorization_details,
        metadata: %{}
      })

    {:ok, _access_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("controller-introspect-access"),
        token_type: :access_token,
        client_id: client.client_id,
        account_id: "subject-controller-introspection",
        interaction_id: "interaction-controller-introspection",
        scopes: ["email"],
        audience: ["api.example.com"],
        consent_grant_id: consent_grant.id,
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      })

    {:ok, _refresh_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("controller-introspect-refresh"),
        token_type: :refresh_token,
        family_id: "controller-introspect-refresh-family",
        generation: 0,
        client_id: client.client_id,
        account_id: "subject-controller-introspection",
        interaction_id: "interaction-controller-introspection-refresh",
        scopes: ["email", "offline_access"],
        audience: ["api.example.com"],
        consent_grant_id: consent_grant.id,
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      })

    {:ok, _missing_grant_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("controller-introspect-missing-grant"),
        token_type: :access_token,
        client_id: client.client_id,
        account_id: "subject-controller-introspection",
        interaction_id: "interaction-controller-introspection-missing-grant",
        scopes: ["email"],
        audience: ["api.example.com"],
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      })

    {:ok, _expired_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("controller-introspect-expired"),
        token_type: :refresh_token,
        family_id: "controller-introspect-family",
        generation: 0,
        client_id: client.client_id,
        account_id: "subject-controller-introspection",
        interaction_id: "interaction-controller-introspection-expired",
        scopes: ["email", "offline_access"],
        issued_at: DateTime.add(now, -7200, :second),
        expires_at: DateTime.add(now, -3600, :second)
      })

    {:ok, _bound_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("controller-introspect-bound"),
        token_type: :access_token,
        client_id: client.client_id,
        account_id: "subject-controller-introspection-bound",
        interaction_id: "interaction-controller-introspection-bound",
        scopes: ["email"],
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second),
        cnf: %{"jkt" => "controller-test-thumbprint"}
      })

    signing_keys = publish_signing_key("introspection-controller-kid")

    %{
      client: client,
      secret: secret,
      public_client: public_client,
      other_client: other_client,
      authorization_details: authorization_details,
      consent_grant_id: consent_grant.id,
      signing_keys: signing_keys
    }
  end

  test "POST /introspect returns a signed JWT when token-introspection+jwt is explicitly accepted",
       %{
         client: client,
         secret: secret,
         authorization_details: authorization_details,
         signing_keys: signing_keys
       } do
    conn =
      build_conn(:post, "/introspect", %{"token" => "controller-introspect-access"})
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/token-introspection+jwt")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["application/token-introspection+jwt"]
    assert get_resp_header(conn, "vary") == ["Accept"]
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    claims = decode_jwt_claims(conn.resp_body, signing_keys)

    assert claims["iss"] == "https://example.test/lockspire"
    assert claims["aud"] == client.client_id
    assert is_integer(claims["iat"])
    assert claims["token_introspection"]["active"] == true
    assert claims["token_introspection"]["aud"] == ["api.example.com"]
    assert claims["token_introspection"]["authorization_details"] == authorization_details
    assert claims["token_introspection"]["client_id"] == client.client_id
    assert claims["token_introspection"]["scope"] == "email"
    assert claims["token_introspection"]["sub"] == "subject-controller-introspection"
    assert claims["token_introspection"]["token_type"] == "access_token"
    assert is_integer(claims["token_introspection"]["iat"])
    assert is_integer(claims["token_introspection"]["exp"])
  end

  test "POST /introspect signs inactive successful introspection payloads as narrow JWTs", %{
    client: client,
    secret: secret,
    signing_keys: signing_keys
  } do
    conn =
      build_conn(:post, "/introspect", %{"token" => "controller-introspect-expired"})
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/token-introspection+jwt")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200

    assert decode_jwt_claims(conn.resp_body, signing_keys)["token_introspection"] == %{
             "active" => false
           }
  end

  test "POST /introspect keeps JSON for missing wildcard malformed or JSON-only accept headers", %{
    client: client,
    secret: secret
  } do
    requests = [
      [],
      [{"accept", "*/*"}],
      [{"accept", "application/json"}],
      [{"accept", "application/token-introspection+jwt;q=0, application/json;q=1.0"}],
      [{"accept", "application/json; q=bogus"}]
    ]

    Enum.each(requests, fn headers ->
      conn =
        Enum.reduce(headers, build_conn(:post, "/introspect", %{"token" => "controller-introspect-access"}), fn {key, value}, conn ->
          put_req_header(conn, key, value)
        end)
        |> put_req_header("authorization", basic_auth(client.client_id, secret))
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      assert Jason.decode!(conn.resp_body)["active"] == true
    end)
  end

  test "POST /introspect honors explicit weighted JWT preferences and q=0 rejection", %{
    client: client,
    secret: secret,
    signing_keys: signing_keys
  } do
    jwt_conn =
      build_conn(:post, "/introspect", %{"token" => "controller-introspect-access"})
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header(
        "accept",
        "application/json;q=0.9, application/token-introspection+jwt;q=0.1"
      )
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert jwt_conn.status == 200
    assert get_resp_header(jwt_conn, "content-type") == ["application/token-introspection+jwt"]
    assert decode_jwt_claims(jwt_conn.resp_body, signing_keys)["aud"] == client.client_id

    json_conn =
      build_conn(:post, "/introspect", %{"token" => "controller-introspect-access"})
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header(
        "accept",
        "application/token-introspection+jwt;q=0, application/json;q=1.0"
      )
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert json_conn.status == 200
    assert get_resp_header(json_conn, "content-type") == ["application/json; charset=utf-8"]
    assert Jason.decode!(json_conn.resp_body)["active"] == true
  end

  test "POST /introspect returns active token metadata for authorized callers", %{
    client: client,
    secret: secret,
    authorization_details: authorization_details
  } do
    conn =
      build_conn(:post, "/introspect", %{"token" => "controller-introspect-access"})
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    body = Jason.decode!(conn.resp_body)

    assert body["active"] == true
    assert body["client_id"] == client.client_id
    assert body["token_type"] == "access_token"
    assert body["sub"] == "subject-controller-introspection"
    assert body["authorization_details"] == authorization_details
  end

  test "POST /introspect returns grant-backed authorization_details for refresh tokens", %{
    client: client,
    secret: secret,
    authorization_details: authorization_details
  } do
    conn =
      build_conn(:post, "/introspect", %{"token" => "controller-introspect-refresh"})
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)

    assert body["active"] == true
    assert body["token_type"] == "refresh_token"
    assert body["authorization_details"] == authorization_details
  end

  test "POST /introspect keeps token storage compact-by-reference and omits missing grant payloads", %{
    client: client,
    secret: secret,
    consent_grant_id: consent_grant_id
  } do
    assert {:ok, %Token{} = token} =
             Repository.fetch_lifecycle_token(
               TokenFormatter.hash_token("controller-introspect-access")
             )

    assert token.consent_grant_id == consent_grant_id
    refute Map.has_key?(Map.from_struct(token), :authorization_details)

    conn =
      build_conn(:post, "/introspect", %{"token" => "controller-introspect-missing-grant"})
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200

    body = Jason.decode!(conn.resp_body)
    assert body["active"] == true
    refute Map.has_key?(body, "authorization_details")
  end

  test "POST /introspect returns cnf for DPoP-bound tokens", %{
    client: client,
    secret: secret
  } do
    conn =
      build_conn(:post, "/introspect", %{"token" => "controller-introspect-bound"})
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)

    assert body["active"] == true
    assert body["cnf"] == %{"jkt" => "controller-test-thumbprint"}
  end

  test "POST /introspect collapses unauthorized public callers to active false", %{
    public_client: client
  } do
    conn =
      build_conn(:post, "/introspect", %{
        "token" => "controller-introspect-access",
        "client_id" => client.client_id
      })
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body) == %{"active" => false}
  end

  test "POST /introspect collapses client mismatch to active false", %{other_client: client} do
    conn =
      build_conn(:post, "/introspect", %{"token" => "controller-introspect-access"})
      |> put_req_header(
        "authorization",
        basic_auth(client.client_id, "other-introspection-controller-secret")
      )
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body) == %{"active" => false}
  end

  test "POST /introspect collapses expired tokens to active false", %{
    client: client,
    secret: secret
  } do
    conn =
      build_conn(:post, "/introspect", %{"token" => "controller-introspect-expired"})
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body) == %{"active" => false}
  end

  test "POST /introspect keeps protocol errors on the JSON path even when JWT is preferred", %{
    client: client
  } do
    conn =
      build_conn(:post, "/introspect", %{"token" => "controller-introspect-access"})
      |> put_req_header("authorization", basic_auth(client.client_id, "wrong-secret"))
      |> put_req_header("accept", "application/token-introspection+jwt")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 401
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert get_resp_header(conn, "www-authenticate") == ["Basic realm=\"Lockspire Token Endpoint\""]

    assert Jason.decode!(conn.resp_body) == %{
             "error" => "invalid_client",
             "error_description" => "Client authentication failed"
           }
  end

  test "POST /introspect falls back to JSON server_error if JWT signing fails after success", %{
    client: client,
    secret: secret
  } do
    Lockspire.TestRepo.delete_all(SigningKeyRecord)

    conn =
      build_conn(:post, "/introspect", %{"token" => "controller-introspect-access"})
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/token-introspection+jwt")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 500
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    assert Jason.decode!(conn.resp_body) == %{
             "error" => "server_error",
             "error_description" => "Unable to sign introspection response"
           }
  end

  defp client_secret_hash(secret) do
    "sha256:static-salt:" <> Base.encode64(:crypto.hash(:sha256, "static-salt" <> secret))
  end

  defp basic_auth(client_id, client_secret) do
    "Basic " <> Base.encode64("#{client_id}:#{client_secret}")
  end

  defp publish_signing_key(kid) do
    keys = JarTestHelpers.generate_keys()
    public_jwk = JOSE.JWK.to_public_map(keys.private_jwk) |> elem(1)
    private_jwk = JOSE.JWK.to_map(keys.private_jwk) |> elem(1)

    assert {:ok, _stored_key} =
             Repository.publish_key(%SigningKey{
               kid: kid,
               kty: :RSA,
               alg: "RS256",
               use: :sig,
               public_jwk:
                 public_jwk
                 |> Map.put("kid", kid)
                 |> Map.put("alg", "RS256")
                 |> Map.put("use", "sig"),
               private_jwk_encrypted: Jason.encode!(Map.put(private_jwk, "kid", kid)),
               status: :active,
               published_at: DateTime.utc_now(),
               activated_at: DateTime.utc_now(),
               metadata: %{}
             })

    keys
  end

  defp decode_jwt_claims(jwt, keys) do
    {_modules, public_jwk_map} = JOSE.JWK.to_public_map(keys.private_jwk)
    public_jwk = JOSE.JWK.from_map(public_jwk_map)

    assert {true, %JOSE.JWT{fields: claims}, _jws} =
             JOSE.JWT.verify_strict(public_jwk, ["RS256"], jwt)

    claims
  end
end
