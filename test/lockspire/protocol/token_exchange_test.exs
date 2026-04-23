defmodule Lockspire.Protocol.TokenExchangeTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Ecto.Query

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.TokenRecord

  defmodule Resolver do
    @behaviour Lockspire.Host.AccountResolver

    alias Lockspire.Host.Claims
    alias Lockspire.Host.InteractionResult

    @impl true
    def resolve_current_account(_conn_or_socket, _context), do: {:ok, %{id: "subject-123"}}

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
    Application.put_env(:lockspire, :account_resolver, Resolver)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    :telemetry.detach("token-exchange-test-handler")

    events = start_supervised!({Agent, fn -> [] end})

    :telemetry.attach_many(
      "token-exchange-test-handler",
      [
        [:lockspire, :authorization_code_redeemed],
        [:lockspire, :access_token_issued],
        [:lockspire, :authorization_code_replay_detected],
        [:lockspire, :token_exchange_failed]
      ],
      fn event, _measurements, metadata, pid ->
        Agent.update(pid, fn current -> [{event, metadata} | current] end)
      end,
      events
    )

    on_exit(fn -> :telemetry.detach("token-exchange-test-handler") end)

    %{events: events}
  end

  test "redeems a confidential-client authorization code into an opaque bearer access token", %{
    events: events
  } do
    secret = "super-secret-value"
    {:ok, client} = create_client("client-basic", :client_secret_basic, secret)

    _code =
      create_authorization_code(client, raw_code: "code-basic", code_verifier: "verifier-basic")

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-basic",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-basic"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert success.access_token
    assert success.token_type == "Bearer"
    assert success.expires_in == 3600
    assert success.scope == "email profile"

    assert {:ok, nil} =
             Repository.fetch_active_authorization_code(TokenFormatter.hash_token("code-basic"))

    persisted_token =
      Lockspire.TestRepo.one!(
        from(token in TokenRecord,
          where: token.token_type == :access_token and token.client_id == ^client.client_id
        )
      )

    assert persisted_token.account_id == "subject-123"
    assert persisted_token.token_hash == TokenFormatter.hash_token(success.access_token)
    refute persisted_token.token_hash == success.access_token

    event_names = recorded_event_names(events)
    assert [:lockspire, :authorization_code_redeemed] in event_names
    assert [:lockspire, :access_token_issued] in event_names
  end

  test "issues an RS256 id token for openid code flow using the linked interaction nonce" do
    secret = "openid-secret"
    {:ok, client} = create_client("client-openid", :client_secret_basic, secret)
    publish_signing_key("kid-openid")

    _code =
      create_authorization_code(client,
        raw_code: "code-openid",
        code_verifier: "verifier-openid",
        scopes: ["openid", "email", "profile"],
        nonce: "nonce-from-interaction"
      )

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-openid",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-openid"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert is_binary(success.id_token)

    assert %{"alg" => "RS256", "kid" => "kid-openid", "typ" => "JWT"} =
             decode_jwt_section(success.id_token, 0)

    claims = decode_jwt_section(success.id_token, 1)

    assert claims["iss"] == "https://example.test/lockspire"
    assert claims["aud"] == client.client_id
    assert claims["sub"] == "subject-123"
    assert claims["nonce"] == "nonce-from-interaction"
    assert claims["at_hash"] == at_hash(success.access_token)
  end

  test "does not issue an id token when openid is not granted" do
    secret = "oauth-secret"
    {:ok, client} = create_client("client-oauth", :client_secret_basic, secret)
    publish_signing_key("kid-oauth")

    _code =
      create_authorization_code(client, raw_code: "code-oauth", code_verifier: "verifier-oauth")

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-oauth",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-oauth"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert success.id_token == nil
  end

  test "issues a refresh token when the client allows refresh grants" do
    secret = "refresh-secret"

    {:ok, client} =
      create_client("client-refresh-issuer", :client_secret_basic, secret, [
        "authorization_code",
        "refresh_token"
      ])

    _code =
      create_authorization_code(client,
        raw_code: "code-refresh-issue",
        code_verifier: "verifier-refresh-issue",
        scopes: ["email", "offline_access"]
      )

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-refresh-issue",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-refresh-issue"
               },
               authorization: basic_auth(client.client_id, secret),
               access_token_generator: fn -> "issued-access-token" end,
               refresh_token_generator: fn -> "issued-refresh-token" end
             )

    assert success.refresh_token == "issued-refresh-token"

    assert {:ok, %Token{} = persisted_refresh_token} =
             Repository.fetch_refresh_token(TokenFormatter.hash_token("issued-refresh-token"))

    assert persisted_refresh_token.family_id == TokenFormatter.hash_token("issued-refresh-token")
    assert persisted_refresh_token.scopes == ["email", "offline_access"]
  end

  test "accepts form-encoded basic auth credentials containing reserved characters and colons" do
    client_id = "client:with/slash"
    secret = "sec:ret?/+= value:tail"
    {:ok, client} = create_client(client_id, :client_secret_basic, secret)

    _code =
      create_authorization_code(client,
        raw_code: "code-encoded-basic",
        code_verifier: "verifier-encoded-basic"
      )

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-encoded-basic",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-encoded-basic"
               },
               authorization: basic_auth_form_encoded(client_id, secret)
             )

    assert success.access_token
    assert success.token_type == "Bearer"
  end

  test "rejects replayed authorization code redemption and emits replay telemetry", %{
    events: events
  } do
    secret = "replay-secret"
    {:ok, client} = create_client("client-replay", :client_secret_basic, secret)

    _code =
      create_authorization_code(client, raw_code: "code-replay", code_verifier: "verifier-replay")

    assert {:ok, _success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-replay",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-replay"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert {:error, error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-replay",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-replay"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert error.error == "invalid_grant"
    assert error.reason_code == :authorization_code_replayed
    assert [:lockspire, :authorization_code_replay_detected] in recorded_event_names(events)
  end

  test "successful redemption and replay attempts append durable audit rows with client attribution",
       %{events: events} do
    secret = "audit-secret"
    {:ok, client} = create_client("client-audit", :client_secret_basic, secret)

    {:ok, authorization_code} =
      create_authorization_code(client, raw_code: "code-audit", code_verifier: "verifier-audit")

    assert {:ok, _success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-audit",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-audit"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert {:error, replay_error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-audit",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-audit"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert replay_error.reason_code == :authorization_code_replayed

    audits =
      Lockspire.TestRepo.all(AuditEventRecord)
      |> Enum.filter(&(&1.actor_id == client.client_id))

    assert Enum.any?(audits, fn audit ->
             audit.action == "authorization_code_redeemed" and
               audit.resource_type == "authorization_code" and
               audit.resource_id == Integer.to_string(authorization_code.id) and
               audit.actor_type == "client" and
               audit.reason_code == "authorization_code_redeemed"
           end)

    assert Enum.any?(audits, fn audit ->
             audit.action == "authorization_code_replay_detected" and
               audit.resource_type == "authorization_code" and
               audit.resource_id == Integer.to_string(authorization_code.id) and
               audit.actor_type == "client" and
               audit.reason_code == "authorization_code_replayed"
           end)

    assert {[:lockspire, :authorization_code_redeemed], %{reason_code: :authorization_code_redeemed}} =
             Enum.find(recorded_events(events), fn {event, metadata} ->
               event == [:lockspire, :authorization_code_redeemed] and
                 metadata[:reason_code] == :authorization_code_redeemed
             end)

    assert {[:lockspire, :authorization_code_replay_detected], %{reason_code: :authorization_code_replayed}} =
             Enum.find(recorded_events(events), fn {event, metadata} ->
               event == [:lockspire, :authorization_code_replay_detected] and
                 metadata[:reason_code] == :authorization_code_replayed
             end)
  end

  test "rejects authorization codes issued with an unsupported PKCE challenge method" do
    secret = "plain-method-secret"
    {:ok, client} = create_client("client-plain-method", :client_secret_basic, secret)
    raw_code = "code-plain-method"
    __MODULE__.PlainMethodTokenStore.use_token(%Token{
      id: 123,
      token_hash: TokenFormatter.hash_token(raw_code),
      token_type: :authorization_code,
      client_id: client.client_id,
      account_id: "subject-123",
      interaction_id: "interaction-code-plain-method",
      redirect_uri: "https://client.example.com/callback",
      scopes: ["email", "profile"],
      code_challenge: code_challenge("verifier-plain-method"),
      code_challenge_method: :plain,
      issued_at: DateTime.utc_now(),
      expires_at: DateTime.add(DateTime.utc_now(), 300, :second)
    })

    assert {:error, error} =
             exchange_with_store(
               %{
                 "grant_type" => "authorization_code",
                 "code" => raw_code,
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-plain-method"
               },
               __MODULE__.PlainMethodTokenStore,
               authorization: basic_auth(client.client_id, secret)
             )

    assert error.reason_code == :unsupported_code_challenge_method
  end

  test "rejects expired, verifier-mismatched, client-mismatched, and redirect-mismatched exchanges" do
    secret = "negative-secret"
    {:ok, client} = create_client("client-negative", :client_secret_basic, secret)

    create_authorization_code(client,
      raw_code: "code-expired",
      code_verifier: "expired-verifier",
      expires_at: DateTime.add(DateTime.utc_now(), -60, :second)
    )

    assert {:error, expired_error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-expired",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "expired-verifier"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert expired_error.reason_code == :authorization_code_expired

    create_authorization_code(client,
      raw_code: "code-verifier",
      code_verifier: "correct-verifier"
    )

    assert {:error, verifier_error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-verifier",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "wrong-verifier"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert verifier_error.reason_code == :code_verifier_mismatch

    secret_two = "other-secret"
    {:ok, other_client} = create_client("client-other", :client_secret_basic, secret_two)

    create_authorization_code(client,
      raw_code: "code-client-mismatch",
      code_verifier: "client-verifier"
    )

    assert {:error, client_error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-client-mismatch",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "client-verifier"
               },
               authorization: basic_auth(other_client.client_id, secret_two)
             )

    assert client_error.reason_code == :client_mismatch

    create_authorization_code(client,
      raw_code: "code-redirect-mismatch",
      code_verifier: "redirect-verifier"
    )

    assert {:error, redirect_error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-redirect-mismatch",
                 "redirect_uri" => "https://attacker.example.com/callback",
                 "code_verifier" => "redirect-verifier"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert redirect_error.reason_code == :redirect_uri_mismatch
  end

  test "rejects unsupported grant types and unsupported token-endpoint auth methods" do
    secret = "post-secret"
    {:ok, basic_client} = create_client("client-basic-only", :client_secret_basic, secret)

    _code =
      create_authorization_code(basic_client,
        raw_code: "code-post",
        code_verifier: "verifier-post"
      )

    assert {:error, grant_error} =
             exchange(
               %{
                 "grant_type" => "refresh_token",
                 "code" => "code-post",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-post"
               },
               authorization: basic_auth(basic_client.client_id, secret)
             )

    assert grant_error.error == "unsupported_grant_type"

    assert {:error, auth_error} =
             exchange(%{
               "grant_type" => "authorization_code",
               "client_id" => basic_client.client_id,
               "client_secret" => secret,
               "code" => "code-post",
               "redirect_uri" => "https://client.example.com/callback",
               "code_verifier" => "verifier-post"
             })

    assert auth_error.error == "invalid_client"
    assert auth_error.reason_code == :unsupported_token_endpoint_auth_method
  end

  defp exchange(params, opts \\ []) do
    exchange_with_store(params, Repository, opts)
  end

  defp exchange_with_store(params, token_store, opts) do
    TokenExchange.exchange_authorization_code(%{
      params: params,
      authorization: Keyword.get(opts, :authorization),
      opts: [
        client_store: Repository,
        token_store: token_store,
        interaction_store: Repository,
        key_store: Repository,
        access_token_generator:
          Keyword.get(opts, :access_token_generator, fn -> "opaque-access-token-123" end),
        refresh_token_generator:
          Keyword.get(opts, :refresh_token_generator, fn -> "opaque-refresh-token-123" end)
      ]
    })
  end

  defp create_client(
         client_id,
         auth_method,
         client_secret,
         allowed_grant_types \\ ["authorization_code"]
       ) do
    Repository.register_client(%Client{
      client_id: client_id,
      client_secret_hash: client_secret_hash(client_secret),
      client_type: :confidential,
      name: "Client #{client_id}",
      redirect_uris: ["https://client.example.com/callback"],
      allowed_scopes: ["email", "profile"],
      allowed_grant_types: allowed_grant_types,
      allowed_response_types: ["code"],
      token_endpoint_auth_method: auth_method,
      pkce_required: true,
      subject_type: :public,
      created_at: DateTime.utc_now(),
      metadata: %{}
    })
  end

  defp create_authorization_code(client, opts) do
    verifier = Keyword.fetch!(opts, :code_verifier)
    raw_code = Keyword.fetch!(opts, :raw_code)
    now = DateTime.utc_now()
    interaction_id = "interaction-#{raw_code}"
    code_challenge_method = Keyword.get(opts, :code_challenge_method, :S256)
    code_challenge = code_challenge(verifier)

    {:ok, _interaction} =
      Repository.put_interaction(%Interaction{
        interaction_id: interaction_id,
        client_id: client.client_id,
        account_id: "subject-123",
        scopes_requested: Keyword.get(opts, :scopes, ["email", "profile"]),
        nonce: Keyword.get(opts, :nonce),
        redirect_uri: "https://client.example.com/callback",
        return_to: "/authorize",
        state: "state-123",
        code_challenge: code_challenge,
        code_challenge_method: code_challenge_method,
        status: :completed,
        completed_at: now,
        expires_at: DateTime.add(now, 300, :second)
      })

    Repository.store_token(%Token{
      token_hash: TokenFormatter.hash_token(raw_code),
      token_type: :authorization_code,
      client_id: client.client_id,
      account_id: "subject-123",
      interaction_id: interaction_id,
      redirect_uri: "https://client.example.com/callback",
      scopes: Keyword.get(opts, :scopes, ["email", "profile"]),
      code_challenge: code_challenge,
      code_challenge_method: code_challenge_method,
      issued_at: now,
      expires_at: Keyword.get(opts, :expires_at, DateTime.add(now, 300, :second))
    })
  end

  defp publish_signing_key(kid) do
    jwk = JOSE.JWK.generate_key({:rsa, 2048}) |> JOSE.JWK.to_map() |> elem(1)

    Repository.publish_key(%SigningKey{
      kid: kid,
      kty: :RSA,
      alg: "RS256",
      use: :sig,
      public_jwk:
        Map.take(jwk, ["kty", "kid", "alg", "use", "n", "e"])
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

  defp basic_auth(client_id, client_secret) do
    "Basic " <> Base.encode64("#{client_id}:#{client_secret}")
  end

  defp basic_auth_form_encoded(client_id, client_secret) do
    encoded_client_id = URI.encode_www_form(client_id)
    encoded_client_secret = URI.encode_www_form(client_secret)
    "Basic " <> Base.encode64("#{encoded_client_id}:#{encoded_client_secret}")
  end

  defp client_secret_hash(secret) do
    salt = "static-salt"
    hash = :crypto.hash(:sha256, salt <> secret) |> Base.encode64()
    "sha256:#{salt}:#{hash}"
  end

  defp code_challenge(verifier) do
    :crypto.hash(:sha256, verifier)
    |> Base.url_encode64(padding: false)
  end

  defp at_hash(access_token) do
    <<left::binary-size(16), _rest::binary>> = :crypto.hash(:sha256, access_token)
    Base.url_encode64(left, padding: false)
  end

  defp decode_jwt_section(jwt, index) do
    jwt
    |> String.split(".")
    |> Enum.at(index)
    |> Base.url_decode64!(padding: false)
    |> Jason.decode!()
  end

  defp recorded_event_names(agent) do
    Agent.get(agent, fn events -> Enum.map(events, fn {event, _metadata} -> event end) end)
  end

  defp recorded_events(agent) do
    agent
    |> Agent.get(&Enum.reverse(&1))
    |> Enum.map(fn {event, metadata} -> {event, Map.take(metadata, [:reason_code])} end)
  end

  defmodule PlainMethodTokenStore do
    def use_token(%Token{} = token), do: Process.put({__MODULE__, :token}, token)

    def fetch_authorization_code(_token_hash), do: {:ok, Process.get({__MODULE__, :token})}
  end
end
