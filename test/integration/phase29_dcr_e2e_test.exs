defmodule Lockspire.Integration.Phase29DcrE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Admin.InitialAccessTokens
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult
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
    %{events: start_telemetry_capture()}
  end

  defp start_telemetry_capture do
    test_pid = self()
    handler_id = "phase29_test_handler_#{System.unique_integer()}"

    events = [
      [:lockspire, :iat, :mint],
      [:lockspire, :dcr, :register],
      [:lockspire, :dcr, :read],
      [:lockspire, :dcr, :update],
      [:lockspire, :dcr, :delete],
      [:lockspire, :dcr, :rotate]
    ]

    :telemetry.attach_many(
      handler_id,
      events,
      fn name, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, name, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    events
  end

  test "DCR End-to-End Scenario Test: Registration, Token Issuance, and Lifecycle Management" do
    # Require IAT
    {:ok, %ServerPolicy{}} =
      Repository.put_server_policy(%ServerPolicy{
        registration_policy: :initial_access_token,
        dcr_allowed_redirect_uri_schemes: ["https"],
        dcr_allowed_redirect_uri_hosts: ["client.example.com"],
        dcr_allowed_scopes: ["openid"],
        dcr_allowed_grant_types: ["authorization_code"],
        dcr_allowed_response_types: ["code"]
      })

    # 1. Mint IAT
    expires_at = DateTime.utc_now() |> DateTime.add(3600, :second)

    {:ok, iat, iat_secret} =
      InitialAccessTokens.mint_iat(%{single_use: true, expires_at: expires_at})

    assert_receive {:telemetry_event, [:lockspire, :iat, :mint], _meas, meta}
    assert meta.iat_id == iat.id

    # 2. Register Client
    register_conn =
      build_conn(:post, "/register", %{
        "client_name" => "Phase 29 E2E Client",
        "redirect_uris" => ["https://client.example.com/callback"]
      })
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{iat_secret}")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert register_conn.status == 201

    assert_receive {:telemetry_event, [:lockspire, :dcr, :register], _meas, dcr_meta}
    assert dcr_meta.status == :success
    assert client_id = dcr_meta.client_id

    response = Jason.decode!(register_conn.resp_body)
    client_secret = response["client_secret"]
    rat = response["registration_access_token"]
    assert rat != nil
    assert client_secret != nil

    # 3. Issue Token using Authorization Code Flow
    publish_signing_key("phase29-e2e-kid")
    {:ok, client} = Repository.fetch_client_by_id(client_id)
    raw_code = "phase29-openid-code"
    verifier = "phase29-openid-verifier"
    create_openid_authorization_code(client, raw_code, verifier, "nonce-phase29")

    token_conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "code" => raw_code,
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => verifier
      })
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", basic_auth(client_id, client_secret))
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert token_conn.status == 200
    token_response = Jason.decode!(token_conn.resp_body)
    assert Map.has_key?(token_response, "access_token")
    assert Map.has_key?(token_response, "id_token")

    # 4. Read Client with RAT
    read_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{rat}")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert read_conn.status == 200
    assert_receive {:telemetry_event, [:lockspire, :dcr, :read], _meas, read_meta}
    assert read_meta.status == :success

    # 5. Rotate RAT via Update
    update_conn =
      build_conn(:put, "/register/#{client_id}", %{
        "client_name" => "Phase 29 E2E Client - Updated",
        "redirect_uris" => ["https://client.example.com/callback"]
      })
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{rat}")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert update_conn.status == 200
    assert_receive {:telemetry_event, [:lockspire, :dcr, :update], _meas, update_meta}
    assert update_meta.status == :success
    assert_receive {:telemetry_event, [:lockspire, :dcr, :rotate], _meas, rotate_meta}
    assert rotate_meta.status == :success

    update_response = Jason.decode!(update_conn.resp_body)
    new_rat = update_response["registration_access_token"]
    assert new_rat != rat

    # 6. Delete Client
    delete_conn =
      build_conn(:delete, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{new_rat}")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert delete_conn.status == 204
    assert_receive {:telemetry_event, [:lockspire, :dcr, :delete], _meas, delete_meta}
    assert delete_meta.status == :success

    # 7. Unauthorized Read Attempt (with old RAT or new RAT on deleted client)
    unauthorized_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{new_rat}")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert unauthorized_conn.status == 401

    unauthorized_old_rat_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{rat}")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert unauthorized_old_rat_conn.status == 401
  end

  defp create_openid_authorization_code(client, raw_code, verifier, nonce) do
    now = DateTime.utc_now()
    interaction_id = "interaction-#{raw_code}"

    {:ok, _interaction} =
      Repository.put_interaction(%Interaction{
        interaction_id: interaction_id,
        client_id: client.client_id,
        account_id: "subject-e2e",
        scopes_requested: ["openid"],
        nonce: nonce,
        redirect_uri: "https://client.example.com/callback",
        return_to: "/authorize",
        state: "state-phase29",
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
        scopes: ["openid"],
        code_challenge: code_challenge(verifier),
        code_challenge_method: :S256,
        issued_at: now,
        expires_at: DateTime.add(now, 300, :second)
      })
  end

  defp code_challenge(verifier) do
    :crypto.hash(:sha256, verifier)
    |> Base.url_encode64(padding: false)
  end

  defp basic_auth(client_id, client_secret) do
    "Basic " <> Base.encode64("#{client_id}:#{client_secret}")
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
end
