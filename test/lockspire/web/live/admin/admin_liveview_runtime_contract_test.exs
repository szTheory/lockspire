defmodule Lockspire.Web.Live.Admin.LiveViewRuntimeContractTest do
  use ExUnit.Case, async: false

  import Plug.Test

  test "the adoption demo scopes a root layout and LiveView boot to the admin route" do
    Code.compile_file("examples/adoption_demo/lib/adoption_demo_web/plugs/current_account.ex")
    Code.compile_file("examples/adoption_demo/lib/adoption_demo_web/plugs/require_operator.ex")
    Code.compile_file("examples/adoption_demo/lib/adoption_demo_web/router.ex")

    router_source = File.read!("examples/adoption_demo/lib/adoption_demo_web/router.ex")
    endpoint_source = File.read!("examples/adoption_demo/lib/adoption_demo_web/endpoint.ex")

    layout_source =
      File.read!("examples/adoption_demo/lib/adoption_demo_web/admin_root/root.html.heex")

    assert router_source =~ "scope \"/lockspire/admin\" do"
    assert router_source =~ "pipe_through([:browser, :operator, :admin_live_view_root_layout])"

    assert router_source =~
             "Phoenix.Controller.put_root_layout(conn, html: {AdoptionDemoWeb.AdminRootLayout, :root})"

    refute router_source =~ "scope \"/lockspire/adminfoo\""

    expected_paths =
      Lockspire.Web.AdminRouter
      |> Phoenix.Router.routes()
      |> Enum.map(& &1.path)
      |> MapSet.new()

    mounted_admin_routes =
      AdoptionDemoWeb.Router
      |> Phoenix.Router.routes()
      |> Enum.filter(&(&1.plug == Phoenix.LiveView.Plug))
      |> Enum.filter(&String.starts_with?(&1.path, "/lockspire/admin"))

    mounted_paths =
      mounted_admin_routes
      |> Enum.map(fn route ->
        case String.replace_prefix(route.path, "/lockspire/admin", "") do
          "" -> "/"
          relative_path -> relative_path
        end
      end)
      |> MapSet.new()

    assert mounted_paths == expected_paths

    assert Enum.all?(mounted_admin_routes, fn route ->
             pipeline =
               AdoptionDemoWeb.Router
               |> Phoenix.Router.route_info(
                 String.upcase(to_string(route.verb)),
                 route.path,
                 "localhost"
               )
               |> Map.fetch!(:pipe_through)

             :browser in pipeline and :operator in pipeline and
               :admin_live_view_root_layout in pipeline
           end)

    assert Enum.any?(
             Phoenix.Router.routes(AdoptionDemoWeb.Router),
             &(&1.plug == Lockspire.Web.AdminRouter)
           )

    assert endpoint_source =~ "from: :phoenix"
    assert endpoint_source =~ "only: ~w(phoenix.js)"
    assert endpoint_source =~ "from: :phoenix_live_view"
    assert endpoint_source =~ "only: ~w(phoenix_live_view.js)"
    assert endpoint_source =~ "only: ~w(lockspire-admin-live-view.js)"
    assert endpoint_source =~ "@session_options ["
    assert endpoint_source =~ "websocket: [connect_info: [session: @session_options]]"
    assert endpoint_source =~ "plug(Plug.Session, @session_options)"
    assert endpoint_source =~ ~s(key: "_adoption_demo_key")
    assert endpoint_source =~ ~s(signing_salt: "adoption_demo_session")

    assert layout_source =~ ~s(name="csrf-token")
    assert layout_source =~ ~s(src="/lockspire-assets/phoenix.js")
    assert layout_source =~ ~s(src="/lockspire-assets/phoenix_live_view.js")
    assert layout_source =~ ~s(src="/lockspire-assets/lockspire-admin-live-view.js")

    bootstrap_source =
      File.read!("examples/adoption_demo/priv/static/lockspire-admin-live-view.js")

    assert bootstrap_source =~ "window.liveSocket ||"
    assert bootstrap_source =~ "new window.LiveView.LiveSocket(\"/live\", window.Phoenix.Socket"
    assert bootstrap_source =~ "meta[name=\"csrf-token\"]"
  end

  test "the demo serves only the required Phoenix LiveView browser assets" do
    for {app, asset, marker} <- [
          {:phoenix, "phoenix.js", "var Phoenix ="},
          {:phoenix_live_view, "phoenix_live_view.js", "var LiveView ="}
        ] do
      conn =
        conn(:get, "/lockspire-assets/#{asset}")
        |> Plug.Static.call(
          Plug.Static.init(
            at: "/lockspire-assets",
            from: app,
            only: [asset]
          )
        )

      assert conn.status == 200
      assert conn.resp_body =~ marker
    end

    bootstrap_conn =
      conn(:get, "/lockspire-assets/lockspire-admin-live-view.js")
      |> Plug.Static.call(
        Plug.Static.init(
          at: "/lockspire-assets",
          from: Path.expand("examples/adoption_demo/priv/static"),
          only: ["lockspire-admin-live-view.js"]
        )
      )

    assert bootstrap_conn.status == 200
    assert bootstrap_conn.resp_body =~ "window.liveSocket ||"
  end
end
