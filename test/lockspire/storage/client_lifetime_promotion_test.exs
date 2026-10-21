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

  test "host management recovery promotes the locked whole v0 row and preserves v1 unrelated deadlines" do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    historical = DateTime.add(now, -500, :second)
    intended_management_deadline = DateTime.add(now, 40, :second)

    {:ok, legacy} =
      create_client("lifetime-management-host-v0", :client_secret_basic, "legacy-secret")

    old_hash = "host-management-v0-hash"
    old_secret_hash = legacy.client_secret_hash
    old_verifier = "host-management-v0-verifier"

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(c in ClientRecord, where: c.id == ^legacy.id),
               set: [
                 lifetime_version: 0,
                 registration_access_token_hash: old_hash,
                 client_expires_at: historical,
                 client_secret_expires_at: historical,
                 registration_access_token_expires_at: historical,
                 client_secret_jwt_verifier_encrypted: old_verifier,
                 active: false,
                 name: "current metadata"
               ]
             )

    {:ok, current} = Repository.fetch_client_by_id(legacy.client_id)

    candidate = %{
      current
      | registration_access_token_expires_at: intended_management_deadline,
        updated_at: now
    }

    assert {:ok, promoted} =
             ClientLifecycle.rotate_registration_access_token(
               candidate,
               "host-management-v1-hash",
               valid_rotation_audit(current, now)
             )

    assert promoted.lifetime_version == 1
    assert promoted.registration_access_token_hash == "host-management-v1-hash"

    assert DateTime.compare(
             promoted.registration_access_token_expires_at,
             intended_management_deadline
           ) == :eq

    assert is_nil(promoted.client_expires_at)
    assert is_nil(promoted.client_secret_expires_at)
    assert promoted.client_secret_hash == old_secret_hash
    assert promoted.client_secret_jwt_verifier_encrypted == old_verifier
    refute promoted.active
    assert promoted.name == "current metadata"

    app_deadline = DateTime.add(now, 500, :second)
    secret_deadline = DateTime.add(now, 450, :second)
    management_deadline = DateTime.add(now, 400, :second)

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(c in ClientRecord, where: c.id == ^legacy.id),
               set: [
                 lifetime_version: 1,
                 client_expires_at: app_deadline,
                 client_secret_expires_at: secret_deadline,
                 registration_access_token_expires_at: management_deadline
               ]
             )

    {:ok, v1} = Repository.fetch_client_by_id(legacy.client_id)

    v1_candidate = %{
      v1
      | registration_access_token_expires_at: intended_management_deadline,
        updated_at: now
    }

    assert {:ok, replaced} =
             ClientLifecycle.rotate_registration_access_token(
               v1_candidate,
               "host-management-v1-next-hash",
               valid_rotation_audit(v1, now)
             )

    assert DateTime.compare(replaced.client_expires_at, app_deadline) == :eq
    assert DateTime.compare(replaced.client_secret_expires_at, secret_deadline) == :eq

    assert DateTime.compare(
             replaced.registration_access_token_expires_at,
             intended_management_deadline
           ) == :eq
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

  test "secret replacement canonicalizes every v0 historical deadline class" do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    classes = [
      {"nil", nil},
      {"creation", now},
      {"past", DateTime.add(now, -60, :second)},
      {"future", DateTime.add(now, 600, :second)},
      {"stale", DateTime.add(now, 300, :second)}
    ]

    for {label, historical} <- classes do
      client_id = "lifetime-v0-#{label}-#{System.unique_integer([:positive])}"
      {:ok, client} = create_client(client_id, :client_secret_basic, "old-#{label}")

      assert {1, _} =
               Lockspire.TestRepo.update_all(
                 from(record in ClientRecord, where: record.id == ^client.id),
                 set: [
                   lifetime_version: 0,
                   client_expires_at: historical,
                   client_secret_expires_at: historical,
                   registration_access_token_expires_at: historical
                 ]
               )

      assert {:ok, current} = Repository.fetch_client_by_id(client_id)

      material = %{
        client_secret_hash: "replacement-hash-#{label}",
        client_secret_jwt_verifier_encrypted: "replacement-verifier-#{label}"
      }

      assert {:ok, rotated} =
               ClientLifecycle.rotate_operator_secret(
                 current,
                 material,
                 now,
                 valid_rotation_audit(current, now)
               )

      assert rotated.lifetime_version == 1
      assert rotated.client_secret_hash == material.client_secret_hash
      assert is_nil(rotated.client_expires_at)
      assert is_nil(rotated.client_secret_expires_at)
      assert is_nil(rotated.registration_access_token_expires_at)
    end
  end

  test "v1 secret replacement preserves app and management deadlines exactly" do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    app_deadline = DateTime.add(now, 5_000, :second)
    management_deadline = DateTime.add(now, 6_000, :second)
    {:ok, client} = create_client("lifetime-v1-secret-preserve", :client_secret_basic, "old-v1")

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.id == ^client.id),
               set: [
                 lifetime_version: 1,
                 client_expires_at: app_deadline,
                 client_secret_expires_at: nil,
                 registration_access_token_expires_at: management_deadline
               ]
             )

    assert {:ok, current} = Repository.fetch_client_by_id(client.client_id)

    material = %{
      client_secret_hash: "replacement-v1-hash",
      client_secret_jwt_verifier_encrypted: "replacement-v1-verifier"
    }

    assert {:ok, rotated} =
             ClientLifecycle.rotate_operator_secret(
               current,
               material,
               now,
               valid_rotation_audit(current, now)
             )

    assert DateTime.compare(rotated.client_expires_at, app_deadline) == :eq

    assert DateTime.compare(rotated.registration_access_token_expires_at, management_deadline) ==
             :eq

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

  defp valid_rotation_audit(client, rotated_at) do
    %{
      action: :client_secret_rotated,
      outcome: :succeeded,
      actor: %{type: :operator, id: "promotion-test"},
      resource: %{type: :client, id: client.client_id},
      metadata: %{rotated_at: rotated_at}
    }
  end
end
