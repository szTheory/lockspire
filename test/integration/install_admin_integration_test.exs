defmodule Lockspire.InstallAdminIntegrationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "installer-rendered router uses the canonical native admin integration" do
    suffix = System.unique_integer([:positive])
    web_module = "LockspireFresh#{suffix}Web"
    scope_module = "LockspireFresh#{suffix}.Lockspire"
    root = Path.join(System.tmp_dir!(), "lockspire-install-admin-#{suffix}")
    on_exit(fn -> File.rm_rf!(root) end)

    capture_io(fn ->
      Mix.Task.reenable("lockspire.install")

      Mix.Tasks.Lockspire.Install.run([
        "--web",
        web_module,
        "--scope",
        scope_module,
        "--path",
        root
      ])
    end)

    router_path = Path.join(root, "lib/#{Macro.underscore(web_module)}/router/lockspire.ex")
    router = File.read!(router_path)

    assert router =~ "Lockspire.Web.AdminRoutes.lockspire_admin_routes"
  end
end
