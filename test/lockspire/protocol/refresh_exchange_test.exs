defmodule Lockspire.Protocol.RefreshExchangeTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.RefreshExchange
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client-refresh",
        client_secret_hash: "sha256:static-salt:ignored",
        client_type: :confidential,
        name: "Refresh Client",
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

    {:ok, refresh_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("seed-refresh-token"),
        token_type: :refresh_token,
        family_id: "family-refresh-seed",
        generation: 0,
        client_id: client.client_id,
        account_id: "subject-refresh",
        interaction_id: "interaction-refresh",
        scopes: ["email", "offline_access"],
        audience: ["api.example.com"],
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      })

    %{client: client, refresh_token: refresh_token, now: now}
  end

  test "rotates a refresh token and returns child access and refresh tokens", %{client: client} do
    assert {:ok, success} =
             RefreshExchange.exchange_refresh_token(client, %{
               params: %{"refresh_token" => "seed-refresh-token"},
               opts: [
                 token_store: Repository,
                 access_token_generator: fn -> "rotated-access-token" end,
                 refresh_token_generator: fn -> "rotated-refresh-token" end,
                 now: fn -> DateTime.utc_now() end
               ]
             })

    assert success.access_token == "rotated-access-token"
    assert success.refresh_token == "rotated-refresh-token"
    assert success.scope == "email offline_access"

    assert {:ok, %Token{} = rotated_refresh_token} =
             Repository.fetch_refresh_token(TokenFormatter.hash_token("rotated-refresh-token"))

    assert rotated_refresh_token.generation == 1
    assert rotated_refresh_token.account_id == "subject-refresh"
  end

  test "replaying a refresh token revokes the family and returns invalid_grant", %{client: client} do
    assert {:ok, _success} =
             RefreshExchange.exchange_refresh_token(client, %{
               params: %{"refresh_token" => "seed-refresh-token"},
               opts: [
                 token_store: Repository,
                 access_token_generator: fn -> "first-access-token" end,
                 refresh_token_generator: fn -> "first-refresh-token" end,
                 now: fn -> DateTime.utc_now() end
               ]
             })

    assert {:error, error} =
             RefreshExchange.exchange_refresh_token(client, %{
               params: %{"refresh_token" => "seed-refresh-token"},
               opts: [
                 token_store: Repository,
                 access_token_generator: fn -> "second-access-token" end,
                 refresh_token_generator: fn -> "second-refresh-token" end,
                 now: fn -> DateTime.utc_now() end
               ]
             })

    assert error.error == "invalid_grant"
    assert error.reason_code == :refresh_token_reuse_detected

    assert {:ok, nil} =
             Repository.fetch_active_access_token(TokenFormatter.hash_token("first-access-token"))
  end

  test "rotation and reuse detection append durable audit rows with explicit reason codes", %{
    client: client,
    refresh_token: refresh_token
  } do
    assert {:ok, _success} =
             RefreshExchange.exchange_refresh_token(client, %{
               params: %{"refresh_token" => "seed-refresh-token"},
               opts: [
                 token_store: Repository,
                 access_token_generator: fn -> "audit-access-token" end,
                 refresh_token_generator: fn -> "audit-refresh-token" end,
                 now: fn -> DateTime.utc_now() end
               ]
             })

    assert {:error, error} =
             RefreshExchange.exchange_refresh_token(client, %{
               params: %{"refresh_token" => "seed-refresh-token"},
               opts: [
                 token_store: Repository,
                 access_token_generator: fn -> "audit-access-token-2" end,
                 refresh_token_generator: fn -> "audit-refresh-token-2" end,
                 now: fn -> DateTime.utc_now() end
               ]
             })

    assert error.reason_code == :refresh_token_reuse_detected

    audits = Lockspire.TestRepo.all(AuditEventRecord)

    assert Enum.any?(audits, fn audit ->
             audit.action == "refresh_token_rotated" and
               audit.actor_type == "client" and
               audit.actor_id == client.client_id and
               audit.reason_code == "refresh_token_rotated"
           end)

    assert Enum.any?(audits, fn audit ->
             audit.action == "refresh_token_reuse_detected" and
               audit.resource_type == "refresh_token" and
               audit.resource_id == Integer.to_string(refresh_token.id) and
               audit.reason_code == "refresh_token_reuse_detected"
           end)

    assert Enum.any?(audits, fn audit ->
             audit.action == "token_family_revoked" and
               audit.resource_type == "token_family" and
               audit.resource_id == refresh_token.family_id and
               audit.reason_code == "refresh_token_reuse_detected"
           end)
  end

  test "rejects refresh tokens issued to a different client", %{now: now} do
    {:ok, other_client} =
      Repository.register_client(%Client{
        client_id: "client-other-refresh",
        client_secret_hash: "sha256:static-salt:ignored",
        client_type: :confidential,
        name: "Other Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email", "offline_access"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: now,
        metadata: %{}
      })

    assert {:error, error} =
             RefreshExchange.exchange_refresh_token(other_client, %{
               params: %{"refresh_token" => "seed-refresh-token"},
               opts: [
                 token_store: Repository,
                 access_token_generator: fn -> "other-access-token" end,
                 refresh_token_generator: fn -> "other-refresh-token" end,
                 now: fn -> now end
               ]
             })

    assert error.reason_code == :client_mismatch
  end
end
