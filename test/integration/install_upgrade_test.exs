defmodule Lockspire.InstallUpgradeTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Lockspire.Install.Manifest

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

  test "manifests keep legacy shape readable and audit a deterministic migration inventory" do
    project_root =
      Path.join(System.tmp_dir!(), "lockspire-manifest-#{System.unique_integer([:positive])}")

    on_exit(fn -> File.rm_rf!(project_root) end)

    assigns = %{
      mount_path: "/lockspire",
      storage_prefix: "lockspire",
      oban_prefix: "lockspire",
      web_module: "ExampleWeb",
      scope_module: "Example.Lockspire"
    }

    managed = [%{relative_path: "config/lockspire.exs", rendered: "managed bytes"}]

    migrations = [
      %{
        version: "20260826000200",
        name: "create_gadgets",
        relative_path: "priv/repo/migrations/20260826000200_create_gadgets.exs",
        checksum: Manifest.checksum("gadgets")
      },
      %{
        version: "20260826000100",
        name: "create_widgets",
        relative_path: "priv/repo/migrations/20260826000100_create_widgets.exs",
        checksum: Manifest.checksum("widgets")
      }
    ]

    manifest = Manifest.build(assigns, managed, migrations)

    assert Enum.map(manifest["migrations"], & &1["version"]) == [
             "20260826000100",
             "20260826000200"
           ]

    assert Enum.all?(manifest["migrations"], fn migration ->
             Map.keys(migration) == ["checksum", "name", "path", "version"]
           end)

    assert :ok = Manifest.write(project_root, manifest)
    assert {:ok, ^manifest} = Manifest.load(project_root)

    legacy = Map.delete(manifest, "migrations")
    legacy_path = Manifest.path(project_root <> "-legacy")
    File.mkdir_p!(Path.dirname(legacy_path))
    File.write!(legacy_path, Jason.encode!(legacy, pretty: true))

    assert {:ok, ^legacy} = Manifest.load(project_root <> "-legacy")
  end

  test "mix lockspire.upgrade updates unchanged managed scaffolding and refreshes the manifest" do
    install_fixture!()

    capture_io(fn ->
      upgrade_fixture!(["--mount-path", "/oauth"])
    end)

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             ~s(mount_path: "/oauth")

    assert forwards_lockspire_router?(
             File.read!(
               Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex")
             ),
             "/oauth"
           )

    manifest = load_manifest!()
    assert manifest["inputs"]["mount_path"] == "/oauth"
  end

  test "mix lockspire.upgrade refuses drifted managed files" do
    install_fixture!()

    config_path = Path.join(@fixture_root, "config/lockspire.exs")
    File.write!(config_path, File.read!(config_path) <> "\n# local managed drift\n")

    assert_raise Mix.Error,
                 ~r/Lockspire upgrade refused because managed scaffolding drifted/,
                 fn ->
                   capture_io(fn ->
                     upgrade_fixture!(["--mount-path", "/oauth"])
                   end)
                 end

    assert File.read!(config_path) =~ "# local managed drift"
  end

  test "mix lockspire.upgrade ignores edited host-owned seams" do
    install_fixture!()

    resolver_path =
      Path.join(@fixture_root, "lib/generated_host_app/lockspire/account_resolver.ex")

    File.write!(resolver_path, File.read!(resolver_path) <> "\n# host-owned edit\n")

    capture_io(fn ->
      upgrade_fixture!(["--mount-path", "/oauth"])
    end)

    assert File.read!(resolver_path) =~ "# host-owned edit"

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             ~s(mount_path: "/oauth")
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

  defp forwards_lockspire_router?(source, mount_path) do
    {_ast, found?} =
      source
      |> Code.string_to_quoted!()
      |> Macro.prewalk(false, fn
        {:forward, _meta, [^mount_path, {:__aliases__, _alias_meta, [:Lockspire, :Web, :Router]}]} =
            node,
        _found? ->
          {node, true}

        node, found? ->
          {node, found?}
      end)

    found?
  end
end
