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
  alias Lockspire.Web.RegistrationJSON
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

  defp encrypted_jarm_metadata(overrides) do
    DcrFixtures.valid_metadata()
    |> Map.put("authorization_signed_response_alg", "RS256")
    |> Map.put("authorization_encrypted_response_alg", "RSA-OAEP-256")
    |> Map.put("authorization_encrypted_response_enc", "A256GCM")
    |> Map.merge(overrides)
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

    test "returns persisted logout metadata truthfully for stored clients" do
      {:ok, stored_client} =
        Repository.register_client(%Client{
          client_id: "persisted-logout-client",
          client_type: :confidential,
          redirect_uris: ["https://app.example.test/callback"],
          allowed_scopes: ["openid"],
          allowed_grant_types: ["authorization_code"],
          allowed_response_types: ["code"],
          token_endpoint_auth_method: :client_secret_basic,
          pkce_required: true,
          subject_type: :public,
          active: true,
          provenance: :self_registered,
          backchannel_logout_uri: "https://rp.example.test/backchannel-logout",
          backchannel_logout_session_required: true,
          frontchannel_logout_uri: "https://app.example.test/frontchannel-logout",
          frontchannel_logout_session_required: false
        })

      assert {:ok, returned_client} =
               RegistrationManagement.read(stored_client.client_id, stored_client)

      assert returned_client.backchannel_logout_uri == "https://rp.example.test/backchannel-logout"
      assert returned_client.backchannel_logout_session_required == true
      assert returned_client.frontchannel_logout_uri == "https://app.example.test/frontchannel-logout"
      assert returned_client.frontchannel_logout_session_required == false

      response = RegistrationJSON.read_response(returned_client)
      assert response.backchannel_logout_uri == "https://rp.example.test/backchannel-logout"
      assert response.backchannel_logout_session_required == true
      assert response.frontchannel_logout_uri == "https://app.example.test/frontchannel-logout"
      assert response.frontchannel_logout_session_required == false
    end
  end

  describe "update/2 — FAPI 2.0 readiness contract" do
    test "rejects update when client algorithm metadata is incompatible with FAPI", %{
      client: client,
      client_id: client_id
    } do
      server_policy = DcrFixtures.server_policy(%{security_profile: :fapi_2_0_security})

      new_metadata =
        Map.put(DcrFixtures.valid_metadata(), "id_token_signed_response_alg", "RS256")

      request = %{metadata: new_metadata, server_policy: server_policy, client: client}

      assert {:error,
              %Registration.Error{
                code: :invalid_client_metadata,
                field: :id_token_signed_response_alg,
                reason: :incompatible_with_fapi_2_0
              }} =
               RegistrationManagement.update(client_id, request)
    end

    test "rejects update when server is missing compliant keys for FAPI", %{
      client: client
    } do
      server_policy = DcrFixtures.server_policy(%{security_profile: :fapi_2_0_security})
      Lockspire.TestRepo.delete_all(Lockspire.Storage.Ecto.SigningKeyRecord)

      request = %{
        metadata: Map.put(DcrFixtures.valid_metadata(), "id_token_signed_response_alg", "ES256"),
        server_policy: server_policy,
        client: client
      }

      assert {:error,
              %Registration.Error{
                code: :invalid_client_metadata,
                field: :security_profile,
                reason: :missing_compliant_publishable_key
              }} =
               RegistrationManagement.update(client.client_id, request)
    end

    test "allows non-FAPI update to store legacy algorithm metadata", %{
      client: client,
      client_id: client_id,
      server_policy: server_policy
    } do
      new_metadata =
        Map.put(DcrFixtures.valid_metadata(), "id_token_signed_response_alg", "RS256")

      request = %{metadata: new_metadata, server_policy: server_policy, client: client}

      assert {:ok, %UpdateSuccess{client: updated_client}} =
               RegistrationManagement.update(client_id, request)

      assert updated_client.id_token_signed_response_alg == :RS256
    end

    test "accepts strict message-signing update when readiness is met", %{
      client: client,
      client_id: client_id
    } do
      now = DateTime.utc_now()

      Repository.publish_key(%Lockspire.Domain.SigningKey{
        kid: "management-message-signing-ready",
        use: :sig,
        status: :active,
        published_at: now,
        activated_at: now,
        public_jwk: %{
          "kty" => "EC",
          "crv" => "P-256",
          "kid" => "management-message-signing-ready",
          "alg" => "ES256",
          "use" => "sig"
        },
        private_jwk_encrypted: <<1>>,
        kty: :EC,
        alg: "ES256"
      })

      metadata =
        DcrFixtures.valid_metadata()
        |> Map.put("security_profile", "fapi_2_0_message_signing")
        |> Map.put("id_token_signed_response_alg", "ES256")
        |> Map.put("authorization_signed_response_alg", "ES256")

      request = %{
        metadata: metadata,
        server_policy: DcrFixtures.server_policy(%{security_profile: :none}),
        client: client
      }

      assert {:ok, %UpdateSuccess{client: updated_client}} =
               RegistrationManagement.update(client_id, request)

      assert updated_client.security_profile == :fapi_2_0_message_signing
      assert updated_client.authorization_signed_response_alg == :ES256
    end

    test "rejects strict message-signing updates without a compliant authorization response signing algorithm",
         %{client: client, client_id: client_id} do
      now = DateTime.utc_now()

      Repository.publish_key(%Lockspire.Domain.SigningKey{
        kid: "management-message-signing-reject",
        use: :sig,
        status: :active,
        published_at: now,
        activated_at: now,
        public_jwk: %{
          "kty" => "EC",
          "crv" => "P-256",
          "kid" => "management-message-signing-reject",
          "alg" => "ES256",
          "use" => "sig"
        },
        private_jwk_encrypted: <<1>>,
        kty: :EC,
        alg: "ES256"
      })

      metadata =
        DcrFixtures.valid_metadata()
        |> Map.put("security_profile", "fapi_2_0_message_signing")
        |> Map.put("id_token_signed_response_alg", "ES256")

      request = %{
        metadata: metadata,
        server_policy: DcrFixtures.server_policy(%{security_profile: :none}),
        client: client
      }

      assert {:error,
              %Registration.Error{
                code: :invalid_client_metadata,
                field: :authorization_signed_response_alg,
                reason: :incompatible_with_fapi_2_0
              }} = RegistrationManagement.update(client_id, request)
    end
  end

  describe "update/2 — RAT rotation" do
    test "updates client with coherent encrypted JARM metadata and persists the fields", %{
      client: client,
      client_id: client_id,
      server_policy: server_policy
    } do
      request = %{
        metadata:
          encrypted_jarm_metadata(%{
            "jwks" => %{"keys" => [%{"kty" => "RSA", "kid" => "enc-1"}]}
          }),
        server_policy: server_policy,
        client: client
      }

      assert {:ok, %UpdateSuccess{client: updated_client}} =
               RegistrationManagement.update(client_id, request)

      assert updated_client.authorization_signed_response_alg == :RS256
      assert updated_client.authorization_encrypted_response_alg == :RSA_OAEP_256
      assert updated_client.authorization_encrypted_response_enc == :A256GCM
      assert updated_client.jwks == %{"keys" => [%{"kty" => "RSA", "kid" => "enc-1"}]}
      assert is_nil(updated_client.jwks_uri)
    end

    test "updates private_key_jwt client from inline jwks to jwks_uri and persists the new field",
         %{
           server_policy: _server_policy
         } do
      server_policy = DcrFixtures.private_key_jwt_server_policy()

      {:ok, %Registration.Success{client: client}} =
        Registration.register(%{
          metadata: DcrFixtures.private_key_jwt_jwks_metadata(),
          iat: nil,
          server_policy: server_policy,
          source: %{ip: "127.0.0.1"}
        })

      request = %{
        metadata: DcrFixtures.private_key_jwt_jwks_uri_metadata(),
        server_policy: server_policy,
        client: client
      }

      assert {:ok, %UpdateSuccess{client: updated_client}} =
               RegistrationManagement.update(client.client_id, request)

      assert updated_client.client_id == client.client_id
      assert updated_client.token_endpoint_auth_method == :private_key_jwt
      assert updated_client.jwks_uri == "https://keys.example.test/client.jwks.json"
      assert is_nil(updated_client.jwks)
    end

    test "rejects update when encrypted JARM metadata is partial", %{
      client: client,
      client_id: client_id,
      server_policy: server_policy
    } do
      request = %{
        metadata:
          DcrFixtures.valid_metadata()
          |> Map.put("authorization_signed_response_alg", "RS256")
          |> Map.put("authorization_encrypted_response_alg", "RSA-OAEP-256")
          |> Map.put("jwks", %{"keys" => [%{"kty" => "RSA", "kid" => "enc-1"}]}),
        server_policy: server_policy,
        client: client
      }

      assert {:error,
              %Registration.Error{
                code: :invalid_client_metadata,
                field: :authorization_encrypted_response_enc,
                reason: :missing_for_encrypted_response
              }} = RegistrationManagement.update(client_id, request)
    end

    test "rejects update when encrypted JARM metadata uses both jwks and jwks_uri", %{
      client: client,
      client_id: client_id,
      server_policy: server_policy
    } do
      request = %{
        metadata:
          encrypted_jarm_metadata(%{
            "jwks" => %{"keys" => [%{"kty" => "RSA", "kid" => "enc-1"}]},
            "jwks_uri" => "https://keys.example.test/client.jwks.json"
          }),
        server_policy: server_policy,
        client: client
      }

      assert {:error,
              %Registration.Error{
                code: :invalid_client_metadata,
                field: :jwks,
                reason: :mutually_exclusive_with_jwks_uri
              }} = RegistrationManagement.update(client_id, request)
    end

    test "rejects update when metadata includes both jwks and jwks_uri", %{
      client: client,
      client_id: client_id
    } do
      server_policy = DcrFixtures.private_key_jwt_server_policy()

      request = %{
        metadata: DcrFixtures.mutual_jwks_metadata(),
        server_policy: server_policy,
        client: client
      }

      assert {:error,
              %Registration.Error{
                code: :invalid_client_metadata,
                field: :jwks,
                reason: :mutually_exclusive_with_jwks_uri
              }} = RegistrationManagement.update(client_id, request)
    end

    test "rejects update when jwks_uri is paired with unsupported auth method", %{
      client: client,
      client_id: client_id,
      server_policy: server_policy
    } do
      request = %{
        metadata: DcrFixtures.invalid_jwks_uri_metadata(),
        server_policy: server_policy,
        client: client
      }

      assert {:error,
              %Registration.Error{
                code: :invalid_client_metadata,
                field: :jwks_uri,
                reason: :unsupported_token_endpoint_auth_method
              }} = RegistrationManagement.update(client_id, request)
    end

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

    test "updates self-registered client dpop_policy to :bearer when dpop_bound_access_tokens is false",
         %{
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
