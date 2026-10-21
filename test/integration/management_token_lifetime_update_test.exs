defmodule Lockspire.Integration.ManagementTokenLifetimeUpdateTest do
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

    Repository.put_server_policy(
      DcrFixtures.server_policy(%{
        registration_policy: :open,
        dcr_default_client_lifetime_seconds: 60,
        dcr_default_client_secret_lifetime_seconds: 10,
        dcr_default_registration_access_token_lifetime_seconds: 40
      })
    )

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

  test "PUT replaces the management deadline from current policy and invalidates the old token" do
    registered = register_client()
    client_id = registered["client_id"]
    old_rat = registered["registration_access_token"]

    issued_at = DateTime.utc_now() |> DateTime.truncate(:second)
    app_deadline = DateTime.add(issued_at, 160, :second)
    secret_deadline = DateTime.add(issued_at, 110, :second)
    prior_management_deadline = DateTime.add(issued_at, 100, :second)

    Lockspire.TestRepo.update_all(
      from(c in ClientRecord, where: c.client_id == ^client_id),
      set: [
        client_expires_at: app_deadline,
        client_secret_expires_at: secret_deadline,
        registration_access_token_expires_at: prior_management_deadline
      ]
    )

    {:ok, before} = Repository.fetch_client_by_id(client_id)
    audit_count = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    metadata =
      DcrFixtures.valid_metadata()
      |> Map.put("client_id", client_id)
      |> Map.put("lockspire_client_expires_at", DateTime.to_unix(app_deadline))
      |> Map.put(
        "lockspire_registration_access_token_expires_at",
        DateTime.to_unix(prior_management_deadline)
      )

    put_conn =
      build_conn(:put, "/register/#{client_id}", metadata)
      |> put_req_header("authorization", "Bearer #{old_rat}")
      |> dispatch()

    assert put_conn.status == 200
    response = Jason.decode!(put_conn.resp_body)
    new_rat = response["registration_access_token"]
    refute new_rat == old_rat
    refute Map.has_key?(response, "client_secret")

    {:ok, after_put} = Repository.fetch_client_by_id(client_id)
    replacement_deadline = after_put.registration_access_token_expires_at
    assert is_struct(replacement_deadline, DateTime)

    assert response["lockspire_registration_access_token_expires_at"] ==
             DateTime.to_unix(replacement_deadline)

    refute after_put.registration_access_token_hash == before.registration_access_token_hash
    assert DateTime.compare(replacement_deadline, prior_management_deadline) == :lt
    assert DateTime.compare(after_put.client_expires_at, app_deadline) == :eq
    assert DateTime.compare(after_put.client_secret_expires_at, secret_deadline) == :eq
    assert after_put.client_secret_hash == before.client_secret_hash
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == audit_count + 1

    audit =
      Lockspire.TestRepo.one!(
        from(a in AuditEventRecord,
          where: a.action == "dcr_management_updated",
          order_by: [desc: a.id],
          limit: 1
        )
      )

    assert {:ok, rotated_at, 0} = DateTime.from_iso8601(audit.metadata["rotated_at"])
    assert DateTime.compare(rotated_at, after_put.updated_at) == :eq

    stale_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{old_rat}")
      |> dispatch()

    assert stale_conn.status == 401
  end

  test "explicit v0 management replacement clears advisory dates and promotes the current row" do
    registered = register_client()
    client_id = registered["client_id"]
    old_rat = registered["registration_access_token"]
    advisory = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(-60, :second)

    Lockspire.TestRepo.update_all(
      from(c in ClientRecord, where: c.client_id == ^client_id),
      set: [
        lifetime_version: 0,
        client_expires_at: advisory,
        client_secret_expires_at: advisory,
        registration_access_token_expires_at: advisory
      ]
    )

    {:ok, before} = Repository.fetch_client_by_id(client_id)

    put_conn =
      build_conn(
        :put,
        "/register/#{client_id}",
        Map.put(DcrFixtures.valid_metadata(), "client_id", client_id)
      )
      |> put_req_header("authorization", "Bearer #{old_rat}")
      |> dispatch()

    assert put_conn.status == 200
    response = Jason.decode!(put_conn.resp_body)
    {:ok, after_put} = Repository.fetch_client_by_id(client_id)

    assert after_put.lifetime_version == 1
    assert is_nil(after_put.client_expires_at)
    assert is_nil(after_put.client_secret_expires_at)
    assert after_put.registration_access_token_expires_at
    assert DateTime.compare(after_put.registration_access_token_expires_at, advisory) == :gt
    assert response["lockspire_client_expires_at"] == 0
    assert after_put.client_secret_hash == before.client_secret_hash
    assert after_put.registration_access_token_hash != before.registration_access_token_hash
  end

  test "missing body client_id is rejected even when the URL contains the same id" do
    registered = register_client()
    client_id = registered["client_id"]
    old_rat = registered["registration_access_token"]
    {:ok, before} = Repository.fetch_client_by_id(client_id)
    audit_count = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    conn =
      build_conn(:put, "/register/#{client_id}", DcrFixtures.valid_metadata())
      |> put_req_header("authorization", "Bearer #{old_rat}")
      |> dispatch()

    assert conn.status == 400
    assert Jason.decode!(conn.resp_body)["error"] == "invalid_client_metadata"
    assert {:ok, ^before} = Repository.fetch_client_by_id(client_id)
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == audit_count
  end
end
