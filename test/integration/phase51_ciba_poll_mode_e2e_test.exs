defmodule Lockspire.Integration.Phase51CibaPollModeE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint Lockspire.Web.Endpoint

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, Lockspire.Web.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false
    )

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Lockspire.Web.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

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

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "ciba-client",
        name: "CIBA Consumer",
        client_type: :public,
        token_endpoint_auth_method: :none,
        allowed_grant_types: ["urn:openid:params:grant-type:ciba"],
        created_at: DateTime.utc_now()
      })

    %{client: client}
  end

  test "POST /bc-authorize initiates a CIBA flow", %{client: client} do
    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/bc-authorize", %{
        "client_id" => client.client_id,
        "scope" => "openid profile",
        "login_hint" => "user@example.com",
        "binding_message" => "Confirm login"
      })

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)

    assert is_binary(body["auth_req_id"])
    assert body["expires_in"] == 600
    assert body["interval"] == 5

    # Verify discovery advertises the endpoint
    conn = build_conn() |> get("/.well-known/openid-configuration")
    assert conn.status == 200
    discovery = Jason.decode!(conn.resp_body)

    assert discovery["backchannel_authentication_endpoint"] ==
             "https://example.test/lockspire/bc-authorize"

    assert discovery["backchannel_token_delivery_modes_supported"] == ["poll", "ping", "push"]
  end

  test "CIBA Poll Mode full lifecycle", %{client: client} do
    # 1. Initiation
    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/bc-authorize", %{
        "client_id" => client.client_id,
        "scope" => "openid profile",
        "login_hint" => "user@example.com"
      })

    assert conn.status == 200
    %{"auth_req_id" => auth_req_id, "interval" => interval} = Jason.decode!(conn.resp_body)
    assert interval == 5

    # 2. Polling too early (slow_down)
    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/token", %{
        "grant_type" => "urn:openid:params:grant-type:ciba",
        "client_id" => client.client_id,
        "auth_req_id" => auth_req_id
      })

    assert conn.status == 400
    assert %{"error" => "slow_down"} = Jason.decode!(conn.resp_body)

    # 3. Polling while pending
    auth_req_id_hash = Lockspire.Security.Policy.hash_token(auth_req_id)

    # Manually move next_poll_allowed_at to the past to allow polling
    Lockspire.TestRepo.query!(
      "UPDATE lockspire_ciba_authorizations SET next_poll_allowed_at = $1 WHERE auth_req_id_hash = $2",
      [DateTime.add(DateTime.utc_now(), -1, :second), auth_req_id_hash]
    )

    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/token", %{
        "grant_type" => "urn:openid:params:grant-type:ciba",
        "client_id" => client.client_id,
        "auth_req_id" => auth_req_id
      })

    assert conn.status == 400
    assert %{"error" => "authorization_pending"} = Jason.decode!(conn.resp_body)

    # 4. Simulate approval
    Lockspire.TestRepo.query!(
      "UPDATE lockspire_ciba_authorizations SET status = 'approved', approved_at = $1 WHERE auth_req_id_hash = $2",
      [DateTime.utc_now(), auth_req_id_hash]
    )

    # 5. Polling after approval (Success)
    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/token", %{
        "grant_type" => "urn:openid:params:grant-type:ciba",
        "client_id" => client.client_id,
        "auth_req_id" => auth_req_id
      })

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert is_binary(body["access_token"])
    assert body["token_type"] == "Bearer"

    # 6. Polling after consumption (invalid_grant)
    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/token", %{
        "grant_type" => "urn:openid:params:grant-type:ciba",
        "client_id" => client.client_id,
        "auth_req_id" => auth_req_id
      })

    assert conn.status == 400
    assert %{"error" => "invalid_grant"} = Jason.decode!(conn.resp_body)
  end
end
