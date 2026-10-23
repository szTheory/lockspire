defmodule Lockspire.Web.Live.Admin.AdminRouteIntegrationTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Lockspire.Web.AdminRouteHost.Endpoint

  @endpoint Endpoint

  setup_all do
    previous_mount = Application.fetch_env(:lockspire, :mount_path)
    previous_endpoint = Application.fetch_env(:lockspire, Endpoint)

    Application.put_env(:lockspire, :mount_path, "/lockspire")

    Application.put_env(:lockspire, Endpoint,
      secret_key_base: String.duplicate("a", 64),
      render_errors: [view: Lockspire.Web.ErrorView, accepts: ~w(html json)],
      live_view: [signing_salt: "admin-route-live-view"]
    )

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    on_exit(fn ->
      restore_env(:mount_path, previous_mount)
      restore_env(Endpoint, previous_endpoint)
    end)

    :ok
  end

  setup do
    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(Lockspire.TestRepo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(owner) end)
    :ok
  end

  @tag :forward_only
  test "forward-only admin HTML renders before the connected join reproduces the path mismatch" do
    response =
      build_conn()
      |> init_test_session(%{"host_staff_id" => "staff-1"})
      |> get("/lockspire/admin")

    assert response.status == 200

    [_, signed_session] =
      Regex.run(~r/data-phx-session="([^"]+)"/, response.resp_body)

    assert {:ok, %{router: Lockspire.Web.AdminRouter}} =
             Phoenix.LiveView.Static.verify_token(Endpoint, signed_session)

    assert %{
             plug: Phoenix.LiveView.Plug,
             phoenix_live_view: {Lockspire.Web.Live.Admin.OverviewLive.Index, :index, _, _}
           } =
             Phoenix.Router.route_info(Lockspire.Web.AdminRouter, "GET", "/", "www.example.com")

    assert :error =
             Phoenix.Router.route_info(
               Lockspire.Web.AdminRouter,
               "GET",
               "/lockspire/admin",
               "www.example.com"
             )

    result =
      try do
        live(
          build_conn() |> init_test_session(%{"host_staff_id" => "staff-1"}),
          "/lockspire/admin"
        )
      rescue
        error -> {:raised, error, __STACKTRACE__}
      catch
        kind, reason -> {:caught, kind, reason, __STACKTRACE__}
      end

    assert result == {:error, {:redirect, %{to: "http://www.example.com/lockspire/admin"}}}
  end

  defp restore_env(key, {:ok, value}), do: Application.put_env(:lockspire, key, value)
  defp restore_env(key, :error), do: Application.delete_env(:lockspire, key)
end

