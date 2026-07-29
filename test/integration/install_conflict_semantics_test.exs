defmodule Lockspire.Integration.InstallConflictSemanticsTest do
  @moduledoc """
  Proves `Lockspire.Generators.Install`'s plan-then-apply conflict semantics
  against a real, committed `mix phx.new` host pushed via
  `Mix.Project.in_project/4`.

  Before this plan, `Install.run/1` wrote files one at a time and raised on
  the first one that differed, then wrote the manifest afterward -- so a
  conflicted re-run wrote some files, aborted mid-loop, and never wrote the
  manifest, leaving the host in an unclear half-installed state (INSTALL-03).
  This module proves the fix: every conflict is reported in one refusal, the
  host tree is byte-identical before and after a refused run, and refusal
  output never echoes file contents.
  """

  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @moduletag :integration

  alias Lockspire.HostSnapshot

  setup do
    scratch = HostSnapshot.copy_to_scratch!()
    on_exit(fn -> File.rm_rf!(scratch) end)
    {:ok, scratch: scratch}
  end

  test "a conflicted re-run reports every conflicted destination and writes zero bytes",
       %{scratch: scratch} do
    capture_io(fn -> install!(scratch) end)

    router_path = Path.join(scratch, "lib/host_app_web/router/lockspire.ex")
    config_path = Path.join(scratch, "config/lockspire.exs")

    router_sentinel = "# SENTINEL_HOST_EDIT_ROUTER_9f3a1c\n"
    config_sentinel = "# SENTINEL_HOST_EDIT_CONFIG_2b7e6d\n"

    File.write!(router_path, File.read!(router_path) <> router_sentinel)
    File.write!(config_path, File.read!(config_path) <> config_sentinel)

    before_checksums = HostSnapshot.tree_checksums(scratch)

    refusal_output =
      capture_io(fn ->
        assert_raise Mix.Error, ~r/Lockspire install refused/, fn ->
          install!(scratch)
        end
      end)

    after_checksums = HostSnapshot.tree_checksums(scratch)

    assert after_checksums == before_checksums,
           "expected zero bytes written on a refused conflicted run"

    assert refusal_output =~ "REFUSE lib/host_app_web/router/lockspire.ex"
    assert refusal_output =~ "REFUSE config/lockspire.exs"

    refute refusal_output =~ "SENTINEL_HOST_EDIT_ROUTER_9f3a1c"
    refute refusal_output =~ "SENTINEL_HOST_EDIT_CONFIG_2b7e6d"
  end

  test "a destination differing only by a trailing newline classifies as a conflict",
       %{scratch: scratch} do
    capture_io(fn -> install!(scratch) end)

    config_path = Path.join(scratch, "config/lockspire.exs")
    File.write!(config_path, File.read!(config_path) <> "\n")

    before_checksums = HostSnapshot.tree_checksums(scratch)

    refusal_output =
      capture_io(fn ->
        assert_raise Mix.Error, ~r/Lockspire install refused/, fn ->
          install!(scratch)
        end
      end)

    after_checksums = HostSnapshot.tree_checksums(scratch)

    assert after_checksums == before_checksums
    assert refusal_output =~ "REFUSE config/lockspire.exs"
  end

  test "a destination that would escape the project root is refused, not written",
       %{scratch: scratch} do
    # `--web`/`--scope` values are derived through `Macro.underscore/1`, which
    # never emits two adjacent literal dots (it always inserts a `/` between
    # them), so a real `..` cannot survive that specific derivation chain --
    # verified empirically this session. The containment guard is defense in
    # depth against that chain changing, and against any other caller that
    # constructs assigns directly (as `Install.plan/1` is public API). Prove
    # the guard itself by overriding `web_path` post-derivation, bypassing
    # `Macro.underscore/1` the same way a future call site could.
    malicious_assigns =
      Mix.Project.in_project(:host_app, scratch, fn _module ->
        assigns = Lockspire.Generators.Install.build_assigns([])
        %{assigns | web_path: String.duplicate("../", 20) <> "tmp/lockspire_escape_probe"}
      end)

    before_checksums = HostSnapshot.tree_checksums(scratch)

    refusal_output =
      capture_io(fn ->
        assert_raise Mix.Error, ~r/Lockspire install refused/, fn ->
          malicious_assigns
          |> Lockspire.Generators.Install.plan()
          |> then(&Lockspire.Generators.Install.apply_plan!(malicious_assigns, &1))
        end
      end)

    after_checksums = HostSnapshot.tree_checksums(scratch)

    assert after_checksums == before_checksums,
           "expected zero bytes written when a destination escapes the project root"

    assert refusal_output =~ "escapes the project root"
  end

  test "a refused first-ever run leaves no install manifest", %{scratch: scratch} do
    config_path = Path.join(scratch, "config/lockspire.exs")
    File.mkdir_p!(Path.dirname(config_path))
    File.write!(config_path, "# pre-existing file the host already had before any install\n")

    manifest_path = Path.join(scratch, ".lockspire/install_manifest.json")
    refute File.exists?(manifest_path)

    capture_io(fn ->
      assert_raise Mix.Error, ~r/Lockspire install refused/, fn ->
        install!(scratch)
      end
    end)

    refute File.exists?(manifest_path),
           "expected no install manifest after a refused first-ever run"
  end

  describe "--dry-run" do
    test "against a clean host prints the full plan and writes nothing", %{scratch: scratch} do
      before_checksums = HostSnapshot.tree_checksums(scratch)

      output = capture_io(fn -> install!(scratch, dry_run: true) end)

      after_checksums = HostSnapshot.tree_checksums(scratch)

      assert after_checksums == before_checksums,
             "expected a dry run against a clean host to write nothing"

      assert output =~ "DRY-RUN config/lockspire.exs"
      assert output =~ "DRY-RUN lib/host_app_web/router/lockspire.ex"
      assert output =~ "DRY-RUN .lockspire/install_manifest.json"
      refute output =~ "Lockspire canonical onboarding next steps"
    end

    test "against a drifted host prints the full refusal list and raises", %{scratch: scratch} do
      capture_io(fn -> install!(scratch) end)

      router_path = Path.join(scratch, "lib/host_app_web/router/lockspire.ex")
      File.write!(router_path, File.read!(router_path) <> "# SENTINEL_DRY_RUN_DRIFT\n")

      before_checksums = HostSnapshot.tree_checksums(scratch)

      refusal_output =
        capture_io(fn ->
          assert_raise Mix.Error, ~r/Lockspire install refused/, fn ->
            install!(scratch, dry_run: true)
          end
        end)

      after_checksums = HostSnapshot.tree_checksums(scratch)

      assert after_checksums == before_checksums,
             "expected a refused dry run to write nothing"

      assert refusal_output =~ "REFUSE lib/host_app_web/router/lockspire.ex"
    end

    test "against a byte-identical prior install reports unchanged and writes nothing",
         %{scratch: scratch} do
      capture_io(fn -> install!(scratch) end)

      before_checksums = HostSnapshot.tree_checksums(scratch)

      output = capture_io(fn -> install!(scratch, dry_run: true) end)

      after_checksums = HostSnapshot.tree_checksums(scratch)

      assert after_checksums == before_checksums,
             "expected a dry run against an unchanged install to write nothing"

      assert output =~ "* unchanged config/lockspire.exs"
      assert output =~ "* unchanged .lockspire/install_manifest.json"
      refute output =~ "DRY-RUN"
    end
  end

  describe "manifest input and content drift" do
    test "a re-run with a differing web module is refused naming both values",
         %{scratch: scratch} do
      capture_io(fn -> install!(scratch) end)

      before_checksums = HostSnapshot.tree_checksums(scratch)

      refusal_output =
        capture_io(fn ->
          assert_raise Mix.Error, ~r/Lockspire install refused/, fn ->
            install!(scratch, web: "OtherWeb")
          end
        end)

      after_checksums = HostSnapshot.tree_checksums(scratch)

      assert after_checksums == before_checksums,
             "expected a refused input-drift run to write nothing, including no second file set"

      assert refusal_output =~ "REFUSE .lockspire/install_manifest.json"
      assert refusal_output =~ "web_module"
      assert refusal_output =~ "HostAppWeb"
      assert refusal_output =~ "OtherWeb"
    end

    test "a re-run with a differing mount path is refused naming both values",
         %{scratch: scratch} do
      capture_io(fn -> install!(scratch) end)

      before_checksums = HostSnapshot.tree_checksums(scratch)

      refusal_output =
        capture_io(fn ->
          assert_raise Mix.Error, ~r/Lockspire install refused/, fn ->
            install!(scratch, mount_path: "/auth")
          end
        end)

      after_checksums = HostSnapshot.tree_checksums(scratch)

      assert after_checksums == before_checksums

      assert refusal_output =~ "REFUSE .lockspire/install_manifest.json"
      assert refusal_output =~ "mount_path"
      assert refusal_output =~ "/lockspire"
      assert refusal_output =~ "/auth"
    end

    test "a manifest with a malformed inputs map is refused without crashing",
         %{scratch: scratch} do
      capture_io(fn -> install!(scratch) end)

      manifest_path = Path.join(scratch, ".lockspire/install_manifest.json")
      manifest = manifest_path |> File.read!() |> Jason.decode!()
      malformed = Map.put(manifest, "inputs", "not-a-map")
      File.write!(manifest_path, Jason.encode!(malformed, pretty: true))

      before_checksums = HostSnapshot.tree_checksums(scratch)

      refusal_output =
        capture_io(fn ->
          assert_raise Mix.Error, ~r/Lockspire install refused/, fn ->
            install!(scratch)
          end
        end)

      after_checksums = HostSnapshot.tree_checksums(scratch)

      assert after_checksums == before_checksums,
             "expected a refused malformed-manifest run to write nothing"

      assert refusal_output =~ "REFUSE .lockspire/install_manifest.json"
      assert refusal_output =~ "malformed"
    end

    test "a manifest the host edited directly is refused rather than overwritten",
         %{scratch: scratch} do
      capture_io(fn -> install!(scratch) end)

      manifest_path = Path.join(scratch, ".lockspire/install_manifest.json")
      File.write!(manifest_path, File.read!(manifest_path) <> "\n")

      before_checksums = HostSnapshot.tree_checksums(scratch)

      refusal_output =
        capture_io(fn ->
          assert_raise Mix.Error, ~r/Lockspire install refused/, fn ->
            install!(scratch)
          end
        end)

      after_checksums = HostSnapshot.tree_checksums(scratch)

      assert after_checksums == before_checksums,
             "expected a host-edited manifest to be refused, not silently overwritten"

      assert refusal_output =~ "REFUSE .lockspire/install_manifest.json"
    end

    test "an identical re-run still reports the manifest unchanged and writes nothing",
         %{scratch: scratch} do
      capture_io(fn -> install!(scratch) end)

      before_checksums = HostSnapshot.tree_checksums(scratch)

      output = capture_io(fn -> install!(scratch) end)

      after_checksums = HostSnapshot.tree_checksums(scratch)

      assert after_checksums == before_checksums
      assert output =~ "* unchanged .lockspire/install_manifest.json"
    end
  end

  defp install!(scratch, opts \\ []) do
    Mix.Project.in_project(:host_app, scratch, fn _module ->
      Lockspire.Generators.Install.run(opts)
    end)
  end
end
