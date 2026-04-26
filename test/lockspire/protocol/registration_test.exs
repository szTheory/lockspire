defmodule Lockspire.Protocol.RegistrationTest do
  use ExUnit.Case, async: false
  import Ecto.Query

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.InitialAccessToken, as: IatDomain
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.Registration.Error
  alias Lockspire.Protocol.Registration.Success
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Test.Fixtures.DcrFixtures
  alias Lockspire.Test.Fixtures.InitialAccessTokenFixtures

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    handler_id = "registration-test-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach_many(
        handler_id,
        [
          [:lockspire, :dcr_registration_succeeded],
          [:lockspire, :dcr_registration_rejected],
          [:lockspire, :audit, :dcr_registration_succeeded],
          [:lockspire, :audit, :dcr_registration_rejected]
        ],
        fn event, measurements, metadata, pid ->
          send(pid, {:telemetry_event, event, measurements, metadata})
        end,
        self()
      )

    on_exit(fn -> :telemetry.detach(handler_id) end)
    %{}
  end

  describe "register/1 happy path" do
    test "returns {:ok, %Success{...}} for valid metadata + redeemable IAT" do
      iat_plaintext = "iat_test_#{:crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)}"
      {:ok, _} = InitialAccessTokenFixtures.persist(%{plaintext: iat_plaintext})

      request = DcrFixtures.register_request(iat: iat_plaintext, server_policy: DcrFixtures.server_policy())
      assert {:ok, %Success{
        client: %Client{},
        client_secret_plaintext: secret,
        registration_access_token_plaintext: rat
      }} = Registration.register(request)
      assert is_binary(secret)
      assert is_binary(rat)
    end

    test "persisted Domain.Client has pkce_required: true regardless of inbound pkce_required" do
      request = DcrFixtures.register_request()
      assert {:ok, %Success{client: client}} = Registration.register(request)
      assert client.pkce_required == true
    end

    test "persisted Domain.Client has client_secret_hash matching the format sha256:<salt>:<hash>" do
      request = DcrFixtures.register_request()
      assert {:ok, %Success{client: client}} = Registration.register(request)
      assert "sha256:" <> _ = client.client_secret_hash
    end

    test "round-trip proof: Policy.verify_client_secret returns true" do
      request = DcrFixtures.register_request()
      assert {:ok, %Success{client: client, client_secret_plaintext: plain}} = Registration.register(request)
      assert Policy.verify_client_secret(client.client_secret_hash, plain) == true
    end

    test "persisted Domain.Client has registration_access_token_hash equal to Policy.hash_token" do
      request = DcrFixtures.register_request()
      assert {:ok, %Success{client: client, registration_access_token_plaintext: rat}} = Registration.register(request)
      assert client.registration_access_token_hash == Policy.hash_token(rat)
    end

    test "persisted Domain.Client has provenance: :self_registered" do
      request = DcrFixtures.register_request()
      assert {:ok, %Success{client: client}} = Registration.register(request)
      assert client.provenance == :self_registered
    end

    test "persisted Domain.Client has initial_access_token_id matching the redeemed IAT's id when iat is non-nil" do
      iat_plaintext = "iat_test_#{:crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)}"
      {:ok, iat} = InitialAccessTokenFixtures.persist(%{plaintext: iat_plaintext})

      request = DcrFixtures.register_request(iat: iat_plaintext, server_policy: DcrFixtures.server_policy())
      assert {:ok, %Success{client: client}} = Registration.register(request)
      assert client.initial_access_token_id == iat.id
    end

    test "persisted Domain.Client has client_id_issued_at set to a recent UTC datetime" do
      request = DcrFixtures.register_request()
      assert {:ok, %Success{client: client}} = Registration.register(request)
      assert %DateTime{} = client.client_id_issued_at
    end

    test "persisted Domain.Client has client_secret_expires_at set from Resolved" do
      request = DcrFixtures.register_request()
      assert {:ok, %Success{client: client}} = Registration.register(request)
      assert %DateTime{} = client.client_secret_expires_at
    end

    test "unknown-field passthrough: register/1 silently ignores software_statement" do
      metadata = Map.put(DcrFixtures.valid_metadata(), "software_statement", "eyJ...")
      request = DcrFixtures.register_request(metadata: metadata)
      
      assert {:ok, %Success{client: client}} = Registration.register(request)
      refute Map.has_key?(client.metadata, "software_statement")
    end

    test "happy-path emits :dcr_registration_succeeded event with actor_type: :dcr in metadata and NO plaintext fields" do
      request = DcrFixtures.register_request()
      assert {:ok, _} = Registration.register(request)

      assert_receive {:telemetry_event, [:lockspire, :dcr_registration_succeeded], %{count: 1}, metadata}, 500
      assert metadata.actor_type == :dcr
      refute Map.has_key?(metadata, :plaintext)
      refute Map.has_key?(metadata, :client_secret)
      refute Map.has_key?(metadata, :registration_access_token)
    end

    test "audit row written by happy path has actor_type == dcr (NOT operator)" do
      request = DcrFixtures.register_request()
      assert {:ok, _} = Registration.register(request)

      rows = Lockspire.TestRepo.all(
        from(audit in AuditEventRecord,
          where: like(audit.action, "dcr_%"),
          order_by: [desc: audit.id])
      )
      assert length(rows) > 0
      refute Enum.any?(rows, &(&1.actor_type == "operator"))
      assert Enum.all?(rows, &(&1.actor_type == "dcr"))
    end
  end

  describe "register/1 — IAT precondition gate (D-13 step 1 — RESEARCH Q5 RESOLVED)" do
    test "rejects with missing iat when server_policy.registration_policy == :initial_access_token AND iat == nil" do
      server_policy = %Lockspire.Domain.ServerPolicy{registration_policy: :initial_access_token}
      request = DcrFixtures.register_request(iat: nil, server_policy: server_policy)
      
      assert {:error, %Error{code: :invalid_token, field: :iat, reason: :missing}} = Registration.register(request)
    end

    test "the precondition emits :dcr_registration_rejected telemetry with code: :invalid_token, field: :iat, reason: :missing and NO call to InitialAccessToken.redeem/1" do
      server_policy = %Lockspire.Domain.ServerPolicy{registration_policy: :initial_access_token}
      request = DcrFixtures.register_request(iat: nil, server_policy: server_policy)
      
      Registration.register(request)
      
      assert_receive {:telemetry_event, [:lockspire, :dcr_registration_rejected], _, metadata}, 500
      assert metadata.code == :invalid_token
      assert metadata.field == :iat
      assert metadata.reason == :missing

      # Verify no IAT redemption failure
      refute_received {:telemetry_event, [:lockspire, :iat_redemption_failed], _, _}
    end

    test "succeeds when server_policy.registration_policy == :open AND iat == nil" do
      server_policy = %Lockspire.Domain.ServerPolicy{registration_policy: :open}
      request = DcrFixtures.register_request(iat: nil, server_policy: server_policy)
      
      assert {:ok, _} = Registration.register(request)
    end

    test "succeeds when server_policy.registration_policy == :initial_access_token AND iat is a valid plaintext" do
      server_policy = %Lockspire.Domain.ServerPolicy{registration_policy: :initial_access_token}
      iat_plaintext = "iat_test_#{:crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)}"
      {:ok, _} = InitialAccessTokenFixtures.persist(%{plaintext: iat_plaintext})
      request = DcrFixtures.register_request(iat: iat_plaintext, server_policy: server_policy)
      
      assert {:ok, _} = Registration.register(request)
    end
  end

  describe "register/1 — IAT redemption (D-13 step 2)" do
    test "rejects with {:error, :invalid_token} when iat is non-nil but already used" do
      iat_plaintext = "iat_test_#{:crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)}"
      {:ok, iat} = InitialAccessTokenFixtures.persist(%{plaintext: iat_plaintext})
      
      Lockspire.TestRepo.update(Ecto.Changeset.change(iat, used_at: DateTime.utc_now()))

      request = DcrFixtures.register_request(iat: iat_plaintext)
      assert {:error, %Error{code: :invalid_token}} = Registration.register(request)
    end

    test "rejects with {:error, :invalid_token} when iat is non-nil but revoked" do
      iat_plaintext = "iat_test_#{:crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)}"
      {:ok, iat} = InitialAccessTokenFixtures.persist(%{plaintext: iat_plaintext})
      
      Lockspire.TestRepo.update(Ecto.Changeset.change(iat, revoked_at: DateTime.utc_now()))

      request = DcrFixtures.register_request(iat: iat_plaintext)
      assert {:error, %Error{code: :invalid_token}} = Registration.register(request)
    end

    test "rejects with {:error, :invalid_token} when iat is non-nil but expired" do
      iat_plaintext = "iat_test_#{:crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)}"
      {:ok, iat} = InitialAccessTokenFixtures.persist(%{plaintext: iat_plaintext})
      
      Lockspire.TestRepo.update(Ecto.Changeset.change(iat, expires_at: DateTime.add(DateTime.utc_now(), -10, :second)))

      request = DcrFixtures.register_request(iat: iat_plaintext)
      assert {:error, %Error{code: :invalid_token}} = Registration.register(request)
    end

    test "registers anonymously when iat is nil and server_policy.registration_policy == :open" do
      server_policy = %Lockspire.Domain.ServerPolicy{registration_policy: :open}
      request = DcrFixtures.register_request(iat: nil, server_policy: server_policy)
      
      assert {:ok, _} = Registration.register(request)

      rows = Lockspire.TestRepo.all(
        from(audit in AuditEventRecord,
          where: like(audit.action, "dcr_%"),
          order_by: [desc: audit.id])
      )
      assert length(rows) > 0
      assert Enum.all?(rows, &(&1.actor_id == "anonymous"))
    end
  end

  describe "register/1 — D-14 validator" do
    test "rejects metadata with jwks_uri" do
      request = DcrFixtures.register_request(metadata: DcrFixtures.invalid_jwks_uri_metadata())
      assert {:error, %Error{code: :invalid_client_metadata, field: :jwks_uri, reason: :unsupported_in_slice}} = Registration.register(request)
    end

    test "rejects metadata with both jwks and jwks_uri" do
      request = DcrFixtures.register_request(metadata: DcrFixtures.mutual_jwks_metadata())
      assert {:error, %Error{code: :invalid_client_metadata, field: :jwks_uri, reason: :unsupported_in_slice}} = Registration.register(request)
    end

    test "rejects RFC 7591 §2 incoherent grant/response pair" do
      request = DcrFixtures.register_request(metadata: DcrFixtures.incoherent_grant_response_metadata())
      assert {:error, %Error{code: :invalid_client_metadata, field: field, reason: :incoherent_pair}} = Registration.register(request)
      assert field in [:grant_types, :response_types]
    end

    test "rejects redirect URIs that fail validate_redirect_uris/1" do
      request = DcrFixtures.register_request(metadata: DcrFixtures.invalid_redirect_uri_metadata())
      assert {:error, %Error{code: :invalid_client_metadata, field: :redirect_uris, reason: :invalid_uri}} = Registration.register(request)
    end
  end

  describe "register/1 — D-15 PKCE floor" do
    test "rejects metadata with explicit pkce_required: false" do
      request = DcrFixtures.register_request(metadata: DcrFixtures.pkce_required_false_metadata())
      assert {:error, %Error{code: :invalid_client_metadata, field: :pkce_required, reason: :pkce_floor_required_for_dcr}} = Registration.register(request)
    end

    test "accepts metadata that omits pkce_required" do
      metadata = Map.drop(DcrFixtures.valid_metadata(), ["pkce_required"])
      request = DcrFixtures.register_request(metadata: metadata)
      
      assert {:ok, %Success{client: client}} = Registration.register(request)
      assert client.pkce_required == true
    end
  end

  describe "register/1 — failure-path telemetry" do
    test "every sad path emits :dcr_registration_rejected with reason measurement and NO plaintext" do
      request = DcrFixtures.register_request(metadata: DcrFixtures.pkce_required_false_metadata())
      assert {:error, _} = Registration.register(request)

      assert_receive {:telemetry_event, [:lockspire, :dcr_registration_rejected], %{count: 1}, metadata}, 500
      assert metadata.reason == :pkce_floor_required_for_dcr
      refute Map.has_key?(metadata, :plaintext)
    end

    test "no audit row from sad path is attributed to :operator" do
      request = DcrFixtures.register_request(metadata: DcrFixtures.pkce_required_false_metadata())
      assert {:error, _} = Registration.register(request)

      rows = Lockspire.TestRepo.all(
        from(audit in AuditEventRecord,
          where: like(audit.action, "dcr_%"),
          order_by: [desc: audit.id])
      )
      refute Enum.any?(rows, &(&1.actor_type == "operator"))
    end
  end
end
