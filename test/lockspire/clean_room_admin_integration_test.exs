defmodule Lockspire.CleanRoomAdminIntegrationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  import Plug.Test

  @repo_root Path.expand("../..", __DIR__)
  @builder Path.join(@repo_root, "scripts/acceptance/clean_room/build_provider.py")
  @overlay_root Path.join(@repo_root, "test/clean_room/provider_host/lib")

  test "clean-room overlay compiles installer routes at default and custom mounts and denies by default" do
    for mount_path <- ["/lockspire", "/teams/ops/identity"] do
      host = install_overlay_host!(mount_path)

      assert_compiled?(host.authorization_module, Code.compile_file(host.authorization_path))

      assert_compiled?(host.helper_module, Code.compile_file(host.helper_path))

      assert_compiled?(host.router_module, Code.compile_file(host.router_path))
      assert_compiled?(host.endpoint_module, Code.compile_file(host.endpoint_path))

      assert Path.wildcard(Path.join(host.root, "**/operator_authorization.ex")) ==
               [host.authorization_path]

      assert File.read!(host.authorization_path) == host.expected_authorization

      routes = Phoenix.Router.routes(host.router_module)
      admin_prefix = mount_path <> "/admin"

      admin_routes =
        Enum.filter(routes, fn route ->
          route.plug == Phoenix.LiveView.Plug and
            (route.path == admin_prefix or String.starts_with?(route.path, admin_prefix <> "/"))
        end)

      expected =
        Enum.map(Lockspire.Web.AdminRoutes.__route_inventory__(), fn {path, view, action} ->
          {admin_prefix <> if(path == "/", do: "", else: path), view, action}
        end)

      actual =
        Enum.map(admin_routes, fn route ->
          {view, action, _opts, session} = route.metadata.phoenix_live_view
          assert session.name == :lockspire_admin

          assert %{
                   pipe_through: [
                     :browser,
                     :lockspire_operator_authorization,
                     :lockspire_admin_mount
                   ]
                 } =
                   Phoenix.Router.route_info(
                     host.router_module,
                     "GET",
                     concrete_path(route.path),
                     "localhost"
                   )

          {route.path, view, action}
        end)

      assert actual == expected
      assert length(admin_routes) == 29

      assert Phoenix.Router.route_info(
               host.router_module,
               "GET",
               mount_path <> "/jwks",
               "localhost"
             ).plug ==
               Lockspire.Web.Router

      denied_http = host.authorization_module.call(:get |> conn(admin_prefix), [])

      assert denied_http.halted
      assert denied_http.status == 403
      assert denied_http.resp_body == "operator authorization required"

      assert {:halt, denied_live} =
               host.authorization_module.on_mount(
                 :default,
                 %{},
                 %{"host_staff_id" => "forged"},
                 %Phoenix.LiveView.Socket{}
               )

      assert denied_live.redirected == {:redirect, %{status: 302, to: "/"}}
    end
  end

  defp install_overlay_host!(mount_path) do
    suffix = System.unique_integer([:positive])
    root = Path.join(System.tmp_dir!(), "lockspire-clean-room-overlay-#{suffix}")
    web_name = "CleanRoomProviderTest#{suffix}Web"
    scope_name = "CleanRoomProviderTest#{suffix}.Lockspire"
    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    emit_builder_runtime!(root)

    capture_io(fn ->
      Mix.Task.reenable("lockspire.install")

      Mix.Tasks.Lockspire.Install.run([
        "--web",
        web_name,
        "--scope",
        scope_name,
        "--mount-path",
        mount_path,
        "--path",
        root
      ])
    end)

    web_path = Macro.underscore(web_name)
    authorization_path = Path.join(root, "lib/#{web_path}/operator_authorization.ex")
    router_path = Path.join(root, "lib/#{web_path}/router.ex")
    helper_path = Path.join(root, "lib/#{web_path}/router/lockspire.ex")
    endpoint_path = Path.join(root, "lib/#{web_path}/endpoint.ex")

    expected_authorization =
      Path.join(@overlay_root, "clean_room_provider_web/operator_authorization.ex")
      |> File.read!()
      |> String.replace("CleanRoomProviderWeb", web_name)

    File.write!(authorization_path, expected_authorization)

    router_source =
      Path.join(@overlay_root, "clean_room_provider_web/router_patch.exs")
      |> File.read!()
      |> String.replace("CleanRoomProviderWeb", web_name)

    File.write!(router_path, router_source)

    builder_endpoint_path = Path.join(root, "lib/clean_room_provider_web/endpoint.ex")

    endpoint_source =
      File.read!(builder_endpoint_path)
      |> String.replace("CleanRoomProviderWeb", web_name)

    File.write!(endpoint_path, endpoint_source)

    %{
      root: root,
      authorization_module: Module.concat([web_name, "OperatorAuthorization"]),
      router_module: Module.concat([web_name, "Router"]),
      helper_module: Module.concat([web_name, "Router", "Lockspire"]),
      endpoint_module: Module.concat([web_name, "Endpoint"]),
      authorization_path: authorization_path,
      router_path: router_path,
      helper_path: helper_path,
      endpoint_path: endpoint_path,
      expected_authorization: expected_authorization
    }
  end

  defp emit_builder_runtime!(root) do
    script = """
    import importlib.util
    import os
    from pathlib import Path
    import sys

    builder_path = Path(os.environ["LOCKSPIRE_PROVIDER_BUILDER"])
    sys.path.insert(0, str(builder_path.parent))
    spec = importlib.util.spec_from_file_location("build_provider", builder_path)
    builder = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(builder)
    builder.write_host_runtime(Path(os.environ["LOCKSPIRE_TEST_HOST"]), "postgres://localhost/clean_room")
    """

    assert {_, 0} =
             System.cmd("python3", ["-c", script],
               env: [
                 {"LOCKSPIRE_PROVIDER_BUILDER", @builder},
                 {"LOCKSPIRE_TEST_HOST", root}
               ],
               stderr_to_stdout: true
             )
  end

  defp concrete_path(path) do
    path
    |> String.replace(":client_id", "demo-client")
    |> String.replace(":id", "demo-record")
  end

  defp assert_compiled?(expected, compiled) do
    assert Enum.any?(compiled, fn {module, _binary} -> module == expected end)
  end
end
