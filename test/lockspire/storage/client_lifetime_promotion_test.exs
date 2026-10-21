defmodule Lockspire.Storage.ClientLifetimePromotionTest do
  use Lockspire.TokenExchangeCase, async: false

  alias Lockspire.ClientLifecycle
  alias Lockspire.Storage.Ecto.ClientRecord

  @moduletag :integration

  test "management replacement promotes v0 and preserves current secret and app state" do
    {:ok, client} =
      create_client("lifetime-management-promotion", :client_secret_basic, "old-secret")

    old_rat = "management-rat-v0"
    past = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(-500, :second)

    Lockspire.TestRepo.update_all(from(c in ClientRecord, where: c.id == ^client.id),
      set: [
        registration_access_token_hash: old_rat,
        client_secret_expires_at: past,
        client_expires_at: past,
        registration_access_token_expires_at: past
      ]
    )

    stale = %{client | client_secret_hash: "stale-secret", active: false, name: "old name"}
    replacement = %{stale | name: "new name"}

    assert {:ok, updated} =
             Repository.replace_client_registration(
               %{client | registration_access_token_hash: old_rat},
               replacement,
               "management-rat-v1",
               valid_audit(client)
             )

    assert updated.lifetime_version == 1
    assert updated.registration_access_token_hash == "management-rat-v1"
    assert updated.client_secret_hash == client.client_secret_hash
    assert updated.active
    assert updated.name == "new name"
    assert is_nil(updated.client_expires_at)
    assert is_nil(updated.client_secret_expires_at)
    assert is_nil(updated.registration_access_token_expires_at)
  end

  test "secret replacement promotes v0 and preserves management credential" do
    {:ok, client} = create_client("lifetime-secret-promotion", :client_secret_basic, "old-secret")
    old_rat = "management-rat-secret-test"

    Lockspire.TestRepo.update_all(from(c in ClientRecord, where: c.id == ^client.id),
      set: [registration_access_token_hash: old_rat]
    )

    material = %{
      client_secret_hash: "new-secret-hash",
      client_secret_jwt_verifier_encrypted: "new-verifier"
    }

    event = %{
      action: :client_secret_rotated,
      outcome: :succeeded,
      actor: %{type: :operator, id: "test"},
      resource: %{type: :client, id: client.client_id},
      metadata: %{}
    }

    assert {:ok, rotated} =
             ClientLifecycle.rotate_operator_secret(
               client,
               material,
               DateTime.utc_now() |> DateTime.truncate(:second),
               event
             )

    assert rotated.lifetime_version == 1
    assert rotated.client_secret_hash == material.client_secret_hash

    assert rotated.client_secret_jwt_verifier_encrypted ==
             material.client_secret_jwt_verifier_encrypted

    assert rotated.registration_access_token_hash == old_rat
    assert is_nil(rotated.client_expires_at)
    assert is_nil(rotated.registration_access_token_expires_at)
    assert is_nil(rotated.client_secret_expires_at)
  end

  test "metadata and enablement leave legacy version and historical secret date untouched" do
    {:ok, client} = create_client("lifetime-no-promotion", :client_secret_basic, "old-secret")
    historical = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(-700, :second)

    Lockspire.TestRepo.update_all(from(c in ClientRecord, where: c.id == ^client.id),
      set: [client_secret_expires_at: historical]
    )

    assert {:ok, _} = Repository.update_client(client, %{name: "metadata only"})
    assert {:ok, _} = Repository.set_client_active(client, true, %{})
    assert {:ok, stored} = Repository.fetch_client_by_id(client.client_id)
    assert stored.lifetime_version == 0
    assert DateTime.compare(stored.client_secret_expires_at, historical) == :eq
    assert is_nil(stored.client_expires_at)
    assert is_nil(stored.registration_access_token_expires_at)
  end

  test "audit failure rolls back version, deadlines, and management credential" do
    {:ok, client} =
      create_client("lifetime-promotion-rollback", :client_secret_basic, "old-secret")

    old_rat = "rollback-rat-v0"
    past = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(-20, :second)

    Lockspire.TestRepo.update_all(from(c in ClientRecord, where: c.id == ^client.id),
      set: [
        registration_access_token_hash: old_rat,
        client_secret_expires_at: past,
        client_expires_at: past,
        registration_access_token_expires_at: past
      ]
    )

    assert {:error, _} =
             Repository.replace_client_registration(
               %{client | registration_access_token_hash: old_rat},
               %{client | registration_access_token_hash: old_rat, name: "must roll back"},
               "new-rat-must-roll-back",
               %{action: nil}
             )

    assert {:ok, stored} = Repository.fetch_client_by_id(client.client_id)
    assert stored.lifetime_version == 0
    assert stored.registration_access_token_hash == old_rat
    assert stored.name == client.name
    assert DateTime.compare(stored.client_expires_at, past) == :eq
    assert DateTime.compare(stored.client_secret_expires_at, past) == :eq
    assert DateTime.compare(stored.registration_access_token_expires_at, past) == :eq
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
