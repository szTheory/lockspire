defmodule Lockspire.Workers.BackchannelLogoutDeliveryWorkerTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  @moduletag :integration

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.LogoutDelivery
  alias Lockspire.Domain.LogoutEvent
  alias Lockspire.Domain.SigningKey
  alias Lockspire.JarTestHelpers
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

    on_exit(fn ->
      if is_nil(original_req_opts) do
        Application.delete_env(:lockspire, :backchannel_logout_req)
      else
        Application.put_env(:lockspire, :backchannel_logout_req, original_req_opts)
      end
    end)

    :ok
  end

  describe "perform/1" do
    test "POSTs the logout_token to the persisted backchannel_logout_uri for the delivery row" do
      owner = self()
      %{delivery: delivery, keys: keys} = create_delivery_fixture()

      Req.Test.expect(:logout_delivery, fn conn ->
        assert conn.host == "snapshot.example.com"
        assert conn.request_path == "/backchannel-logout"
        assert conn.method == "POST"
        assert conn.body_params["logout_token"]

        claims = decode_claims(conn.body_params["logout_token"], keys)
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

  defp decode_claims(jwt, keys) do
    public_jwk = JOSE.JWK.to_public(keys.private_jwk)

    assert {true, %JOSE.JWT{fields: claims}, _jws} =
             JOSE.JWT.verify_strict(public_jwk, ["RS256"], jwt)

    claims
  end
end
