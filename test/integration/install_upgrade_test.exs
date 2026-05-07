defmodule Lockspire.InstallUpgradeTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @fixture_root Path.expand("../support/fixtures/generated_host_app", __DIR__)

  setup do
    reset_fixture!()
    on_exit(&reset_fixture!/0)
    :ok
  end

  test "mix lockspire.upgrade --dry-run lists managed files without writing them" do
    install_fixture!()

    original_config = File.read!(Path.join(@fixture_root, "config/lockspire.exs"))

    output =
      capture_io(fn ->
        upgrade_fixture!(["--mount-path", "/oauth", "--dry-run"])
      end)

    assert output =~ "DRY-RUN config/lockspire.exs"
    assert output =~ "DRY-RUN lib/generated_host_app_web/router/lockspire.ex"
    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) == original_config
  end

  test "mix lockspire.upgrade updates unchanged managed scaffolding and refreshes the manifest" do
    install_fixture!()

    capture_io(fn ->
      upgrade_fixture!(["--mount-path", "/oauth"])
    end)

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~ ~s(mount_path: "/oauth")

    assert File.read!(Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex")) =~
             ~s(forward "/oauth", Lockspire.Web.Router)

    manifest = load_manifest!()
    assert manifest["inputs"]["mount_path"] == "/oauth"
  end

  test "mix lockspire.upgrade refuses drifted managed files" do
    install_fixture!()

    config_path = Path.join(@fixture_root, "config/lockspire.exs")
    File.write!(config_path, File.read!(config_path) <> "\n# local managed drift\n")

    assert_raise Mix.Error, ~r/Lockspire upgrade refused because managed scaffolding drifted/, fn ->
      capture_io(fn ->
        upgrade_fixture!(["--mount-path", "/oauth"])
      end)
    end

    assert File.read!(config_path) =~ "# local managed drift"
  end

  test "mix lockspire.upgrade ignores edited host-owned seams" do
    install_fixture!()

    resolver_path = Path.join(@fixture_root, "lib/generated_host_app/lockspire/account_resolver.ex")
    File.write!(resolver_path, File.read!(resolver_path) <> "\n# host-owned edit\n")

    capture_io(fn ->
      upgrade_fixture!(["--mount-path", "/oauth"])
    end)

    assert File.read!(resolver_path) =~ "# host-owned edit"
    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~ ~s(mount_path: "/oauth")
  end

  defp install_fixture! do
    File.cd!(@fixture_root, fn ->
      Mix.Task.reenable("lockspire.install")

      Mix.Tasks.Lockspire.Install.run([
        "--web",
        "GeneratedHostAppWeb",
        "--scope",
        "GeneratedHostApp.Lockspire"
      ])
    end)
  end

  defp upgrade_fixture!(extra_args) do
    File.cd!(@fixture_root, fn ->
      Mix.Task.reenable("lockspire.upgrade")

      Mix.Tasks.Lockspire.Upgrade.run(
        [
          "--web",
          "GeneratedHostAppWeb",
          "--scope",
          "GeneratedHostApp.Lockspire"
        ] ++ extra_args
      )
    end)
  end

  defp load_manifest! do
    @fixture_root
    |> Path.join(".lockspire/install_manifest.json")
    |> File.read!()
    |> Jason.decode!()
  end

  defp reset_fixture! do
    File.rm_rf!(Path.join(@fixture_root, ".lockspire"))
    File.rm_rf!(Path.join(@fixture_root, "config"))
    File.rm_rf!(Path.join(@fixture_root, "lib"))
    File.rm_rf!(Path.join(@fixture_root, "test"))
    File.mkdir_p!(@fixture_root)
    File.write!(Path.join(@fixture_root, ".keep"), "")
  end
end
