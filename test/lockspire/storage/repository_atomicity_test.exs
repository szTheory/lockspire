defmodule Lockspire.Storage.RepositoryAtomicityTest do
  use Lockspire.TokenExchangeCase, async: false

  alias Lockspire.Domain.Token
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.Repository

  @moduletag :integration

  test "authorization-code redemption has one DB-backed winner" do
    {:ok, client} = create_client("atomic-code-client", :client_secret_basic, "atomic-secret")

    assert {:ok, authorization_code} =
             create_authorization_code(client,
               raw_code: "atomic-code",
               code_verifier: "atomic-verifier"
             )

    access_token = %Token{
      token_hash: TokenFormatter.hash_token("atomic-access-token"),
      token_type: :access_token,
      client_id: client.client_id,
      account_id: authorization_code.account_id,
      interaction_id: authorization_code.interaction_id,
      scopes: authorization_code.scopes,
      issued_at: DateTime.utc_now(),
      expires_at: DateTime.add(DateTime.utc_now(), 300, :second)
    }

    assert {:ok, %{authorization_code: redeemed, access_token: persisted}} =
             Repository.redeem_authorization_code(
               TokenFormatter.hash_token("atomic-code"),
               DateTime.utc_now(),
               access_token
             )

    assert redeemed.redeemed_at
    assert persisted.token_hash == access_token.token_hash

    assert {:error, :already_redeemed} =
             Repository.redeem_authorization_code(
               TokenFormatter.hash_token("atomic-code"),
               DateTime.utc_now(),
               access_token
             )
  end

  test "refresh reuse atomically revokes every active token in its family" do
    now = DateTime.utc_now()
    family_id = "atomic-refresh-family"

    for {hash, type, redeemed_at} <- [
          {"atomic-replayed-refresh", :refresh_token, DateTime.add(now, -1, :second)},
          {"atomic-active-refresh", :refresh_token, nil},
          {"atomic-active-access", :access_token, nil}
        ] do
      assert {:ok, _token} =
               Repository.store_token(%Token{
                 token_hash: hash,
                 token_type: type,
                 family_id: family_id,
                 generation: 0,
                 client_id: "atomic-refresh-client",
                 account_id: "subject-123",
                 scopes: ["email"],
                 issued_at: DateTime.add(now, -30, :second),
                 redeemed_at: redeemed_at,
                 revoked_at: redeemed_at,
                 expires_at: DateTime.add(now, 300, :second)
               })
    end

    assert {:error, :reuse_detected} =
             Repository.rotate_refresh_token(
               "atomic-replayed-refresh",
               "atomic-refresh-client",
               now,
               %Token{
                 token_hash: "atomic-unused-refresh",
                 token_type: :refresh_token,
                 expires_at: DateTime.add(now, 300, :second)
               },
               %Token{
                 token_hash: "atomic-unused-access",
                 token_type: :access_token,
                 expires_at: DateTime.add(now, 300, :second)
               }
             )

    for hash <- ["atomic-replayed-refresh", "atomic-active-refresh", "atomic-active-access"] do
      assert {:ok, %Token{revoked_at: ^now}} = Repository.fetch_lifecycle_token(hash)
    end
  end

  test "DCR replacement rolls back metadata and RAT when its audit event is invalid" do
    {:ok, %Lockspire.Domain.Client{} = client} =
      create_client("atomic-dcr-client", :client_secret_basic, "atomic-dcr-secret")

    original_rat = "original-rat-hash"

    assert {:ok, client} =
             Repository.rotate_registration_access_token(
               client,
               original_rat,
               valid_audit(client)
             )

    assert {:error, _changeset} =
             Repository.replace_client_registration(
               client,
               %{client | name: "should-not-persist"},
               "replacement-rat-hash",
               %{
                 action: :dcr_management_updated,
                 outcome: :succeeded,
                 resource: %{type: :client, id: nil}
               }
             )

    assert {:ok, persisted} = Repository.fetch_client_by_id(client.client_id)
    assert persisted.name == client.name
    assert persisted.registration_access_token_hash == original_rat
  end

  test "signing-key guided transitions retain serialized states" do
    now = DateTime.utc_now()
    assert {:ok, active} = publish_signing_key("atomic-active-key")

    assert {:ok, upcoming} =
             Repository.publish_key(%SigningKey{
               kid: "atomic-upcoming-key",
               kty: :RSA,
               alg: "RS256",
               use: :sig,
               public_jwk: %{"kty" => "RSA", "kid" => "atomic-upcoming-key", "alg" => "RS256"},
               private_jwk_encrypted: <<1>>,
               status: :upcoming
             })

    assert {:error, :not_published} = Repository.activate_signing_key(upcoming.id, now)
    assert {:ok, _published} = Repository.publish_signing_key(upcoming.id, now)

    assert {:ok, %{activated_key: %{status: :active}, retiring_key: %{status: :retiring}}} =
             Repository.activate_signing_key(upcoming.id, now)

    assert {:ok, %{status: :retired}} = Repository.retire_signing_key(active.id, now)
  end

  defp valid_audit(client) do
    %{
      action: :dcr_management_updated,
      outcome: :succeeded,
      actor: %{type: :self_registered_client, id: client.client_id},
      resource: %{type: :client, id: client.client_id},
      metadata: %{}
    }
  end
end
