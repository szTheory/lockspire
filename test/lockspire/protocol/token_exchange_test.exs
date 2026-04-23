defmodule Lockspire.Protocol.TokenExchangeTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Ecto.Query

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.TokenRecord

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

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
    TokenExchange.exchange_authorization_code(%{
      params: params,
      authorization: Keyword.get(opts, :authorization),
      opts: [
        client_store: Repository,
        token_store: Repository,
        token_generator: fn -> "opaque-access-token-123" end
      ]
    })
  end

  defp create_client(client_id, auth_method, client_secret) do
    Repository.register_client(%Client{
      client_id: client_id,
      client_secret_hash: client_secret_hash(client_secret),
      client_type: :confidential,
      name: "Client #{client_id}",
      redirect_uris: ["https://client.example.com/callback"],
      allowed_scopes: ["email", "profile"],
      allowed_grant_types: ["authorization_code"],
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

    Repository.store_token(%Token{
      token_hash: TokenFormatter.hash_token(raw_code),
      token_type: :authorization_code,
      client_id: client.client_id,
      account_id: "subject-123",
      interaction_id: "interaction-#{raw_code}",
      redirect_uri: "https://client.example.com/callback",
      scopes: ["email", "profile"],
      code_challenge: code_challenge(verifier),
      code_challenge_method: :S256,
      issued_at: now,
      expires_at: Keyword.get(opts, :expires_at, DateTime.add(now, 300, :second))
    })
  end

  defp basic_auth(client_id, client_secret) do
    "Basic " <> Base.encode64("#{client_id}:#{client_secret}")
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

  defp recorded_event_names(agent) do
    Agent.get(agent, fn events -> Enum.map(events, fn {event, _metadata} -> event end) end)
  end
end
