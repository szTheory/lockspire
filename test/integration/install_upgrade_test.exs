defmodule Lockspire.InstallUpgradeTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Lockspire.Install.Manifest
  alias Lockspire.Install.Migrations

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

  test "an opted-in FAPI smoke remains managed across dry-run and upgrade" do
    install_fixture!(["--with-fapi-smoke"])

    fapi_path = Path.join(@fixture_root, "test/generated_host_app/lockspire_fapi_smoke_e2e.exs")
    original = File.read!(fapi_path)

    dry_run = capture_io(fn -> upgrade_fixture!(["--dry-run"]) end)

    assert dry_run =~ "DRY-RUN test/generated_host_app/lockspire_fapi_smoke_e2e.exs"
    assert File.read!(fapi_path) == original

    capture_io(fn -> upgrade_fixture!(["--mount-path", "/oauth"]) end)

    assert File.exists?(fapi_path)

    assert "test/generated_host_app/lockspire_fapi_smoke_e2e.exs" in Enum.map(
             load_manifest!()["managed_files"],
             & &1["path"]
           )

    assert load_manifest!()["inputs"]["with_fapi_smoke"] == true
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

  test "public install copies packaged migrations, records them, and repeats byte-identically" do
    with_package_migrations!(
      %{
        "20260826000100_create_widgets.exs" => "create widgets"
      },
      fn source_root ->
        capture_io(&install_fixture!/0)

        migration_path =
          Path.join(@fixture_root, "priv/repo/migrations/20260826000100_create_widgets.exs")

        assert File.read!(migration_path) == "create widgets"

        assert [%{"path" => "priv/repo/migrations/20260826000100_create_widgets.exs"}] =
                 load_manifest!()["migrations"]

        before = tree_snapshot(@fixture_root)
        output = capture_io(&install_fixture!/0)

        assert output =~ "UNCHANGED priv/repo/migrations/20260826000100_create_widgets.exs"
        assert tree_snapshot(@fixture_root) == before

        assert source_root == Migrations.source_root()
      end
    )
  end

  test "public upgrade adds only newly packaged migrations and dry-run is non-mutating" do
    with_package_migrations!(
      %{
        "20260826000100_create_widgets.exs" => "create widgets"
      },
      fn source_root ->
        capture_io(&install_fixture!/0)

        second = Path.join(source_root, "20260826000200_create_gadgets.exs")
        File.write!(second, "create gadgets")

        before = tree_snapshot(@fixture_root)

        dry_run =
          capture_io(fn ->
            upgrade_fixture!(["--dry-run"])
          end)

        assert dry_run =~ "DRY-RUN COPY priv/repo/migrations/20260826000200_create_gadgets.exs"
        assert tree_snapshot(@fixture_root) == before

        capture_io(fn ->
          upgrade_fixture!([])
        end)

        assert File.read!(
                 Path.join(
                   @fixture_root,
                   "priv/repo/migrations/20260826000200_create_gadgets.exs"
                 )
               ) == "create gadgets"

        assert Enum.map(load_manifest!()["migrations"], & &1["version"]) == [
                 "20260826000100",
                 "20260826000200"
               ]
      end
    )
  end

  test "a legacy manifest without migration metadata remains a valid public upgrade input" do
    with_package_migrations!(
      %{
        "20260826000100_create_widgets.exs" => "create widgets"
      },
      fn _source_root ->
        capture_io(&install_fixture!/0)

        legacy_manifest = load_manifest!() |> Map.delete("migrations")
        File.write!(Manifest.path(@fixture_root), Jason.encode!(legacy_manifest, pretty: true))

        capture_io(fn ->
          upgrade_fixture!(["--mount-path", "/oauth"])
        end)

        assert File.read!(
                 Path.join(
                   @fixture_root,
                   "priv/repo/migrations/20260826000100_create_widgets.exs"
                 )
               ) == "create widgets"

        assert [%{"version" => "20260826000100"}] = load_manifest!()["migrations"]
      end
    )
  end

  test "a late upgrade migration collision leaves earlier additive candidates and manifest unchanged" do
    with_package_migrations!(
      %{
        "20260826000100_create_widgets.exs" => "create widgets"
      },
      fn source_root ->
        capture_io(&install_fixture!/0)

        File.write!(
          Path.join(source_root, "20260826000200_create_gadgets.exs"),
          "create gadgets"
        )

        conflict = "20260826000300_create_accounts.exs"
        File.write!(Path.join(source_root, conflict), "package accounts")

        host_conflict = Path.join(@fixture_root, "priv/repo/migrations/#{conflict}")
        File.write!(host_conflict, "host accounts")
        before = tree_snapshot(@fixture_root)

        assert_raise Mix.Error, ~r/Lockspire upgrade refused/, fn ->
          capture_io(fn -> upgrade_fixture!([]) end)
        end

        assert tree_snapshot(@fixture_root) == before

        refute File.exists?(
                 Path.join(
                   @fixture_root,
                   "priv/repo/migrations/20260826000200_create_gadgets.exs"
                 )
               )
      end
    )
  end

  test "a managed collision aborts public install before migrations or manifest mutate the host" do
    with_package_migrations!(
      %{
        "20260826000100_create_widgets.exs" => "create widgets"
      },
      fn _source_root ->
        config_path = Path.join(@fixture_root, "config/lockspire.exs")
        File.mkdir_p!(Path.dirname(config_path))
        File.write!(config_path, "# host-owned config\n")
        before = tree_snapshot(@fixture_root)

        assert_raise Mix.Error, ~r/Lockspire install refused/, fn ->
          capture_io(&install_fixture!/0)
        end

        assert tree_snapshot(@fixture_root) == before
        refute File.exists?(Path.join(@fixture_root, "priv/repo/migrations"))
        refute File.exists?(Manifest.path(@fixture_root))
      end
    )
  end

  test "a migration collision aborts public install before generated files or manifest mutate the host" do
    with_package_migrations!(
      %{
        "20260826000100_create_widgets.exs" => "package bytes"
      },
      fn _source_root ->
        collision =
          Path.join(@fixture_root, "priv/repo/migrations/20260826000100_create_widgets.exs")

        File.mkdir_p!(Path.dirname(collision))
        File.write!(collision, "host bytes")
        before = tree_snapshot(@fixture_root)

        assert_raise Mix.Error, ~r/Lockspire install refused/, fn ->
          capture_io(&install_fixture!/0)
        end

        assert tree_snapshot(@fixture_root) == before
        refute File.exists?(Path.join(@fixture_root, "config/lockspire.exs"))
        refute File.exists?(Manifest.path(@fixture_root))
      end
    )
  end

  defp install_fixture!(extra_args \\ []) do
    File.cd!(@fixture_root, fn ->
      Mix.Task.reenable("lockspire.install")

      Mix.Tasks.Lockspire.Install.run(
        [
          "--web",
          "GeneratedHostAppWeb",
          "--scope",
          "GeneratedHostApp.Lockspire"
        ] ++ extra_args
      )
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
    File.rm_rf!(Path.join(@fixture_root, "priv"))
    File.mkdir_p!(@fixture_root)
    File.write!(Path.join(@fixture_root, ".keep"), "")
  end

  defp with_package_migrations!(files, fun) do
    root =
      Path.join(
        System.tmp_dir!(),
        "lockspire-package-migrations-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)

    Enum.each(files, fn {filename, contents} ->
      File.write!(Path.join(root, filename), contents)
    end)

    try do
      Migrations.with_test_source_root(root, fn -> fun.(root) end)
    after
      File.rm_rf!(root)
    end
  end

  defp tree_snapshot(root) do
    root
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.sort()
    |> Enum.reduce(%{}, fn path, snapshot ->
      relative_path = Path.relative_to(path, root)

      value =
        cond do
          File.dir?(path) -> :directory
          File.regular?(path) -> File.read!(path)
          true -> :other
        end

      Map.put(snapshot, relative_path, value)
    end)
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
