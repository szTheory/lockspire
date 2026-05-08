defmodule Lockspire.Integration.Phase53CibaDeliveryModesE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint Lockspire.Web.Endpoint

  import Phoenix.ConnTest
  import Plug.Conn
  use Oban.Testing, repo: Lockspire.TestRepo, name: Lockspire.Oban

  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Workers.CibaNotificationWorker

  setup_all do
    Application.put_env(:lockspire, Lockspire.Web.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false
    )

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Lockspire.Web.Endpoint)

    # Oban is started by the application automatically in test mode.

    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup context do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Req.Test.verify_on_exit!(context)
    Req.Test.set_req_test_from_context(context)

    # Ensure an active signing key exists
    case Lockspire.Admin.Keys.list_keys() do
      {:ok, []} ->
        {:ok, %{key: %{id: id}}} = Lockspire.Admin.Keys.generate_key()
        {:ok, _} = Lockspire.Admin.Keys.publish_key(id)
        {:ok, _} = Lockspire.Admin.Keys.activate_key(id)

      {:ok, views} ->
        unless Enum.any?(views, &(&1.key.status == :active)) do
          id = List.first(views).key.id
          {:ok, _} = Lockspire.Admin.Keys.publish_key(id)
          {:ok, _} = Lockspire.Admin.Keys.activate_key(id)
        end

        :ok
    end

    {:ok, conn: build_conn()}
  end

  test "CIBA Ping Mode delivery", %{conn: conn} do
    client_id = "ping-client"
    notification_endpoint = "https://rp.example.test/notify"
    notification_token = "ping-token-123"

    {:ok, _client} =
      Repository.register_client(%Client{
        client_id: client_id,
        name: "Ping Mode Client",
        client_type: :public,
        token_endpoint_auth_method: :none,
        allowed_grant_types: ["urn:openid:params:grant-type:ciba"],
        backchannel_token_delivery_mode: :ping,
        backchannel_client_notification_endpoint: notification_endpoint,
        created_at: DateTime.utc_now()
      })

    # 1. Initiation
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> post("/bc-authorize", %{
        "client_id" => client_id,
        "scope" => "openid profile",
        "login_hint" => "user@example.com",
        "client_notification_token" => notification_token
      })

    assert conn.status == 200
    %{"auth_req_id" => auth_req_id} = Jason.decode!(conn.resp_body)
    auth_req_id_hash = Lockspire.Security.Policy.hash_token(auth_req_id)

    # 2. Approve authorization
    {:ok, ciba_auth} =
      Lockspire.Ciba.approve_authorization(auth_req_id_hash, "user-123", ["openid", "profile"])

    # 3. Verify Oban job enqueued
    assert_enqueued(worker: CibaNotificationWorker, args: %{ciba_authorization_id: ciba_auth.id})

    # 4. Mock RP endpoint and perform job
    Req.Test.expect(CibaNotificationWorker, fn req ->
      assert req.url.host == "rp.example.test"
      assert req.url.path == "/notify"
      assert {"authorization", "Bearer #{notification_token}"} in req.headers
      assert req.body == Jason.encode!(%{"auth_req_id" => auth_req_id})

      Req.Test.json(req, %{status: "ok"})
    end)

    Application.put_env(:lockspire, :backchannel_ciba_req,
      plug: {Req.Test, CibaNotificationWorker},
      retry: false
    )

    Oban.drain_queue(Lockspire.Oban, queue: :ciba_notification)

    # 5. Verify RP can now poll for tokens
    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/token", %{
        "grant_type" => "urn:openid:params:grant-type:ciba",
        "client_id" => client_id,
        "auth_req_id" => auth_req_id
      })

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert is_binary(body["access_token"])
  end

  test "CIBA Push Mode delivery", %{conn: conn} do
    client_id = "push-client"
    notification_endpoint = "https://rp.example.test/push"
    notification_token = "push-token-456"

    {:ok, _client} =
      Repository.register_client(%Client{
        client_id: client_id,
        name: "Push Mode Client",
        client_type: :public,
        token_endpoint_auth_method: :none,
        allowed_grant_types: ["urn:openid:params:grant-type:ciba"],
        backchannel_token_delivery_mode: :push,
        backchannel_client_notification_endpoint: notification_endpoint,
        created_at: DateTime.utc_now()
      })

    # 1. Initiation
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> post("/bc-authorize", %{
        "client_id" => client_id,
        "scope" => "openid profile",
        "login_hint" => "user@example.com",
        "client_notification_token" => notification_token
      })

    assert conn.status == 200
    %{"auth_req_id" => auth_req_id} = Jason.decode!(conn.resp_body)
    auth_req_id_hash = Lockspire.Security.Policy.hash_token(auth_req_id)

    # 2. Approve authorization
    {:ok, ciba_auth} =
      Lockspire.Ciba.approve_authorization(auth_req_id_hash, "user-456", ["openid", "profile"])

    # 3. Verify Oban job enqueued
    assert_enqueued(worker: CibaNotificationWorker, args: %{ciba_authorization_id: ciba_auth.id})

    # 4. Mock RP endpoint and perform job
    Req.Test.expect(CibaNotificationWorker, fn req ->
      assert req.url.host == "rp.example.test"
      assert req.url.path == "/push"
      assert {"authorization", "Bearer #{notification_token}"} in req.headers

      body = Jason.decode!(req.body)
      assert body["auth_req_id"] == auth_req_id
      assert is_binary(body["access_token"])
      assert is_binary(body["id_token"])
      assert body["token_type"] == "Bearer"

      Req.Test.json(req, %{status: "ok"})
    end)

    Application.put_env(:lockspire, :backchannel_ciba_req,
      plug: {Req.Test, CibaNotificationWorker},
      retry: false
    )

    Oban.drain_queue(Lockspire.Oban, queue: :ciba_notification)

    # 5. Verify authorization is now consumed
    {:ok, ciba_auth} = Repository.fetch_ciba_authorization_by_auth_req_id_hash(auth_req_id_hash)
    assert ciba_auth.status == :consumed
  end

  test "CIBA delivery fails if client_notification_token is missing for Ping/Push", %{conn: conn} do
    # Register a ping client
    client_id = "missing-token-client"

    {:ok, _client} =
      Repository.register_client(%Client{
        client_id: client_id,
        client_type: :public,
        token_endpoint_auth_method: :none,
        allowed_grant_types: ["urn:openid:params:grant-type:ciba"],
        backchannel_token_delivery_mode: :ping,
        backchannel_client_notification_endpoint: "https://example.test",
        created_at: DateTime.utc_now()
      })

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> post("/bc-authorize", %{
        "client_id" => client_id,
        "scope" => "openid profile",
        "login_hint" => "user@example.com"
        # missing client_notification_token
      })

    assert conn.status == 400

    assert %{"error" => "invalid_request", "reason_code" => "missing_client_notification_token"} =
             Jason.decode!(conn.resp_body)
  end
end
