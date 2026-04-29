defmodule Lockspire.Protocol.LogoutPropagationTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  @moduletag :integration

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.LogoutDelivery
  alias Lockspire.Domain.Token
  alias Lockspire.Observability
  alias Lockspire.Protocol.LogoutPropagation
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.LogoutDeliveryRecord
  alias Lockspire.Storage.Ecto.LogoutEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.TokenRecord
  alias Lockspire.Workers.BackchannelLogoutDeliveryWorker
  alias Oban.Job

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    handler_id = "logout-propagation-test-#{System.unique_integer([:positive])}"

    :telemetry.attach_many(
      handler_id,
      Enum.flat_map([:requested, :delivery_enqueued], fn stage ->
        event_name = Observability.logout_event_name!(stage)
        [[:lockspire, event_name], [:lockspire, :audit, event_name]]
      end),
      fn event, measurements, metadata, pid ->
        send(pid, {:telemetry_event, event, measurements, metadata})
      end,
      self()
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    :ok
  end

  describe "complete/1" do
    test "persists logout state, enqueues backchannel delivery, and revokes sid in one completion flow" do
      sid = "sid-complete-#{System.unique_integer([:positive])}"
      event_id = "evt-complete-#{System.unique_integer([:positive])}"

      assert {:ok, client} =
               build_client(%{
                 client_id: "client-complete-#{System.unique_integer([:positive])}",
                 backchannel_logout_uri: "https://rp.example.com/backchannel-logout",
                 backchannel_logout_session_required: true,
                 frontchannel_logout_uri: "https://rp.example.com/frontchannel-logout",
                 frontchannel_logout_session_required: true
               })
               |> Repository.register_client()

      store_session_tokens(client.client_id, sid)

      assert {:ok, completed} =
               LogoutPropagation.complete(%{
                 event_id: event_id,
                 sid: sid,
                 account_id: "account-123",
                 subject: "subject-123",
                 state: "after-logout",
                 post_logout_redirect_uri: "https://rp.example.com/logged-out",
                 frontchannel_continue_to: "/signed-out"
               })

      assert completed.event.event_id == event_id
      assert completed.post_logout_redirect_uri == "https://rp.example.com/logged-out"
      assert completed.state == "after-logout"
      assert completed.frontchannel_continue_to == "/signed-out"
      assert Enum.map(completed.frontchannel_deliveries, & &1.target_uri) == [
               "https://rp.example.com/frontchannel-logout"
             ]

      assert Lockspire.TestRepo.aggregate(LogoutEventRecord, :count, :id) == 1
      assert Lockspire.TestRepo.aggregate(LogoutDeliveryRecord, :count, :id) == 2

      persisted_deliveries =
        LogoutDeliveryRecord
        |> where([delivery], delivery.logout_event_id == ^completed.event.id)
        |> order_by([delivery], asc: delivery.channel)
        |> Lockspire.TestRepo.all()
        |> Enum.map(&LogoutDeliveryRecord.to_domain/1)

      assert [
               %LogoutDelivery{
                 channel: :backchannel,
                 status: :enqueued,
                 oban_job_id: backchannel_job_id,
                 target_uri: "https://rp.example.com/backchannel-logout"
               },
               %LogoutDelivery{
                 channel: :frontchannel,
                 status: :pending,
                 oban_job_id: nil,
                 target_uri: "https://rp.example.com/frontchannel-logout"
               }
             ] = persisted_deliveries

      assert is_integer(backchannel_job_id)

      assert %Job{id: ^backchannel_job_id, worker: worker, args: %{"logout_delivery_id" => logout_delivery_id}} =
               fetch_job!(backchannel_job_id)

      assert worker == to_string(BackchannelLogoutDeliveryWorker)
      assert Enum.any?(persisted_deliveries, &(&1.id == logout_delivery_id and &1.channel == :backchannel))

      revoked_count =
        TokenRecord
        |> tokens_by_sid_query(sid)
        |> where([token], not is_nil(token.revoked_at))
        |> Lockspire.TestRepo.aggregate(:count, :id)

      assert revoked_count == 2
    end

    test "records logout requested and delivery enqueued as distinct observability and audit milestones" do
      sid = "sid-events-#{System.unique_integer([:positive])}"
      event_id = "evt-events-#{System.unique_integer([:positive])}"

      assert {:ok, client} =
               build_client(%{
                 client_id: "client-events-#{System.unique_integer([:positive])}",
                 backchannel_logout_uri: "https://rp.example.com/backchannel-events"
               })
               |> Repository.register_client()

      store_session_tokens(client.client_id, sid)

      assert {:ok, completed} =
               LogoutPropagation.complete(%{
                 event_id: event_id,
                 sid: sid,
                 account_id: "account-123",
                 subject: "subject-123"
               })

      assert_receive {:telemetry_event, [:lockspire, :logout_requested], %{count: 1},
                      requested_metadata}

      assert requested_metadata.logout_event_id == completed.event.id
      refute Map.has_key?(requested_metadata, :logout_token)

      assert_receive {:telemetry_event, [:lockspire, :logout_delivery_enqueued], %{count: 1},
                      enqueued_metadata}

      assert enqueued_metadata.logout_event_id == completed.event.id
      assert enqueued_metadata.channel == :backchannel
      refute Map.has_key?(enqueued_metadata, :logout_token)

      assert %AuditEventRecord{} = requested_audit = latest_audit!("logout_requested")
      assert requested_audit.resource_id == Integer.to_string(completed.event.id)
      assert requested_audit.outcome == "requested"

      assert %AuditEventRecord{} = enqueued_audit = latest_audit!("logout_delivery_enqueued")
      assert enqueued_audit.outcome == "enqueued"
      assert enqueued_audit.resource_id == Integer.to_string(hd(completed.deliveries).id)
    end

    test "replaying completion for the same event_id returns existing state without duplicating deliveries or jobs" do
      sid = "sid-replay-#{System.unique_integer([:positive])}"
      event_id = "evt-replay-#{System.unique_integer([:positive])}"

      assert {:ok, client} =
               build_client(%{
                 client_id: "client-replay-#{System.unique_integer([:positive])}",
                 backchannel_logout_uri: "https://rp.example.com/backchannel-replay",
                 frontchannel_logout_uri: "https://rp.example.com/frontchannel-replay"
               })
               |> Repository.register_client()

      store_session_tokens(client.client_id, sid)

      attrs = %{
        event_id: event_id,
        sid: sid,
        account_id: "account-123",
        subject: "subject-123",
        post_logout_redirect_uri: "https://rp.example.com/logged-out",
        state: "same-state",
        frontchannel_continue_to: "/signed-out"
      }

      assert {:ok, first_result} = LogoutPropagation.complete(attrs)
      assert {:ok, second_result} = LogoutPropagation.complete(attrs)

      assert second_result.event.id == first_result.event.id
      assert Enum.map(second_result.deliveries, & &1.id) == Enum.map(first_result.deliveries, & &1.id)
      assert Enum.map(second_result.frontchannel_deliveries, & &1.id) ==
               Enum.map(first_result.frontchannel_deliveries, & &1.id)

      assert Lockspire.TestRepo.aggregate(LogoutEventRecord, :count, :id) == 1
      assert Lockspire.TestRepo.aggregate(LogoutDeliveryRecord, :count, :id) == 2
      assert Lockspire.TestRepo.aggregate(Job, :count, :id) == 1

      assert Lockspire.TestRepo.aggregate(
               from(a in AuditEventRecord, where: a.action == "logout_requested"),
               :count,
               :id
             ) == 1

      assert Lockspire.TestRepo.aggregate(
               from(a in AuditEventRecord, where: a.action == "logout_delivery_enqueued"),
               :count,
               :id
             ) == 1
    end
  end

  defp build_client(overrides) do
    base = %Client{
      client_id: "client-#{System.unique_integer([:positive])}",
      client_secret_hash: "sha256:test:hash",
      client_type: :confidential,
      name: "Logout RP",
      redirect_uris: ["https://rp.example.com/callback"],
      allowed_scopes: ["openid", "profile"],
      allowed_grant_types: ["authorization_code", "refresh_token"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      subject_type: :public
    }

    struct!(base, overrides)
  end

  defp store_session_tokens(client_id, sid) do
    now = DateTime.utc_now()

    assert {:ok, refresh_token} =
             Repository.store_token(%Token{
               token_hash: "refresh-#{sid}",
               token_type: :refresh_token,
               family_id: "family-#{sid}",
               generation: 0,
               client_id: client_id,
               account_id: "subject-123",
               sid: sid,
               scopes: ["offline_access"],
               issued_at: now,
               expires_at: DateTime.add(now, 86_400, :second)
             })

    assert {:ok, _access_token} =
             Repository.store_token(%Token{
               token_hash: "access-#{sid}",
               token_type: :access_token,
               family_id: "family-#{sid}",
               generation: 1,
               parent_token_id: refresh_token.id,
               client_id: client_id,
               account_id: "subject-123",
               sid: sid,
               scopes: ["openid"],
               issued_at: DateTime.add(now, 5, :second),
               expires_at: DateTime.add(now, 3600, :second)
             })
  end

  defp tokens_by_sid_query(queryable, sid) do
    from(token in queryable, where: token.sid == ^sid)
  end

  defp fetch_job!(job_id) do
    Lockspire.TestRepo.get!(Job, job_id)
  end

  defp latest_audit!(action) do
    AuditEventRecord
    |> where([record], record.action == ^action)
    |> order_by([record], desc: record.inserted_at, desc: record.id)
    |> limit(1)
    |> Lockspire.TestRepo.one!()
  end
end
