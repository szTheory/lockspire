defmodule Lockspire.Web.AdminRouteSeparationTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Plug.Conn

  alias Lockspire.Web.AdminRouteHost

  @endpoint AdminRouteHost.CanonicalEndpoint
  @surface_mounts [
    {AdminRouteHost.DefaultRouter, AdminRouteHost.DefaultEndpoint, "/lockspire",
     "/lockspire/admin"},
    {AdminRouteHost.NestedRouter, AdminRouteHost.NestedEndpoint, "/teams/ops/identity",
     "/teams/ops/identity/admin"},
    {AdminRouteHost.RootRouter, AdminRouteHost.RootEndpoint, "", "/admin"}
  ]

  @public_routes [
    {:get, "/.well-known/openid-configuration", Lockspire.Web.DiscoveryController, :show},
    {:get, "/jwks", Lockspire.Web.JwksController, :index},
    {:post, "/par", Lockspire.Web.PushedAuthorizationRequestController, :create},
    {:post, "/register", Lockspire.Web.RegistrationController, :create},
    {:get, "/register/:client_id", Lockspire.Web.RegistrationController, :show},
    {:put, "/register/:client_id", Lockspire.Web.RegistrationController, :update},
    {:delete, "/register/:client_id", Lockspire.Web.RegistrationController, :delete},
    {:post, "/device/code", Lockspire.Web.DeviceAuthorizationController, :create},
    {:post, "/bc-authorize", Lockspire.Web.BCAuthorizeController, :create},
    {:post, "/revoke", Lockspire.Web.RevocationController, :create},
    {:post, "/introspect", Lockspire.Web.IntrospectionController, :create},
    {:get, "/end_session", Lockspire.Web.EndSessionController, :show},
    {:post, "/end_session", Lockspire.Web.EndSessionController, :create},
    {:get, "/end_session/complete", Lockspire.Web.EndSessionController, :complete},
    {:get, "/interactions/:interaction_id", Lockspire.Web.InteractionController, :show},
    {:post, "/interactions/:interaction_id/complete", Lockspire.Web.InteractionController,
     :complete},
    {:get, "/authorize", Lockspire.Web.AuthorizeController, :show},
    {:post, "/token", Lockspire.Web.TokenController, :create},
    {:get, "/userinfo", Lockspire.Web.UserinfoController, :show}
  ]

  setup_all do
    previous_mount = Application.fetch_env(:lockspire, :mount_path)
    previous_repo = Application.fetch_env(:lockspire, :repo)

    endpoints = [
      @endpoint,
      AdminRouteHost.DefaultEndpoint,
      AdminRouteHost.NestedEndpoint,
      AdminRouteHost.RootEndpoint
    ]

    previous_endpoints = Map.new(endpoints, &{&1, Application.fetch_env(:lockspire, &1)})

    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    Enum.each(endpoints, fn endpoint ->
      Application.put_env(:lockspire, endpoint,
        secret_key_base: String.duplicate("b", 64),
        render_errors: [view: Lockspire.Web.ErrorView, accepts: ~w(html json)],
        live_view: [signing_salt: "admin-route-separation"]
      )
    end)

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(@endpoint)
    start_supervised!(AdminRouteHost.DefaultEndpoint)
    start_supervised!(AdminRouteHost.NestedEndpoint)
    start_supervised!(AdminRouteHost.RootEndpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    on_exit(fn ->
      restore_env(:mount_path, previous_mount)
      restore_env(:repo, previous_repo)
      Enum.each(previous_endpoints, fn {endpoint, value} -> restore_env(endpoint, value) end)
    end)

    :ok
  end

  setup do
    previous_mount = Application.fetch_env(:lockspire, :mount_path)
    previous_observer = :persistent_term.get(:lockspire_admin_route_hook_observer, :unset)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    :persistent_term.put(:lockspire_admin_route_hook_observer, self())
    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(Lockspire.TestRepo, shared: true)

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.stop_owner(owner)
      restore_observer(previous_observer)
      restore_env(:mount_path, previous_mount)
    end)

    :ok
  end

  test "admin and host consent are ordered before each broad public forward" do
    for {router, _endpoint, prefix, admin_path} <- @surface_mounts do
      routes = Phoenix.Router.routes(router)

      admin_index =
        route_index!(routes, &(&1.plug == Phoenix.LiveView.Plug and &1.path == admin_path))

      consent_path = prefix <> "/consent/:interaction_id"

      consent_index =
        route_index!(routes, &(&1.plug == Phoenix.LiveView.Plug and &1.path == consent_path))

      forward_index = route_index!(routes, &(&1.plug == Lockspire.Web.Router))
      assert admin_index < forward_index
      assert consent_index < forward_index

      consent =
        Phoenix.Router.route_info(router, "GET", prefix <> "/consent/trace-1", "localhost")

      assert consent.plug == Phoenix.LiveView.Plug
      assert consent.log_module == AdminRouteHost.ConsentLive
      {_view, :show, _opts, live_session} = consent.phoenix_live_view
      assert live_session.name == :host_consent
      assert consent.pipe_through == [:host_consent]

      forward = Phoenix.Router.route_info(router, "GET", prefix <> "/jwks", "localhost")
      assert forward.plug == Lockspire.Web.Router
      refute Map.has_key?(forward, :phoenix_live_view)
    end
  end

  test "the public OAuth router retains its independent literal route and handler surface" do
    actual =
      Lockspire.Web.Router
      |> Phoenix.Router.routes()
      |> Enum.reject(&(&1.path == "/consent/:interaction_id"))
      |> Enum.map(fn route ->
        {route.verb, route.path, route.plug, route.plug_opts}
      end)

    assert actual == @public_routes
  end

  test "anonymous public HTTP and host consent work while admin remains staff protected" do
    trace = "separation-http-1"

    discovery =
      build_conn()
      |> put_req_header("x-route-trace", trace)
      |> get("/lockspire/.well-known/openid-configuration")

    assert discovery.status == 200
    assert_receive {:route_trace, ^trace, :public_http}

    jwks =
      build_conn()
      |> put_req_header("x-route-trace", "separation-jwks-1")
      |> get("/lockspire/jwks")

    assert jwks.status == 200
    assert_receive {:route_trace, "separation-jwks-1", :public_http}

    unsupported_grant =
      build_conn()
      |> put_req_header("x-route-trace", "separation-token-1")
      |> put_req_header("accept", "application/json")
      |> post("/lockspire/token", %{"grant_type" => "password"})

    assert unsupported_grant.status == 400
    assert Jason.decode!(unsupported_grant.resp_body)["error"] == "unsupported_grant_type"
    assert_receive {:route_trace, "separation-token-1", :public_http}

    anonymous_admin =
      build_conn()
      |> put_req_header("x-route-trace", "separation-denied-admin")
      |> get("/lockspire/admin")

    assert anonymous_admin.status == 403
    assert_receive {:route_trace, "separation-denied-admin", :admin_http_denied}

    consent =
      build_conn()
      |> put_req_header("x-route-trace", "separation-consent-http")
      |> get("/lockspire/consent/interaction-1")

    assert consent.status == 200
    assert consent.resp_body =~ "Host consent"
    assert_receive {:route_trace, "separation-consent-http", :consent_http}
    assert_receive {:route_trace, "separation-consent-http", :consent_session}
    refute_receive {:route_trace, "separation-consent-http", :admin_http_allowed}
  end

  test "connected consent and authorized admin run distinct sessions and hooks" do
    consent =
      build_conn()
      |> put_req_header("x-route-trace", "connected-consent-1")
      |> live("/lockspire/consent/interaction-2")

    assert {:ok, consent_view, consent_html} = consent
    assert consent_view.module == AdminRouteHost.ConsentLive
    assert consent_html =~ "interaction-2"
    assert_receive {:route_trace, "connected-consent-1", :consent_session}
    assert_receive {:route_trace, "connected-consent-1", :consent_hook}

    admin =
      build_conn()
      |> put_req_header("x-route-trace", "connected-admin-1")
      |> init_test_session(%{"host_staff_id" => "staff-1"})
      |> live("/lockspire/admin")

    assert {:ok, admin_view, _html} = admin
    assert admin_view.module == Lockspire.Web.Live.Admin.OverviewLive.Index
    assert_receive {:route_trace, "connected-admin-1", :admin_session}
    assert_receive {:route_trace, "connected-admin-1", :admin_hook}
    assert_receive {:route_trace, "connected-admin-1", :admin_http_allowed}
    refute_receive {:route_trace, "connected-admin-1", :consent_hook}
    refute_receive {:route_trace, "connected-consent-1", :admin_hook}
  end

  test "concurrent public, host consent and staff admin HTTP requests keep trace provenance" do
    cases = [
      {:public, "/lockspire/.well-known/openid-configuration", nil, 200},
      {:consent, "/lockspire/consent/concurrent-1", nil, 200},
      {:admin, "/lockspire/admin", "staff-1", 200}
    ]

    results =
      cases
      |> Task.async_stream(
        fn {surface, path, staff, expected_status} ->
          trace = "concurrent-#{surface}"
          conn = build_conn() |> put_req_header("x-route-trace", trace)
          conn = if staff, do: init_test_session(conn, %{"host_staff_id" => staff}), else: conn
          response = get(conn, path)
          {surface, trace, expected_status, response.status}
        end,
        max_concurrency: 3,
        timeout: 10_000
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert Enum.all?(results, fn {_surface, _trace, expected, actual} -> expected == actual end)

    assert_receive {:route_trace, "concurrent-public", :public_http}
    assert_receive {:route_trace, "concurrent-consent", :consent_http}
    assert_receive {:route_trace, "concurrent-consent", :consent_session}
    assert_receive {:route_trace, "concurrent-admin", :admin_http_allowed}
    refute_receive {:route_trace, "concurrent-public", :admin_http_allowed}
    refute_receive {:route_trace, "concurrent-consent", :admin_http_allowed}
    refute_receive {:route_trace, "concurrent-admin", :consent_http}
  end

  defp route_index!(routes, predicate) do
    routes
    |> Enum.with_index()
    |> Enum.find_value(fn {route, index} -> if predicate.(route), do: index end)
    |> then(&(&1 || flunk("expected route was absent")))
  end

  defp restore_env(key, {:ok, value}), do: Application.put_env(:lockspire, key, value)
  defp restore_env(key, :error), do: Application.delete_env(:lockspire, key)

  defp restore_observer(:unset), do: :persistent_term.erase(:lockspire_admin_route_hook_observer)

  defp restore_observer(observer),
    do: :persistent_term.put(:lockspire_admin_route_hook_observer, observer)
end
