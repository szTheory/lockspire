defmodule Lockspire.Protocol.DiscoveryTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Protocol.Discovery
  alias Lockspire.Storage.Ecto.Repository

  @static_methods ["none", "client_secret_basic", "client_secret_post"]

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    # We must start the repo if it's not already started.
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    original = Application.get_env(:lockspire, :issuer)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")

    on_exit(fn ->
      if is_nil(original) do
        Application.delete_env(:lockspire, :issuer)
      else
        Application.put_env(:lockspire, :issuer, original)
      end
    end)

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    :ok
  end

  test "token_endpoint_auth_methods_supported/0 returns the static seam value (Phase 25 Plan 01)" do
    assert Discovery.token_endpoint_auth_methods_supported() == @static_methods
  end

  test "published_token_endpoint_auth_methods_supported/0 reflects the static list when /token is mounted" do
    assert Discovery.published_token_endpoint_auth_methods_supported() == @static_methods
  end

  test "openid_configuration/0 publishes the shipped device grant and device authorization endpoint truth" do
    config = Discovery.openid_configuration()

    assert config["grant_types_supported"] == [
             "authorization_code",
             "refresh_token",
             "urn:ietf:params:oauth:grant-type:device_code"
           ]

    assert config["device_authorization_endpoint"] ==
             "https://example.test/lockspire/device/code"
  end

  describe "truthful discovery for registration_endpoint" do
    test "when registration_policy is :disabled, endpoint is hidden and router returns 404" do
      Repository.update_server_policy(fn policy -> %{policy | registration_policy: :disabled} end)

      config = Discovery.openid_configuration()
      refute Map.has_key?(config, "registration_endpoint")

      conn =
        build_conn(:post, "/register", %{})
        |> put_req_header("accept", "application/json")
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status == 404
    end

    test "when registration_policy is :initial_access_token, endpoint is shown and router handles it" do
      Repository.update_server_policy(fn policy ->
        %{policy | registration_policy: :initial_access_token}
      end)

      config = Discovery.openid_configuration()
      assert config["registration_endpoint"] == "https://example.test/lockspire/register"

      conn =
        build_conn(:post, "/register", %{})
        |> put_req_header("accept", "application/json")
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      # Should return 401 or 400, not 404
      assert conn.status in [400, 401]
    end

    test "when registration_policy is :open, endpoint is shown and router handles it" do
      Repository.update_server_policy(fn policy -> %{policy | registration_policy: :open} end)

      config = Discovery.openid_configuration()
      assert config["registration_endpoint"] == "https://example.test/lockspire/register"

      conn =
        build_conn(:post, "/register", %{})
        |> put_req_header("accept", "application/json")
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      # Should return 400 (bad request due to missing body), not 404
      assert conn.status == 400
    end
  end
end
