defmodule Lockspire.Integration.ManagementTokenLifetimeRecoveryTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn
  import Ecto.Query

  alias Lockspire.Protocol.RegistrationManagement
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
    conn = build_conn(:post, "/register", DcrFixtures.valid_metadata()) |> dispatch()
    assert conn.status == 201
    Jason.decode!(conn.resp_body)
  end

  test "host recovery uses current policy and preserves app, secret, identity, and enabled state" do
    registered = register_client()
    client_id = registered["client_id"]
    old_token = registered["registration_access_token"]
    now = ~U[2030-01-02 03:04:05Z]
    app_deadline = DateTime.add(now, 35, :second)
    secret_deadline = DateTime.add(now, 25, :second)

    Lockspire.TestRepo.update_all(
      from(c in ClientRecord, where: c.client_id == ^client_id),
      set: [
        client_expires_at: app_deadline,
        client_secret_expires_at: secret_deadline,
        registration_access_token_expires_at: DateTime.add(now, -1, :second)
      ]
    )

    {:ok, original} = Repository.fetch_client_by_id(client_id)

    assert {:ok, new_token, recovered} =
             RegistrationManagement.rotate_registration_access_token(original, now: now)

    assert new_token != old_token
    assert recovered.client_id == original.client_id
    assert recovered.registration_access_token_hash != original.registration_access_token_hash

    assert DateTime.compare(
             recovered.registration_access_token_expires_at,
             DateTime.add(now, 40, :second)
           ) == :eq

    assert DateTime.compare(recovered.client_expires_at, app_deadline) == :eq
    assert DateTime.compare(recovered.client_secret_expires_at, secret_deadline) == :eq
    assert recovered.client_secret_hash == original.client_secret_hash
    assert recovered.active

    old_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{old_token}")
      |> dispatch()

    assert old_conn.status == 401
  end

  test "a stale host snapshot cannot overwrite a winning replacement, and a refreshed retry works" do
    registered = register_client()
    {:ok, stale} = Repository.fetch_client_by_id(registered["client_id"])

    now = ~U[2030-01-02 03:04:05Z]

    assert {:ok, _first_token, first} =
             RegistrationManagement.rotate_registration_access_token(stale, now: now)

    assert {:error, _reason} =
             RegistrationManagement.rotate_registration_access_token(stale, now: now)

    {:ok, current} = Repository.fetch_client_by_id(stale.client_id)
    assert current.registration_access_token_hash == first.registration_access_token_hash

    assert {:ok, retry_token, retried} =
             RegistrationManagement.rotate_registration_access_token(current, now: now)

    assert is_binary(retry_token)
    assert retried.registration_access_token_hash != first.registration_access_token_hash
  end

  test "host recovery leaves a disabled app disabled and unusable" do
    registered = register_client()
    client_id = registered["client_id"]

    Lockspire.TestRepo.update_all(
      from(c in ClientRecord, where: c.client_id == ^client_id),
      set: [active: false]
    )

    {:ok, disabled} = Repository.fetch_client_by_id(client_id)

    assert {:ok, token, recovered} =
             RegistrationManagement.rotate_registration_access_token(
               disabled,
               now: ~U[2030-01-02 03:04:05Z]
             )

    refute recovered.active

    conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{token}")
      |> dispatch()

    assert conn.status == 401
  end

  test "an expired enabled app can be recovered for GET and DELETE, while PUT remains blocked" do
    registered = register_client()
    client_id = registered["client_id"]
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    expired_at = DateTime.add(now, -1, :second)

    Lockspire.TestRepo.update_all(
      from(c in ClientRecord, where: c.client_id == ^client_id),
      set: [client_expires_at: expired_at]
    )

    {:ok, current} = Repository.fetch_client_by_id(client_id)

    assert {:ok, token, recovered} =
             RegistrationManagement.rotate_registration_access_token(current, now: now)

    assert recovered.active
    assert DateTime.compare(recovered.client_expires_at, expired_at) == :eq

    get_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{token}")
      |> dispatch()

    assert get_conn.status == 200

    put_conn =
      build_conn(
        :put,
        "/register/#{client_id}",
        DcrFixtures.valid_metadata() |> Map.put("client_id", client_id)
      )
      |> put_req_header("authorization", "Bearer #{token}")
      |> dispatch()

    assert put_conn.status == 403
    assert Jason.decode!(put_conn.resp_body)["error"] == "registration_expired"

    delete_conn =
      build_conn(:delete, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{token}")
      |> dispatch()

    assert delete_conn.status == 204
  end

  test "nil and zero management policies both recover to unlimited" do
    for duration <- [nil, 0] do
      registered = register_client()

      Repository.put_server_policy(
        DcrFixtures.server_policy(%{
          registration_policy: :open,
          dcr_default_registration_access_token_lifetime_seconds: duration
        })
      )

      {:ok, current} = Repository.fetch_client_by_id(registered["client_id"])

      assert {:ok, _token, recovered} =
               RegistrationManagement.rotate_registration_access_token(
                 current,
                 now: ~U[2030-01-02 03:04:05Z]
               )

      assert is_nil(recovered.registration_access_token_expires_at)
    end
  end

  test "a lost successful PUT response is recovered only by a fresh host snapshot" do
    registered = register_client()
    client_id = registered["client_id"]
    old_token = registered["registration_access_token"]

    put_conn =
      build_conn(
        :put,
        "/register/#{client_id}",
        DcrFixtures.valid_metadata() |> Map.put("client_id", client_id)
      )
      |> put_req_header("authorization", "Bearer #{old_token}")
      |> dispatch()

    assert put_conn.status == 200
    # Ignore the returned token as if the response were lost. Host staff reloads current state.
    {:ok, current} = Repository.fetch_client_by_id(client_id)

    assert {:ok, recovered_token, recovered} =
             RegistrationManagement.rotate_registration_access_token(
               current,
               now: ~U[2030-01-02 03:04:05Z]
             )

    assert is_binary(recovered_token)
    assert recovered.registration_access_token_hash != current.registration_access_token_hash

    stale_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{old_token}")
      |> dispatch()

    assert stale_conn.status == 401
  end
end
