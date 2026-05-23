defmodule Lockspire.Web.TokenControllerTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Ecto.Query
  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Protocol.DPoPNonce
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.TokenRecord

  defmodule Resolver do
    @behaviour Lockspire.Host.AccountResolver

    alias Lockspire.Host.Claims
    alias Lockspire.Host.InteractionResult

    @impl true
    def resolve_current_account(_conn_or_socket, _context), do: {:ok, %{id: "subject-public"}}

    @impl true
    def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

    @impl true
    def build_claims(account, _context) do
      {:ok,
       %Claims{
         subject: account.id,
         id_token: %{"email" => "#{account.id}@example.test"},
         userinfo: %{"email" => "#{account.id}@example.test", "name" => "Subject #{account.id}"}
       }}
    end

    @impl true
    def redirect_for_login(_conn_or_socket, _context) do
      %InteractionResult{login_path: "/sign-in", return_to: "/authorize", params: %{}}
    end
  end

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :account_resolver, Resolver)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, public_client} =
      Repository.register_client(%Client{
        client_id: "client-public",
        client_secret_hash: nil,
        client_type: :public,
        name: "Public App",
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

    now = DateTime.utc_now()
    interaction_id = "interaction-public"

    {:ok, _interaction} =
      Repository.put_interaction(%Interaction{
        interaction_id: interaction_id,
        client_id: public_client.client_id,
        account_id: "subject-public",
        scopes_requested: ["email", "profile"],
        redirect_uri: "https://client.example.com/callback",
        return_to: "/authorize",
        state: "state-public",
        code_challenge: code_challenge("public-verifier"),
        code_challenge_method: :S256,
        status: :completed,
        completed_at: now,
        expires_at: DateTime.add(now, 300, :second)
      })

    {:ok, _code} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("public-code"),
        token_type: :authorization_code,
        client_id: public_client.client_id,
        account_id: "subject-public",
        interaction_id: interaction_id,
        redirect_uri: "https://client.example.com/callback",
        scopes: ["email", "profile"],
        code_challenge: code_challenge("public-verifier"),
        code_challenge_method: :S256,
        issued_at: now,
        expires_at: DateTime.add(now, 300, :second)
      })

    %{public_client: public_client}
  end

  test "POST /token returns an oauth token response for public clients", %{
    public_client: public_client
  } do
    conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => public_client.client_id,
        "code" => "public-code",
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => "public-verifier"
      })
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    body = Jason.decode!(conn.resp_body)

    assert Map.keys(body) |> Enum.sort() == ["access_token", "expires_in", "scope", "token_type"]
    assert body["token_type"] == "Bearer"
    assert body["scope"] == "email profile"

    persisted_token =
      Lockspire.TestRepo.one!(
        from(token in TokenRecord,
          where: token.token_type == :access_token and token.client_id == ^public_client.client_id
        )
      )

    assert persisted_token.token_hash == TokenFormatter.hash_token(body["access_token"])
  end

  test "POST /token includes an id_token for openid code flow", %{public_client: public_client} do
    publish_signing_key("kid-token-controller")
    create_openid_authorization_code(public_client, "openid-code", "openid-verifier", "nonce-123")

    conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => public_client.client_id,
        "code" => "openid-code",
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => "openid-verifier"
      })
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200

    body = Jason.decode!(conn.resp_body)

    assert Map.has_key?(body, "id_token")
    assert body["token_type"] == "Bearer"
  end

  test "POST /token returns token_type DPoP for DPoP-mode clients" do
    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client-public-dpop",
        client_secret_hash: nil,
        client_type: :public,
        name: "Public DPoP App",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email", "profile"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        dpop_policy: :dpop,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    now = DateTime.utc_now()
    interaction_id = "interaction-public-dpop"

    {:ok, _interaction} =
      Repository.put_interaction(%Interaction{
        interaction_id: interaction_id,
        client_id: client.client_id,
        account_id: "subject-public",
        scopes_requested: ["email", "profile"],
        redirect_uri: "https://client.example.com/callback",
        return_to: "/authorize",
        state: "state-public-dpop",
        code_challenge: code_challenge("public-dpop-verifier"),
        code_challenge_method: :S256,
        status: :completed,
        completed_at: now,
        expires_at: DateTime.add(now, 300, :second)
      })

    {:ok, _code} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("public-dpop-code"),
        token_type: :authorization_code,
        client_id: client.client_id,
        account_id: "subject-public",
        interaction_id: interaction_id,
        redirect_uri: "https://client.example.com/callback",
        scopes: ["email", "profile"],
        code_challenge: code_challenge("public-dpop-verifier"),
        code_challenge_method: :S256,
        issued_at: now,
        expires_at: DateTime.add(now, 300, :second)
      })

    %{jwt: proof_jwt, validated: validated_proof} = dpop_proof_fixture()

    conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "code" => "public-dpop-code",
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => "public-dpop-verifier"
      })
      |> put_req_header("accept", "application/json")
      |> put_req_header("dpop", proof_jwt)
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200

    body = Jason.decode!(conn.resp_body)

    assert body["token_type"] == "DPoP"

    persisted_token =
      Lockspire.TestRepo.one!(
        from(token in TokenRecord,
          where:
            token.token_type == :access_token and
              token.client_id == ^client.client_id and
              token.token_hash == ^TokenFormatter.hash_token(body["access_token"])
        )
      )

    assert persisted_token.cnf["jkt"] == validated_proof.jkt
  end

  test "POST /token returns invalid_dpop_proof when proof iat is a string" do
    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client-public-dpop-invalid-iat",
        client_secret_hash: nil,
        client_type: :public,
        name: "Public DPoP Invalid IAT App",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email", "profile"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        dpop_policy: :dpop,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    now = DateTime.utc_now()
    interaction_id = "interaction-public-dpop-invalid-iat"

    {:ok, _interaction} =
      Repository.put_interaction(%Interaction{
        interaction_id: interaction_id,
        client_id: client.client_id,
        account_id: "subject-public",
        scopes_requested: ["email", "profile"],
        redirect_uri: "https://client.example.com/callback",
        return_to: "/authorize",
        state: "state-public-dpop-invalid-iat",
        code_challenge: code_challenge("public-dpop-invalid-iat-verifier"),
        code_challenge_method: :S256,
        status: :completed,
        completed_at: now,
        expires_at: DateTime.add(now, 300, :second)
      })

    {:ok, _code} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("public-dpop-invalid-iat-code"),
        token_type: :authorization_code,
        client_id: client.client_id,
        account_id: "subject-public",
        interaction_id: interaction_id,
        redirect_uri: "https://client.example.com/callback",
        scopes: ["email", "profile"],
        code_challenge: code_challenge("public-dpop-invalid-iat-verifier"),
        code_challenge_method: :S256,
        issued_at: now,
        expires_at: DateTime.add(now, 300, :second)
      })

    %{jwt: proof_jwt} =
      dpop_proof_fixture(iat: Integer.to_string(DateTime.to_unix(DateTime.utc_now())))

    conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "code" => "public-dpop-invalid-iat-code",
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => "public-dpop-invalid-iat-verifier"
      })
      |> put_req_header("accept", "application/json")
      |> put_req_header("dpop", proof_jwt)
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 400

    body = Jason.decode!(conn.resp_body)
    assert body["error"] == "invalid_dpop_proof"
    assert body["error_description"] == "The DPoP proof is invalid"
  end

  test "POST /token returns use_dpop_nonce and a retry nonce when a DPoP proof omits nonce" do
    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client-public-dpop-nonce",
        client_secret_hash: nil,
        client_type: :public,
        name: "Public DPoP Nonce App",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email", "profile"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        dpop_policy: :dpop,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    now = DateTime.utc_now()
    interaction_id = "interaction-public-dpop-nonce"

    {:ok, _interaction} =
      Repository.put_interaction(%Interaction{
        interaction_id: interaction_id,
        client_id: client.client_id,
        account_id: "subject-public",
        scopes_requested: ["email", "profile"],
        redirect_uri: "https://client.example.com/callback",
        return_to: "/authorize",
        state: "state-public-dpop-nonce",
        code_challenge: code_challenge("public-dpop-nonce-verifier"),
        code_challenge_method: :S256,
        status: :completed,
        completed_at: now,
        expires_at: DateTime.add(now, 300, :second)
      })

    {:ok, _code} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("public-dpop-nonce-code"),
        token_type: :authorization_code,
        client_id: client.client_id,
        account_id: "subject-public",
        interaction_id: interaction_id,
        redirect_uri: "https://client.example.com/callback",
        scopes: ["email", "profile"],
        code_challenge: code_challenge("public-dpop-nonce-verifier"),
        code_challenge_method: :S256,
        issued_at: now,
        expires_at: DateTime.add(now, 300, :second)
      })

    %{jwt: proof_without_nonce} = dpop_proof_fixture(nonce: nil)

    challenge_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "code" => "public-dpop-nonce-code",
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => "public-dpop-nonce-verifier"
      })
      |> put_req_header("accept", "application/json")
      |> put_req_header("dpop", proof_without_nonce)
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert challenge_conn.status == 400
    assert Jason.decode!(challenge_conn.resp_body)["error"] == "use_dpop_nonce"
    assert [retry_nonce] = get_resp_header(challenge_conn, "dpop-nonce")

    %{jwt: proof_with_nonce} = dpop_proof_fixture(nonce: retry_nonce)

    retry_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "code" => "public-dpop-nonce-code",
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => "public-dpop-nonce-verifier"
      })
      |> put_req_header("accept", "application/json")
      |> put_req_header("dpop", proof_with_nonce)
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert retry_conn.status == 200
    assert Jason.decode!(retry_conn.resp_body)["token_type"] == "DPoP"
  end

  test "POST /token returns oauth-safe error json for unsupported grant types", %{
    public_client: public_client
  } do
    conn =
      build_conn(:post, "/token", %{
        "grant_type" => "password",
        "client_id" => public_client.client_id
      })
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 400

    body = Jason.decode!(conn.resp_body)

    assert body == %{
             "error" => "unsupported_grant_type",
             "error_description" =>
               "Only grant_type=authorization_code, grant_type=refresh_token, grant_type=urn:ietf:params:oauth:grant-type:device_code, grant_type=urn:openid:params:grant-type:ciba, and grant_type=urn:ietf:params:oauth:grant-type:token-exchange are supported"
           }
  end

  test "POST /token rotates refresh tokens for confidential clients" do
    secret = "controller-refresh-secret"

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client-controller-refresh",
        client_secret_hash: client_secret_hash(secret),
        client_type: :confidential,
        name: "Controller Refresh Client",
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

    now = DateTime.utc_now()

    {:ok, _refresh_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("controller-refresh-token"),
        token_type: :refresh_token,
        family_id: "controller-refresh-family",
        generation: 0,
        client_id: client.client_id,
        account_id: "subject-public",
        interaction_id: "interaction-controller-refresh",
        scopes: ["email", "offline_access"],
        audience: ["api.example.com"],
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      })

    conn =
      build_conn(:post, "/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => "controller-refresh-token"
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200

    body = Jason.decode!(conn.resp_body)

    assert Map.has_key?(body, "access_token")
    assert Map.has_key?(body, "refresh_token")
    assert body["scope"] == "email offline_access"
  end

  test "POST /token returns invalid_grant after refresh-token replay" do
    secret = "controller-replay-secret"

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client-controller-replay",
        client_secret_hash: client_secret_hash(secret),
        client_type: :confidential,
        name: "Controller Replay Client",
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

    now = DateTime.utc_now()

    {:ok, _refresh_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("controller-replay-token"),
        token_type: :refresh_token,
        family_id: "controller-replay-family",
        generation: 0,
        client_id: client.client_id,
        account_id: "subject-public",
        interaction_id: "interaction-controller-replay",
        scopes: ["email", "offline_access"],
        audience: ["api.example.com"],
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      })

    first_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => "controller-replay-token"
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert first_conn.status == 200

    replay_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => "controller-replay-token"
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert replay_conn.status == 400

    body = Jason.decode!(replay_conn.resp_body)
    assert body["error"] == "invalid_grant"
    assert body["error_description"] =~ "reuse detected"
  end

  test "POST /token returns authorization_pending for a compliant device poll" do
    secret = "device-pending-secret"
    {:ok, client} = register_device_client("controller-device-pending", secret)

    {:ok, authorization} =
      create_device_authorization(client,
        device_code: "controller-device-code-pending",
        user_code: "PEND-ING1",
        now: DateTime.add(DateTime.utc_now(), -10, :second)
      )

    conn =
      build_conn(:post, "/token", %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "device_code" => "controller-device-code-pending"
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 400
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    body = Jason.decode!(conn.resp_body)
    assert body["error"] == "authorization_pending"

    assert {:ok, stored} =
             Repository.fetch_device_authorization_by_verification_handle(
               authorization.verification_handle
             )

    assert stored.status == :pending
  end

  test "POST /token returns slow_down for a too-early device poll" do
    secret = "device-slow-down-secret"
    {:ok, client} = register_device_client("controller-device-slow-down", secret)

    {:ok, _authorization} =
      create_device_authorization(client,
        device_code: "controller-device-code-too-early",
        user_code: "SLOW-DOWN"
      )

    conn =
      build_conn(:post, "/token", %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "device_code" => "controller-device-code-too-early"
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 400
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    body = Jason.decode!(conn.resp_body)
    assert body["error"] == "slow_down"
  end

  test "POST /token returns the standard token shape for an approved device poll" do
    secret = "device-approved-secret"
    {:ok, client} = register_device_client("controller-device-approved", secret)

    {:ok, _authorization} =
      create_device_authorization(client,
        device_code: "controller-device-code-approved",
        user_code: "APPR-OVED",
        scopes: ["email", "profile"],
        now: DateTime.add(DateTime.utc_now(), -10, :second),
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-public"
        }
      )

    conn =
      build_conn(:post, "/token", %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "device_code" => "controller-device-code-approved"
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    body = Jason.decode!(conn.resp_body)

    assert Map.keys(body) |> Enum.sort() == [
             "access_token",
             "expires_in",
             "scope",
             "token_type"
           ]

    assert body["token_type"] == "Bearer"
    assert body["scope"] == "email profile"
    refute Map.has_key?(body, "refresh_token")
  end

  test "POST /token returns access_denied for a denied device authorization" do
    secret = "device-denied-secret"
    {:ok, client} = register_device_client("controller-device-denied", secret)

    {:ok, _authorization} =
      create_device_authorization(client,
        device_code: "controller-device-code-denied",
        user_code: "DENI-ED01",
        transition: %{status: :denied, denied_at: DateTime.utc_now()}
      )

    conn =
      build_conn(:post, "/token", %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "device_code" => "controller-device-code-denied"
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 400
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    body = Jason.decode!(conn.resp_body)
    assert body["error"] == "access_denied"
  end

  test "POST /token returns expired_token for an expired device authorization" do
    secret = "device-expired-secret"
    {:ok, client} = register_device_client("controller-device-expired", secret)

    {:ok, _authorization} =
      create_device_authorization(client,
        device_code: "controller-device-code-expired",
        user_code: "EXPI-RED1",
        transition: %{status: :expired, expired_at: DateTime.utc_now()}
      )

    conn =
      build_conn(:post, "/token", %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "device_code" => "controller-device-code-expired"
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 400
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    body = Jason.decode!(conn.resp_body)
    assert body["error"] == "expired_token"
  end

  test "POST /token returns invalid_grant when an approved device authorization is replayed" do
    secret = "device-replay-secret"
    {:ok, client} = register_device_client("controller-device-replay", secret)

    {:ok, _authorization} =
      create_device_authorization(client,
        device_code: "controller-device-code-replay",
        user_code: "REPL-AY01",
        now: DateTime.add(DateTime.utc_now(), -10, :second),
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-public"
        }
      )

    first_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "device_code" => "controller-device-code-replay"
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert first_conn.status == 200

    replay_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "device_code" => "controller-device-code-replay"
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert replay_conn.status == 400

    body = Jason.decode!(replay_conn.resp_body)
    assert body["error"] == "invalid_grant"
  end

  defp code_challenge(verifier) do
    :crypto.hash(:sha256, verifier)
    |> Base.url_encode64(padding: false)
  end

  defp publish_signing_key(kid) do
    jwk = JOSE.JWK.generate_key({:rsa, 2048}) |> JOSE.JWK.to_map() |> elem(1)

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
  end

  defp dpop_proof_fixture(overrides \\ []) do
    keys = JarTestHelpers.generate_ec_keys()
    now = DateTime.utc_now()
    target_uri = "https://example.test/lockspire/token"
    iat = Keyword.get(overrides, :iat, DateTime.to_unix(now))
    nonce = Keyword.get_lazy(overrides, :nonce, fn -> DPoPNonce.issue(:authorization_server) end)

    claims =
      %{
        "htm" => "POST",
        "htu" => target_uri,
        "iat" => iat,
        "jti" => Ecto.UUID.generate(),
        "nonce" => nonce
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    proof = JarTestHelpers.sign_dpop_proof(keys.private_jwk, claims)

    validated =
      case DPoP.validate_proof(proof,
             method: "POST",
             target_uri: target_uri,
             now: now,
             max_age: 300,
             clock_skew: 30
           ) do
        {:ok, %DPoP{} = proof_struct} -> proof_struct
        _other -> nil
      end

    %{jwt: proof, validated: validated}
  end

  defp client_secret_hash(secret) do
    "sha256:static-salt:" <> Base.encode64(:crypto.hash(:sha256, "static-salt" <> secret))
  end

  defp basic_auth(client_id, client_secret) do
    "Basic " <> Base.encode64("#{client_id}:#{client_secret}")
  end

  defp register_device_client(client_id, secret) do
    Repository.register_client(%Client{
      client_id: client_id,
      client_secret_hash: client_secret_hash(secret),
      client_type: :confidential,
      name: "Device Controller Client",
      redirect_uris: [],
      allowed_scopes: ["openid", "email", "profile", "offline_access"],
      allowed_grant_types: ["urn:ietf:params:oauth:grant-type:device_code", "refresh_token"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      created_at: DateTime.utc_now(),
      metadata: %{}
    })
  end

  defp create_device_authorization(client, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    authorization =
      DeviceAuthorization.issue(
        %{
          client_id: client.client_id,
          device_code: Keyword.fetch!(opts, :device_code),
          user_code: Keyword.fetch!(opts, :user_code),
          scopes: Keyword.get(opts, :scopes, ["email", "profile"])
        },
        now: now
      )

    with {:ok, stored} <- Repository.put_device_authorization(authorization) do
      case Keyword.get(opts, :transition) do
        nil ->
          {:ok, stored}

        attrs ->
          Repository.transition_device_authorization(
            stored.verification_handle,
            [stored.status],
            attrs
          )
      end
    end
  end

  defp create_openid_authorization_code(client, raw_code, verifier, nonce) do
    now = DateTime.utc_now()
    interaction_id = "interaction-#{raw_code}"

    {:ok, _interaction} =
      Repository.put_interaction(%Interaction{
        interaction_id: interaction_id,
        client_id: client.client_id,
        account_id: "subject-public",
        scopes_requested: ["openid", "email", "profile"],
        nonce: nonce,
        redirect_uri: "https://client.example.com/callback",
        return_to: "/authorize",
        state: "state-openid",
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
      account_id: "subject-public",
      interaction_id: interaction_id,
      redirect_uri: "https://client.example.com/callback",
      scopes: ["openid", "email", "profile"],
      code_challenge: code_challenge(verifier),
      code_challenge_method: :S256,
      issued_at: now,
      expires_at: DateTime.add(now, 300, :second)
    })
  end
end
