defmodule Lockspire.Web.RegistrationControllerTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Test.Fixtures.DcrFixtures

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

    Repository.put_server_policy(%Lockspire.Domain.ServerPolicy{
      registration_policy: :initial_access_token
    })

    on_exit(fn ->
      Repository.put_server_policy(%Lockspire.Domain.ServerPolicy{
        registration_policy: :initial_access_token
      })
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

    conn =
      build_conn(:post, "/register", %{"client_name" => "Test"})
      |> dispatch()

    assert conn.status == 404
  end

  test "create responds with 201 JSON on success" do
    Repository.put_server_policy(
      Lockspire.Test.Fixtures.DcrFixtures.server_policy(%{registration_policy: :open})
    )

    conn =
      build_conn(:post, "/register", Lockspire.Test.Fixtures.DcrFixtures.valid_metadata())
      |> dispatch()

    assert conn.status == 201
    assert Jason.decode!(conn.resp_body)["client_id"] != nil
  end

  test "create and subsequent show expose persisted logout metadata" do
    Repository.put_server_policy(
      Lockspire.Test.Fixtures.DcrFixtures.server_policy(%{registration_policy: :open})
    )

    create_conn =
      build_conn(:post, "/register", Lockspire.Test.Fixtures.DcrFixtures.valid_logout_metadata())
      |> dispatch()

    assert create_conn.status == 201

    create_body = Jason.decode!(create_conn.resp_body)
    assert client_id = create_body["client_id"]
    assert rat = create_body["registration_access_token"]
    assert create_body["backchannel_logout_uri"] == "https://rp.example.test/backchannel-logout"
    assert create_body["backchannel_logout_session_required"] == true

    assert create_body["frontchannel_logout_uri"] ==
             "https://app.example.test/frontchannel-logout"

    assert create_body["frontchannel_logout_session_required"] == true

    show_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{rat}")
      |> dispatch()

    assert show_conn.status == 200

    show_body = Jason.decode!(show_conn.resp_body)
    assert show_body["backchannel_logout_uri"] == "https://rp.example.test/backchannel-logout"
    assert show_body["backchannel_logout_session_required"] == true
    assert show_body["frontchannel_logout_uri"] == "https://app.example.test/frontchannel-logout"
    assert show_body["frontchannel_logout_session_required"] == true
  end

  test "create yields 401 when IAT is invalid" do
    conn =
      build_conn(:post, "/register", %{"client_name" => "Test App"})
      |> put_req_header("authorization", "Bearer invalid-iat")
      |> dispatch()

    assert conn.status == 401

    assert get_resp_header(conn, "www-authenticate") == [
             "Bearer realm=\"Lockspire Dynamic Client Registration\", error=\"invalid_token\""
           ]
  end

  test "show yields 401 without RAT" do
    conn =
      build_conn(:get, "/register/client-123")
      |> dispatch()

    assert conn.status == 401
  end

  test "update yields 401 without RAT" do
    conn =
      build_conn(:put, "/register/client-123", %{"client_name" => "Updated"})
      |> dispatch()

    assert conn.status == 401
  end

  test "update returns persisted logout metadata and a rotated RAT" do
    Repository.put_server_policy(DcrFixtures.server_policy(%{registration_policy: :open}))

    create_conn =
      build_conn(:post, "/register", DcrFixtures.valid_metadata())
      |> dispatch()

    assert create_conn.status == 201
    create_body = Jason.decode!(create_conn.resp_body)
    client_id = create_body["client_id"]
    prior_rat = create_body["registration_access_token"]

    update_conn =
      build_conn(:put, "/register/#{client_id}", DcrFixtures.replacement_logout_metadata())
      |> put_req_header("authorization", "Bearer #{prior_rat}")
      |> dispatch()

    assert update_conn.status == 200

    update_body = Jason.decode!(update_conn.resp_body)
    assert update_body["registration_access_token"] != prior_rat

    assert update_body["backchannel_logout_uri"] ==
             "https://rp.example.test/replaced-backchannel-logout"

    assert update_body["backchannel_logout_session_required"] == false

    assert update_body["frontchannel_logout_uri"] ==
             "https://app.example.test/replaced-frontchannel-logout"

    assert update_body["frontchannel_logout_session_required"] == false

    show_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{update_body["registration_access_token"]}")
      |> dispatch()

    assert show_conn.status == 200

    show_body = Jason.decode!(show_conn.resp_body)
    assert show_body["backchannel_logout_uri"] == update_body["backchannel_logout_uri"]
    assert show_body["frontchannel_logout_uri"] == update_body["frontchannel_logout_uri"]
  end

  test "update returns invalid_client_metadata for malformed logout metadata" do
    Repository.put_server_policy(DcrFixtures.server_policy(%{registration_policy: :open}))

    create_conn =
      build_conn(:post, "/register", DcrFixtures.valid_metadata())
      |> dispatch()

    assert create_conn.status == 201
    create_body = Jason.decode!(create_conn.resp_body)

    update_conn =
      build_conn(
        :put,
        "/register/#{create_body["client_id"]}",
        DcrFixtures.invalid_backchannel_logout_uri_metadata()
      )
      |> put_req_header("authorization", "Bearer #{create_body["registration_access_token"]}")
      |> dispatch()

    assert update_conn.status == 400

    assert Jason.decode!(update_conn.resp_body) == %{
             "error" => "invalid_client_metadata",
             "error_description" => "invalid_logout_uri for backchannel_logout_uri"
           }
  end

  test "delete yields 401 without RAT" do
    conn =
      build_conn(:delete, "/register/client-123")
      |> dispatch()

    assert conn.status == 401
  end
end
