defmodule Lockspire.Web.RegistrationControllerTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["profile", "email", "openid"])

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    
    Repository.put_server_policy(%Lockspire.Domain.ServerPolicy{registration_policy: :initial_access_token})
    on_exit(fn ->
      Repository.put_server_policy(%Lockspire.Domain.ServerPolicy{registration_policy: :initial_access_token})
    end)
    :ok
  end

  defp dispatch(conn) do
    conn
    |> put_req_header("accept", "application/json")
    |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
  end

  test "returns 404 if DCR is disabled" do
    Repository.put_server_policy(%Lockspire.Domain.ServerPolicy{registration_policy: :disabled})
    conn = build_conn(:post, "/register", %{"client_name" => "Test"})
           |> dispatch()
    assert conn.status == 404
  end

  test "create responds with 201 JSON on success" do
    Repository.put_server_policy(Lockspire.Test.Fixtures.DcrFixtures.server_policy(%{registration_policy: :open}))
    conn = build_conn(:post, "/register", Lockspire.Test.Fixtures.DcrFixtures.valid_metadata())
           |> dispatch()
    assert conn.status == 201
    assert Jason.decode!(conn.resp_body)["client_id"] != nil
  end

  test "create yields 401 when IAT is invalid" do
    conn = build_conn(:post, "/register", %{"client_name" => "Test App"})
           |> put_req_header("authorization", "Bearer invalid-iat")
           |> dispatch()

    assert conn.status == 401
    assert get_resp_header(conn, "www-authenticate") == ["Bearer realm=\"Lockspire Dynamic Client Registration\", error=\"invalid_token\""]
  end

  test "show yields 401 without RAT" do
    conn = build_conn(:get, "/register/client-123")
           |> dispatch()
    assert conn.status == 401
  end

  test "update yields 401 without RAT" do
    conn = build_conn(:put, "/register/client-123", %{"client_name" => "Updated"})
           |> dispatch()
    assert conn.status == 401
  end

  test "delete yields 401 without RAT" do
    conn = build_conn(:delete, "/register/client-123")
           |> dispatch()
    assert conn.status == 401
  end
end
