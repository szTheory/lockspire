defmodule Lockspire.Web.TokenControllerTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Ecto.Query
  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenFormatter
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
               "Only grant_type=authorization_code and grant_type=refresh_token are supported"
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

  defp client_secret_hash(secret) do
    "sha256:static-salt:" <> Base.encode64(:crypto.hash(:sha256, "static-salt" <> secret))
  end

  defp basic_auth(client_id, client_secret) do
    "Basic " <> Base.encode64("#{client_id}:#{client_secret}")
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
