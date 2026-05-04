defmodule Lockspire.Workers.BackchannelLogoutDeliveryWorkerTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  @moduletag :integration

  alias Lockspire.Audit.Event
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.LogoutDelivery
  alias Lockspire.Domain.LogoutEvent
  alias Lockspire.Domain.SigningKey
  alias Lockspire.JarTestHelpers
  alias Lockspire.Observability
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.LogoutDeliveryRecord
  alias Lockspire.Storage.Ecto.LogoutEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Workers.BackchannelLogoutDeliveryWorker

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup context do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Req.Test.verify_on_exit!(context)
    Req.Test.set_req_test_from_context(context)

    original_req_opts = Application.get_env(:lockspire, :backchannel_logout_req)
    handler_id = "logout-delivery-worker-test-#{System.unique_integer([:positive])}"

    on_exit(fn ->
      if is_nil(original_req_opts) do
        Application.delete_env(:lockspire, :backchannel_logout_req)
      else
        Application.put_env(:lockspire, :backchannel_logout_req, original_req_opts)
      end

      :telemetry.detach(handler_id)
    end)

    :telemetry.attach_many(
      handler_id,
      Enum.flat_map(Observability.logout_lifecycle_events(), fn event_name ->
        [
          [:lockspire, event_name],
          [:lockspire, :audit, event_name]
        ]
      end),
      fn event, measurements, metadata, pid ->
        send(pid, {:telemetry_event, event, measurements, metadata})
      end,
      self()
    )

    {:ok, handler_id: handler_id}
  end

  describe "perform/1" do
    test "POSTs the logout_token to the persisted backchannel_logout_uri for the delivery row" do
      owner = self()
      %{delivery: delivery} = create_delivery_fixture()

      Req.Test.expect(:logout_delivery, fn conn ->
        assert conn.host == "snapshot.example.com"
        assert conn.request_path == "/backchannel-logout"
        assert conn.method == "POST"
        assert conn.body_params["logout_token"]

        claims = decode_unverified_claims(conn.body_params["logout_token"])
        send(owner, {:logout_claims, claims})

        Plug.Conn.send_resp(conn, 200, "")
      end)

      Application.put_env(:lockspire, :backchannel_logout_req,
        plug: {Req.Test, :logout_delivery},
        retry: false
      )

      assert :ok =
               BackchannelLogoutDeliveryWorker.perform(%Oban.Job{
                 args: %{"logout_delivery_id" => delivery.id}
               })

      assert_receive {:logout_claims, claims}
      assert claims["aud"] == delivery.client_id
      assert claims["sid"] == "sid-123"

      stored_delivery = fetch_delivery!(delivery.id)

      assert stored_delivery.target_uri == "https://snapshot.example.com/backchannel-logout"
      assert stored_delivery.status == :succeeded
      assert stored_delivery.attempt_count == 1
      assert stored_delivery.http_status == 200
      assert is_binary(stored_delivery.logout_token_jti)
      assert %DateTime{} = stored_delivery.last_attempted_at
      assert %DateTime{} = stored_delivery.delivered_at
      assert %DateTime{} = stored_delivery.finalized_at

      assert_receive {:telemetry_event, [:lockspire, :logout_delivery_attempted], %{count: 1},
                      attempted_metadata}

      assert attempted_metadata.logout_delivery_id == delivery.id
      refute Map.has_key?(attempted_metadata, :logout_token)

      assert_receive {:telemetry_event, [:lockspire, :logout_delivery_succeeded], %{count: 1},
                      succeeded_metadata}

      assert succeeded_metadata.http_status == 200
      assert succeeded_metadata.logout_token_jti == stored_delivery.logout_token_jti
      refute Map.has_key?(succeeded_metadata, :logout_token)
      refute Map.has_key?(succeeded_metadata, :response_body)

      assert latest_audit!("logout_delivery_attempted").resource_id ==
               Integer.to_string(delivery.id)

      assert %AuditEventRecord{} = success_audit = latest_audit!("logout_delivery_succeeded")
      assert success_audit.resource_id == Integer.to_string(delivery.id)
      assert success_audit.outcome == "succeeded"
      refute Map.has_key?(success_audit.metadata, "logout_token")
      refute Map.has_key?(success_audit.metadata, "response_body")
    end

    test "marks transient network or 5xx failures retryable while keeping the delivery pending for later attempts" do
      %{delivery: delivery} = create_delivery_fixture()

      Req.Test.expect(:logout_delivery, fn conn ->
        Req.Test.transport_error(conn, :timeout)
      end)

      Application.put_env(:lockspire, :backchannel_logout_req,
        plug: {Req.Test, :logout_delivery},
        retry: false
      )

      assert {:error, {:request_failed, :timeout}} =
               BackchannelLogoutDeliveryWorker.perform(%Oban.Job{
                 args: %{"logout_delivery_id" => delivery.id}
               })

      stored_delivery = fetch_delivery!(delivery.id)

      assert stored_delivery.status == :retryable
      assert stored_delivery.attempt_count == 1
      assert stored_delivery.failure_reason == "request_failed:timeout"
      assert %DateTime{} = stored_delivery.last_attempted_at
      assert is_nil(stored_delivery.delivered_at)
      assert is_nil(stored_delivery.finalized_at)

      assert_receive {:telemetry_event, [:lockspire, :logout_delivery_failed], %{count: 1},
                      failed_metadata}

      assert failed_metadata.failure_reason == "request_failed:timeout"
      refute Map.has_key?(failed_metadata, :logout_token)

      assert %AuditEventRecord{} = failed_audit = latest_audit!("logout_delivery_failed")
      assert failed_audit.outcome == "failed"
      assert failed_audit.metadata["failure_reason"] == "request_failed:timeout"
    end

    test "converges repeated 4xx or invalid client configuration failures to a terminal discarded state" do
      %{delivery: delivery} = create_delivery_fixture()

      Req.Test.expect(:logout_delivery, fn conn ->
        Plug.Conn.send_resp(conn, 400, "bad logout token")
      end)

      Application.put_env(:lockspire, :backchannel_logout_req,
        plug: {Req.Test, :logout_delivery},
        retry: false
      )

      assert {:discard, {:http_error, 400}} =
               BackchannelLogoutDeliveryWorker.perform(%Oban.Job{
                 args: %{"logout_delivery_id" => delivery.id}
               })

      stored_delivery = fetch_delivery!(delivery.id)

      assert stored_delivery.status == :discarded
      assert stored_delivery.attempt_count == 1
      assert stored_delivery.http_status == 400
      assert stored_delivery.failure_reason == "http_error:400"
      assert %DateTime{} = stored_delivery.last_attempted_at
      assert %DateTime{} = stored_delivery.finalized_at

      assert_receive {:telemetry_event, [:lockspire, :logout_delivery_discarded], %{count: 1},
                      discarded_metadata}

      assert discarded_metadata.http_status == 400
      refute Map.has_key?(discarded_metadata, :logout_token)

      assert %AuditEventRecord{} = discarded_audit = latest_audit!("logout_delivery_discarded")
      assert discarded_audit.outcome == "discarded"
      assert discarded_audit.metadata["http_status"] == 400
    end

    test "records attempted and succeeded as separate durable/auditable transitions" do
      %{delivery: delivery} = create_delivery_fixture()

      Application.put_env(:lockspire, :backchannel_logout_req,
        plug: fn conn -> Plug.Conn.send_resp(conn, 204, "") end,
        retry: false
      )

      assert :ok =
               BackchannelLogoutDeliveryWorker.perform(%Oban.Job{
                 args: %{"logout_delivery_id" => delivery.id}
               })

      stored_delivery = fetch_delivery!(delivery.id)

      assert stored_delivery.attempt_count == 1
      assert %DateTime{} = stored_delivery.last_attempted_at
      assert %DateTime{} = stored_delivery.delivered_at
      assert stored_delivery.last_attempted_at <= stored_delivery.delivered_at
    end

    test "defines requested and enqueued lifecycle stages with redaction-safe metadata" do
      assert Observability.logout_event_name!(:requested) == :logout_requested
      assert Observability.logout_event_name!(:delivery_enqueued) == :logout_delivery_enqueued

      Observability.emit_logout(:requested, %{}, %{
        logout_event_id: "evt-requested",
        logout_token: "secret-logout-token",
        response_body: "should-drop"
      })

      Observability.emit_logout(:delivery_enqueued, %{}, %{
        logout_delivery_id: 123,
        logout_token: "secret-logout-token",
        response_body: "should-drop"
      })

      assert_receive {:telemetry_event, [:lockspire, :logout_requested], %{count: 1},
                      requested_metadata}

      refute Map.has_key?(requested_metadata, :logout_token)
      refute Map.has_key?(requested_metadata, :response_body)

      assert_receive {:telemetry_event, [:lockspire, :logout_delivery_enqueued], %{count: 1},
                      enqueued_metadata}

      refute Map.has_key?(enqueued_metadata, :logout_token)
      refute Map.has_key?(enqueued_metadata, :response_body)

      requested_audit =
        Event.logout_lifecycle(:requested, %{
          logout_event_id: "evt-requested",
          logout_token: "secret-logout-token",
          response_body: "should-drop"
        })

      assert requested_audit.action == "logout_requested"
      refute Map.has_key?(requested_audit.metadata, "logout_token")
      refute Map.has_key?(requested_audit.metadata, "response_body")
    end

    test "redacts raw logout_token and response body material from logs, telemetry, and failure metadata" do
      %{delivery: delivery} = create_delivery_fixture()

      Req.Test.expect(:logout_delivery, fn conn ->
        Plug.Conn.send_resp(conn, 500, "upstream body should not persist")
      end)

      Application.put_env(:lockspire, :backchannel_logout_req,
        plug: {Req.Test, :logout_delivery},
        retry: false
      )

      assert {:error, {:http_error, 500}} =
               BackchannelLogoutDeliveryWorker.perform(%Oban.Job{
                 args: %{"logout_delivery_id" => delivery.id}
               })

      stored_delivery = fetch_delivery!(delivery.id)

      assert stored_delivery.failure_reason == "http_error:500"
      refute Map.has_key?(Map.from_struct(stored_delivery), :logout_token)
      refute Map.has_key?(Map.from_struct(stored_delivery), :response_body)

      assert_receive {:telemetry_event, [:lockspire, :logout_delivery_failed], %{count: 1},
                      failed_metadata}

      refute Map.has_key?(failed_metadata, :logout_token)
      refute Map.has_key?(failed_metadata, :response_body)

      assert %AuditEventRecord{} = failed_audit = latest_audit!("logout_delivery_failed")
      refute Map.has_key?(failed_audit.metadata, "logout_token")
      refute Map.has_key?(failed_audit.metadata, "response_body")
    end
  end

  defp create_delivery_fixture do
    keys = JarTestHelpers.generate_keys()
    now = DateTime.utc_now()

    assert {:ok, _client} =
             Repository.register_client(%Client{
               client_id: "client-123",
               client_secret_hash: "sha256:test:hash",
               client_type: :confidential,
               name: "Snapshot RP",
               redirect_uris: ["https://rp.example.com/callback"],
               allowed_scopes: ["openid"],
               allowed_grant_types: ["authorization_code", "refresh_token"],
               allowed_response_types: ["code"],
               token_endpoint_auth_method: :client_secret_basic,
               subject_type: :public,
               backchannel_logout_uri: "https://current.example.com/changed"
             })

    assert {:ok, _key} =
             Repository.publish_key(%SigningKey{
               kid: "kid-123",
               kty: :RSA,
               alg: "RS256",
               use: :sig,
               public_jwk: Map.put(keys.pub_jwk_map, "kid", "kid-123"),
               private_jwk_encrypted: Jason.encode!(Map.put(keys.priv_jwk_map, "kid", "kid-123")),
               status: :active,
               published_at: now,
               activated_at: now
             })

    assert {:ok, event_record} =
             %LogoutEventRecord{}
             |> LogoutEventRecord.changeset(%LogoutEvent{
               event_id: "evt-123",
               sid: "sid-123",
               subject: "subject-123",
               completed_at: now
             })
             |> Lockspire.TestRepo.insert()

    assert {:ok, delivery_record} =
             %LogoutDeliveryRecord{}
             |> LogoutDeliveryRecord.changeset(%LogoutDelivery{
               delivery_id: "delivery-123",
               logout_event_id: event_record.id,
               client_id: "client-123",
               channel: :backchannel,
               target_uri: "https://snapshot.example.com/backchannel-logout",
               session_required: true
             })
             |> Lockspire.TestRepo.insert()

    %{delivery: LogoutDeliveryRecord.to_domain(delivery_record), keys: keys}
  end

  defp fetch_delivery!(delivery_id) do
    LogoutDeliveryRecord
    |> where([delivery], delivery.id == ^delivery_id)
    |> Lockspire.TestRepo.one!()
    |> LogoutDeliveryRecord.to_domain()
  end

  defp decode_unverified_claims(jwt) do
    %JOSE.JWT{fields: claims} = JOSE.JWT.peek_payload(jwt)
    claims
  end

  defp latest_audit!(action) do
    AuditEventRecord
    |> where([audit], audit.action == ^action)
    |> order_by([audit], desc: audit.inserted_at, desc: audit.id)
    |> limit(1)
    |> Lockspire.TestRepo.one!()
  end
end
