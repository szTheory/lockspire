defmodule Lockspire.Integration.ManagementTokenLifetimeAccessTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn
  import Ecto.Query

  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Protocol.RegistrationManagement
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

  defp set_management_deadline!(client_id, deadline, metadata \\ nil) do
    fields = [
      lifetime_version: 1,
      client_expires_at: nil,
      registration_access_token_expires_at: deadline
    ]

    fields = if metadata, do: Keyword.put(fields, :metadata, metadata), else: fields

    Lockspire.TestRepo.update_all(
      from(c in ClientRecord, where: c.client_id == ^client_id),
      set: fields
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

    assert is_integer(registered["lockspire_client_expires_at"])
    assert is_integer(registered["lockspire_registration_access_token_expires_at"])

    {:ok, issued_client} = Repository.fetch_client_by_id(client_id)

    issued_app_deadline =
      if issued_client.client_expires_at,
        do: DateTime.to_unix(issued_client.client_expires_at),
        else: 0

    issued_management_deadline =
      if issued_client.registration_access_token_expires_at,
        do: DateTime.to_unix(issued_client.registration_access_token_expires_at),
        else: 0

    assert registered["lockspire_client_expires_at"] == issued_app_deadline

    assert registered["lockspire_registration_access_token_expires_at"] ==
             issued_management_deadline

    deadline = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(3_600, :second)

    set_management_deadline!(client_id, deadline, %{
      "registration_access_token" => "forged-token",
      "registration_access_token_hash" => "forged-hash",
      "client_secret" => "forged-secret",
      "client_secret_hash" => "forged-secret-hash",
      "lockspire_client_expires_at" => 1,
      "lockspire_registration_access_token_expires_at" => 1
    })

    {:ok, before} = Repository.fetch_client_by_id(client_id)

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

    {:ok, after_future_get} = Repository.fetch_client_by_id(client_id)

    assert after_future_get.registration_access_token_hash ==
             before.registration_access_token_hash

    assert after_future_get.client_expires_at == before.client_expires_at
    assert after_future_get.client_secret_expires_at == before.client_secret_expires_at
    assert after_future_get.lifetime_version == before.lifetime_version

    assert after_future_get.registration_access_token_expires_at ==
             before.registration_access_token_expires_at

    assert before.lifetime_version == 1
    assert DateTime.compare(before.registration_access_token_expires_at, deadline) == :eq

    assert {:error, :invalid_token} =
             RegistrationManagement.read(client_id, before, now: deadline)

    past = DateTime.add(deadline, -3_601, :second)
    set_management_deadline!(client_id, past, before.metadata)
    {:ok, before_expired_get} = Repository.fetch_client_by_id(client_id)

    expired_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{rat}")
      |> dispatch()

    assert expired_conn.status == 401
    assert {:ok, after_get} = Repository.fetch_client_by_id(client_id)

    assert after_get.registration_access_token_hash ==
             before_expired_get.registration_access_token_hash

    assert after_get.client_expires_at == before_expired_get.client_expires_at
    assert after_get.client_secret_expires_at == before_expired_get.client_secret_expires_at
    assert after_get.lifetime_version == before_expired_get.lifetime_version

    assert after_get.registration_access_token_expires_at ==
             before_expired_get.registration_access_token_expires_at
  end
end
