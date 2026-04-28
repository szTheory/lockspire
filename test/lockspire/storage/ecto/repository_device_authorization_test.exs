defmodule Lockspire.Storage.Ecto.RepositoryDeviceAuthorizationTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
  end

  defp issue_device_authorization(attrs \\ %{}) do
    now = Map.get(attrs, :now, DateTime.utc_now())

    device_authorization =
      DeviceAuthorization.issue(
        %{
          device_code: Map.get(attrs, :device_code, "dev123"),
          user_code: Map.get(attrs, :user_code, "WDJB-MJHT"),
          client_id: Map.get(attrs, :client_id, "client_abc"),
          scopes: Map.get(attrs, :scopes, ["openid"])
        },
        now: now
      )

    {:ok, stored} = Repository.put_device_authorization(device_authorization)
    stored
  end

  describe "put_device_authorization/1" do
    test "inserts the record and returns it given a valid DeviceAuthorization struct" do
      now = DateTime.utc_now()

      auth = DeviceAuthorization.issue(%{
        device_code: "dev123",
        user_code: "usr456",
        client_id: "client_abc"
      }, now: now)

      assert {:ok, result} = Repository.put_device_authorization(auth)
      assert %DeviceAuthorization{} = result
      assert result.device_code_hash == auth.device_code_hash
      assert result.user_code_hash == auth.user_code_hash
      assert result.client_id == auth.client_id
    end

    test "inserting a duplicate code hash yields a constraint error" do
      now = DateTime.utc_now()

      auth = DeviceAuthorization.issue(%{
        device_code: "dev123",
        user_code: "usr456",
        client_id: "client_abc"
      }, now: now)

      assert {:ok, _} = Repository.put_device_authorization(auth)

      assert {:error, %Ecto.Changeset{} = changeset} = Repository.put_device_authorization(auth)
      assert {"has already been taken", _} = changeset.errors[:device_code_hash]
    end

    test "persists a unique verification handle for later approval or denial" do
      first = issue_device_authorization(%{device_code: "dev111"})
      second = issue_device_authorization(%{device_code: "dev222", user_code: "ABCD-EFGH"})

      assert is_binary(first.verification_handle)
      assert is_binary(second.verification_handle)
      refute first.verification_handle == second.verification_handle
    end
  end

  describe "verification lookups and transitions" do
    test "fetches the same pending authorization for formatted and unformatted user codes" do
      stored = issue_device_authorization()

      assert {:ok, %DeviceAuthorization{} = formatted} =
               Repository.fetch_device_authorization_by_user_code_hash(
                 DeviceAuthorization.hash_user_code("WDJB-MJHT")
               )

      assert {:ok, %DeviceAuthorization{} = unformatted} =
               Repository.fetch_device_authorization_by_user_code_hash(
                 DeviceAuthorization.hash_user_code("wdjbmjht")
               )

      assert formatted.id == stored.id
      assert unformatted.id == stored.id
      assert formatted.status == :pending
      assert unformatted.verification_handle == stored.verification_handle
    end

    test "fetches a pending authorization by verification handle" do
      stored = issue_device_authorization()

      assert {:ok, %DeviceAuthorization{} = fetched} =
               Repository.fetch_device_authorization_by_verification_handle(
                 stored.verification_handle
               )

      assert fetched.id == stored.id
      assert fetched.status == :pending
      assert fetched.verification_handle == stored.verification_handle
    end

    test "transitions a pending authorization to approved with subject binding" do
      now = DateTime.utc_now()
      stored = issue_device_authorization(%{now: now})

      assert {:ok, %DeviceAuthorization{} = approved} =
               Repository.transition_device_authorization(
                 stored.verification_handle,
                 [:pending],
                 %{status: :approved, subject_id: "subject_123", approved_at: now}
               )

      assert approved.id == stored.id
      assert approved.status == :approved
      assert approved.subject_id == "subject_123"
      assert approved.approved_at == now

      assert {:ok, %DeviceAuthorization{} = fetched} =
               Repository.fetch_device_authorization_by_verification_handle(
                 stored.verification_handle
               )

      assert fetched.status == :approved
      assert fetched.subject_id == "subject_123"
    end

    test "transitions a pending authorization to denied and rejects a stale approve retry" do
      now = DateTime.utc_now()
      stored = issue_device_authorization(%{now: now})

      assert {:ok, %DeviceAuthorization{} = denied} =
               Repository.transition_device_authorization(
                 stored.verification_handle,
                 [:pending],
                 %{status: :denied, denied_at: now}
               )

      assert denied.status == :denied
      assert denied.denied_at == now

      assert {:error, :invalid_state} =
               Repository.transition_device_authorization(
                 stored.verification_handle,
                 [:pending],
                 %{status: :approved, subject_id: "subject_123", approved_at: now}
               )
    end

    test "rejects duplicate approve transitions after the first approval succeeds" do
      now = DateTime.utc_now()
      stored = issue_device_authorization(%{now: now})

      assert {:ok, %DeviceAuthorization{} = approved} =
               Repository.transition_device_authorization(
                 stored.verification_handle,
                 [:pending],
                 %{status: :approved, subject_id: "subject_123", approved_at: now}
               )

      assert approved.status == :approved

      assert {:error, :invalid_state} =
               Repository.transition_device_authorization(
                 stored.verification_handle,
                 [:pending],
                 %{status: :approved, subject_id: "subject_123", approved_at: now}
               )
    end
  end
end