defmodule Lockspire.Web.Live.Admin.CanonicalAdminRouteIntegrationTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Lockspire.Web.AdminRouteHost.CanonicalEndpoint

  @endpoint CanonicalEndpoint

  setup_all do
    previous_mount = Application.fetch_env(:lockspire, :mount_path)
    previous_endpoint = Application.fetch_env(:lockspire, CanonicalEndpoint)

    Application.put_env(:lockspire, :mount_path, "/lockspire")

    Application.put_env(:lockspire, CanonicalEndpoint,
      secret_key_base: String.duplicate("a", 64),
      render_errors: [view: Lockspire.Web.ErrorView, accepts: ~w(html json)],
      live_view: [signing_salt: "admin-route-live-view"]
    )

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(CanonicalEndpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    on_exit(fn ->
      restore_env(:mount_path, previous_mount)
      restore_env(CanonicalEndpoint, previous_endpoint)
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

  @tag :canonical_host
  test "the native host route connects the actual overview LiveView" do
    response =
      build_conn()
      |> Phoenix.ConnTest.init_test_session(%{"host_staff_id" => "staff-1"})
      |> live("/lockspire/admin")

    assert {:ok, view, html} = response
    assert Process.alive?(view.pid)
    assert view.module == Lockspire.Web.Live.Admin.OverviewLive.Index
    assert html =~ "Overview"
    assert_receive {:host_live_hook, "staff-1"}
    assert_receive {:host_session_callback, "admin-route"}

    assert %{pipe_through: [:browser, :lockspire_admin_mount]} =
             Phoenix.Router.route_info(
               Lockspire.Web.AdminRouteHost.CanonicalRouter,
               "GET",
               "/lockspire/admin",
               "www.example.com"
             )
  end

  test "cached-response denial halts before protected probe callbacks and actions" do
    install_authority()
    trace = "cached-probe-policy-withdrawn"

    initial_conn =
      build_conn()
      |> Plug.Conn.put_req_header("x-route-trace", trace)
      |> Phoenix.ConnTest.init_test_session(
        Map.put(
          Lockspire.Web.AdminRouteHost.Identity.staff_session("staff-1"),
          "trace_id",
          trace
        )
      )
      |> Phoenix.ConnTest.get("/admin-auth-probe")

    assert initial_conn.status == 200
    assert initial_conn.resp_body =~ "admin-route-sensitive-id"
    assert_receive {:host_authorization, ^trace, :disconnected, :allowed, "staff-1"}
    assert_receive {:probe_callback, :disconnected, :mount}
    assert_receive {:probe_callback, :disconnected, :params}
    assert_receive {:probe_callback, :disconnected, :render_data}

    assert {:ok, first_view, html} = live(initial_conn)
    assert html =~ "admin-route-sensitive-id"
    assert_receive {:host_authorization, ^trace, :connected, :allowed, "staff-1"}
    assert_receive {:probe_callback, :connected, :mount}
    assert_receive {:probe_callback, :connected, :params}
    assert_receive {:probe_callback, :connected, :render_data}

    first_view |> element("#probe-action") |> render_click()
    assert_receive {:probe_callback, :connected, :action}
    stop_live_view(first_view)

    authority =
      Lockspire.Web.AdminRouteHost.Identity.default_authority()
      |> Map.put(:permissions, %{"staff-1" => false, "staff-2" => false})

    assert :ok = Lockspire.Web.AdminRouteHost.Identity.put_authority(authority)

    assert live(initial_conn) ==
             {:error, {:redirect, %{status: 302, to: "/host/sign-in"}}}

    assert_receive {:host_authorization, ^trace, :connected, :denied, "staff-1"}
    assert_receive {:host_live_hook, :denied}
    refute_receive {:probe_callback, :connected, _callback}
    refute_receive {:host_session_callback, _label}
  end

  test "connected entry rechecks current host policy against the already-rendered response" do
    install_authority()

    allowed_trace = "entry-allowed"

    allowed_conn =
      build_conn()
      |> Plug.Conn.put_req_header("x-route-trace", allowed_trace)
      |> Phoenix.ConnTest.init_test_session(
        Lockspire.Web.AdminRouteHost.Identity.staff_session("staff-1")
      )
      |> Phoenix.ConnTest.get("/lockspire/admin")

    assert allowed_conn.status == 200
    assert allowed_conn.resp_body =~ "Overview"

    assert_receive {:host_authorization, ^allowed_trace, :disconnected, :allowed, "staff-1"}

    assert {:ok, allowed_view, allowed_html} = live(allowed_conn)
    assert allowed_view.module == Lockspire.Web.Live.Admin.OverviewLive.Index
    assert allowed_html =~ "Overview"
    assert_receive {:host_authorization, ^allowed_trace, :connected, :allowed, "staff-1"}
    assert_receive {:host_live_hook, "staff-1"}
    assert_receive {:host_live_hook, "staff-1"}

    denied_trace = "entry-withdrawn"

    denied_conn =
      build_conn()
      |> Plug.Conn.put_req_header("x-route-trace", denied_trace)
      |> Phoenix.ConnTest.init_test_session(
        Lockspire.Web.AdminRouteHost.Identity.staff_session("staff-1")
      )
      |> Phoenix.ConnTest.get("/lockspire/admin")

    assert denied_conn.status == 200
    assert denied_conn.resp_body =~ "Overview"

    assert_receive {:host_authorization, ^denied_trace, :disconnected, :allowed, "staff-1"}

    denied_authority =
      Lockspire.Web.AdminRouteHost.Identity.default_authority()
      |> Map.put(:permissions, %{"staff-1" => false, "staff-2" => false})

    assert :ok = Lockspire.Web.AdminRouteHost.Identity.put_authority(denied_authority)

    assert live(denied_conn) ==
             {:error, {:redirect, %{status: 302, to: "/host/sign-in"}}}

    assert_receive {:host_authorization, ^denied_trace, :connected, :denied, "staff-1"}
    assert_receive {:host_live_hook, :denied}
  end

  test "disconnected authorization probe reaches the host hook without the HTTP staff guard" do
    install_authority()
    trace = "probe-disconnected-denied"

    response =
      build_conn()
      |> Plug.Conn.put_req_header("x-route-trace", trace)
      |> Phoenix.ConnTest.init_test_session(
        Map.put(
          Lockspire.Web.AdminRouteHost.Identity.staff_session("staff-2"),
          "trace_id",
          trace
        )
      )
      |> Phoenix.ConnTest.get("/admin-auth-probe")

    assert response.status == 302
    assert response.resp_body =~ "/host/sign-in"
    assert_receive {:host_authorization, ^trace, :disconnected, :denied, "staff-2"}
    refute_receive {:probe_callback, _, _}
  end

  test "allowed disconnected and connected probe reaches protected callbacks and action" do
    install_authority()
    trace = "probe-allowed"

    session =
      Lockspire.Web.AdminRouteHost.Identity.staff_session("staff-1")
      |> Map.put("trace_id", trace)

    assert {:ok, view, html} =
             build_conn()
             |> Plug.Conn.put_req_header("x-route-trace", trace)
             |> Phoenix.ConnTest.init_test_session(session)
             |> live("/admin-auth-probe")

    assert view.module == Lockspire.Web.AdminRouteHost.MountSentinelLive
    assert html =~ "admin-route-sensitive-id"
    assert_receive {:host_authorization, ^trace, :disconnected, :allowed, "staff-1"}
    assert_receive {:probe_callback, :disconnected, :mount}
    assert_receive {:probe_callback, :disconnected, :params}
    assert_receive {:probe_callback, :disconnected, :render_data}
    assert_receive {:host_authorization, ^trace, :connected, :allowed, "staff-1"}
    assert_receive {:probe_callback, :connected, :mount}
    assert_receive {:probe_callback, :connected, :params}
    assert_receive {:probe_callback, :connected, :render_data}

    view
    |> element("#probe-action")
    |> render_click()

    assert_receive {:probe_callback, :connected, :action}
  end

  test "connected probe denial after static success prevents connected protected callbacks" do
    install_authority()
    trace = "probe-connected-denied"

    session =
      Lockspire.Web.AdminRouteHost.Identity.staff_session("staff-1")
      |> Map.put("trace_id", trace)

    static_conn =
      build_conn()
      |> Plug.Conn.put_req_header("x-route-trace", trace)
      |> Phoenix.ConnTest.init_test_session(session)
      |> Phoenix.ConnTest.get("/admin-auth-probe")

    assert static_conn.status == 200
    assert static_conn.resp_body =~ "admin-route-sensitive-id"
    assert_receive {:host_authorization, ^trace, :disconnected, :allowed, "staff-1"}
    assert_receive {:probe_callback, :disconnected, :mount}
    assert_receive {:probe_callback, :disconnected, :params}
    assert_receive {:probe_callback, :disconnected, :render_data}

    denied_authority =
      Lockspire.Web.AdminRouteHost.Identity.default_authority()
      |> Map.put(:permissions, %{"staff-1" => false, "staff-2" => false})

    assert :ok = Lockspire.Web.AdminRouteHost.Identity.put_authority(denied_authority)

    assert live(static_conn) ==
             {:error, {:redirect, %{status: 302, to: "/host/sign-in"}}}

    assert_receive {:host_authorization, ^trace, :connected, :denied, "staff-1"}
    refute_receive {:probe_callback, :connected, _callback}
  end

  test "the host HTTP gate and current-identity hook deny before a view mounts" do
    denied_http = get(build_conn(), "/lockspire/admin")
    assert denied_http.status == 403

    result =
      live(
        build_conn() |> Phoenix.ConnTest.init_test_session(%{"host_staff_id" => "deleted-staff"}),
        "/admin-auth-probe"
      )

    assert result == {:error, {:redirect, %{to: "/host/sign-in"}}}
    assert_receive {:host_live_hook, :denied}
    refute_receive :admin_mount_reached
  end

  test "the host identity hook halts missing and deleted identities for both socket states" do
    sockets = [
      {"disconnected",
       %Phoenix.LiveView.Socket{host_uri: URI.parse("http://www.example.com/admin")}, false},
      {"connected",
       %Phoenix.LiveView.Socket{
         host_uri: URI.parse("http://www.example.com/admin"),
         transport_pid: self()
       }, true}
    ]

    identities = [{:missing, %{}}, {:deleted, %{"host_staff_id" => "deleted-staff"}}]

    for {_state, socket, expected_connected?} <- sockets,
        {_identity_kind, session} <- identities do
      assert Phoenix.LiveView.connected?(socket) == expected_connected?

      assert {:halt, redirected_socket} =
               Lockspire.Web.AdminRouteHost.LiveAuthorization.on_mount(
                 :default,
                 %{},
                 session,
                 socket
               )

      assert redirected_socket.redirected ==
               {:redirect, %{to: "/host/sign-in", status: 302}}

      assert_receive {:host_live_hook, :denied}
      refute_receive :admin_mount_reached
    end
  end

  test "a runtime mount mismatch fails at HTTP entry without exposing session data" do
    Application.put_env(:lockspire, :mount_path, "/different-secret-prefix")

    error =
      assert_raise ArgumentError, fn ->
        build_conn()
        |> Phoenix.ConnTest.init_test_session(%{"host_staff_id" => "staff-1"})
        |> get("/lockspire/admin")
      end

    assert Exception.message(error) =~ "does not match configured :lockspire, :mount_path"
    refute Exception.message(error) =~ "staff-1"
    refute Exception.message(error) =~ "cookie"
  end

  test "a runtime mount mismatch also fails at the LiveView mount boundary" do
    Application.put_env(:lockspire, :mount_path, "/different-secret-prefix")

    socket = %Phoenix.LiveView.Socket{
      host_uri: URI.parse("http://www.example.com/lockspire/admin")
    }

    error =
      assert_raise ArgumentError, fn ->
        Lockspire.Web.AdminMount.on_mount(
          {:mount_path, Lockspire.Web.AdminRouteHost.CanonicalRouter},
          %{},
          %{},
          socket
        )
      end

    assert Exception.message(error) =~ "does not match configured :lockspire, :mount_path"
    assert Exception.message(error) =~ "/lockspire/admin"
    refute Exception.message(error) =~ "staff-1"
    refute Exception.message(error) =~ "csrf"
  end

  defp restore_env(key, {:ok, value}), do: Application.put_env(:lockspire, key, value)
  defp restore_env(key, :error), do: Application.delete_env(:lockspire, key)

  defp stop_live_view(view) do
    pid = view.pid
    monitor = Process.monitor(pid)
    GenServer.stop(pid)
    assert_receive {:DOWN, ^monitor, :process, ^pid, _reason}
  end

  defp restore_observer(:unset), do: :persistent_term.erase(:lockspire_admin_route_hook_observer)

  defp restore_observer(observer),
    do: :persistent_term.put(:lockspire_admin_route_hook_observer, observer)

  defp install_authority do
    identity = Lockspire.Web.AdminRouteHost.Identity
    previous = identity.authority_pointer()
    {:ok, pid} = start_supervised({identity, authority: identity.default_authority()})
    identity.install_authority(pid)
    on_exit(fn -> identity.restore_authority(previous) end)
  end
end

defmodule Lockspire.Web.Live.Admin.ExpandedAdminRouteIntegrationTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Lockspire.Web.AdminRouteHost

  @endpoint AdminRouteHost.DefaultEndpoint

  @mounts [
    {AdminRouteHost.DefaultEndpoint, AdminRouteHost.DefaultRouter, "/lockspire",
     "/lockspire/admin"},
    {AdminRouteHost.NestedEndpoint, AdminRouteHost.NestedRouter, "/teams/ops/identity",
     "/teams/ops/identity/admin"},
    {AdminRouteHost.RootEndpoint, AdminRouteHost.RootRouter, "", "/admin"}
  ]

  @journeys [
    {"/", Lockspire.Web.Live.Admin.OverviewLive.Index, :index},
    {"/overview", Lockspire.Web.Live.Admin.OverviewLive.Index, :index},
    {"/clients", Lockspire.Web.Live.Admin.ClientsLive.Index, :index},
    {"/clients/new", Lockspire.Web.Live.Admin.ClientsLive.Index, :new},
    {"/clients/:client_id", Lockspire.Web.Live.Admin.ClientsLive.Show, :show},
    {"/consents", Lockspire.Web.Live.Admin.ConsentsLive.Index, :index},
    {"/consents/:id", Lockspire.Web.Live.Admin.ConsentsLive.Show, :show},
    {"/tokens", Lockspire.Web.Live.Admin.TokensLive.Index, :index},
    {"/tokens/:id", Lockspire.Web.Live.Admin.TokensLive.Show, :show},
    {"/keys", Lockspire.Web.Live.Admin.KeysLive.Index, :index},
    {"/keys/:id", Lockspire.Web.Live.Admin.KeysLive.Show, :show},
    {"/interactions", Lockspire.Web.Live.Admin.InteractionsLive.Index, :index},
    {"/logouts", Lockspire.Web.Live.Admin.LogoutDeliveriesLive.Index, :index},
    {"/iats", Lockspire.Web.Live.Admin.IatLive.Index, :index},
    {"/iats/new", Lockspire.Web.Live.Admin.IatLive.New, :new},
    {"/device_authorizations", Lockspire.Web.Live.Admin.DeviceAuthorizationsLive.Index, :index},
    {"/clients/:client_id/edit", Lockspire.Web.Live.Admin.ClientsLive.Show, :edit},
    {"/clients/:client_id/par-policy", Lockspire.Web.Live.Admin.ClientsLive.Show, :par_policy},
    {"/clients/:client_id/security-profile", Lockspire.Web.Live.Admin.ClientsLive.Show,
     :security_profile},
    {"/clients/:client_id/redirects", Lockspire.Web.Live.Admin.ClientsLive.Show, :redirects},
    {"/clients/:client_id/logout-uris", Lockspire.Web.Live.Admin.ClientsLive.Show, :logout_uris},
    {"/clients/:client_id/rotate-secret", Lockspire.Web.Live.Admin.ClientsLive.Show,
     :rotate_secret},
    {"/clients/:client_id/rotate-registration-access-token",
     Lockspire.Web.Live.Admin.ClientsLive.Show, :rotate_registration_access_token},
    {"/dcr", Lockspire.Web.Live.Admin.DcrLive.Index, :index},
    {"/policies", Lockspire.Web.Live.Admin.PoliciesLive.Index, :index},
    {"/policies/par", Lockspire.Web.Live.Admin.PoliciesLive.Par, :show},
    {"/policies/security-profile", Lockspire.Web.Live.Admin.PoliciesLive.SecurityProfile, :show},
    {"/policies/dpop", Lockspire.Web.Live.Admin.PoliciesLive.Dpop, :show},
    {"/policies/dcr", Lockspire.Web.Live.Admin.PoliciesLive.Dcr, :show}
  ]

  setup_all do
    previous_endpoint_envs =
      Enum.map(@mounts, fn {endpoint, _router, _mount, _path} ->
        {endpoint, Application.fetch_env(:lockspire, endpoint)}
      end)

    Enum.each(@mounts, fn {endpoint, _router, _mount, _path} ->
      Application.put_env(:lockspire, endpoint,
        secret_key_base: String.duplicate("b", 64),
        render_errors: [view: Lockspire.Web.ErrorView, accepts: ~w(html json)],
        live_view: [signing_salt: "expanded-admin-route-live-view"]
      )
    end)

    start_supervised!(Lockspire.TestRepo)

    Enum.each(@mounts, fn {endpoint, _router, _mount, _path} ->
      start_supervised!(endpoint)
    end)

    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    on_exit(fn ->
      Enum.each(previous_endpoint_envs, fn {endpoint, previous} ->
        restore_env(endpoint, previous)
      end)
    end)

    :ok
  end

  setup do
    previous_mount = Application.fetch_env(:lockspire, :mount_path)
    previous_issuer = Application.fetch_env(:lockspire, :issuer)
    previous_observer = :persistent_term.get(:lockspire_admin_route_hook_observer, :unset)
    :persistent_term.put(:lockspire_admin_route_hook_observer, self())
    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(Lockspire.TestRepo, shared: true)

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.stop_owner(owner)
      restore_env(:mount_path, previous_mount)
      restore_env(:issuer, previous_issuer)
      restore_observer(previous_observer)
    end)

    :ok
  end

  test "a cached default admin response rejoins a new process under current host policy" do
    configure_mount("/lockspire")
    install_authority()

    allowed_trace = "cached-rejoin-allowed"
    session = AdminRouteHost.Identity.staff_session("staff-1")

    initial_conn =
      build_conn()
      |> Plug.Conn.put_req_header("x-route-trace", allowed_trace)
      |> init_test_session(session)
      |> Phoenix.ConnTest.dispatch(AdminRouteHost.DefaultEndpoint, :get, "/lockspire/admin")

    assert initial_conn.status == 200
    assert initial_conn.resp_body =~ "Overview"
    assert_receive {:host_authorization, ^allowed_trace, :disconnected, :allowed, "staff-1"}
    assert_receive {:host_session_callback, "default"}

    original_html = initial_conn.resp_body
    original_session = Plug.Conn.get_session(initial_conn)
    assert {:ok, first_view, first_html} = live(initial_conn)
    assert first_view.module == Lockspire.Web.Live.Admin.OverviewLive.Index
    assert first_html =~ "Overview"
    assert_receive {:host_authorization, ^allowed_trace, :connected, :allowed, "staff-1"}
    assert_receive {:host_live_hook, "staff-1"}

    stop_live_view(first_view)

    assert initial_conn.resp_body == original_html
    assert Plug.Conn.get_session(initial_conn) == original_session
    assert Plug.Conn.get_session(initial_conn, "host_session_id") == "host-session-staff-1"

    assert {:ok, rejoined_view, rejoined_html} = live(initial_conn)
    assert rejoined_view.pid != first_view.pid
    assert rejoined_view.module == first_view.module
    assert rejoined_html =~ "Overview"
    assert_receive {:host_authorization, ^allowed_trace, :connected, :allowed, "staff-1"}
    assert_receive {:host_live_hook, "staff-1"}
    refute_receive {:host_session_callback, _label}

    stop_live_view(rejoined_view)

    denied_trace = "cached-rejoin-policy-withdrawn"

    denied_conn =
      build_conn()
      |> Plug.Conn.put_req_header("x-route-trace", denied_trace)
      |> init_test_session(session)
      |> Phoenix.ConnTest.dispatch(AdminRouteHost.DefaultEndpoint, :get, "/lockspire/admin")

    assert denied_conn.status == 200
    assert denied_conn.resp_body =~ "Overview"
    assert_receive {:host_authorization, ^denied_trace, :disconnected, :allowed, "staff-1"}
    assert_receive {:host_session_callback, "default"}
    assert {:ok, previously_allowed_view, _html} = live(denied_conn)
    assert_receive {:host_authorization, ^denied_trace, :connected, :allowed, "staff-1"}
    assert_receive {:host_live_hook, "staff-1"}
    stop_live_view(previously_allowed_view)

    denied_authority =
      AdminRouteHost.Identity.default_authority()
      |> Map.put(:permissions, %{"staff-1" => false, "staff-2" => false})

    assert :ok = AdminRouteHost.Identity.put_authority(denied_authority)
    denied_html = denied_conn.resp_body
    denied_session = Plug.Conn.get_session(denied_conn)

    assert live(denied_conn) ==
             {:error, {:redirect, %{status: 302, to: "/host/sign-in"}}}

    assert denied_conn.resp_body == denied_html
    assert Plug.Conn.get_session(denied_conn) == denied_session
    assert_receive {:host_authorization, ^denied_trace, :connected, :denied, "staff-1"}
    assert_receive {:host_live_hook, :denied}
    refute_receive {:host_session_callback, _label}
    refute_receive {:probe_callback, :connected, _callback}
  end

  test "cached admin rejoin checks session, identity and policy at every mount" do
    install_authority()
    fixtures = AdminRouteHost.seed_admin_records!()
    assert fixtures.client.client_id == "admin-route-client"

    invalidations = [
      {"invalid session",
       fn authority ->
         put_in(authority, [:sessions, "host-session-staff-1", :valid?], false)
       end},
      {"removed session binding",
       fn authority ->
         update_in(authority, [:sessions], &Map.delete(&1, "host-session-staff-1"))
       end},
      {"deleted identity",
       fn authority ->
         update_in(authority, [:identities], &Map.delete(&1, "staff-1"))
       end},
      {"withdrawn staff policy",
       fn authority ->
         put_in(authority, [:permissions, "staff-1"], false)
       end}
    ]

    for {endpoint, _router, mount, base} <- @mounts do
      configure_mount(mount)
      route = base <> "/clients"
      allowed_trace = "cached-allowed-#{inspect(endpoint)}"

      assert :ok =
               AdminRouteHost.Identity.put_authority(AdminRouteHost.Identity.default_authority())

      {allowed_conn, first_view, first_html} =
        connected_admin_response(endpoint, route, allowed_trace)

      assert first_view.module == Lockspire.Web.Live.Admin.ClientsLive.Index
      assert first_html != ""
      assert Plug.Conn.get_session(allowed_conn, "host_session_id") == "host-session-staff-1"
      first_pid = first_view.pid
      stop_live_view(first_view)

      assert {:ok, rejoined_view, rejoined_html} = live(allowed_conn)
      assert rejoined_view.pid != first_pid
      assert rejoined_view.module == Lockspire.Web.Live.Admin.ClientsLive.Index
      assert rejoined_html != ""
      assert_receive {:host_authorization, ^allowed_trace, :connected, :allowed, "staff-1"}
      assert_receive {:route_trace, ^allowed_trace, :admin_hook}
      assert_receive {:host_live_hook, "staff-1"}
      refute_receive {:host_session_callback, _label}
      refute_receive {:route_trace, ^allowed_trace, :admin_http_allowed}
      refute_receive {:route_trace, ^allowed_trace, :admin_session}
      stop_live_view(rejoined_view)

      for {label, invalidate} <- invalidations do
        trace = "cached-denied-#{inspect(endpoint)}-#{label}"
        authority = AdminRouteHost.Identity.default_authority()
        assert :ok = AdminRouteHost.Identity.put_authority(authority)

        {denied_conn, original_view, original_html} =
          connected_admin_response(endpoint, route, trace)

        assert original_view.module == Lockspire.Web.Live.Admin.ClientsLive.Index
        assert original_html != ""
        assert Plug.Conn.get_session(denied_conn, "host_session_id") == "host-session-staff-1"
        assert denied_conn.assigns.host_staff_id == "staff-1"
        original_session = Plug.Conn.get_session(denied_conn)
        stop_live_view(original_view)

        assert :ok = AdminRouteHost.Identity.put_authority(invalidate.(authority))

        assert live(denied_conn) ==
                 {:error, {:redirect, %{status: 302, to: "/host/sign-in"}}}

        assert Plug.Conn.get_session(denied_conn) == original_session
        assert_receive {:host_authorization, ^trace, :connected, :denied, "staff-1"}
        assert_receive {:route_trace, ^trace, :admin_hook_denied}
        assert_receive {:host_live_hook, :denied}
        refute_receive {:host_session_callback, _label}
        refute_receive {:route_trace, ^trace, :admin_http_allowed}
        refute_receive {:route_trace, ^trace, :admin_http_denied}
        refute_receive {:route_trace, ^trace, :admin_session}
        refute_receive {:probe_callback, :connected, _callback}
      end
    end
  end

  for {_endpoint, _router, _mount, path} <- @mounts do
    @tag expanded_mount: path
    test "#{path} connects the real overview and clients pages and rejoins with fresh host hooks",
         %{expanded_mount: path} do
      {endpoint, router, mount, ^path} = Enum.find(@mounts, fn {_ep, _r, _m, p} -> p == path end)
      configure_mount(mount)
      fixtures = AdminRouteHost.seed_admin_records!()

      for route <- [path, path <> "/clients"] do
        session = %{"host_staff_id" => "staff-1"}
        {{:ok, view, html}, initial_conn} = endpoint_live_with_conn(endpoint, route, session)

        expected_module =
          if route == path,
            do: Lockspire.Web.Live.Admin.OverviewLive.Index,
            else: Lockspire.Web.Live.Admin.ClientsLive.Index

        assert view.module == expected_module
        assert html != ""
        assert_receive {:host_live_hook, "staff-1"}
        assert_receive {:host_session_callback, _label}
        first_pid = view.pid
        monitor = Process.monitor(first_pid)
        GenServer.stop(first_pid)
        assert_receive {:DOWN, ^monitor, :process, ^first_pid, _reason}

        rejoin_conn =
          initial_conn
          |> Phoenix.ConnTest.recycle()
          |> Phoenix.ConnTest.dispatch(endpoint, :get, route)

        assert Plug.Conn.get_session(rejoin_conn, "host_staff_id") == "staff-1"
        assert {:ok, rejoined, _html} = Phoenix.LiveViewTest.__live__(rejoin_conn, nil, [])
        assert rejoined.pid != first_pid
        assert rejoined.module == view.module
        assert_receive {:host_live_hook, "staff-1"}
        assert_receive {:host_session_callback, _label}
      end

      assert %{pipe_through: [:browser, :lockspire_admin_mount]} =
               Phoenix.Router.route_info(router, "GET", path, "www.example.com")

      assert Lockspire.Web.AdminRoutes.effective_admin_path(
               router,
               "GET",
               path <> "/clients",
               "www.example.com"
             ) == path

      for {relative, expected_module, expected_action} <- @journeys do
        route_path = route_path(path, relative, fixtures)

        assert %{
                 phoenix_live_view: {^expected_module, ^expected_action, _options, _extra}
               } = Phoenix.Router.route_info(router, "GET", route_path, "www.example.com")

        assert Lockspire.Web.AdminRoutes.effective_admin_path(
                 router,
                 "GET",
                 route_path,
                 "www.example.com"
               ) == path

        assert {:ok, route_view, _html} =
                 endpoint_live(endpoint, route_path, %{"host_staff_id" => "staff-1"})

        assert route_view.module == expected_module
        assert_receive {:host_live_hook, "staff-1"}
        assert_receive {:host_session_callback, _label}
      end
    end
  end

  test "rendered navigation and filters keep the configured prefix at every mount" do
    fixtures = AdminRouteHost.seed_admin_records!()

    for {endpoint, _router, mount, base} <- @mounts do
      configure_mount(mount)
      client_path = base <> "/clients"
      detail_path = client_path <> "/#{fixtures.client.client_id}"
      edit_path = detail_path <> "/edit"

      assert {:ok, overview, overview_html} =
               endpoint_live(endpoint, base, %{"host_staff_id" => "staff-1"})

      assert overview_html =~ ~s(href="#{client_path}")

      assert {:ok, clients, clients_html} =
               Phoenix.LiveViewTest.live_redirect(overview, to: client_path)

      assert clients.module == Lockspire.Web.Live.Admin.ClientsLive.Index
      assert clients_html =~ ~s(href="#{client_path}/new?)
      assert clients_html =~ ~s(href="#{detail_path}")
      assert_receive {:host_live_hook, "staff-1"}

      assert {:ok, details, detail_html} =
               Phoenix.LiveViewTest.live_redirect(clients, to: detail_path)

      assert details.module == Lockspire.Web.Live.Admin.ClientsLive.Show
      assert detail_html =~ ~s(href="#{client_path}")
      assert_receive {:host_live_hook, "staff-1"}

      assert {:ok, edit, edit_html} =
               Phoenix.LiveViewTest.live_redirect(details, to: edit_path)

      assert edit.module == Lockspire.Web.Live.Admin.ClientsLive.Show
      assert edit_html =~ ~s(href="#{detail_path}")
      assert_receive {:host_live_hook, "staff-1"}

      assert {:ok, client_filter, _html} =
               endpoint_live(endpoint, client_path, %{"host_staff_id" => "staff-1"})

      client_filter
      |> form("form[phx-submit=filter_inventory]", %{
        "q" => "admin-route",
        "status" => "all",
        "provenance" => "all"
      })
      |> render_submit()

      assert_patch(
        client_filter,
        client_path <> "?page=1&provenance=all&q=admin-route&status=all"
      )

      assert render(client_filter) =~ ~s(href="#{client_path}/new?)
      assert render(client_filter) =~ ~s(href="#{detail_path}?)

      token_path = base <> "/tokens"

      assert {:ok, token_filter, _html} =
               endpoint_live(endpoint, token_path, %{"host_staff_id" => "staff-1"})

      token_filter
      |> form("form[phx-submit=filter_inventory]", %{
        "account" => "admin-route-account",
        "client" => fixtures.client.client_id,
        "status" => "all"
      })
      |> render_submit()

      assert_patch(
        token_filter,
        token_path <>
          "?account=admin-route-account&client=admin-route-client&status=all"
      )

      assert render(token_filter) =~ ~s(href="#{token_path}/#{fixtures.token.id}?)

      workflow_path = edit_path <> "?workflow=logout-propagation"

      assert {:ok, _workflow, workflow_html} =
               endpoint_live(endpoint, workflow_path, %{"host_staff_id" => "staff-1"})

      assert workflow_html =~ "Server sign-out notification URL"
    end
  end

  test "missing detail records retain their prefixed recovery links" do
    for {endpoint, _router, mount, base} <- @mounts do
      configure_mount(mount)
      missing_id = "987654321"

      for {path, heading, return_path} <- [
            {base <> "/clients/not-a-real-app", "App not found", base <> "/clients"},
            {base <> "/consents/#{missing_id}", "Consent grant not found", base <> "/consents"},
            {base <> "/tokens/#{missing_id}", "Token not found", base <> "/tokens"},
            {base <> "/keys/#{missing_id}", "Key not found", base <> "/keys"}
          ] do
        assert {:ok, _view, html} =
                 endpoint_live(endpoint, path, %{"host_staff_id" => "staff-1"})

        assert html =~ heading
        assert html =~ ~s(href="#{return_path}")
        refute html =~ "//admin"
      end
    end
  end

  test "HTTP authority denial precedes protected routes at default, nested and root mounts" do
    fixtures = AdminRouteHost.seed_admin_records!()
    {:ok, client_before} = Lockspire.Admin.Clients.get_client(fixtures.client.client_id)
    install_authority()

    default_authority = AdminRouteHost.Identity.default_authority()

    invalid_session_authority =
      Map.update!(default_authority, :sessions, fn sessions ->
        Map.put(sessions, "host-session-staff-1", %{identity_id: "staff-1", valid?: false})
      end)

    denied_cases = [
      {:missing, %{}, default_authority},
      {:empty_identity, %{"host_staff_id" => "", "host_session_id" => "host-session-staff-1"},
       default_authority},
      {:deleted_identity, AdminRouteHost.Identity.staff_session("deleted-staff"),
       default_authority},
      {:invalid_session, AdminRouteHost.Identity.staff_session("staff-1"),
       invalid_session_authority},
      {:disallowed_policy, AdminRouteHost.Identity.staff_session("staff-2"), default_authority}
    ]

    for {endpoint, router, mount, base} <- @mounts do
      configure_mount(mount)

      paths = [
        base,
        base <> "/clients/#{fixtures.client.client_id}",
        base <> "/clients/#{fixtures.client.client_id}/edit?workflow=logout-propagation"
      ]

      for {path, expected_action} <-
            Enum.zip(paths, [
              :index,
              :show,
              :edit
            ]) do
        assert :ok = AdminRouteHost.Identity.put_authority(default_authority)

        allowed =
          build_conn()
          |> Phoenix.ConnTest.init_test_session(AdminRouteHost.Identity.staff_session("staff-1"))
          |> Phoenix.ConnTest.dispatch(endpoint, :get, path)

        assert allowed.status == 200
        assert allowed.resp_body != ""

        assert %{phoenix_live_view: {_view, ^expected_action, _opts, _session}} =
                 Phoenix.Router.route_info(
                   router,
                   "GET",
                   URI.parse(path).path,
                   "www.example.com"
                 )
      end

      for {{case_name, session, authority}, index} <- Enum.with_index(denied_cases) do
        assert :ok = AdminRouteHost.Identity.put_authority(authority)
        path = Enum.at(paths, rem(index, length(paths)))
        trace = "denied-#{inspect(case_name)}-#{inspect(base)}"

        conn =
          build_conn()
          |> Plug.Conn.put_req_header("x-route-trace", trace)
          |> Phoenix.ConnTest.init_test_session(session)
          |> Phoenix.ConnTest.dispatch(endpoint, :get, path)

        assert conn.status == 403
        refute conn.resp_body =~ "Admin Route Fixture"
        refute conn.resp_body =~ fixtures.client.client_id
        assert_receive {:route_trace, ^trace, :admin_http_denied}
        refute_receive {:route_trace, ^trace, :admin_http_allowed}
        refute_receive {:host_authorization, ^trace, _, _, _}
      end

      poisoned_session =
        AdminRouteHost.Identity.staff_session("staff-2")
        |> Map.put("host_staff_allowed", true)
        |> Map.put("is_admin", true)

      poisoned_conn =
        build_conn()
        |> Plug.Conn.assign(:host_staff_id, "staff-1")
        |> Plug.Conn.assign(:host_staff, %{id: "staff-1", role: :admin})
        |> Phoenix.ConnTest.init_test_session(poisoned_session)
        |> Phoenix.ConnTest.dispatch(endpoint, :get, base)

      assert poisoned_conn.status == 403
      refute poisoned_conn.resp_body =~ "Overview"
      assert {:ok, client_after} = Lockspire.Admin.Clients.get_client(fixtures.client.client_id)
      assert client_after == client_before
    end
  end

  test "concurrent connected filters retain separate state under one fixed mount" do
    configure_mount("/lockspire")
    AdminRouteHost.seed_admin_records!()

    assert {:ok, alpha, _html} =
             endpoint_live(
               AdminRouteHost.DefaultEndpoint,
               "/lockspire/admin/clients?q=admin-route&status=all&provenance=all",
               %{"host_staff_id" => "staff-1"}
             )

    assert {:ok, beta, _html} =
             endpoint_live(
               AdminRouteHost.DefaultEndpoint,
               "/lockspire/admin/clients?q=missing&status=all&provenance=all",
               %{"host_staff_id" => "staff-1"}
             )

    assert alpha.pid != beta.pid
    assert alpha.module == Lockspire.Web.Live.Admin.ClientsLive.Index
    assert beta.module == Lockspire.Web.Live.Admin.ClientsLive.Index
    assert render(alpha) =~ ~s(value="admin-route")
    assert render(beta) =~ ~s(value="missing")

    assert %{phoenix_live_view: {Lockspire.Web.Live.Admin.ClientsLive.Index, :index, _, _}} =
             Phoenix.Router.route_info(
               AdminRouteHost.DefaultRouter,
               "GET",
               "/lockspire/admin/clients",
               "www.example.com"
             )

    assert_receive {:host_live_hook, "staff-1"}
    assert_receive {:host_live_hook, "staff-1"}
    assert_receive {:host_session_callback, _label}
    assert_receive {:host_session_callback, _label}
  end

  test "both root mount config values and a normalized trailing slash produce one admin slash" do
    for mount <- ["", "/", "/teams/ops/identity/"] do
      configure_mount(mount)
      path = if mount in ["", "/"], do: "/admin", else: "/teams/ops/identity/admin"
      assert Lockspire.mount_path() == String.trim_trailing(mount, "/")

      endpoint =
        if mount == "/teams/ops/identity/",
          do: AdminRouteHost.NestedEndpoint,
          else: AdminRouteHost.RootEndpoint

      assert {:ok, view, html} = endpoint_live(endpoint, path, %{"host_staff_id" => "staff-1"})

      assert view.module == Lockspire.Web.Live.Admin.OverviewLive.Index
      assert html =~ ~s(href="#{path}/clients")
      refute html =~ "//admin"
    end
  end

  defp configure_mount(mount) do
    normalized = String.trim_trailing(mount, "/")
    Application.put_env(:lockspire, :mount_path, mount)
    Application.put_env(:lockspire, :issuer, "https://issuer.example" <> normalized)
  end

  defp stop_live_view(view) do
    pid = view.pid
    monitor = Process.monitor(pid)
    GenServer.stop(pid)
    assert_receive {:DOWN, ^monitor, :process, ^pid, _reason}
  end

  defp endpoint_live(endpoint, path, session) do
    {result, _conn} = endpoint_live_with_conn(endpoint, path, session)
    result
  end

  defp endpoint_live_with_conn(endpoint, path, session) do
    conn =
      build_conn()
      |> init_test_session(session)
      |> Phoenix.ConnTest.dispatch(endpoint, :get, path)

    {Phoenix.LiveViewTest.__live__(conn, nil, []), conn}
  end

  defp connected_admin_response(endpoint, path, trace) do
    conn =
      build_conn()
      |> Plug.Conn.put_req_header("x-route-trace", trace)
      |> init_test_session(AdminRouteHost.Identity.staff_session("staff-1"))
      |> Phoenix.ConnTest.dispatch(endpoint, :get, path)

    assert conn.status == 200
    assert_receive {:host_authorization, ^trace, :disconnected, :allowed, "staff-1"}
    assert_receive {:route_trace, ^trace, :admin_http_allowed}
    assert_receive {:route_trace, ^trace, :admin_session}
    assert_receive {:route_trace, ^trace, :admin_hook}
    assert_receive {:host_live_hook, "staff-1"}
    assert_receive {:host_session_callback, _label}

    assert {:ok, view, html} = live(conn)
    assert_receive {:host_authorization, ^trace, :connected, :allowed, "staff-1"}
    assert_receive {:route_trace, ^trace, :admin_hook}
    assert_receive {:host_live_hook, "staff-1"}

    {conn, view, html}
  end

  defp route_path(base, "/", _fixtures), do: base

  defp route_path(base, relative, fixtures) do
    relative = String.replace(relative, ":client_id", fixtures.client.client_id)

    relative
    |> then(fn path ->
      cond do
        String.starts_with?(path, "/consents/") ->
          String.replace(path, ":id", Integer.to_string(fixtures.consent.id))

        String.starts_with?(path, "/tokens/") ->
          String.replace(path, ":id", Integer.to_string(fixtures.token.id))

        String.starts_with?(path, "/keys/") ->
          String.replace(path, ":id", Integer.to_string(fixtures.key.id))

        true ->
          path
      end
    end)
    |> then(&(base <> &1))
  end

  defp restore_env(key, {:ok, value}), do: Application.put_env(:lockspire, key, value)
  defp restore_env(key, :error), do: Application.delete_env(:lockspire, key)

  defp restore_observer(:unset), do: :persistent_term.erase(:lockspire_admin_route_hook_observer)

  defp restore_observer(observer),
    do: :persistent_term.put(:lockspire_admin_route_hook_observer, observer)

  defp install_authority do
    identity = AdminRouteHost.Identity
    previous = identity.authority_pointer()
    {:ok, pid} = start_supervised({identity, authority: identity.default_authority()})
    identity.install_authority(pid)
    on_exit(fn -> identity.restore_authority(previous) end)
  end
end
