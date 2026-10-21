defmodule Lockspire.Integration.AppLifetimeManagementTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn
  import Ecto.Query

  alias Lockspire.Storage.Ecto.AuditEventRecord
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

  defp expire_app!(client_id) do
    past = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(-1, :second)

    Lockspire.TestRepo.update_all(from(c in ClientRecord, where: c.client_id == ^client_id),
      set: [client_expires_at: past]
    )
  end

  test "expired enabled app allows GET and DELETE but rejects PUT without changing state" do
    registered = register_client()
    client_id = registered["client_id"]
    rat = registered["registration_access_token"]
    expire_app!(client_id)

    Repository.put_server_policy(%{
      DcrFixtures.server_policy(%{registration_policy: :disabled})
      | registration_policy: :disabled
    })

    before = elem(Repository.fetch_client_by_id(client_id), 1)
    audit_count = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    get_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{rat}")
      |> dispatch()

    assert get_conn.status == 200

    after_get = elem(Repository.fetch_client_by_id(client_id), 1)
    assert after_get.registration_access_token_hash == before.registration_access_token_hash
    assert after_get.client_expires_at == before.client_expires_at
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == audit_count

    put_conn =
      build_conn(:put, "/register/#{client_id}", DcrFixtures.valid_metadata())
      |> put_req_header("authorization", "Bearer #{rat}")
      |> dispatch()

    assert put_conn.status == 403
    assert Jason.decode!(put_conn.resp_body)["error"] == "registration_expired"

    after_put = elem(Repository.fetch_client_by_id(client_id), 1)
    assert after_put == before

    delete_conn =
      build_conn(:delete, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{rat}")
      |> dispatch()

    assert delete_conn.status == 204
    assert {:ok, %{active: false}} = Repository.fetch_client_by_id(client_id)
  end

  test "closed intake does not block management, while disabled and stale credentials do" do
    registered = register_client()
    client_id = registered["client_id"]
    old_rat = registered["registration_access_token"]

    Repository.put_server_policy(%{
      DcrFixtures.server_policy(%{registration_policy: :disabled})
      | registration_policy: :disabled
    })

    get_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{old_rat}")
      |> dispatch()

    assert get_conn.status == 200

    put_conn =
      build_conn(:put, "/register/#{client_id}", DcrFixtures.valid_metadata())
      |> put_req_header("authorization", "Bearer #{old_rat}")
      |> dispatch()

    assert put_conn.status == 200
    rotated_rat = Jason.decode!(put_conn.resp_body)["registration_access_token"]
    refute rotated_rat == old_rat

    stale_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{old_rat}")
      |> dispatch()

    assert stale_conn.status == 401

    Repository.set_client_active(elem(Repository.fetch_client_by_id(client_id), 1), false, %{})

    disabled_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{rotated_rat}")
      |> dispatch()

    assert disabled_conn.status == 401

    disabled_put_conn =
      build_conn(:put, "/register/#{client_id}", DcrFixtures.valid_metadata())
      |> put_req_header("authorization", "Bearer #{rotated_rat}")
      |> dispatch()

    assert disabled_put_conn.status == 401

    disabled_delete_conn =
      build_conn(:delete, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{rotated_rat}")
      |> dispatch()

    assert disabled_delete_conn.status == 401
  end

  @tag :phase165_bare_bearer
  test "missing bearer stays a non-disclosing 401 challenge" do
    conns = [
      build_conn(:get, "/register/unknown"),
      build_conn(:put, "/register/unknown", DcrFixtures.valid_metadata()),
      build_conn(:delete, "/register/unknown")
    ]

    Enum.each(conns, fn conn ->
      conn = dispatch(conn)
      assert conn.status == 401

      assert get_resp_header(conn, "www-authenticate") == [
               "Bearer realm=\"Lockspire Dynamic Client Registration\""
             ]

      assert conn.resp_body == ""
    end)
  end

  test "supplied invalid management credentials keep the invalid_token challenge" do
    conn =
      build_conn(:get, "/register/unknown")
      |> put_req_header("authorization", "Bearer supplied-but-unknown")
      |> dispatch()

    assert conn.status == 401

    assert get_resp_header(conn, "www-authenticate") == [
             "Bearer realm=\"Lockspire Dynamic Client Registration\", error=\"invalid_token\""
           ]

    assert conn.resp_body == ""
  end

  test "invalid durable lifetime state is a redacted server error for every management method" do
    registered = register_client()
    client_id = registered["client_id"]
    rat = registered["registration_access_token"]

    Lockspire.TestRepo.update_all(
      from(c in ClientRecord, where: c.client_id == ^client_id),
      set: [lifetime_version: 2]
    )

    conns = [
      build_conn(:get, "/register/#{client_id}"),
      build_conn(:put, "/register/#{client_id}", DcrFixtures.valid_metadata()),
      build_conn(:delete, "/register/#{client_id}")
    ]

    Enum.each(conns, fn conn ->
      conn = conn |> put_req_header("authorization", "Bearer #{rat}") |> dispatch()
      assert conn.status == 500
      assert Jason.decode!(conn.resp_body) == %{"error" => "server_error"}
      assert get_resp_header(conn, "www-authenticate") == []
    end)
  end

  test "registration access-token lookup failures remain server errors" do
    registered = register_client()
    client_id = registered["client_id"]
    rat = registered["registration_access_token"]

    Ecto.Adapters.SQL.query!(
      Lockspire.TestRepo,
      "ALTER TABLE lockspire_clients RENAME TO lockspire_clients_unavailable",
      []
    )

    conns = [
      build_conn(:get, "/register/#{client_id}"),
      build_conn(:put, "/register/#{client_id}", DcrFixtures.valid_metadata()),
      build_conn(:delete, "/register/#{client_id}")
    ]

    Enum.each(conns, fn conn ->
      conn = conn |> put_req_header("authorization", "Bearer #{rat}") |> dispatch()
      assert conn.status == 500
      assert Jason.decode!(conn.resp_body) == %{"error" => "server_error"}
      assert get_resp_header(conn, "www-authenticate") == []
    end)
  end

  test "server policy lookup failure on PUT returns a redacted server error" do
    registered = register_client()
    client_id = registered["client_id"]
    rat = registered["registration_access_token"]

    Ecto.Adapters.SQL.query!(
      Lockspire.TestRepo,
      "ALTER TABLE lockspire_server_policies RENAME TO lockspire_server_policies_unavailable",
      []
    )

    conn =
      build_conn(:put, "/register/#{client_id}", DcrFixtures.valid_metadata())
      |> put_req_header("authorization", "Bearer #{rat}")

    result =
      try do
        dispatch(conn)
      rescue
        _error -> :raised
      end

    assert %Plug.Conn{status: 500, resp_body: body} = result
    assert Jason.decode!(body) == %{"error" => "server_error"}
    assert get_resp_header(result, "www-authenticate") == []
  end
end
