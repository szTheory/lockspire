defmodule Lockspire.InstallUpgradeTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Lockspire.Install.Manifest
  alias Lockspire.Install.FileTransaction
  alias Lockspire.Install.Migrations
  alias Lockspire.Install.OperationPlan
  alias Lockspire.Generators.Install

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

  test "a checksum-tracked v1.45 forward helper converts and preserves recorded host inputs" do
    install_fixture!([
      "--mount-path",
      "/teams/auth",
      "--storage-prefix",
      "tenant_data",
      "--oban-prefix",
      "tenant_jobs",
      "--with-fapi-smoke"
    ])

    router_path = Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex")
    historical_router = historical_router_bytes()
    File.write!(router_path, historical_router)

    seam_path = Path.join(@fixture_root, "lib/generated_host_app_web/operator_authorization.ex")
    File.rm!(seam_path)

    manifest = load_manifest!()

    legacy_manifest =
      manifest
      |> Map.delete("migrations")
      |> put_in(["inputs", "mount_path"], "/teams/auth")
      |> put_in(["inputs", "storage_prefix"], "tenant_data")
      |> put_in(["inputs", "oban_prefix"], "tenant_jobs")
      |> put_in(["inputs", "with_fapi_smoke"], true)
      |> update_in(["managed_files"], fn entries ->
        Enum.map(entries, fn
          %{"path" => "lib/generated_host_app_web/router/lockspire.ex"} = entry ->
            %{entry | "checksum" => Manifest.checksum(historical_router)}

          entry ->
            entry
        end)
      end)

    File.write!(Manifest.path(@fixture_root), Jason.encode!(legacy_manifest, pretty: true))
    preserved = tree_snapshot(@fixture_root)

    capture_io(fn -> upgrade_fixture!([]) end)

    converted = File.read!(router_path)
    assert converted =~ "Lockspire.Web.AdminRoutes.lockspire_admin_routes"
    refute converted =~ "forward(\"/\", Lockspire.Web.AdminRouter)"
    assert [{GeneratedHostAppWeb.Router.Lockspire, _}] = Code.compile_file(router_path)

    compiled_router =
      Code.compile_string("""
      defmodule GeneratedHostAppWeb.Router do
        use Phoenix.Router
        import GeneratedHostAppWeb.Router.Lockspire

        pipeline :browser do
          plug(:accepts, ["html"])
        end

        lockspire_routes()
      end
      """)

    assert Enum.any?(compiled_router, fn {module, _binary} ->
             module == GeneratedHostAppWeb.Router
           end)

    assert Lockspire.Web.Live.Admin.OverviewLive.Index ==
             Phoenix.Router.route_info(
               GeneratedHostAppWeb.Router,
               "GET",
               "/teams/auth/admin",
               "localhost"
             )
             |> Map.fetch!(:phoenix_live_view)
             |> elem(0)

    assert File.regular?(seam_path), "upgrade should create the absent authorization seam"
    assert File.read!(seam_path) =~ "Admin access is not configured."

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             ~s(storage_prefix: "tenant_data")

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             ~s(oban_prefix: "tenant_jobs")

    assert load_manifest!()["inputs"] == legacy_manifest["inputs"]

    refute "lib/generated_host_app_web/operator_authorization.ex" in Enum.map(
             load_manifest!()["managed_files"],
             & &1["path"]
           )

    assert File.read!(
             Path.join(@fixture_root, "lib/generated_host_app/lockspire/account_resolver.ex")
           ) ==
             preserved["lib/generated_host_app/lockspire/account_resolver.ex"]

    first_result = tree_snapshot(@fixture_root)
    capture_io(fn -> upgrade_fixture!([]) end)
    assert tree_snapshot(@fixture_root) == first_result
  end

  test "dry-run preserves the complete tree and refuses read-only while recovery is pending" do
    install_fixture!()
    clean_snapshot = tree_snapshot(@fixture_root)

    capture_io(fn -> upgrade_fixture!(["--dry-run"]) end)
    assert tree_snapshot(@fixture_root) == clean_snapshot

    File.rm!(Path.join(@fixture_root, "lib/generated_host_app_web/operator_authorization.ex"))
    manifest_contents = File.read!(Manifest.path(@fixture_root))

    artifacts = [
      %{
        relative_path: "lib/generated_host_app_web/operator_authorization.ex",
        kind: :host_owned,
        expected: :absent,
        contents: "interrupted policy",
        checksum: Manifest.checksum("interrupted policy"),
        provenance: "test bootstrap"
      },
      %{
        relative_path: ".lockspire/install_manifest.json",
        kind: :manifest,
        expected: Manifest.checksum(manifest_contents),
        contents: manifest_contents,
        checksum: Manifest.checksum(manifest_contents),
        provenance: "test manifest"
      }
    ]

    FileTransaction.with_test_failure(:after_host_owned_create, fn ->
      assert {:error, [%{type: :interrupted}]} = FileTransaction.apply(@fixture_root, artifacts)
    end)

    interrupted_snapshot = tree_snapshot(@fixture_root)
    assert FileTransaction.recovery_status(@fixture_root) |> elem(0) == :recovery_required

    assert_raise Mix.Error, ~r/Lockspire upgrade refused/, fn ->
      capture_io(fn -> upgrade_fixture!(["--dry-run"]) end)
    end

    assert tree_snapshot(@fixture_root) == interrupted_snapshot

    capture_io(fn -> upgrade_fixture!([]) end)
    assert FileTransaction.recovery_status(@fixture_root) == :clean
    assert tree_snapshot(@fixture_root) != interrupted_snapshot
  end

  test "stale preflight and competing plans refuse without replacing host bytes" do
    install_fixture!()
    manifest = load_manifest!()
    config_path = Path.join(@fixture_root, "config/lockspire.exs")
    original_config = File.read!(config_path)

    assigns =
      Install.build_assigns(
        web: "GeneratedHostAppWeb",
        scope: "GeneratedHostApp.Lockspire",
        path: @fixture_root
      )

    File.rm!(Path.join(@fixture_root, "lib/generated_host_app_web/operator_authorization.ex"))
    rendered = Install.rendered_templates(assigns)
    {:ok, create_plan} = OperationPlan.upgrade(assigns, rendered, manifest)
    policy_path = Path.join(@fixture_root, "lib/generated_host_app_web/operator_authorization.ex")
    File.write!(policy_path, "host policy wins")
    competing_snapshot = tree_snapshot(@fixture_root)

    assert {:error, [%{type: :approved_plan_changed}]} = OperationPlan.apply(create_plan)
    assert tree_snapshot(@fixture_root) == competing_snapshot

    changed_assigns = Map.put(assigns, :mount_path, "/oauth")

    {:ok, update_plan} =
      OperationPlan.upgrade(
        changed_assigns,
        Install.rendered_templates(changed_assigns),
        manifest
      )

    File.write!(config_path, File.read!(config_path) <> "\n# concurrent host edit\n")
    changed_snapshot = tree_snapshot(@fixture_root)

    assert {:error, errors} = OperationPlan.apply(update_plan)
    assert Enum.any?(errors, &(&1.type == :approved_plan_changed))
    assert tree_snapshot(@fixture_root) == changed_snapshot

    File.rm!(policy_path)
    File.write!(config_path, original_config)
    {:ok, first_plan} = OperationPlan.upgrade(assigns, rendered, manifest)
    {:ok, second_plan} = OperationPlan.upgrade(assigns, rendered, manifest)
    assert {:ok, _} = OperationPlan.apply(first_plan)
    winning_policy = File.read!(policy_path)
    winner_snapshot = tree_snapshot(@fixture_root)

    assert {:error, errors} = OperationPlan.apply(second_plan)
    assert Enum.any?(errors, &(&1.type == :approved_plan_changed))
    assert File.read!(policy_path) == winning_policy
    assert tree_snapshot(@fixture_root) == winner_snapshot
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

    authorization_path =
      Path.join(@fixture_root, "lib/generated_host_app_web/operator_authorization.ex")

    File.write!(resolver_path, File.read!(resolver_path) <> "\n# host-owned edit\n")
    File.write!(authorization_path, File.read!(authorization_path) <> "\n# host policy edit\n")
    authorization = File.read!(authorization_path)

    capture_io(fn ->
      upgrade_fixture!(["--mount-path", "/oauth"])
    end)

    assert File.read!(resolver_path) =~ "# host-owned edit"
    assert File.read!(authorization_path) == authorization

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

        legacy_manifest =
          load_manifest!()
          |> Map.delete("migrations")
          |> update_in(["inputs"], &Map.delete(&1, "with_fapi_smoke"))

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

  test "duplicate or malformed managed manifest entries refuse before host mutations" do
    install_fixture!()
    manifest = load_manifest!()
    [entry | _] = manifest["managed_files"]

    for entries <- [[entry, entry], [%{"path" => entry["path"]}]] do
      candidate = %{manifest | "managed_files" => entries}
      File.write!(Manifest.path(@fixture_root), Jason.encode!(candidate, pretty: true))
      before = tree_snapshot(@fixture_root)

      assert_raise Mix.Error, ~r/Lockspire upgrade refused/, fn ->
        capture_io(fn -> upgrade_fixture!([]) end)
      end

      assert tree_snapshot(@fixture_root) == before
    end
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

  defp historical_router_bytes do
    assigns = %{
      web_module: "GeneratedHostAppWeb",
      web_path: "generated_host_app_web",
      mount_path: "/teams/auth"
    }

    template =
      Path.expand("../support/fixtures/install_upgrade/v1_45_forward_router.ex.eex", __DIR__)

    rendered = EEx.eval_file(template, assigns: assigns)

    header =
      """
      # Lockspire-managed scaffolding
      # Safe to update later only through `mix lockspire.upgrade` when the manifest says this file is unchanged.
      # Keep this file unchanged if you want future managed upgrades to apply automatically.

      """

    header <> rendered
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
