defmodule Lockspire.Protocol.RefreshExchangeTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Protocol.RefreshExchange
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
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
    assert success.token_type == "Bearer"
    assert success.scope == "email offline_access"

    assert {:ok, %Token{} = rotated_refresh_token} =
             Repository.fetch_refresh_token(TokenFormatter.hash_token("rotated-refresh-token"))

    assert rotated_refresh_token.generation == 1
    assert rotated_refresh_token.account_id == "subject-refresh"
  end

  test "repository rotation preserves matching expected cnf on rotated children", %{
    client: client,
    now: now
  } do
    cnf = %{"jkt" => "refresh-proof-thumbprint"}
    presented_hash = TokenFormatter.hash_token("dpop-refresh-token")

    assert {:ok, %Token{}} =
             Repository.store_token(%Token{
               token_hash: presented_hash,
               token_type: :refresh_token,
               family_id: "family-refresh-dpop",
               generation: 0,
               client_id: client.client_id,
               account_id: "subject-refresh",
               interaction_id: "interaction-refresh",
               scopes: ["email", "offline_access"],
               audience: ["api.example.com"],
               cnf: cnf,
               issued_at: now,
               expires_at: DateTime.add(now, 86_400, :second)
             })

    rotated_at = DateTime.add(now, 60, :second)

    assert {:ok, result} =
             Repository.rotate_refresh_token(
               presented_hash,
               client.client_id,
               rotated_at,
               %Token{
                 token_hash: TokenFormatter.hash_token("dpop-child-refresh-token"),
                 token_type: :refresh_token,
                 client_id: client.client_id,
                 expires_at: DateTime.add(rotated_at, 86_400, :second)
               },
               %Token{
                 token_hash: TokenFormatter.hash_token("dpop-child-access-token"),
                 token_type: :access_token,
                 client_id: client.client_id,
                 expires_at: DateTime.add(rotated_at, 3_600, :second)
               },
               cnf
             )

    assert result.refresh_token.cnf["jkt"] == cnf["jkt"]
    assert result.access_token.cnf["jkt"] == cnf["jkt"]
  end

  test "repository rotation rejects mismatched expected cnf without mutating the family", %{
    client: client,
    now: now
  } do
    presented_hash = TokenFormatter.hash_token("mismatch-refresh-token")

    assert {:ok, presented_refresh_token} =
             Repository.store_token(%Token{
               token_hash: presented_hash,
               token_type: :refresh_token,
               family_id: "family-refresh-mismatch",
               generation: 0,
               client_id: client.client_id,
               account_id: "subject-refresh",
               interaction_id: "interaction-refresh",
               scopes: ["email", "offline_access"],
               audience: ["api.example.com"],
               cnf: %{"jkt" => "expected-jkt"},
               issued_at: now,
               expires_at: DateTime.add(now, 86_400, :second)
             })

    rotated_at = DateTime.add(now, 60, :second)

    assert {:error, :dpop_binding_mismatch} =
             Repository.rotate_refresh_token(
               presented_hash,
               client.client_id,
               rotated_at,
               %Token{
                 token_hash: TokenFormatter.hash_token("mismatch-child-refresh-token"),
                 token_type: :refresh_token,
                 client_id: client.client_id,
                 expires_at: DateTime.add(rotated_at, 86_400, :second)
               },
               %Token{
                 token_hash: TokenFormatter.hash_token("mismatch-child-access-token"),
                 token_type: :access_token,
                 client_id: client.client_id,
                 expires_at: DateTime.add(rotated_at, 3_600, :second)
               },
               %{"jkt" => "wrong-jkt"}
             )

    assert {:ok, %Token{} = unchanged_refresh_token} =
             Repository.fetch_refresh_token(presented_hash)

    assert unchanged_refresh_token.id == presented_refresh_token.id
    assert unchanged_refresh_token.redeemed_at == nil
    assert unchanged_refresh_token.revoked_at == nil

    assert {:ok, family_tokens} = Repository.list_token_family("family-refresh-mismatch")
    assert Enum.count(family_tokens) == 1
  end

  test "repository rotation still succeeds for bearer families when expected cnf is nil", %{
    client: client,
    now: now
  } do
    presented_hash = TokenFormatter.hash_token("bearer-refresh-token")

    assert {:ok, %Token{}} =
             Repository.store_token(%Token{
               token_hash: presented_hash,
               token_type: :refresh_token,
               family_id: "family-refresh-bearer",
               generation: 0,
               client_id: client.client_id,
               account_id: "subject-refresh",
               interaction_id: "interaction-refresh",
               scopes: ["email", "offline_access"],
               audience: ["api.example.com"],
               issued_at: now,
               expires_at: DateTime.add(now, 86_400, :second)
             })

    rotated_at = DateTime.add(now, 60, :second)

    assert {:ok, result} =
             Repository.rotate_refresh_token(
               presented_hash,
               client.client_id,
               rotated_at,
               %Token{
                 token_hash: TokenFormatter.hash_token("bearer-child-refresh-token"),
                 token_type: :refresh_token,
                 client_id: client.client_id,
                 expires_at: DateTime.add(rotated_at, 86_400, :second)
               },
               %Token{
                 token_hash: TokenFormatter.hash_token("bearer-child-access-token"),
                 token_type: :access_token,
                 client_id: client.client_id,
                 expires_at: DateTime.add(rotated_at, 3_600, :second)
               },
               nil
             )

    assert result.refresh_token.cnf == nil
    assert result.access_token.cnf == nil
  end

  test "rotates a DPoP-bound refresh token with token_type DPoP and preserves cnf", %{
    client: client,
    now: now
  } do
    %{jwt: proof_jwt, validated: validated_proof} = dpop_proof_fixture(now)

    assert {:ok, %Token{}} =
             Repository.store_token(%Token{
               token_hash: TokenFormatter.hash_token("dpop-exchange-refresh-token"),
               token_type: :refresh_token,
               family_id: "family-refresh-exchange-dpop",
               generation: 0,
               client_id: client.client_id,
               account_id: "subject-refresh",
               interaction_id: "interaction-refresh",
               scopes: ["email", "offline_access"],
               audience: ["api.example.com"],
               cnf: %{"jkt" => validated_proof.jkt},
               issued_at: now,
               expires_at: DateTime.add(now, 86_400, :second)
             })

    assert {:ok, success} =
             RefreshExchange.exchange_refresh_token(client, %{
               method: "POST",
               dpop: proof_jwt,
               params: %{"refresh_token" => "dpop-exchange-refresh-token"},
               opts: [
                 token_store: Repository,
                 dpop_replay_store: Repository,
                 access_token_generator: fn -> "dpop-rotated-access-token" end,
                 refresh_token_generator: fn -> "dpop-rotated-refresh-token" end,
                 now: fn -> now end
               ]
             })

    assert success.token_type == "DPoP"

    assert {:ok, %Token{} = rotated_access_token} =
             Repository.fetch_active_access_token(
               TokenFormatter.hash_token("dpop-rotated-access-token")
             )

    assert {:ok, %Token{} = rotated_refresh_token} =
             Repository.fetch_refresh_token(
               TokenFormatter.hash_token("dpop-rotated-refresh-token")
             )

    assert rotated_access_token.cnf["jkt"] == validated_proof.jkt
    assert rotated_refresh_token.cnf["jkt"] == validated_proof.jkt
  end

  test "returns invalid_grant when a DPoP-bound refresh token is presented with the wrong key", %{
    client: client,
    now: now
  } do
    %{validated: stored_proof} = dpop_proof_fixture(now)
    %{jwt: wrong_key_proof} = dpop_proof_fixture(now)

    assert {:ok, %Token{}} =
             Repository.store_token(%Token{
               token_hash: TokenFormatter.hash_token("wrong-key-refresh-token"),
               token_type: :refresh_token,
               family_id: "family-refresh-wrong-key",
               generation: 0,
               client_id: client.client_id,
               account_id: "subject-refresh",
               interaction_id: "interaction-refresh",
               scopes: ["email", "offline_access"],
               audience: ["api.example.com"],
               cnf: %{"jkt" => stored_proof.jkt},
               issued_at: now,
               expires_at: DateTime.add(now, 86_400, :second)
             })

    assert {:error, error} =
             RefreshExchange.exchange_refresh_token(client, %{
               method: "POST",
               dpop: wrong_key_proof,
               params: %{"refresh_token" => "wrong-key-refresh-token"},
               opts: [
                 token_store: Repository,
                 dpop_replay_store: Repository,
                 access_token_generator: fn -> "wrong-key-access-token" end,
                 refresh_token_generator: fn -> "wrong-key-refresh-child-token" end,
                 now: fn -> now end
               ]
             })

    assert error.error == "invalid_grant"
    assert error.reason_code == :refresh_dpop_binding_mismatch
  end

  test "returns invalid_dpop_proof when a DPoP-bound refresh token is missing proof", %{
    client: client,
    now: now
  } do
    assert {:ok, %Token{}} =
             Repository.store_token(%Token{
               token_hash: TokenFormatter.hash_token("missing-proof-refresh-token"),
               token_type: :refresh_token,
               family_id: "family-refresh-missing-proof",
               generation: 0,
               client_id: client.client_id,
               account_id: "subject-refresh",
               interaction_id: "interaction-refresh",
               scopes: ["email", "offline_access"],
               audience: ["api.example.com"],
               cnf: %{"jkt" => "missing-proof-jkt"},
               issued_at: now,
               expires_at: DateTime.add(now, 86_400, :second)
             })

    assert {:error, error} =
             RefreshExchange.exchange_refresh_token(client, %{
               method: "POST",
               params: %{"refresh_token" => "missing-proof-refresh-token"},
               opts: [
                 token_store: Repository,
                 dpop_replay_store: Repository,
                 access_token_generator: fn -> "missing-proof-access-token" end,
                 refresh_token_generator: fn -> "missing-proof-refresh-child-token" end,
                 now: fn -> now end
               ]
             })

    assert error.error == "invalid_dpop_proof"
    assert error.reason_code == :missing_dpop_proof
  end

  test "returns invalid_dpop_proof when a DPoP-bound refresh token has a malformed proof", %{
    client: client,
    now: now
  } do
    assert {:ok, %Token{}} =
             Repository.store_token(%Token{
               token_hash: TokenFormatter.hash_token("malformed-proof-refresh-token"),
               token_type: :refresh_token,
               family_id: "family-refresh-malformed-proof",
               generation: 0,
               client_id: client.client_id,
               account_id: "subject-refresh",
               interaction_id: "interaction-refresh",
               scopes: ["email", "offline_access"],
               audience: ["api.example.com"],
               cnf: %{"jkt" => "malformed-proof-jkt"},
               issued_at: now,
               expires_at: DateTime.add(now, 86_400, :second)
             })

    assert {:error, error} =
             RefreshExchange.exchange_refresh_token(client, %{
               method: "POST",
               dpop: "not-a-jwt",
               params: %{"refresh_token" => "malformed-proof-refresh-token"},
               opts: [
                 token_store: Repository,
                 dpop_replay_store: Repository,
                 access_token_generator: fn -> "malformed-proof-access-token" end,
                 refresh_token_generator: fn -> "malformed-proof-refresh-child-token" end,
                 now: fn -> now end
               ]
             })

    assert error.error == "invalid_dpop_proof"
    assert error.reason_code == :invalid_jwt
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

  defp dpop_proof_fixture(now) do
    keys = JarTestHelpers.generate_ec_keys()
    target_uri = "https://example.test/lockspire/token"

    proof =
      JarTestHelpers.sign_dpop_proof(keys.private_jwk, %{
        "htm" => "POST",
        "htu" => target_uri,
        "iat" => DateTime.to_unix(now),
        "jti" => Ecto.UUID.generate()
      })

    assert {:ok, %DPoP{} = validated} =
             DPoP.validate_proof(proof,
               method: "POST",
               target_uri: target_uri,
               now: now,
               max_age: 300,
               clock_skew: 30
             )

    %{jwt: proof, validated: validated}
  end
end
