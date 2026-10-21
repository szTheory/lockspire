defmodule Lockspire.ClientLifecycleTest do
  use Lockspire.DataCase, async: false

  alias Lockspire.ClientLifecycle
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.AuditEventRecord

  import Ecto.Query

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  test "DCR creation persists the client and its DCR audit attribution together" do
    client_id = "lifecycle-dcr-#{System.unique_integer([:positive])}"
    actor_id = "iat-#{client_id}"

    client = %Client{
      lifetime_version: 0,
      client_id: client_id,
      client_type: :public,
      redirect_uris: ["https://client.example.test/callback"],
      allowed_scopes: [],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :none,
      pkce_required: true,
      subject_type: :public,
      active: true
    }

    assert {:ok, persisted} =
             ClientLifecycle.create_dcr(%{
               client: client,
               actor: %{type: :dcr, id: actor_id}
             })

    assert persisted.client_id == client_id

    assert %AuditEventRecord{
             action: "dcr_client_created",
             actor_type: "dcr",
             actor_id: ^actor_id,
             resource_type: "client",
             resource_id: ^client_id,
             metadata: %{"client_id" => ^client_id, "provenance" => "operator"}
           } =
             Lockspire.TestRepo.one!(
               from(audit in AuditEventRecord,
                 where: audit.action == "dcr_client_created" and audit.resource_id == ^client_id
               )
             )
  end

  test "operator and RAT lifecycle writes preserve persistence and audit atomicity" do
    client_id = "lifecycle-operator-#{System.unique_integer([:positive])}"

    client = %Client{
      lifetime_version: 0,
      client_id: client_id,
      client_type: :confidential,
      client_secret_hash: "old-secret-hash",
      redirect_uris: ["https://client.example.test/callback"],
      allowed_scopes: [],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      active: true
    }

    assert {:ok, persisted} = ClientLifecycle.persist_direct(client)
    assert {:ok, updated} = ClientLifecycle.update_operator(persisted, %{name: "Updated"})
    assert updated.name == "Updated"

    rotated_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    secret_material = %{
      client_secret_hash: "new-secret-hash",
      client_secret_jwt_verifier_encrypted: "encrypted-secret"
    }

    assert {:ok, rotated} =
             ClientLifecycle.rotate_operator_secret(
               updated,
               secret_material,
               rotated_at,
               audit_event(:client_secret_rotated, updated, %{rotated_at: rotated_at})
             )

    assert rotated.client_secret_hash == "new-secret-hash"
    assert rotated.last_secret_rotated_at == rotated_at

    disabled_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    assert {:ok, disabled} =
             ClientLifecycle.disable_operator(
               rotated,
               disabled_at,
               "ops@example.test",
               audit_event(:client_disabled, rotated, %{disabled_by: "ops@example.test"})
             )

    refute disabled.active
    assert {:ok, enabled} = ClientLifecycle.enable_operator(disabled)
    assert enabled.active
    assert is_nil(enabled.disabled_at)

    assert {:ok, rat_rotated} =
             ClientLifecycle.rotate_registration_access_token(
               enabled,
               "new-rat-hash",
               audit_event(:dcr_management_rat_rotated, enabled, %{})
             )

    assert rat_rotated.registration_access_token_hash == "new-rat-hash"

    for action <- ["client_secret_rotated", "client_disabled", "dcr_management_rat_rotated"] do
      assert %AuditEventRecord{resource_id: ^client_id} =
               Lockspire.TestRepo.one!(
                 from(audit in AuditEventRecord,
                   where: audit.action == ^action and audit.resource_id == ^client_id
                 )
               )
    end
  end

  test "secret lifecycle accepts a deferred clock and builds audit from committed time" do
    client_id = "lifecycle-clock-#{System.unique_integer([:positive])}"

    client = %Client{
      lifetime_version: 0,
      client_id: client_id,
      client_type: :confidential,
      client_secret_hash: "old-secret-hash",
      redirect_uris: ["https://client.example.test/callback"],
      token_endpoint_auth_method: :client_secret_basic
    }

    assert {:ok, persisted} = ClientLifecycle.persist_direct(client)
    now = ~U[2030-01-02 03:04:05Z]

    material = %{
      client_secret_hash: "replacement-hash",
      client_secret_jwt_verifier_encrypted: "replacement-verifier"
    }

    assert {:ok, rotated} =
             ClientLifecycle.rotate_operator_secret(
               persisted,
               material,
               fn -> now end,
               fn %Client{last_secret_rotated_at: committed_at} = updated ->
                 audit_event(:client_secret_rotated, updated, %{rotated_at: committed_at})
               end
             )

    assert DateTime.compare(rotated.last_secret_rotated_at, now) == :eq

    assert %AuditEventRecord{metadata: %{"rotated_at" => audit_time}} =
             Lockspire.TestRepo.one!(
               from(audit in AuditEventRecord,
                 where:
                   audit.action == "client_secret_rotated" and audit.resource_id == ^client_id
               )
             )

    assert {:ok, parsed_audit_time, 0} = DateTime.from_iso8601(audit_time)
    assert DateTime.compare(parsed_audit_time, now) == :eq
  end

  test "host management rotation persists the intended deadline and decision instant" do
    client_id = "lifecycle-management-clock-#{System.unique_integer([:positive])}"
    app_deadline = ~U[2030-01-02 03:05:00Z]
    secret_deadline = ~U[2030-01-02 03:04:30Z]

    client = %Client{
      lifetime_version: 1,
      client_id: client_id,
      client_type: :confidential,
      client_secret_hash: "current-secret-hash",
      client_secret_jwt_verifier_encrypted: "current-secret-verifier",
      registration_access_token_hash: "current-rat-hash",
      client_expires_at: app_deadline,
      client_secret_expires_at: secret_deadline,
      registration_access_token_expires_at: nil,
      redirect_uris: ["https://client.example.test/callback"],
      token_endpoint_auth_method: :client_secret_basic
    }

    assert {:ok, persisted} = ClientLifecycle.persist_direct(client)
    now = ~U[2030-01-02 03:04:05Z]
    deadline = DateTime.add(now, 40, :second)
    candidate = %{persisted | registration_access_token_expires_at: deadline, updated_at: now}

    assert {:ok, rotated} =
             ClientLifecycle.rotate_registration_access_token(
               candidate,
               "replacement-rat-hash",
               audit_event(:dcr_management_rat_rotated, persisted, %{rotated_at: now})
             )

    assert rotated.registration_access_token_hash == "replacement-rat-hash"
    assert DateTime.compare(rotated.registration_access_token_expires_at, deadline) == :eq
    assert DateTime.compare(rotated.client_expires_at, app_deadline) == :eq
    assert DateTime.compare(rotated.client_secret_expires_at, secret_deadline) == :eq
    assert rotated.client_secret_hash == client.client_secret_hash

    assert rotated.client_secret_jwt_verifier_encrypted ==
             client.client_secret_jwt_verifier_encrypted

    assert DateTime.compare(rotated.updated_at, now) == :eq
  end

  defp audit_event(action, %Client{} = client, metadata) do
    %{
      action: action,
      outcome: :succeeded,
      reason_code: action,
      actor: %{type: :operator, id: "lifecycle-test"},
      resource: %{type: :client, id: client.client_id},
      metadata: metadata
    }
  end
end
