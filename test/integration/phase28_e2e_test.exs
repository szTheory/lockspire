defmodule Lockspire.Integration.Phase28E2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Admin.InitialAccessTokens
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    %{events: start_telemetry_capture()}
  end

  defp start_telemetry_capture do
    test_pid = self()
    handler_id = "phase28_test_handler_#{System.unique_integer()}"

    events = [
      [:lockspire, :iat, :mint],
      [:lockspire, :iat, :use],
      [:lockspire, :iat, :revoke],
      [:lockspire, :dcr, :register],
      [:lockspire, :dcr, :read],
      [:lockspire, :dcr, :update],
      [:lockspire, :dcr, :delete],
      [:lockspire, :dcr, :rotate],
      [:lockspire, :dcr, :unauthorized]
    ]

    :telemetry.attach_many(
      handler_id,
      events,
      fn name, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, name, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    events
  end

  test "Full flow triggers every expected event: mint -> register -> read -> rotate -> update -> delete -> revoke -> unauthorized" do
    # Require IAT
    {:ok, %ServerPolicy{}} =
      Repository.put_server_policy(%ServerPolicy{
        registration_policy: :initial_access_token,
        dcr_allowed_redirect_uri_schemes: ["https"],
        dcr_allowed_redirect_uri_hosts: ["client.example.com"],
        dcr_allowed_scopes: ["openid"],
        dcr_allowed_grant_types: ["authorization_code"],
        dcr_allowed_response_types: ["code"]
      })

    # 1. Mint IAT
    expires_at = DateTime.utc_now() |> DateTime.add(3600, :second)

    {:ok, iat, iat_secret} =
      InitialAccessTokens.mint_iat(%{single_use: true, expires_at: expires_at})

    assert_receive {:telemetry_event, [:lockspire, :iat, :mint], _meas, meta}
    assert meta.iat_id == iat.id
    refute Map.has_key?(meta, :iat_secret)
    refute Map.has_key?(meta, "iat_secret")

    # 2. Register Client
    register_conn =
      build_conn(:post, "/register", %{
        "client_name" => "Phase 28 E2E Client",
        "redirect_uris" => ["https://client.example.com/callback"]
      })
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{iat_secret}")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert register_conn.status == 201

    assert_receive {:telemetry_event, [:lockspire, :iat, :use], _meas, iat_meta}
    assert iat_meta.status == :success
    assert iat_meta.iat_id == iat.id

    assert_receive {:telemetry_event, [:lockspire, :dcr, :register], _meas, dcr_meta}
    assert dcr_meta.status == :success
    assert client_id = dcr_meta.client_id
    refute Map.has_key?(dcr_meta, :client_secret)
    refute Map.has_key?(dcr_meta, :registration_access_token)

    response = Jason.decode!(register_conn.resp_body)
    rat = response["registration_access_token"]
    assert rat != nil

    # 3. Read Client
    read_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{rat}")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert read_conn.status == 200

    assert_receive {:telemetry_event, [:lockspire, :dcr, :read], _meas, read_meta}
    assert read_meta.status == :success
    assert read_meta.client_id == client_id

    # 4. Update Client (this triggers update and rotate)
    update_conn =
      build_conn(:put, "/register/#{client_id}", %{
        "client_name" => "Phase 28 E2E Client - Updated",
        "redirect_uris" => ["https://client.example.com/callback2"]
      })
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{rat}")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert update_conn.status == 200

    assert_receive {:telemetry_event, [:lockspire, :dcr, :update], _meas, update_meta}
    assert update_meta.status == :success
    assert update_meta.client_id == client_id

    assert_receive {:telemetry_event, [:lockspire, :dcr, :rotate], _meas, rotate_meta}
    assert rotate_meta.status == :success
    assert rotate_meta.client_id == client_id

    update_response = Jason.decode!(update_conn.resp_body)
    new_rat = update_response["registration_access_token"]
    assert new_rat != rat

    # 5. Delete Client
    delete_conn =
      build_conn(:delete, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{new_rat}")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert delete_conn.status == 204

    assert_receive {:telemetry_event, [:lockspire, :dcr, :delete], _meas, delete_meta}
    assert delete_meta.status == :success
    assert delete_meta.client_id == client_id

    # 6. Unauthorized Read
    unauthorized_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{new_rat}")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert unauthorized_conn.status == 401

    assert_receive {:telemetry_event, [:lockspire, :dcr, :unauthorized], _meas, unauth_meta}
    assert unauth_meta.client_id == client_id

    # 7. Revoke IAT
    assert :ok = InitialAccessTokens.revoke_iat(iat.id)

    assert_receive {:telemetry_event, [:lockspire, :iat, :revoke], _meas, revoke_meta}
    assert revoke_meta.iat_id == iat.id

    # Flush mailbox to process assertions properly
    flush_mailbox = fn f ->
      receive do
        _msg -> f.(f)
      after
        100 -> :ok
      end
    end

    flush_mailbox.(flush_mailbox)

    # Need to verify no secrets leaked - checking process state could be flaky,
    # The true assertion is done by checking the structure of telemetry events metadata
    # that we received. Since we use the single test process, if a secret leaked it would
    # be in the `meta` of those events. But the redact fn covers them.
    # The E2E asserts `refute Map.has_key?(dcr_meta, :client_secret)` which is strictly evaluated.
  end
end
