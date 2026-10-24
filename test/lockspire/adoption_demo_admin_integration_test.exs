defmodule Lockspire.AdoptionDemoAdminIntegrationTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @repo_root Path.expand("../..", __DIR__)
  @demo_root Path.join(@repo_root, "examples/adoption_demo/lib")
  @router_path Path.join(
                 @repo_root,
                 "examples/adoption_demo/lib/adoption_demo_web/router.ex"
               )
  @endpoint Lockspire.AdoptionDemoTest.Endpoint

  setup_all do
    compile_demo_modules!()

    previous_endpoint = Application.fetch_env(:lockspire, @endpoint)

    Application.put_env(:lockspire, @endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false,
      render_errors: [view: Lockspire.Web.ErrorView, accepts: ~w(html json)],
      live_view: [signing_salt: "adoption-demo-test-live-view"]
    )

    unless Process.whereis(Lockspire.TestRepo) do
      start_supervised!(Lockspire.TestRepo)
    end

    start_supervised!(@endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    on_exit(fn -> restore_env(previous_endpoint) end)
    :ok
  end

  setup do
    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(Lockspire.TestRepo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(owner) end)
    :ok
  end

  test "demo router delegates its admin inventory to the canonical native route macro" do
    source = File.read!(@router_path)

    assert source =~ "Lockspire.Web.AdminRoutes.lockspire_admin_routes(\"/lockspire/admin\""
    refute source =~ "Phoenix.LiveView.Router.live"
    refute source =~ "Lockspire.Web.AdminRouter"
  end

  test "the demo router dispatches the exact canonical inventory and protects real HTTP and connected entry" do
    routes = Phoenix.Router.routes(AdoptionDemoWeb.Router)

    admin_routes =
      Enum.filter(routes, fn route ->
        route.plug == Phoenix.LiveView.Plug and
          (route.path == "/lockspire/admin" or
             String.starts_with?(route.path, "/lockspire/admin/"))
      end)

    expected =
      Enum.map(Lockspire.Web.AdminRoutes.__route_inventory__(), fn {path, view, action} ->
        {"/lockspire/admin" <> if(path == "/", do: "", else: path), view, action}
      end)

    actual =
      Enum.map(admin_routes, fn route ->
        {view, action, _opts, live_session} = route.metadata.phoenix_live_view

        assert %{
                 pipe_through: [
                   :browser,
                   :operator,
                   :admin_live_view_root_layout,
                   :lockspire_admin_mount
                 ]
               } =
                 Phoenix.Router.route_info(
                   AdoptionDemoWeb.Router,
                   route.verb |> Atom.to_string() |> String.upcase(),
                   concrete_path(route.path),
                   "localhost"
                 )

        assert live_session.name == :lockspire_admin

        assert hook_modules(live_session) == [
                 AdoptionDemoWeb.OperatorAuthorization,
                 Lockspire.Web.AdminMount
               ]

        {route.path, view, action}
      end)

    assert actual == expected

    refute Enum.any?(
             routes,
             &(&1.path == "/lockspire/admin" and &1.plug != Phoenix.LiveView.Plug)
           )

    anonymous = get(build_conn(), "/lockspire/admin")
    assert anonymous.status == 302

    assert Plug.Conn.get_resp_header(anonymous, "location") ==
             ["/login?return_to=%2Flockspire%2Fadmin"]

    nonstaff =
      build_conn()
      |> init_test_session(%{"demo_login" => "alice"})
      |> get("/lockspire/admin")

    assert nonstaff.status == 403
    assert nonstaff.resp_body =~ "Operator access requires the demo ops account"

    conn =
      build_conn()
      |> init_test_session(%{"demo_login" => "ops"})
      |> get("/lockspire/admin")

    assert conn.status == 200
    assert conn.resp_body =~ "Lockspire admin - Billingo"

    assert {:ok, view, html} = live(conn)
    assert view.module == Lockspire.Web.Live.Admin.OverviewLive.Index
    assert html =~ "Overview"
    assert render_patch(view, "/lockspire/admin/overview") =~ "Overview"
  end

  test "the LiveView hook resolves the session reference instead of trusting cached socket identity" do
    forged_socket = %Phoenix.LiveView.Socket{
      assigns:
        demo_socket_assigns(%{
          operator?: true,
          current_account: AdoptionDemo.Accounts.get("ops")
        })
    }

    assert {:halt, denied} =
             AdoptionDemoWeb.OperatorAuthorization.on_mount(:default, %{}, %{}, forged_socket)

    assert denied.redirected ==
             {:redirect, %{status: 302, to: "/login?return_to=%2Flockspire%2Fadmin"}}

    assert {:halt, denied_nonstaff} =
             AdoptionDemoWeb.OperatorAuthorization.on_mount(
               :default,
               %{},
               %{"demo_login" => "alice"},
               forged_socket
             )

    assert denied_nonstaff.redirected == denied.redirected
  end

  defp compile_demo_modules! do
    modules = [
      {AdoptionDemo.Accounts, "adoption_demo/accounts.ex"},
      {AdoptionDemoWeb, "adoption_demo_web.ex"},
      {AdoptionDemoWeb.HTML, "adoption_demo_web/html.ex"},
      {AdoptionDemoWeb.AdminRootLayout, "adoption_demo_web/admin_root_layout.ex"},
      {AdoptionDemoWeb.Plugs.CurrentAccount, "adoption_demo_web/plugs/current_account.ex"},
      {AdoptionDemoWeb.Plugs.RequireOperator, "adoption_demo_web/plugs/require_operator.ex"},
      {AdoptionDemoWeb.OperatorAuthorization, "adoption_demo_web/operator_authorization.ex"},
      {AdoptionDemoWeb.Router, "adoption_demo_web/router.ex"}
    ]

    for {module, relative} <- modules do
      unless Code.ensure_loaded?(module) do
        Code.compile_file(Path.join(@demo_root, relative))
      end
    end

    unless Code.ensure_loaded?(@endpoint) do
      Code.compile_string("""
      defmodule #{inspect(@endpoint)} do
        use Phoenix.Endpoint, otp_app: :lockspire

        @session_options [store: :cookie, key: "_adoption_demo_test", signing_salt: "demo-test-session"]
        socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])
        plug(Plug.Session, @session_options)
        plug(#{inspect(AdoptionDemoWeb.Router)})
      end
      """)
    end
  end

  defp hook_modules(live_session) do
    Enum.map(live_session.extra.on_mount, fn %{id: {module, _arg}} -> module end)
  end

  defp demo_socket_assigns(assigns), do: Map.put(assigns, :__changed__, %{})

  defp concrete_path(path) do
    path
    |> String.replace(":client_id", "demo-client")
    |> String.replace(":id", "demo-record")
  end

  defp restore_env({:ok, value}), do: Application.put_env(:lockspire, @endpoint, value)
  defp restore_env(:error), do: Application.delete_env(:lockspire, @endpoint)
end
