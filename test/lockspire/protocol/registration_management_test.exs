defmodule Lockspire.Protocol.RegistrationManagementTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationManagement
  alias Lockspire.Protocol.RegistrationManagement.UpdateSuccess
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Test.Fixtures.DcrFixtures
  import Ecto.Query

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    
    server_policy = %ServerPolicy{
      registration_policy: :open,
      id: Lockspire.Storage.Ecto.ServerPolicyRecord.singleton_id()
    }
    Repository.put_server_policy(server_policy)

    handler_id = "dcr-management-test-#{System.unique_integer([:positive])}"

    :telemetry.attach_many(
      handler_id,
      [
        [:lockspire, :dcr_management_read],
        [:lockspire, :audit, :dcr_management_read],
        [:lockspire, :dcr_management_updated],
        [:lockspire, :audit, :dcr_management_updated],
        [:lockspire, :dcr_management_deleted],
        [:lockspire, :audit, :dcr_management_deleted],
        [:lockspire, :dcr_management_unauthorized],
        [:lockspire, :audit, :dcr_management_unauthorized],
        [:lockspire, :dcr_registration_access_token_rotated],
        [:lockspire, :audit, :dcr_registration_access_token_rotated]
      ],
      &__MODULE__.handle_event/4,
      self()
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    # Register a client to test against
    {:ok, %Registration.Success{} = success} =
      Registration.register(%{
        metadata: DcrFixtures.valid_metadata(),
        iat: nil,
        server_policy: server_policy,
        source: %{ip: "127.0.0.1"}
      })

    %{
      success: success,
      client: success.client,
      client_id: success.client.client_id,
      rat: success.registration_access_token_plaintext,
      server_policy: server_policy
    }
  end

  def handle_event(event, measurements, metadata, pid) do
    send(pid, {:telemetry_event, event, measurements, metadata})
  end

  describe "read/2" do
    test "returns {:ok, %Client{}} when client_id_from_url == client.client_id", %{client: client, client_id: client_id} do
      assert {:ok, %Client{} = returned_client} = RegistrationManagement.read(client_id, client)
      assert returned_client.client_id == client_id

      assert_received {:telemetry_event, [:lockspire, :dcr_management_read], _, metadata}
      assert metadata.actor_type == :self_registered_client
    end

    test "returns {:error, :invalid_token} when client_id_from_url != client.client_id (enumeration defense)", %{client: client} do
      assert {:error, :invalid_token} = RegistrationManagement.read("wrong_id", client)

      assert_received {:telemetry_event, [:lockspire, :dcr_management_unauthorized], _, _}
    end
  end

  describe "update/2 — RAT rotation" do
    test "accepts (client_id_from_url, %{metadata, server_policy, client}) and returns UpdateSuccess", %{client: client, client_id: client_id, server_policy: server_policy, rat: prior_rat} do
      new_metadata = Map.put(DcrFixtures.valid_metadata(), "client_name", "Updated Name")
      
      request = %{
        metadata: new_metadata,
        server_policy: server_policy,
        client: client
      }

      assert {:ok, %UpdateSuccess{client: updated_client, registration_access_token_plaintext: new_rat}} = RegistrationManagement.update(client_id, request)
      
      assert updated_client.client_id == client_id
      assert updated_client.name == "Updated Name"
      assert new_rat != prior_rat

      assert updated_client.registration_access_token_hash == Policy.hash_token(new_rat)
      
      # Implicit invalidation
      assert {:ok, nil} = Repository.get_client_by_registration_access_token_hash(Policy.hash_token(prior_rat))

      assert_received {:telemetry_event, [:lockspire, :dcr_management_updated], _, _}
      assert_received {:telemetry_event, [:lockspire, :dcr_registration_access_token_rotated], _, _}
    end

    test "returns {:error, %Error{}} for invalid metadata (jwks_uri)", %{client: client, client_id: client_id, server_policy: server_policy} do
      new_metadata = Map.put(DcrFixtures.valid_metadata(), "jwks_uri", "https://example.com/jwks")
      
      request = %{
        metadata: new_metadata,
        server_policy: server_policy,
        client: client
      }

      assert {:error, %Registration.Error{code: :invalid_client_metadata, field: :jwks_uri}} = RegistrationManagement.update(client_id, request)
    end

    test "returns {:error, :invalid_token} on URL/RAT mismatch", %{client: client, server_policy: server_policy} do
      request = %{
        metadata: DcrFixtures.valid_metadata(),
        server_policy: server_policy,
        client: client
      }

      assert {:error, :invalid_token} = RegistrationManagement.update("wrong_id", request)
      assert_received {:telemetry_event, [:lockspire, :dcr_management_unauthorized], _, _}
    end
  end

  describe "delete/2" do
    test "returns :ok and client row is soft-disabled", %{client: client, client_id: client_id} do
      assert :ok = RegistrationManagement.delete(client_id, client)
      
      # Client is soft deleted
      {:ok, updated_client} = Repository.fetch_client_by_id(client_id)
      assert updated_client.active == false
      assert updated_client.disabled_by == "dcr_self_delete"
      assert not is_nil(updated_client.disabled_at)

      assert_received {:telemetry_event, [:lockspire, :dcr_management_deleted], _, metadata}
      assert metadata.actor_type == :self_registered_client

      audit_row = Lockspire.TestRepo.one!(from a in AuditEventRecord, where: a.action == "dcr_management_deleted", order_by: [desc: a.id], limit: 1)
      assert audit_row.actor_type == "self_registered_client"

      # Reuse prevention
      {:error, error} = Repository.register_client(%Client{client | id: nil, registration_access_token_hash: nil})
      # Fails on unique constraint
      assert %Ecto.Changeset{} = error
    end

    test "returns {:error, :invalid_token} on URL/RAT mismatch", %{client: client} do
      assert {:error, :invalid_token} = RegistrationManagement.delete("wrong_id", client)
      assert_received {:telemetry_event, [:lockspire, :dcr_management_unauthorized], _, _}
    end
  end
end