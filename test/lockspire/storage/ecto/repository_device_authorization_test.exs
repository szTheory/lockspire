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

  defp fetch_by_verification_handle!(verification_handle) do
    assert {:ok, %DeviceAuthorization{} = authorization} =
             Repository.fetch_device_authorization_by_verification_handle(verification_handle)

    authorization
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

    test "fetches a pending authorization by device code hash" do
      stored = issue_device_authorization(%{device_code: "device-poll-code"})

      assert {:ok, %DeviceAuthorization{} = fetched} =
               Repository.fetch_device_authorization_by_device_code_hash(
                 stored.device_code_hash
               )

      assert fetched.id == stored.id
      assert fetched.client_id == stored.client_id
      assert fetched.effective_poll_interval_seconds == 5
      assert fetched.next_poll_allowed_at == stored.next_poll_allowed_at
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

  describe "device polling and consume semantics" do
    test "returns slow_down for too-early polls and widens the interval durably by five seconds" do
      now = DateTime.utc_now()
      stored = issue_device_authorization(%{now: now})

      assert {:ok,
              %{
                result: :slow_down,
                effective_poll_interval_seconds: 10,
                device_authorization: %DeviceAuthorization{} = slowed
              }} =
               Repository.record_device_poll(
                 stored.device_code_hash,
                 stored.client_id,
                 DateTime.add(now, 2, :second)
               )

      assert slowed.id == stored.id
      assert slowed.effective_poll_interval_seconds == 10
      assert DateTime.diff(slowed.next_poll_allowed_at, stored.next_poll_allowed_at, :second) == 10

      persisted = fetch_by_verification_handle!(stored.verification_handle)
      assert persisted.effective_poll_interval_seconds == 10
      assert persisted.next_poll_allowed_at == slowed.next_poll_allowed_at
    end

    test "keeps widening the interval by five seconds on repeated early polls" do
      now = DateTime.utc_now()
      stored = issue_device_authorization(%{now: now})

      assert {:ok, %{result: :slow_down, effective_poll_interval_seconds: 10}} =
               Repository.record_device_poll(
                 stored.device_code_hash,
                 stored.client_id,
                 DateTime.add(now, 2, :second)
               )

      assert {:ok,
              %{
                result: :slow_down,
                effective_poll_interval_seconds: 15,
                device_authorization: %DeviceAuthorization{} = slowed_again
              }} =
               Repository.record_device_poll(
                 stored.device_code_hash,
                 stored.client_id,
                 DateTime.add(now, 4, :second)
               )

      assert slowed_again.effective_poll_interval_seconds == 15
    end

    test "returns pending for compliant polls and advances the next allowed poll window" do
      now = DateTime.utc_now()
      stored = issue_device_authorization(%{now: now})

      assert {:ok,
              %{
                result: :pending,
                device_authorization: %DeviceAuthorization{} = pending
              }} =
               Repository.record_device_poll(
                 stored.device_code_hash,
                 stored.client_id,
                 stored.next_poll_allowed_at
               )

      assert pending.id == stored.id
      assert pending.effective_poll_interval_seconds == 5
      assert DateTime.diff(pending.next_poll_allowed_at, stored.next_poll_allowed_at, :second) == 5

      persisted = fetch_by_verification_handle!(stored.verification_handle)
      assert persisted.effective_poll_interval_seconds == 5
      assert persisted.next_poll_allowed_at == pending.next_poll_allowed_at
    end

    test "enforces the advanced poll window after a compliant pending poll" do
      now = DateTime.utc_now()
      stored = issue_device_authorization(%{now: now})

      assert {:ok,
              %{
                result: :pending,
                device_authorization: %DeviceAuthorization{} = pending
              }} =
               Repository.record_device_poll(
                 stored.device_code_hash,
                 stored.client_id,
                 stored.next_poll_allowed_at
               )

      assert {:ok, %{result: :slow_down, effective_poll_interval_seconds: 10}} =
               Repository.record_device_poll(
                 stored.device_code_hash,
                 stored.client_id,
                 DateTime.add(pending.next_poll_allowed_at, -1, :second)
               )
    end

    test "returns a typed client mismatch outcome without exposing another record" do
      stored = issue_device_authorization()

      assert {:ok, %{result: :client_mismatch}} =
               Repository.record_device_poll(
                 stored.device_code_hash,
                 "other_client",
                 DateTime.add(stored.next_poll_allowed_at, 1, :second)
               )
    end

    test "classifies denied, expired, and consumed rows as terminal polling outcomes" do
      now = DateTime.utc_now()
      denied = issue_device_authorization(%{device_code: "denied-device", user_code: "DENY-CODE"})

      assert {:ok, %DeviceAuthorization{}} =
               Repository.transition_device_authorization(
                 denied.verification_handle,
                 [:pending],
                 %{status: :denied, denied_at: now}
               )

      expired = issue_device_authorization(%{device_code: "expired-device", user_code: "EXPR-CODE"})

      assert {:ok, %DeviceAuthorization{}} =
               Repository.transition_device_authorization(
                 expired.verification_handle,
                 [:pending],
                 %{status: :expired, expired_at: now}
               )

      consumed =
        issue_device_authorization(%{device_code: "consumed-device", user_code: "USED-CODE"})

      assert {:ok, %DeviceAuthorization{}} =
               Repository.transition_device_authorization(
                 consumed.verification_handle,
                 [:pending],
                 %{status: :approved, subject_id: "subject_123", approved_at: now}
               )

      assert {:ok, %DeviceAuthorization{}} =
               Repository.consume_device_authorization(
                 consumed.verification_handle,
                 consumed.client_id,
                 now
               )

      assert {:ok, %{result: :denied}} =
               Repository.record_device_poll(denied.device_code_hash, denied.client_id, now)

      assert {:ok, %{result: :expired}} =
               Repository.record_device_poll(expired.device_code_hash, expired.client_id, now)

      assert {:ok, %{result: :consumed}} =
               Repository.record_device_poll(consumed.device_code_hash, consumed.client_id, now)
    end

    test "returns approved_ready for approved rows until consume wins" do
      now = DateTime.utc_now()
      stored = issue_device_authorization(%{now: now})

      assert {:ok, %DeviceAuthorization{} = approved} =
               Repository.transition_device_authorization(
                 stored.verification_handle,
                 [:pending],
                 %{status: :approved, subject_id: "subject_123", approved_at: now}
               )

      assert {:ok,
              %{
                result: :approved_ready,
                device_authorization: %DeviceAuthorization{} = ready
              }} =
               Repository.record_device_poll(
                 stored.device_code_hash,
                 stored.client_id,
                 DateTime.add(now, 10, :second)
               )

      assert ready.id == approved.id
      assert ready.status == :approved
      assert is_nil(ready.consumed_at)
    end

    test "expires approved rows before redemption after ttl elapses" do
      now = DateTime.utc_now()
      issued_at = DateTime.add(now, -310, :second)
      stored = issue_device_authorization(%{now: issued_at})

      assert {:ok, %DeviceAuthorization{} = approved} =
               Repository.transition_device_authorization(
                 stored.verification_handle,
                 [:pending],
                 %{status: :approved, subject_id: "subject_123", approved_at: issued_at}
               )

      assert {:ok,
              %{
                result: :expired,
                device_authorization: %DeviceAuthorization{} = expired
              }} =
               Repository.record_device_poll(
                 stored.device_code_hash,
                 stored.client_id,
                 now
               )

      assert expired.id == approved.id
      assert expired.status == :expired
      assert %DateTime{} = expired.expired_at

      assert {:error, :invalid_state} =
               Repository.consume_device_authorization(
                 approved.verification_handle,
                 approved.client_id,
                 now
               )
    end

    test "consume can win only once from approved to consumed" do
      now = DateTime.utc_now()
      stored = issue_device_authorization(%{now: now})

      assert {:ok, %DeviceAuthorization{} = approved} =
               Repository.transition_device_authorization(
                 stored.verification_handle,
                 [:pending],
                 %{status: :approved, subject_id: "subject_123", approved_at: now}
               )

      assert {:ok, %DeviceAuthorization{} = consumed} =
               Repository.consume_device_authorization(
                 approved.verification_handle,
                 approved.client_id,
                 DateTime.add(now, 1, :second)
               )

      assert consumed.status == :consumed
      assert %DateTime{} = consumed.consumed_at

      persisted = fetch_by_verification_handle!(stored.verification_handle)
      assert persisted.status == :consumed
      assert persisted.consumed_at == consumed.consumed_at

      assert {:error, :invalid_state} =
               Repository.consume_device_authorization(
                 approved.verification_handle,
                 approved.client_id,
                 DateTime.add(now, 2, :second)
               )
    end
  end
end
