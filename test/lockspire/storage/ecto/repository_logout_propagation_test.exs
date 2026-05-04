defmodule Lockspire.Storage.Ecto.RepositoryLogoutPropagationTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  @moduletag :integration

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.LogoutDelivery
  alias Lockspire.Domain.LogoutEvent
  alias Lockspire.Domain.Token
  alias Lockspire.Storage.LogoutStore
  alias Lockspire.Storage.Ecto.LogoutDeliveryRecord
  alias Lockspire.Storage.Ecto.LogoutEventRecord
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

  describe "logout domain/storage contracts" do
    test "logout events expose explicit durable protocol fields" do
      event = %LogoutEvent{
        event_id: "evt_123",
        sid: "sid_123",
        account_id: "account_123",
        subject: "subject_123",
        initiated_by: :rp_initiated_logout,
        post_logout_redirect_uri: "https://rp.example.com/logout-complete",
        frontchannel_continue_to: "/logout/continue"
      }

      assert event.event_id == "evt_123"
      assert event.initiated_by == :rp_initiated_logout
      assert event.frontchannel_continue_to == "/logout/continue"
    end

    test "logout deliveries model explicit channel and lifecycle state" do
      delivery = %LogoutDelivery{
        delivery_id: "ld_123",
        client_id: "client_123",
        channel: :backchannel,
        target_uri: "https://rp.example.com/backchannel-logout",
        session_required: true
      }

      assert delivery.status == :pending
      assert delivery.attempt_count == 0
      assert delivery.channel == :backchannel
      assert delivery.target_uri == "https://rp.example.com/backchannel-logout"
    end

    test "logout store behaviour exposes durable persistence contract" do
      callbacks = LogoutStore.behaviour_info(:callbacks)

      assert {:persist_logout_propagation, 1} in callbacks
    end
  end

  describe "persist_logout_propagation/1" do
    test "logout event and delivery records round-trip durable snapshot fields" do
      event =
        %LogoutEvent{
          event_id: "evt_record_#{System.unique_integer([:positive])}",
          sid: "sid_record_#{System.unique_integer([:positive])}",
          account_id: "account_record",
          subject: "subject_record",
          post_logout_redirect_uri: "https://rp.example.com/logout-complete",
          frontchannel_continue_to: "/logout/continue",
          completed_at: DateTime.utc_now()
        }

      assert {:ok, stored_event} =
               %LogoutEventRecord{}
               |> LogoutEventRecord.changeset(event)
               |> Lockspire.TestRepo.insert()

      stored_event = LogoutEventRecord.to_domain(stored_event)

      delivery =
        %LogoutDelivery{
          delivery_id: "ld_record_#{System.unique_integer([:positive])}",
          logout_event_id: stored_event.id,
          client_id: "client_record",
          channel: :frontchannel,
          target_uri: "https://rp.example.com/frontchannel-logout",
          session_required: true,
          rendered_at: DateTime.utc_now(),
          finalized_at: DateTime.utc_now(),
          logout_token_jti: "logout-jti-record"
        }

      assert {:ok, stored_delivery} =
               %LogoutDeliveryRecord{}
               |> LogoutDeliveryRecord.changeset(delivery)
               |> Lockspire.TestRepo.insert()

      stored_delivery = LogoutDeliveryRecord.to_domain(stored_delivery)

      assert stored_event.frontchannel_continue_to == "/logout/continue"
      assert stored_delivery.channel == :frontchannel
      assert stored_delivery.status == :pending
      assert stored_delivery.target_uri == "https://rp.example.com/frontchannel-logout"
      assert stored_delivery.session_required == true
      assert stored_delivery.logout_token_jti == "logout-jti-record"
    end

    test "logout delivery records stay redaction-safe and never persist raw logout artifacts" do
      fields = LogoutDeliveryRecord.__schema__(:fields)

      assert :logout_token_jti in fields
      refute :logout_token in fields
      refute :response_body in fields
      refute :response_headers in fields
    end

    test "stores one logout event with backchannel and frontchannel delivery rows transactionally" do
      sid = "sid_txn_#{System.unique_integer([:positive])}"

      client =
        build_client(%{
          client_id: "logout-client-#{System.unique_integer([:positive])}",
          backchannel_logout_uri: "https://rp.example.com/backchannel-logout",
          backchannel_logout_session_required: true,
          frontchannel_logout_uri: "https://rp.example.com/frontchannel-logout",
          frontchannel_logout_session_required: true
        })

      assert {:ok, _client} = Repository.register_client(client)
      assert {:ok, _} = Repository.store_token(build_token(client.client_id, sid, :refresh_token))
      assert {:ok, _} = Repository.store_token(build_token(client.client_id, sid, :access_token))

      assert {:ok, %{event: event, deliveries: deliveries}} =
               Repository.persist_logout_propagation(logout_event(sid))

      assert is_integer(event.id)
      assert is_binary(event.event_id)
      assert length(deliveries) == 2
      assert Lockspire.TestRepo.aggregate(LogoutEventRecord, :count, :id) == 1
      assert Lockspire.TestRepo.aggregate(LogoutDeliveryRecord, :count, :id) == 2
      assert Enum.all?(deliveries, &(&1.logout_event_id == event.id))
      assert Enum.map(deliveries, & &1.channel) |> Enum.sort() == [:backchannel, :frontchannel]
    end

    test "snapshots client logout URIs and session-required flags from token-linked clients before sid revocation" do
      sid = "sid_snapshot_#{System.unique_integer([:positive])}"

      assert {:ok, client} =
               build_client(%{
                 client_id: "snapshot-client-#{System.unique_integer([:positive])}",
                 backchannel_logout_uri: "https://rp.example.com/backchannel-old",
                 backchannel_logout_session_required: true,
                 frontchannel_logout_uri: "https://rp.example.com/frontchannel-old",
                 frontchannel_logout_session_required: true
               })
               |> Repository.register_client()

      assert {:ok, _} = Repository.store_token(build_token(client.client_id, sid, :refresh_token))

      assert {:ok, %{event: event}} = Repository.persist_logout_propagation(logout_event(sid))

      assert {:ok, _updated_client} =
               Repository.update_client(client, %{
                 backchannel_logout_uri: "https://rp.example.com/backchannel-new",
                 backchannel_logout_session_required: false,
                 frontchannel_logout_uri: "https://rp.example.com/frontchannel-new",
                 frontchannel_logout_session_required: false
               })

      assert {:ok, 1} = Repository.revoke_by_sid(sid)

      persisted_deliveries =
        LogoutDeliveryRecord
        |> where([delivery], delivery.logout_event_id == ^event.id)
        |> order_by([delivery], asc: delivery.channel)
        |> Lockspire.TestRepo.all()
        |> Enum.map(&LogoutDeliveryRecord.to_domain/1)

      assert [
               %LogoutDelivery{
                 channel: :backchannel,
                 target_uri: "https://rp.example.com/backchannel-old",
                 session_required: true
               },
               %LogoutDelivery{
                 channel: :frontchannel,
                 target_uri: "https://rp.example.com/frontchannel-old",
                 session_required: true
               }
             ] = persisted_deliveries
    end

    test "returns unique durable delivery identities suitable for one-job-per-delivery enqueueing" do
      sid = "sid_unique_#{System.unique_integer([:positive])}"

      clients =
        for index <- 1..2 do
          client_id = "unique-client-#{index}-#{System.unique_integer([:positive])}"

          assert {:ok, client} =
                   build_client(%{
                     client_id: client_id,
                     backchannel_logout_uri: "https://rp#{index}.example.com/backchannel",
                     frontchannel_logout_uri: "https://rp#{index}.example.com/frontchannel"
                   })
                   |> Repository.register_client()

          client
        end

      Enum.each(clients, fn client ->
        assert {:ok, _} =
                 Repository.store_token(build_token(client.client_id, sid, :refresh_token))
      end)

      assert {:ok, %{deliveries: deliveries}} =
               Repository.persist_logout_propagation(logout_event(sid))

      delivery_ids = Enum.map(deliveries, & &1.delivery_id)

      assert length(delivery_ids) == 4
      assert Enum.all?(delivery_ids, &is_binary/1)
      assert Enum.uniq(delivery_ids) == delivery_ids
    end

    test "persists only redacted delivery metadata and never the raw logout_token artifact" do
      client_id = "redacted-client-#{System.unique_integer([:positive])}"
      sid = "sid_redacted_#{System.unique_integer([:positive])}"

      assert {:ok, _client} =
               build_client(%{
                 client_id: client_id,
                 backchannel_logout_uri: "https://rp.example.com/backchannel-redacted"
               })
               |> Repository.register_client()

      assert {:ok, _} = Repository.store_token(build_token(client_id, sid, :refresh_token))

      assert {:ok, %{event: event, deliveries: [delivery]}} =
               Repository.persist_logout_propagation(logout_event(sid))

      stored_delivery =
        LogoutDeliveryRecord
        |> where([record], record.id == ^delivery.id and record.logout_event_id == ^event.id)
        |> Lockspire.TestRepo.one()

      persisted_fields = Map.from_struct(stored_delivery)

      assert delivery.logout_token_jti == nil
      refute Map.has_key?(persisted_fields, :logout_token)
      refute Map.has_key?(persisted_fields, :response_body)
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

  defp build_token(client_id, sid, token_type) do
    base = %Token{
      token_hash: "token_#{token_type}_#{System.unique_integer([:positive])}",
      token_type: token_type,
      family_id: "family_#{System.unique_integer([:positive])}",
      client_id: client_id,
      account_id: "account_123",
      sid: sid,
      scopes: ["openid"],
      expires_at: DateTime.add(DateTime.utc_now(), 86_400, :second)
    }

    base
  end

  defp logout_event(sid) do
    base = %LogoutEvent{
      sid: sid,
      account_id: "account_123",
      subject: "subject_123",
      post_logout_redirect_uri: "https://rp.example.com/logout-complete",
      frontchannel_continue_to: "/logout/continue",
      completed_at: DateTime.utc_now()
    }

    base
  end
end
