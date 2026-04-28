defmodule Lockspire.Web.DeviceAuthorizationControllerTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    # Insert a public client to test the device auth flow
    {:ok, client} = Repository.register_client(%Lockspire.Domain.Client{
      client_id: "device-client-123",
      name: "Device Client",
      client_type: :public,
      token_endpoint_auth_method: :none,
      allowed_grant_types: ["urn:ietf:params:oauth:grant-type:device_code"],
      created_at: DateTime.utc_now()
    })

    {:ok, client: client}
  end

  defp dispatch(conn) do
    conn
    |> put_req_header("accept", "application/json")
    # For now, we'll route directly through the controller instead of the router
    # since router integration is Task 2. We set private maps so Phoenix.Controller
    # functions like json/2 work correctly.
    |> Map.put(:private, %{phoenix_format: "json"})
    |> Lockspire.Web.DeviceAuthorizationController.call(:create)
  end

  test "returns 200 OK with device authorization fields and proper cache headers", %{client: client} do
    conn =
      build_conn(:post, "/device/code", %{"client_id" => client.client_id})
      |> dispatch()

    assert conn.status == 200

    # Test cache headers
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    # Test JSON response fields
    body = Jason.decode!(conn.resp_body)
    assert Map.has_key?(body, "device_code")
    assert Map.has_key?(body, "user_code")
    assert Map.has_key?(body, "verification_uri")
    assert Map.has_key?(body, "verification_uri_complete")
    assert body["verification_uri_complete"] ==
             "#{body["verification_uri"]}?user_code=#{body["user_code"]}"
    assert Map.has_key?(body, "expires_in")
  end

  test "returns 401 for missing client_id" do
    conn =
      build_conn(:post, "/device/code", %{})
      |> dispatch()

    assert conn.status == 401
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]
    
    body = Jason.decode!(conn.resp_body)
    assert body["error"] == "invalid_client"
  end
end
