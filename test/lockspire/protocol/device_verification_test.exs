defmodule Lockspire.Protocol.DeviceVerificationTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Protocol.DeviceVerification

  defmodule FakeDeviceAuthorizationStore do
    alias Lockspire.Domain.DeviceAuthorization

    def fetch_device_authorization_by_user_code_hash(hash) do
      case hash do
        "pending-hash" -> {:ok, pending_authorization()}
        "expired-hash" -> {:ok, expired_authorization()}
        "approved-hash" -> {:ok, approved_authorization()}
        "missing-client-hash" -> {:ok, missing_client_authorization()}
        "missing-hash" -> {:ok, nil}
        "store-error-hash" -> {:error, :store_unavailable}
      end
    end

    def fetch_device_authorization_by_verification_handle("pending-handle"),
      do: {:ok, pending_authorization()}

    def fetch_device_authorization_by_verification_handle("approved-handle"),
      do: {:ok, approved_authorization()}

    def fetch_device_authorization_by_verification_handle("unknown-handle"), do: {:ok, nil}

    def fetch_device_authorization_by_verification_handle("store-error-handle"),
      do: {:error, :store_unavailable}

    def transition_device_authorization("pending-handle", [:pending], attrs) do
      merged =
        pending_authorization()
        |> Map.from_struct()
        |> Map.merge(attrs)

      {:ok, struct!(DeviceAuthorization, merged)}
    end

    def transition_device_authorization("approved-handle", [:pending], _attrs),
      do: {:error, :invalid_state}

    def transition_device_authorization("unknown-handle", [:pending], _attrs), do: {:error, :not_found}
    def transition_device_authorization("store-error-handle", [:pending], _attrs), do: {:error, :store_unavailable}

    defp pending_authorization do
      %DeviceAuthorization{
        id: 1,
        device_code_hash: "device-hash",
        user_code_hash: "pending-hash",
        verification_handle: "pending-handle",
        client_id: "client-123",
        scopes: ["openid", "profile"],
        status: :pending,
        expires_at: ~U[2026-04-28 15:00:00Z],
        user_code: "WDJB-MJHT"
      }
    end

    defp expired_authorization do
      %DeviceAuthorization{
        id: 2,
        device_code_hash: "expired-device-hash",
        user_code_hash: "expired-hash",
        verification_handle: "expired-handle",
        client_id: "client-123",
        scopes: ["openid"],
        status: :pending,
        expires_at: ~U[2026-04-28 10:59:59Z],
        user_code: "WDJB-MJHT"
      }
    end

    defp approved_authorization do
      %DeviceAuthorization{
        id: 3,
        device_code_hash: "approved-device-hash",
        user_code_hash: "approved-hash",
        verification_handle: "approved-handle",
        client_id: "client-123",
        scopes: ["openid"],
        status: :approved,
        subject_id: "subject-123",
        approved_at: ~U[2026-04-28 10:30:00Z],
        expires_at: ~U[2026-04-28 15:00:00Z],
        user_code: "WDJB-MJHT"
      }
    end

    defp missing_client_authorization do
      %DeviceAuthorization{
        id: 4,
        device_code_hash: "missing-client-device-hash",
        user_code_hash: "missing-client-hash",
        verification_handle: "missing-client-handle",
        client_id: "client-without-name",
        scopes: [],
        status: :pending,
        expires_at: ~U[2026-04-28 15:00:00Z],
        user_code: "ABCD-EFGH"
      }
    end
  end

  defmodule FakeClientStore do
    def fetch_client_by_id("client-123"),
      do: {:ok, %Client{client_id: "client-123", name: "Living Room TV"}}

    def fetch_client_by_id("client-without-name"), do: {:ok, %Client{client_id: "client-without-name"}}
    def fetch_client_by_id("missing-client"), do: {:ok, nil}
    def fetch_client_by_id("store-error"), do: {:error, :store_unavailable}
  end

  @opts [
    device_authorization_store: FakeDeviceAuthorizationStore,
    client_store: FakeClientStore,
    now: ~U[2026-04-28 11:00:00Z]
  ]

  describe "lookup_pending_device_authorization/2" do
    test "normalizes formatted user codes and returns pending verification context" do
      assert {:ok, %DeviceVerification.PendingAuthorization{} = pending} =
               DeviceVerification.lookup_pending_device_authorization(" wdjb-mjht ", @opts)

      assert pending.verification_handle == "pending-handle"
      assert pending.user_code == "WDJBMJHT"
      assert pending.client_id == "client-123"
      assert pending.client_name == "Living Room TV"
      assert pending.scopes == ["openid", "profile"]
    end

    test "falls back to client_id when client name is unavailable" do
      assert {:ok, %DeviceVerification.PendingAuthorization{} = pending} =
               DeviceVerification.lookup_pending_device_authorization("abcd-efgh", @opts)

      assert pending.user_code == "ABCDEFGH"
      assert pending.client_name == "client-without-name"
    end

    test "returns :expired when the authorization is no longer active by time" do
      assert {:error, :expired} =
               DeviceVerification.lookup_pending_device_authorization("expired-hash", @opts)
    end

    test "returns :not_active for non-pending authorizations" do
      assert {:error, :not_active} =
               DeviceVerification.lookup_pending_device_authorization("approved-hash", @opts)
    end

    test "returns :not_found when no authorization matches the code" do
      assert {:error, :not_found} =
               DeviceVerification.lookup_pending_device_authorization("missing-hash", @opts)
    end
  end

  describe "approve_device_authorization/3" do
    test "requires subject_id and mutates by opaque verification handle" do
      now = ~U[2026-04-28 11:05:00Z]

      assert {:ok, %DeviceAuthorization{} = approved} =
               DeviceVerification.approve_device_authorization(
                 "pending-handle",
                 %{subject_id: "subject-456"},
                 Keyword.put(@opts, :now, now)
               )

      assert approved.status == :approved
      assert approved.subject_id == "subject-456"
      assert approved.approved_at == now
    end

    test "rejects missing actor subject_id" do
      assert {:error, :invalid_actor_context} =
               DeviceVerification.approve_device_authorization("pending-handle", %{}, @opts)
    end

    test "preserves typed stale outcomes from the store" do
      assert {:error, :invalid_state} =
               DeviceVerification.approve_device_authorization(
                 "approved-handle",
                 %{subject_id: "subject-456"},
                 @opts
               )
    end
  end

  describe "deny_device_authorization/3" do
    test "requires actor context and marks the authorization denied" do
      now = ~U[2026-04-28 11:10:00Z]

      assert {:ok, %DeviceAuthorization{} = denied} =
               DeviceVerification.deny_device_authorization(
                 "pending-handle",
                 %{subject_id: "subject-456"},
                 Keyword.put(@opts, :now, now)
               )

      assert denied.status == :denied
      assert denied.denied_at == now
      assert denied.subject_id == nil
    end

    test "preserves typed not_found outcomes from the store" do
      assert {:error, :not_found} =
               DeviceVerification.deny_device_authorization(
                 "unknown-handle",
                 %{subject_id: "subject-456"},
                 @opts
               )
    end
  end
end
