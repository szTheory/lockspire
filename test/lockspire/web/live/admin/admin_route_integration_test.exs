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

    assert %{plug: Phoenix.LiveView.Plug, phoenix_live_view: {Lockspire.Web.Live.Admin.OverviewLive.Index, :index, _, _}} =
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

  defp restore_env(key, {:ok, value}), do: Application.put_env(:lockspire, key, value)
  defp restore_env(key, :error), do: Application.delete_env(:lockspire, key)

  defp restore_observer(:unset), do: :persistent_term.erase(:lockspire_admin_route_hook_observer)
  defp restore_observer(observer), do: :persistent_term.put(:lockspire_admin_route_hook_observer, observer)
end
