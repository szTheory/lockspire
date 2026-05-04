defmodule Lockspire.Protocol.RegistrationManagementTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
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

    server_policy =
      DcrFixtures.server_policy(%{
        id: Lockspire.Storage.Ecto.ServerPolicyRecord.singleton_id()
      })

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
    test "returns {:ok, %Client{}} when client_id_from_url == client.client_id", %{
      client: client,
      client_id: client_id
    } do
      assert {:ok, %Client{} = returned_client} = RegistrationManagement.read(client_id, client)
      assert returned_client.client_id == client_id
    end

    test "returns {:error, :invalid_token} when client_id_from_url != client.client_id (enumeration defense)",
         %{client: client} do
      assert {:error, :invalid_token} = RegistrationManagement.read("wrong_id", client)
    end
  end

  describe "update/2 — FAPI 2.0 readiness contract" do
    test "rejects update when client algorithm metadata is incompatible with FAPI", %{
      client: client,
      client_id: client_id
    } do
      server_policy = DcrFixtures.server_policy(%{security_profile: :fapi_2_0_security})
      
      new_metadata = Map.put(DcrFixtures.valid_metadata(), "id_token_signed_response_alg", "RS256")
      request = %{metadata: new_metadata, server_policy: server_policy, client: client}

      assert {:error, %Registration.Error{code: :invalid_client_metadata, field: :id_token_signed_response_alg, reason: :incompatible_with_fapi_2_0}} =
               RegistrationManagement.update(client_id, request)
    end

    test "rejects update when server is missing compliant keys for FAPI", %{
      client: client,
      client_id: client_id
    } do
      server_policy = DcrFixtures.server_policy(%{security_profile: :fapi_2_0_security})
      Lockspire.TestRepo.delete_all(Lockspire.Storage.Ecto.SigningKeyRecord)
      
      request = %{metadata: Map.put(DcrFixtures.valid_metadata(), "id_token_signed_response_alg", "ES256"), server_policy: server_policy, client: client}

      assert {:error, %Registration.Error{code: :invalid_client_metadata, field: :security_profile, reason: :missing_compliant_publishable_key}} =
               RegistrationManagement.update(client.client_id, request)
    end

    test "allows non-FAPI update to store legacy algorithm metadata", %{
      client: client,
      client_id: client_id,
      server_policy: server_policy
    } do
      new_metadata = Map.put(DcrFixtures.valid_metadata(), "id_token_signed_response_alg", "RS256")
      request = %{metadata: new_metadata, server_policy: server_policy, client: client}

      assert {:ok, %UpdateSuccess{client: updated_client}} = RegistrationManagement.update(client_id, request)
      assert updated_client.id_token_signed_response_alg == :RS256
    end
  end

  describe "update/2 — RAT rotation" do
    test "accepts (client_id_from_url, %{metadata, server_policy, client}) and returns UpdateSuccess",
         %{client: client, client_id: client_id, server_policy: server_policy, rat: prior_rat} do
      new_metadata = Map.put(DcrFixtures.valid_metadata(), "client_name", "Updated Name")

      request = %{
        metadata: new_metadata,
        server_policy: server_policy,
        client: client
      }

      assert {:ok,
              %UpdateSuccess{client: updated_client, registration_access_token_plaintext: new_rat}} =
               RegistrationManagement.update(client_id, request)

      assert updated_client.client_id == client_id
      assert updated_client.name == "Updated Name"
      assert new_rat != prior_rat

      assert updated_client.registration_access_token_hash == Policy.hash_token(new_rat)

      # Implicit invalidation
      assert {:ok, nil} =
               Repository.get_client_by_registration_access_token_hash(
                 Policy.hash_token(prior_rat)
               )
    end

    test "returns {:error, %Error{}} for invalid metadata (redirect_uris)", %{
      client: client,
      client_id: client_id,
      server_policy: server_policy
    } do
      new_metadata = DcrFixtures.invalid_redirect_uri_metadata()

      request = %{
        metadata: new_metadata,
        server_policy: server_policy,
        client: client
      }

      assert {:error, %Registration.Error{code: :invalid_client_metadata, field: :redirect_uris}} =
               RegistrationManagement.update(client_id, request)
    end

    test "returns {:error, :invalid_token} on URL/RAT mismatch", %{
      client: client,
      server_policy: server_policy
    } do
      request = %{
        metadata: DcrFixtures.valid_metadata(),
        server_policy: server_policy,
        client: client
      }

      assert {:error, :invalid_token} = RegistrationManagement.update("wrong_id", request)
    end

    test "updates self-registered client dpop_policy to :dpop from dpop_bound_access_tokens", %{
      client: client,
      client_id: client_id,
      server_policy: server_policy
    } do
      new_metadata = Map.put(DcrFixtures.valid_metadata(), "dpop_bound_access_tokens", true)

      request = %{
        metadata: new_metadata,
        server_policy: server_policy,
        client: client
      }

      assert {:ok, %UpdateSuccess{client: updated_client}} =
               RegistrationManagement.update(client_id, request)

      assert updated_client.dpop_policy == :dpop
    end

    test "updates self-registered client dpop_policy to :bearer when dpop_bound_access_tokens is false", %{
      client: client,
      client_id: client_id,
      server_policy: server_policy
    } do
      new_metadata = Map.put(DcrFixtures.valid_metadata(), "dpop_bound_access_tokens", false)

      request = %{
        metadata: new_metadata,
        server_policy: server_policy,
        client: client
      }

      assert {:ok, %UpdateSuccess{client: updated_client}} =
               RegistrationManagement.update(client_id, request)

      assert updated_client.dpop_policy == :bearer
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

      audit_row =
        Lockspire.TestRepo.one!(
          from(a in AuditEventRecord,
            where: a.action == "client_disabled",
            order_by: [desc: a.id],
            limit: 1
          )
        )

      assert audit_row.actor_type == "self_registered_client"

      # Reuse prevention
      %Client{} = client_struct = client

      {:error, error} =
        Repository.register_client(%Client{
          client_struct
          | id: nil,
            registration_access_token_hash: nil
        })

      # Fails on unique constraint
      assert %Ecto.Changeset{} = error
    end

    test "returns {:error, :invalid_token} on URL/RAT mismatch", %{client: client} do
      assert {:error, :invalid_token} = RegistrationManagement.delete("wrong_id", client)
    end
  end
end
