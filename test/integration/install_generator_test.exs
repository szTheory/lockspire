defmodule Lockspire.InstallGeneratorTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @fixture_root Path.expand("../support/fixtures/generated_host_app", __DIR__)
  @runtime_fixture_root Path.expand("../support/generated_host_app_web", __DIR__)

  setup do
    reset_fixture!()
    on_exit(&reset_fixture!/0)
    :ok
  end

  test "mix lockspire.install writes the host-owned integration files" do
    original_mount_path = Application.get_env(:lockspire, :mount_path)

    on_exit(fn ->
      if is_nil(original_mount_path) do
        Application.delete_env(:lockspire, :mount_path)
      else
        Application.put_env(:lockspire, :mount_path, original_mount_path)
      end
    end)

    Application.delete_env(:lockspire, :mount_path)

    output =
      capture_io(fn ->
        install_fixture!()
      end)

    # Sanity check: total templates rendered. Update this constant if a future plan
    # adds or removes a template. Baseline at Plan 43-04 write time was 11; the FAPI
    # smoke template makes it 12.
    assert length(Lockspire.Generators.Templates.all()) == 12

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             "config :lockspire"

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             "Lockspire-managed scaffolding"

    manifest = load_manifest!()

    assert manifest["version"] == Application.spec(:lockspire, :vsn) |> List.to_string()
    assert manifest["version"] =~ ~r/^\d+\.\d+\.\d+/
    assert manifest["inputs"]["mount_path"] == "/lockspire"
    assert manifest["inputs"]["storage_prefix"] == "lockspire"
    assert manifest["inputs"]["oban_prefix"] == "lockspire"

    managed_paths =
      manifest["managed_files"]
      |> Enum.map(& &1["path"])
      |> Enum.sort()

    assert "config/lockspire.exs" in managed_paths
    assert "lib/generated_host_app_web/router/lockspire.ex" in managed_paths
    assert "test/generated_host_app/lockspire_fapi_smoke_e2e_test.exs" in managed_paths
    refute Enum.any?(managed_paths, &String.contains?(&1, "account_resolver.ex"))

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             ~s(import_config "lockspire.exs")

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             "account_resolver: GeneratedHostApp.Lockspire.AccountResolver"

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             ~s(storage_prefix: "lockspire")

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             ~s(oban_prefix: "lockspire")

    config = File.read!(Path.join(@fixture_root, "config/lockspire.exs"))

    # ADOPT-D04: the issuer must include the mount path or Lockspire's own
    # issuer/mount-path consistency check raises at boot.
    assert config =~ ~s(issuer: "https://example.com/lockspire")
    assert config =~ ~s(known_scopes: ["openid", "email", "profile"])
    assert config =~ ~s(signing_alg: "RS256")
    assert config =~ "secret_key_base:"

    # ADOPT-D04/T-127-02: assert the placeholder positively (so a missing key
    # can't vacuously satisfy the negative check below) and assert no run of
    # 32+ hex/base64url characters exists anywhere in the rendered config
    # except one naming its own replacement -- no secret literal may ship.
    assert config =~ "REPLACE"

    long_runs = Regex.scan(~r/[A-Za-z0-9+\/=_-]{32,}/, config) |> List.flatten()

    assert Enum.all?(long_runs, &(&1 =~ ~r/REPLACE|GENERATE/)),
           "rendered config must not contain an unlabeled secret-shaped literal: #{inspect(long_runs)}"

    assert File.read!(Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex")) =~
             ~s<forward("/lockspire", Lockspire.Web.Router)>

    assert File.read!(Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex")) =~
             ~s<get("/authorized-apps", AuthorizedAppsController, :index)>

    router =
      File.read!(Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex"))

    assert router =~ ~s<get("/verify", LockspireVerificationController, :show)>
    assert router =~ ~s<post("/verify", LockspireVerificationController, :lookup)>

    assert router =~
             ~s<post("/verify/:handle/approve", LockspireVerificationController, :approve)>

    assert router =~ ~s<post("/verify/:handle/deny", LockspireVerificationController, :deny)>
    assert router =~ "prefill-only"
    assert router =~ "device-flow-host-guide.md"
    assert router =~ ~s(scope "/lockspire/admin")
    assert router =~ "pipe_through([:browser, :lockspire_require_operator])"
    assert router =~ ~s<forward("/", Lockspire.Web.AdminRouter)>
    assert router =~ "Do not rely on Lockspire to authenticate your operators"
    assert router =~ ~s<forward("/lockspire", Lockspire.Web.Router)>

    # The namespaced operator pipeline is defined by the generated file itself --
    # a stock host needs to declare no pipeline of its own for the admin mount.
    assert router =~ "pipeline :lockspire_require_operator"

    # Route ordering, proven over the raw source position (not a fixed-shape
    # regex): the admin forward must be emitted before the public forward so it
    # cannot be shadowed. `install_template_compile_test.exs` proves the same
    # property over the real, compiled `Phoenix.Router.routes/1` table.
    {admin_forward_index, _} =
      :binary.match(router, ~s<forward("/", Lockspire.Web.AdminRouter)>)

    {public_forward_index, _} =
      :binary.match(router, ~s<forward("/lockspire", Lockspire.Web.Router)>)

    assert admin_forward_index < public_forward_index,
           "admin forward must appear before the public forward in the generated router"

    resolver =
      File.read!(Path.join(@fixture_root, "lib/generated_host_app/lockspire/account_resolver.ex"))

    assert resolver =~ "Host-owned Lockspire seam"
    assert resolver =~ "@behaviour Lockspire.Host.AccountResolver"
    assert resolver =~ "Implement GeneratedHostApp.Lockspire.AccountResolver.resolve_account/2"
    assert resolver =~ "Implement GeneratedHostApp.Lockspire.AccountResolver.build_claims/2"
    assert resolver =~ "defp current_account(%Plug.Conn{assigns: %{current_user: user}})"

    assert resolver =~
             "defp current_account(%Phoenix.LiveView.Socket{assigns: %{current_user: user}})"

    assert resolver =~ "\"user:\" <> to_string(account.id)"
    assert resolver =~ "Keep tenant authorization, billing tier checks, and product policy"
    assert resolver =~ "raise"
    refute resolver =~ "Sigra"

    # ADOPT-D09: the generated login redirect must match a real Phoenix 1.8
    # `phx.gen.auth --live` host, and say so, so the adopter knows it's a
    # change-me default and not Lockspire claiming ownership of login.
    assert resolver =~ ~s(login_path: "/users/log-in")
    assert resolver =~ "Phoenix 1.8's `phx.gen.auth --live` default"
    assert resolver =~ "Change this to your host's real login route"
    assert resolver =~ "Change this to your host's real logout route"

    assert File.read!(
             Path.join(@fixture_root, "lib/generated_host_app/lockspire/interaction_handler.ex")
           ) =~ "consent_path"

    assert File.read!(
             Path.join(@fixture_root, "lib/generated_host_app/lockspire/interaction_handler.ex")
           ) =~ "/interactions/\#{interaction_id}/complete"

    refute File.read!(
             Path.join(@fixture_root, "lib/generated_host_app/lockspire/interaction_handler.ex")
           ) =~ "Lockspire.Protocol"

    assert File.read!(
             Path.join(@fixture_root, "lib/generated_host_app_web/live/lockspire_consent_live.ex")
           ) =~ "Approve access"

    assert File.read!(
             Path.join(@fixture_root, "lib/generated_host_app_web/live/lockspire_consent_live.ex")
           ) =~ "name=\"decision\" value=\"deny\""

    assert File.read!(
             Path.join(@fixture_root, "lib/generated_host_app_web/live/lockspire_consent_live.ex")
           ) =~ "/interactions/\#{interaction_id}/complete"

    assert File.read!(
             Path.join(
               @fixture_root,
               "lib/generated_host_app_web/controllers/authorized_apps_controller.ex"
             )
           ) =~ "Lockspire.Admin.Consents"

    assert File.read!(
             Path.join(
               @fixture_root,
               "lib/generated_host_app_web/controllers/authorized_apps_html/index.html.heex"
             )
           ) =~ "Host-owned account settings page"

    assert File.read!(
             Path.join(
               @fixture_root,
               "lib/generated_host_app_web/controllers/lockspire_verification_controller.ex"
             )
           ) =~ "def lookup"

    assert File.read!(
             Path.join(
               @fixture_root,
               "lib/generated_host_app_web/controllers/lockspire_verification_controller.ex"
             )
           ) ==
             File.read!(
               Path.join(
                 @runtime_fixture_root,
                 "controllers/lockspire_verification_controller.ex"
               )
             )

    assert File.read!(
             Path.join(
               @fixture_root,
               "lib/generated_host_app_web/controllers/lockspire_verification_html.ex"
             )
           ) =~ "embed_templates"

    assert File.read!(
             Path.join(
               @fixture_root,
               "lib/generated_host_app_web/controllers/lockspire_verification_html.ex"
             )
           ) ==
             File.read!(
               Path.join(@runtime_fixture_root, "controllers/lockspire_verification_html.ex")
             )

    assert File.read!(
             Path.join(
               @fixture_root,
               "lib/generated_host_app_web/controllers/lockspire_verification_html/index.html.heex"
             )
           ) =~ "Review device request"

    assert File.read!(
             Path.join(
               @fixture_root,
               "lib/generated_host_app_web/controllers/lockspire_verification_html/index.html.heex"
             )
           ) ==
             File.read!(
               Path.join(
                 @runtime_fixture_root,
                 "controllers/lockspire_verification_html/index.html.heex"
               )
             )

    assert File.read!(Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex")) ==
             File.read!(Path.join(@runtime_fixture_root, "router/lockspire.ex"))

    fapi_smoke_path =
      Path.join(@fixture_root, "test/generated_host_app/lockspire_fapi_smoke_e2e_test.exs")

    assert File.exists?(fapi_smoke_path),
           "Expected FAPI smoke E2E test to be rendered to host fixture"

    fapi_smoke = File.read!(fapi_smoke_path)

    assert fapi_smoke =~ "defmodule GeneratedHostApp.Lockspire.FapiSmokeE2ETest"
    assert fapi_smoke =~ "Lockspire-managed scaffolding"
    assert fapi_smoke =~ "@endpoint GeneratedHostAppWeb.Endpoint"
    assert fapi_smoke =~ ~s(get("/lockspire/authorize")
    assert fapi_smoke =~ "Lockspire.Clients.register_client"
    assert fapi_smoke =~ "Lockspire.issuer()"
    assert fapi_smoke =~ "FAPI 2.0"
    assert fapi_smoke =~ "redirect_uri must match a registered URI"

    refute fapi_smoke =~ "Lockspire.TestRepo"
    refute fapi_smoke =~ "Lockspire.Storage"
    refute fapi_smoke =~ "Lockspire.Domain"
    refute fapi_smoke =~ "Lockspire.Security"
    refute fapi_smoke =~ "Application.compile_env"
    refute fapi_smoke =~ "@endpoint Lockspire.Web.Router"

    :code.purge(GeneratedHostApp.Lockspire.FapiSmokeE2ETest)
    :code.delete(GeneratedHostApp.Lockspire.FapiSmokeE2ETest)

    assert [{GeneratedHostApp.Lockspire.FapiSmokeE2ETest, _binary} | _rest] =
             Code.compile_string(fapi_smoke, fapi_smoke_path)

    assert output =~ "Lockspire canonical onboarding next steps"
    assert output =~ "Import `config/lockspire.exs`"
    assert output =~ "auth-code + PKCE flow"
    assert output =~ "docs/device-flow-host-guide.md"
  end

  test "mix lockspire.install --sigra-host emits Sigra-oriented resolver stub" do
    capture_io(fn ->
      install_fixture!(["--sigra-host"])
    end)

    resolver =
      File.read!(Path.join(@fixture_root, "lib/generated_host_app/lockspire/account_resolver.ex"))

    assert resolver =~ "Sigra"
    assert resolver =~ "@behaviour Lockspire.Host.AccountResolver"
    assert resolver =~ "current_scope.user"
    assert resolver =~ "preserve both return_to and"
    assert resolver =~ "interaction_id"
    assert resolver =~ "Lockspire must not import Sigra at compile"
    assert resolver =~ "current_account(conn_or_socket)"
  end

  test "mix lockspire.install renders a mount-path-consistent issuer for a custom mount path" do
    capture_io(fn ->
      install_fixture!(["--mount-path", "/auth"])
    end)

    config = File.read!(Path.join(@fixture_root, "config/lockspire.exs"))

    assert config =~ ~s(issuer: "https://example.com/auth")
    assert config =~ ~s(mount_path: "/auth")
  end

  test "mix lockspire.install requires explicit public-schema opt in" do
    capture_io(fn ->
      install_fixture!(["--storage-prefix", "public", "--oban-prefix", "public"])
    end)

    config = File.read!(Path.join(@fixture_root, "config/lockspire.exs"))
    manifest = load_manifest!()

    assert config =~ ~s(storage_prefix: "public")
    assert config =~ ~s(oban_prefix: "public")
    assert manifest["inputs"]["storage_prefix"] == "public"
    assert manifest["inputs"]["oban_prefix"] == "public"
  end

  test "mix lockspire.install --sigra-host keeps the canonical generated file set unchanged" do
    capture_io(fn ->
      install_fixture!()
    end)

    generic_files =
      @fixture_root
      |> generated_files()
      |> Enum.sort()

    reset_fixture!()

    capture_io(fn ->
      install_fixture!(["--sigra-host"])
    end)

    sigra_files =
      @fixture_root
      |> generated_files()
      |> Enum.sort()

    assert sigra_files == generic_files
  end

  test "mix lockspire.install is idempotent when the host has not edited generated files" do
    capture_io(fn ->
      install_fixture!()
    end)

    rerun_output =
      capture_io(fn ->
        install_fixture!()
      end)

    assert rerun_output =~ "* unchanged lib/generated_host_app_web/router/lockspire.ex"
    assert rerun_output =~ "* unchanged config/lockspire.exs"
    assert rerun_output =~ "* unchanged .lockspire/install_manifest.json"

    assert rerun_output =~
             "* unchanged lib/generated_host_app_web/controllers/lockspire_verification_controller.ex"

    assert rerun_output =~ "Lockspire canonical onboarding next steps"
  end

  test "mix lockspire.install refuses to overwrite host edits" do
    capture_io(fn ->
      install_fixture!()
    end)

    router_path = Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex")
    File.write!(router_path, File.read!(router_path) <> "\n# host customization\n")

    assert_raise Mix.Error, ~r/Refusing to overwrite modified file/, fn ->
      File.cd!(@fixture_root, fn ->
        Mix.Task.reenable("lockspire.install")
        Mix.Tasks.Lockspire.Install.run(base_args())
      end)
    end

    reset_fixture!()

    capture_io(fn ->
      install_fixture!()
    end)

    verification_path =
      Path.join(
        @fixture_root,
        "lib/generated_host_app_web/controllers/lockspire_verification_controller.ex"
      )

    File.write!(
      verification_path,
      File.read!(verification_path) <> "\n# host verification customization\n"
    )

    assert_raise Mix.Error, ~r/Refusing to overwrite modified file/, fn ->
      File.cd!(@fixture_root, fn ->
        Mix.Task.reenable("lockspire.install")
        Mix.Tasks.Lockspire.Install.run(base_args())
      end)
    end
  end

  defp install_fixture!(extra_args \\ []) do
    File.cd!(@fixture_root, fn ->
      Mix.Task.reenable("lockspire.install")
      Mix.Tasks.Lockspire.Install.run(base_args() ++ extra_args)
    end)
  end

  defp base_args do
    [
      "--web",
      "GeneratedHostAppWeb",
      "--scope",
      "GeneratedHostApp.Lockspire"
    ]
  end

  defp reset_fixture! do
    File.rm_rf!(Path.join(@fixture_root, ".lockspire"))
    File.rm_rf!(Path.join(@fixture_root, "config"))
    File.rm_rf!(Path.join(@fixture_root, "lib"))
    File.rm_rf!(Path.join(@fixture_root, "test"))
    File.mkdir_p!(@fixture_root)
    File.write!(Path.join(@fixture_root, ".keep"), "")
  end

  defp generated_files(root) do
    root
    |> Path.join("{config,lib,test}/**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.reject(&File.dir?/1)
    |> Enum.map(&Path.relative_to(&1, root))
  end

  defp load_manifest! do
    @fixture_root
    |> Path.join(".lockspire/install_manifest.json")
    |> File.read!()
    |> Jason.decode!()
  end
end
