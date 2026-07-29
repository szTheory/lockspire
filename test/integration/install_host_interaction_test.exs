defmodule Lockspire.Integration.InstallHostInteractionTest do
  @moduledoc """
  Proves `mix lockspire.install` resolves app name, web module, router module,
  scope module, and repo module from a real, committed `mix phx.new` host
  pushed via `Mix.Project.in_project/4` -- not from module-override flag
  values the test itself supplied.

  `install_generator_test.exs:363-368` wraps the task in `File.cd!`, which
  changes the working directory but never the Mix project, so
  `Lockspire.Generators.Install.build_assigns/1` still answers `:lockspire`.
  Passing no module-override options here means a proof that would still pass
  with the host absent (INSTALL-02's exact defect) cannot pass this file.
  """

  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @moduletag :integration

  alias Lockspire.HostSnapshot

  @managed_destinations [
    "lib/host_app_web/router/lockspire.ex",
    "config/lockspire.exs",
    "lib/host_app/lockspire/account_resolver.ex",
    "lib/host_app/lockspire/interaction_handler.ex",
    "lib/host_app_web/live/lockspire_consent_live.ex",
    "lib/host_app_web/controllers/authorized_apps_controller.ex",
    "lib/host_app_web/controllers/authorized_apps_html.ex",
    "lib/host_app_web/controllers/authorized_apps_html/index.html.heex",
    "lib/host_app_web/controllers/lockspire_verification_controller.ex",
    "lib/host_app_web/controllers/lockspire_verification_html.ex",
    "lib/host_app_web/controllers/lockspire_verification_html/index.html.heex",
    "test/host_app/lockspire_fapi_smoke_e2e_test.exs"
  ]

  @manifest_path ".lockspire/install_manifest.json"

  setup do
    scratch = HostSnapshot.copy_to_scratch!()
    on_exit(fn -> File.rm_rf!(scratch) end)
    {:ok, scratch: scratch}
  end

  test "resolves app name, web module, router module, scope module, and repo module from the host with no module flags",
       %{scratch: scratch} do
    output =
      capture_io(fn ->
        Mix.Project.in_project(:host_app, scratch, fn _module ->
          Lockspire.Generators.Install.run([])
        end)
      end)

    # Mix.Project.in_project prints its own `==> host_app` project banner into
    # the same capture, so this must be a substring match, never equality.
    assert output =~ "Lockspire canonical onboarding next steps"

    config = File.read!(Path.join(scratch, "config/lockspire.exs"))
    assert config =~ "repo: HostApp.Repo"
    assert config =~ "account_resolver: HostApp.Lockspire.AccountResolver"

    router_path = Path.join(scratch, "lib/host_app_web/router/lockspire.ex")
    assert File.exists?(router_path)
    assert File.read!(router_path) =~ "defmodule HostAppWeb.Router.Lockspire"

    assert File.exists?(Path.join(scratch, "lib/host_app/lockspire/account_resolver.ex"))
    assert File.exists?(Path.join(scratch, "test/host_app/lockspire_fapi_smoke_e2e_test.exs"))

    # Negative controls -- the defect class this file exists to catch is
    # library-name leakage into host-shaped output. A generator that silently
    # fell back to Lockspire's own identity must fail these.
    refute config =~ "Lockspire.Repo"
    refute File.dir?(Path.join(scratch, "lib/lockspire"))
  end

  test "installing into a host with no prior Lockspire output creates every destination directory and file",
       %{scratch: scratch} do
    before_checksums = HostSnapshot.tree_checksums(scratch)

    for path <- @managed_destinations ++ [@manifest_path] do
      refute Map.has_key?(before_checksums, path),
             "expected #{path} to be absent from the scratch host before the install run"
    end

    capture_io(fn ->
      Mix.Project.in_project(:host_app, scratch, fn _module ->
        Lockspire.Generators.Install.run([])
      end)
    end)

    after_checksums = HostSnapshot.tree_checksums(scratch)

    for path <- @managed_destinations ++ [@manifest_path] do
      assert Map.has_key?(after_checksums, path),
             "expected #{path} to exist after the install run"
    end
  end
end
