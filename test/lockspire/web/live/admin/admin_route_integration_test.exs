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

  defp restore_observer(:unset), do: :persistent_term.erase(:lockspire_admin_route_hook_observer)

  defp restore_observer(observer),
    do: :persistent_term.put(:lockspire_admin_route_hook_observer, observer)
end

defmodule Lockspire.Web.Live.Admin.ExpandedAdminRouteIntegrationTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest

  alias Lockspire.Web.AdminRouteHost

  @mounts [
    {AdminRouteHost.DefaultEndpoint, AdminRouteHost.DefaultRouter, "/lockspire",
     "/lockspire/admin"},
    {AdminRouteHost.NestedEndpoint, AdminRouteHost.NestedRouter, "/teams/ops/identity",
     "/teams/ops/identity/admin"},
    {AdminRouteHost.RootEndpoint, AdminRouteHost.RootRouter, "", "/admin"}
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

  for {endpoint, _router, mount, path} <- @mounts do
    @tag expanded_mount: path
    test "#{path} connects the real overview and clients pages and rejoins with fresh host hooks",
         %{expanded_mount: path} do
      {endpoint, router, mount, ^path} = Enum.find(@mounts, fn {_ep, _r, _m, p} -> p == path end)
      configure_mount(mount)

      for route <- [path, path <> "/clients"] do
        session = %{"host_staff_id" => "staff-1"}
        assert {:ok, view, html} = endpoint_live(endpoint, route, session)

        expected_module =
          if route == path,
            do: Lockspire.Web.Live.Admin.OverviewLive.Index,
            else: Lockspire.Web.Live.Admin.ClientsLive.Index

        assert view.module == expected_module
        assert html != ""
        first_pid = view.pid
        monitor = Process.monitor(first_pid)
        GenServer.stop(first_pid)
        assert_receive {:DOWN, ^monitor, :process, ^first_pid, _reason}

        assert {:ok, rejoined, _html} = endpoint_live(endpoint, route, session)
        assert rejoined.pid != first_pid
        assert rejoined.module == view.module
        assert_receive {:host_live_hook, "staff-1"}
        assert_receive {:host_live_hook, "staff-1"}
        assert_receive {:host_session_callback, _label}
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
    end
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

  defp endpoint_live(endpoint, path, session) do
    conn =
      build_conn()
      |> init_test_session(session)
      |> Phoenix.ConnTest.dispatch(endpoint, :get, path)

    Phoenix.LiveViewTest.__live__(conn, nil, [])
  end

  defp restore_env(key, {:ok, value}), do: Application.put_env(:lockspire, key, value)
  defp restore_env(key, :error), do: Application.delete_env(:lockspire, key)

  defp restore_observer(:unset), do: :persistent_term.erase(:lockspire_admin_route_hook_observer)

  defp restore_observer(observer),
    do: :persistent_term.put(:lockspire_admin_route_hook_observer, observer)
end
