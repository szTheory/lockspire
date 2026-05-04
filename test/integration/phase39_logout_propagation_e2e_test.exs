defmodule Lockspire.Integration.Phase39LogoutPropagationE2ETest do
  use ExUnit.Case, async: false

  import Ecto.Query
  import Phoenix.ConnTest

  @moduletag :integration

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.JarTestHelpers
  alias Lockspire.Storage.Ecto.LogoutDeliveryRecord
  alias Lockspire.Storage.Ecto.LogoutEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.SigningKeyRecord
  alias Lockspire.Storage.Ecto.TokenRecord
  alias Lockspire.Workers.BackchannelLogoutDeliveryWorker
  alias Oban.Job

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Lockspire.Web.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup context do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, {:shared, self()})
    Req.Test.verify_on_exit!(context)
    Req.Test.set_req_test_from_context(context)

    original_req_opts = Application.get_env(:lockspire, :backchannel_logout_req)

    on_exit(fn ->
      if is_nil(original_req_opts) do
        Application.delete_env(:lockspire, :backchannel_logout_req)
      else
        Application.put_env(:lockspire, :backchannel_logout_req, original_req_opts)
      end

      Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    end)

    publish_signing_key("phase39-e2e-kid")

    :ok
  end

  describe "RP logout propagation end-to-end" do
    test "host logout completion persists the logout event, enqueues backchannel delivery, and renders frontchannel iframe targets" do
      sid = "phase39-sid-#{System.unique_integer([:positive])}"
      event_id = "phase39-event-#{System.unique_integer([:positive])}"

      client =
        register_client!(
          client_id: "phase39-client-#{System.unique_integer([:positive])}",
          backchannel_logout_uri: "https://rp.example.com/backchannel-logout",
          backchannel_logout_session_required: true,
          frontchannel_logout_uri: "https://rp.example.com/frontchannel-logout",
          frontchannel_logout_session_required: true
        )

      store_session_tokens(client.client_id, sid)

      conn =
        build_conn(:get, "/end_session/complete", %{"token" => completion_token(event_id, sid)})
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status == 200
      assert conn.resp_body =~ "Signing you out of connected apps"
      assert conn.resp_body =~ "best effort"
      assert conn.resp_body =~ ~s(name="lockspire-frontchannel-logout")

      assert conn.resp_body =~
               ~s(src="https://rp.example.com/frontchannel-logout?iss=https%3A%2F%2Fexample.test%2Flockspire&amp;sid=#{sid}")

      assert conn.resp_body =~ "Continue"
      assert conn.resp_body =~ ~s(href="https://rp.example.com/logged-out")

      persisted_event = fetch_event!(event_id)
      persisted_deliveries = fetch_deliveries!(persisted_event.id)

      assert Enum.map(persisted_deliveries, & &1.channel) == [:backchannel, :frontchannel]
      assert Enum.find(persisted_deliveries, &(&1.channel == :backchannel)).status == :enqueued
      assert Enum.find(persisted_deliveries, &(&1.channel == :frontchannel)).status == :rendered
      assert Lockspire.TestRepo.aggregate(Job, :count, :id) == 1

      revoked_count =
        TokenRecord
        |> where([token], token.sid == ^sid and not is_nil(token.revoked_at))
        |> Lockspire.TestRepo.aggregate(:count, :id)

      assert revoked_count == 2
    end

    test "draining the logout queue updates delivery outcomes without changing the already-rendered frontchannel truth model" do
      sid = "phase39-drain-sid-#{System.unique_integer([:positive])}"
      event_id = "phase39-drain-event-#{System.unique_integer([:positive])}"
      owner = self()

      client =
        register_client!(
          client_id: "phase39-drain-client-#{System.unique_integer([:positive])}",
          backchannel_logout_uri: "https://snapshot.example.com/backchannel-logout",
          backchannel_logout_session_required: true,
          frontchannel_logout_uri: "https://snapshot.example.com/frontchannel-logout",
          frontchannel_logout_session_required: true
        )

      store_session_tokens(client.client_id, sid)

      conn =
        build_conn(:get, "/end_session/complete", %{"token" => completion_token(event_id, sid)})
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status == 200
      assert conn.resp_body =~ "best effort"

      assert conn.resp_body =~
               ~s(src="https://snapshot.example.com/frontchannel-logout?iss=https%3A%2F%2Fexample.test%2Flockspire&amp;sid=#{sid}")

      persisted_event = fetch_event!(event_id)
      [backchannel_delivery, frontchannel_delivery] = fetch_deliveries!(persisted_event.id)

      Req.Test.expect(:phase39_logout_delivery, fn conn ->
        send(owner, {:backchannel_request, conn.body_params["logout_token"]})
        Plug.Conn.send_resp(conn, 200, "")
      end)

      Application.put_env(:lockspire, :backchannel_logout_req,
        plug: {Req.Test, :phase39_logout_delivery},
        retry: false
      )

      assert :ok =
               BackchannelLogoutDeliveryWorker.perform(%Oban.Job{
                 args: %{"logout_delivery_id" => backchannel_delivery.id}
               })

      assert_receive {:backchannel_request, logout_token}
      assert is_binary(logout_token)

      [updated_backchannel_delivery, updated_frontchannel_delivery] =
        fetch_deliveries!(persisted_event.id)

      assert updated_backchannel_delivery.id == backchannel_delivery.id
      assert updated_backchannel_delivery.status == :succeeded
      assert updated_frontchannel_delivery.id == frontchannel_delivery.id
      assert updated_frontchannel_delivery.status == :rendered
      assert conn.resp_body =~ "Continue"
    end

    test "repeated completion requests do not duplicate deliveries for the same logout event" do
      sid = "phase39-repeat-sid-#{System.unique_integer([:positive])}"
      event_id = "phase39-repeat-event-#{System.unique_integer([:positive])}"

      client =
        register_client!(
          client_id: "phase39-repeat-client-#{System.unique_integer([:positive])}",
          backchannel_logout_uri: "https://rp.example.com/backchannel-repeat",
          frontchannel_logout_uri: "https://rp.example.com/frontchannel-repeat"
        )

      store_session_tokens(client.client_id, sid)

      first_conn =
        build_conn(:get, "/end_session/complete", %{"token" => completion_token(event_id, sid)})
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      second_conn =
        build_conn(:get, "/end_session/complete", %{"token" => completion_token(event_id, sid)})
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert first_conn.status == 200
      assert second_conn.status == 200

      assert first_conn.resp_body =~
               ~s(src="https://rp.example.com/frontchannel-repeat?iss=https%3A%2F%2Fexample.test%2Flockspire")

      assert second_conn.resp_body =~
               ~s(src="https://rp.example.com/frontchannel-repeat?iss=https%3A%2F%2Fexample.test%2Flockspire")

      assert Lockspire.TestRepo.aggregate(LogoutEventRecord, :count, :id) == 1
      assert Lockspire.TestRepo.aggregate(LogoutDeliveryRecord, :count, :id) == 2
      assert Lockspire.TestRepo.aggregate(Job, :count, :id) == 1
    end
  end

  defp register_client!(overrides) do
    attrs = Map.new(overrides)

    %Client{
      client_id: Map.fetch!(attrs, :client_id),
      client_secret_hash: "sha256:phase39:hash",
      client_type: :confidential,
      name: "Phase 39 Client",
      redirect_uris: ["https://rp.example.com/callback"],
      post_logout_redirect_uris: ["https://rp.example.com/logged-out"],
      backchannel_logout_uri: Map.get(attrs, :backchannel_logout_uri),
      backchannel_logout_session_required:
        Map.get(attrs, :backchannel_logout_session_required, false),
      frontchannel_logout_uri: Map.get(attrs, :frontchannel_logout_uri),
      frontchannel_logout_session_required:
        Map.get(attrs, :frontchannel_logout_session_required, false),
      allowed_scopes: ["openid", "profile"],
      allowed_grant_types: ["authorization_code", "refresh_token"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      created_at: DateTime.utc_now(),
      metadata: %{}
    }
    |> Repository.register_client()
    |> then(fn {:ok, client} -> client end)
  end

  defp publish_signing_key(kid) do
    Lockspire.TestRepo.delete_all(SigningKeyRecord)

    keys = JarTestHelpers.generate_keys()
    public_jwk = JOSE.JWK.to_public_map(keys.private_jwk) |> elem(1)
    private_jwk = JOSE.JWK.to_map(keys.private_jwk) |> elem(1)

    {:ok, _stored_key} =
      Repository.publish_key(%SigningKey{
        kid: kid,
        kty: :RSA,
        alg: "RS256",
        use: :sig,
        public_jwk:
          public_jwk
          |> Map.put("kid", kid)
          |> Map.put("alg", "RS256")
          |> Map.put("use", "sig"),
        private_jwk_encrypted: Jason.encode!(Map.put(private_jwk, "kid", kid)),
        status: :active,
        published_at: DateTime.utc_now(),
        activated_at: DateTime.utc_now(),
        metadata: %{}
      })
  end

  defp store_session_tokens(client_id, sid) do
    now = DateTime.utc_now()

    assert {:ok, _refresh_token} =
             Repository.store_token(%Token{
               token_hash: "phase39-refresh-#{sid}",
               token_type: :refresh_token,
               family_id: "phase39-family-#{sid}",
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
               token_hash: "phase39-access-#{sid}",
               token_type: :access_token,
               client_id: client_id,
               account_id: "subject-123",
               sid: sid,
               scopes: ["openid", "profile"],
               issued_at: now,
               expires_at: DateTime.add(now, 3_600, :second)
             })
  end

  defp completion_token(event_id, sid) do
    Phoenix.Token.sign(Lockspire.Web.Endpoint, "lockspire_logout", %{
      event_id: event_id,
      sid: sid,
      post_logout_redirect_uri: "https://rp.example.com/logged-out",
      state: nil
    })
  end

  defp fetch_event!(event_id) do
    LogoutEventRecord
    |> where([event], event.event_id == ^event_id)
    |> Lockspire.TestRepo.one!()
  end

  defp fetch_deliveries!(logout_event_id) do
    LogoutDeliveryRecord
    |> where([delivery], delivery.logout_event_id == ^logout_event_id)
    |> order_by([delivery], asc: delivery.channel)
    |> Lockspire.TestRepo.all()
  end
end
