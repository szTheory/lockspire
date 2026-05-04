defmodule Lockspire.Integration.Phase30DeviceAuthorizationE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint Lockspire.Web.Endpoint
  @user_code_alphabet ~r/^[BCDFGHJKLMNPQRSTVWXZ]{8}$/

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, Lockspire.Web.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false
    )

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Lockspire.Web.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "phase30-device-client",
        name: "Kitchen TV",
        client_type: :public,
        token_endpoint_auth_method: :none,
        allowed_grant_types: ["urn:ietf:params:oauth:grant-type:device_code"],
        created_at: DateTime.utc_now()
      })

    %{client: client}
  end

  test "POST /device/code returns the RFC fields, cache headers, and durably stored hashed codes",
       %{client: client} do
    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/device/code", %{"client_id" => client.client_id, "scope" => "openid profile"})

    assert conn.status == 200
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    body = Jason.decode!(conn.resp_body)

    assert Map.keys(body) |> Enum.sort() == [
             "device_code",
             "expires_in",
             "interval",
             "user_code",
             "verification_uri",
             "verification_uri_complete"
           ]

    assert is_binary(body["device_code"])
    assert Regex.match?(@user_code_alphabet, body["user_code"])
    assert body["expires_in"] == 300
    assert body["interval"] == 5
    assert body["verification_uri"] == "https://example.test/verify"

    assert body["verification_uri_complete"] ==
             "#{body["verification_uri"]}?user_code=#{body["user_code"]}"

    device_code_hash = Policy.hash_token(body["device_code"])

    assert {:ok, authorization} =
             Repository.fetch_device_authorization_by_device_code_hash(device_code_hash)

    assert authorization.client_id == client.client_id
    assert authorization.scopes == ["openid", "profile"]
    assert authorization.status == :pending
    assert authorization.device_code == nil
    assert authorization.user_code == nil
    assert authorization.device_code_hash == device_code_hash
    assert authorization.user_code_hash == DeviceAuthorization.hash_user_code(body["user_code"])
    assert authorization.effective_poll_interval_seconds == 5

    assert DateTime.diff(authorization.expires_at, authorization.next_poll_allowed_at, :second) ==
             295
  end

  test "POST /device/code rejects missing client identity with invalid_client and cache headers" do
    conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/device/code", %{})

    assert conn.status == 401
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    assert get_resp_header(conn, "www-authenticate") == [
             "Basic realm=\"Lockspire Device Authorization Endpoint\""
           ]

    body = Jason.decode!(conn.resp_body)
    assert body["error"] == "invalid_client"
  end
end
