defmodule Lockspire.InstallAdminIntegrationTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import ExUnit.CaptureIO

  setup_all do
    unless Process.whereis(Lockspire.TestRepo), do: start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(Lockspire.TestRepo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(owner) end)
    :ok
  end

  test "installer-rendered router uses the canonical native admin integration" do
    host = build_host!()
    seam_module = host.seam_module
    router_helper_module = host.router_helper_module
    router_module = host.router_module
    endpoint_module = host.endpoint_module

    assert File.read!(host.router_helper_path) =~
             "Lockspire.Web.AdminRoutes.lockspire_admin_routes"

    assert [{^seam_module, _binary}] = Code.compile_file(host.seam_path)
    assert [{^router_helper_module, _binary}] = Code.compile_file(host.router_helper_path)

    assert_compiled!(router_module, Code.compile_string(host_router_source(host), host.root))

    assert [{^endpoint_module, _binary}] =
             Code.compile_string(host_endpoint_source(host), host.root)

    start_endpoint!(host)

    conn = request(host, "/lockspire/admin")
    assert conn.status == 403
    assert conn.halted
    assert conn.resp_body == "Admin access is not configured."

    socket = %Phoenix.LiveView.Socket{assigns: %{operator?: true, current_staff: "staff-1"}}

    assert {:halt, redirected} =
             host.seam_module.on_mount(
               :default,
               %{},
               %{"host_staff_id" => "staff-1"},
               socket
             )

    assert redirected.redirected == {:redirect, %{status: 302, to: "/"}}

    for session <- [nil, %{}] do
      assert {:halt, denied} = host.seam_module.on_mount(:default, %{}, session, socket)
      assert denied.redirected == {:redirect, %{status: 302, to: "/"}}
    end

    connected_socket = %{socket | transport_pid: self()}

    assert {:halt, connected_redirected} =
             host.seam_module.on_mount(
               :default,
               %{},
               %{"host_staff_id" => "staff-1"},
               connected_socket
             )

    assert connected_redirected.redirected == {:redirect, %{status: 302, to: "/"}}
  end

  test "an explicitly implemented host policy connects its rendered admin overview" do
    host = build_host!()
    File.write!(host.seam_path, authorized_policy_source(host))
    seam_module = host.seam_module
    router_helper_module = host.router_helper_module
    router_module = host.router_module
    endpoint_module = host.endpoint_module

    assert [{^seam_module, _binary}] = Code.compile_file(host.seam_path)
    assert [{^router_helper_module, _binary}] = Code.compile_file(host.router_helper_path)

    assert_compiled!(router_module, Code.compile_string(host_router_source(host), host.root))

    assert [{^endpoint_module, _binary}] =
             Code.compile_string(host_endpoint_source(host), host.root)

    start_endpoint!(host)

    conn = request(host, "/lockspire/admin", %{"host_staff_id" => "staff-1"})
    assert conn.status == 200
    assert conn.resp_body =~ "Overview"

    assert {:ok, view, html} = Phoenix.LiveViewTest.__live__(conn, nil, [])
    assert view.module == Lockspire.Web.Live.Admin.OverviewLive.Index
    assert html =~ "Overview"
  end

  defp build_host! do
    suffix = System.unique_integer([:positive])
    web_name = "LockspireFresh#{suffix}Web"
    scope_name = "LockspireFresh#{suffix}.Lockspire"
    root = Path.join(System.tmp_dir!(), "lockspire-install-admin-#{suffix}")
    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)

    capture_io(fn ->
      Mix.Task.reenable("lockspire.install")

      Mix.Tasks.Lockspire.Install.run([
        "--web",
        web_name,
        "--scope",
        scope_name,
        "--path",
        root
      ])
    end)

    endpoint_module = Module.concat([web_name, "Endpoint"])
    previous_mount = Application.get_env(:lockspire, :mount_path)
    previous_endpoint = Application.get_env(:lockspire, endpoint_module)
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    Application.put_env(:lockspire, endpoint_module,
      secret_key_base: String.duplicate("a", 64),
      server: false,
      live_view: [signing_salt: "fresh-admin-test-salt"]
    )

    on_exit(fn ->
      restore_env(:mount_path, previous_mount)
      restore_env(endpoint_module, previous_endpoint)
    end)

    %{
      root: root,
      endpoint_module: endpoint_module,
      router_module: Module.concat([web_name, "Router"]),
      router_helper_module: Module.concat([web_name, "Router", "Lockspire"]),
      seam_module: Module.concat([web_name, "OperatorAuthorization"]),
      seam_path: Path.join(root, "lib/#{Macro.underscore(web_name)}/operator_authorization.ex"),
      router_helper_path: Path.join(root, "lib/#{Macro.underscore(web_name)}/router/lockspire.ex")
    }
  end

  defp host_router_source(host) do
    """
    defmodule #{inspect(host.router_module)} do
      use Phoenix.Router
      import #{inspect(host.router_helper_module)}

      pipeline :browser do
        plug(:accepts, ["html"])
        plug(:fetch_session)
        plug(:protect_from_forgery)
        plug(:put_secure_browser_headers)
      end

      lockspire_routes()
    end
    """
  end

  defp host_endpoint_source(host) do
    """
    defmodule #{inspect(host.endpoint_module)} do
      use Phoenix.Endpoint, otp_app: :lockspire

      @session_options [store: :cookie, key: "_lockspire_fresh_host", signing_salt: "fresh-host-session"]
      socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])
      plug(Plug.Session, @session_options)
      plug(#{inspect(host.router_module)})
    end
    """
  end

  defp authorized_policy_source(host) do
    """
    defmodule #{inspect(host.seam_module)} do
      @behaviour Plug
      import Phoenix.LiveView, only: [redirect: 2]

      def init(opts), do: opts

      def call(conn, _opts) do
        conn = Plug.Conn.fetch_session(conn)

        if Plug.Conn.get_session(conn, "host_staff_id") == "staff-1" do
          Plug.Conn.assign(conn, :current_staff, "staff-1")
        else
          conn |> Plug.Conn.send_resp(:forbidden, "host policy denied") |> Plug.Conn.halt()
        end
      end

      def on_mount(_name, _params, session, socket) do
        if session["host_staff_id"] == "staff-1" do
          {:cont, Phoenix.Component.assign(socket, :current_staff, "staff-1")}
        else
          {:halt, redirect(socket, to: "/")}
        end
      end
    end
    """
  end

  defp request(host, path, session \\ %{}) do
    conn =
      Plug.Test.conn(:get, path)
      |> init_test_session(session)
      |> Plug.Conn.put_private(:phoenix_endpoint, host.endpoint_module)

    apply(host.endpoint_module, :call, [conn, apply(host.endpoint_module, :init, [[]])])
  end

  defp start_endpoint!(host), do: start_supervised!(host.endpoint_module)

  defp assert_compiled!(module, compiled_modules) do
    assert Enum.any?(compiled_modules, fn {compiled, _binary} -> compiled == module end)
  end

  defp restore_env(key, nil), do: Application.delete_env(:lockspire, key)
  defp restore_env(key, value), do: Application.put_env(:lockspire, key, value)
end
