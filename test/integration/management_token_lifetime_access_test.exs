defmodule Lockspire.Integration.ManagementTokenLifetimeAccessTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn
  import Ecto.Query

  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Test.Fixtures.DcrFixtures

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "email", "profile"])
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Repository.put_server_policy(DcrFixtures.server_policy(%{registration_policy: :open}))
    :ok
  end

  defp dispatch(conn) do
    conn
    |> put_req_header("accept", "application/json")
    |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
  end

  defp register_client do
    conn =
      build_conn(:post, "/register", DcrFixtures.valid_metadata())
      |> dispatch()

    assert conn.status == 201
    Jason.decode!(conn.resp_body)
  end

  defp set_management_deadline!(client_id, deadline) do
    Lockspire.TestRepo.update_all(
      from(c in ClientRecord, where: c.client_id == ^client_id),
      set: [lifetime_version: 1, registration_access_token_expires_at: deadline]
    )
  end

  @tag :management_expiry
  test "GET rejects a persisted management token after its stored deadline" do
    registered = register_client()
    client_id = registered["client_id"]
    rat = registered["registration_access_token"]

    deadline = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(-1, :second)
    set_management_deadline!(client_id, deadline)

    conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{rat}")
      |> dispatch()

    assert conn.status == 401
    assert get_resp_header(conn, "www-authenticate") == [
             "Bearer realm=\"Lockspire Dynamic Client Registration\", error=\"invalid_token\""
           ]
  end

  test "GET returns server-owned deadlines without disclosing credentials" do
    registered = register_client()
    client_id = registered["client_id"]
    rat = registered["registration_access_token"]
    deadline = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(3_600, :second)
    set_management_deadline!(client_id, deadline)

    conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{rat}")
      |> dispatch()

    assert conn.status == 200
    payload = Jason.decode!(conn.resp_body)
    assert payload["lockspire_client_expires_at"] == 0
    assert payload["lockspire_registration_access_token_expires_at"] == DateTime.to_unix(deadline)
    refute Map.has_key?(payload, "registration_access_token")
    refute Map.has_key?(payload, "client_secret")
  end
end
