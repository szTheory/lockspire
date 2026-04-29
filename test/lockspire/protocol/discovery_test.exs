defmodule Lockspire.Protocol.DiscoveryTest.TokenAndUserinfoController do
  use Phoenix.Controller, formats: [:json]

  def create(conn, _params), do: json(conn, %{})
  def show(conn, _params), do: json(conn, %{})
end

defmodule Lockspire.Protocol.DiscoveryTest.TokenOnlyController do
  use Phoenix.Controller, formats: [:json]

  def create(conn, _params), do: json(conn, %{})
end

defmodule Lockspire.Protocol.DiscoveryTest.TokenAndUserinfoRouter do
  use Phoenix.Router

  scope "/" do
    post("/token", Lockspire.Protocol.DiscoveryTest.TokenAndUserinfoController, :create)
    get("/userinfo", Lockspire.Protocol.DiscoveryTest.TokenAndUserinfoController, :show)
  end
end

defmodule Lockspire.Protocol.DiscoveryTest.TokenOnlyRouter do
  use Phoenix.Router

  scope "/" do
    post("/token", Lockspire.Protocol.DiscoveryTest.TokenOnlyController, :create)
  end
end

defmodule Lockspire.Protocol.DiscoveryTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest, only: [build_conn: 3]
  import Plug.Conn

  alias Lockspire.Protocol.Discovery
  alias Lockspire.Protocol.DPoP
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
    original_router = Application.get_env(:lockspire, :discovery_router)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")

    on_exit(fn ->
      if is_nil(original) do
        Application.delete_env(:lockspire, :issuer)
      else
        Application.put_env(:lockspire, :issuer, original)
      end

      if is_nil(original_router) do
        Application.delete_env(:lockspire, :discovery_router)
      else
        Application.put_env(:lockspire, :discovery_router, original_router)
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

  test "openid_configuration/0 publishes dpop metadata when /token and /userinfo are both mounted" do
    Application.put_env(
      :lockspire,
      :discovery_router,
      Lockspire.Protocol.DiscoveryTest.TokenAndUserinfoRouter
    )

    config = Discovery.openid_configuration()

    assert config["dpop_signing_alg_values_supported"] == DPoP.signing_alg_values_supported()
  end

  test "openid_configuration/0 omits dpop metadata when the owned userinfo surface is not mounted" do
    Application.put_env(
      :lockspire,
      :discovery_router,
      Lockspire.Protocol.DiscoveryTest.TokenOnlyRouter
    )

    config = Discovery.openid_configuration()

    # Acceptance gate: refute Map.has_key(config, "dpop_signing_alg_values_supported")
    refute Map.has_key?(config, "dpop_signing_alg_values_supported")
  end

  describe "openid_configuration/0 — Phase 38 session/logout fields" do
    test "includes end_session_endpoint pointing to /end_session" do
      config = Discovery.openid_configuration()

      assert config["end_session_endpoint"] == "https://example.test/lockspire/end_session"
    end

    test "backchannel_logout_supported is false (truthful Phase 38 placeholder, D-19)" do
      config = Discovery.openid_configuration()

      assert config["backchannel_logout_supported"] == false
    end

    test "frontchannel_logout_supported is false (truthful Phase 38 placeholder, D-19)" do
      config = Discovery.openid_configuration()

      assert config["frontchannel_logout_supported"] == false
    end
  end

  describe "openid_configuration/0 — Phase 39 logout propagation truth stubs" do
    @tag :skip
    test "backchannel_logout_supported is published together with the rest of the shipped Phase 39 logout metadata" do
      # Phase 39 implementation must flip all logout propagation booleans as one
      # truthful metadata surface, not in partial slices.
      _config = Discovery
      flunk("not yet implemented")
    end

    @tag :skip
    test "backchannel_logout_session_supported describes sid-aware logout token support truthfully" do
      # This boolean must track the shipped session-aware back-channel behavior
      # rather than remaining an undocumented placeholder.
      _config = Discovery
      flunk("not yet implemented")
    end

    @tag :skip
    test "frontchannel_logout_supported is published together with the rest of the shipped Phase 39 logout metadata" do
      # Front-channel support truth must move in lockstep with back-channel and
      # the two session-supported booleans.
      _config = Discovery
      flunk("not yet implemented")
    end

    @tag :skip
    test "frontchannel_logout_session_supported describes sid-aware iframe logout support truthfully" do
      # The completion-page iframe flow may be best effort, but discovery still
      # needs a precise published contract for session-aware behavior.
      _config = Discovery
      flunk("not yet implemented")
    end
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
