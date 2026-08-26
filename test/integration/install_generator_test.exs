defmodule Lockspire.InstallGeneratorTest do
  use Lockspire.DataCase, async: false

  import ExUnit.CaptureIO

  alias Lockspire.Storage.Ecto.Repository

  @fixture_root Path.expand("../support/fixtures/generated_host_app", __DIR__)
  @runtime_fixture_root Path.expand("../support/generated_host_app_web", __DIR__)

  setup_all do
    Application.put_env(:lockspire, GeneratedHostAppWeb.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false,
      live_view: [signing_salt: "generated_host_salt"]
    )

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "profile"])

    Application.put_env(
      :lockspire,
      :account_resolver,
      GeneratedHostApp.Lockspire.TestAccountResolver
    )

    unless Process.whereis(Lockspire.TestRepo), do: start_supervised!(Lockspire.TestRepo)

    unless Process.whereis(GeneratedHostAppWeb.Endpoint),
      do: start_supervised!(GeneratedHostAppWeb.Endpoint)

    :ok
  end

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
    # adds or removes a template. Baseline at Plan 43-04 write time was 11; the default
    # smoke template makes it 12 while the FAPI proof remains opt-in.
    assert length(Lockspire.Generators.Templates.all()) == 12

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             "config :lockspire"

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             "Lockspire-managed scaffolding"

    manifest = load_manifest!()

    assert manifest["version"] == to_string(Mix.Project.config()[:version])
    assert manifest["inputs"]["mount_path"] == "/lockspire"
    assert manifest["inputs"]["storage_prefix"] == "lockspire"
    assert manifest["inputs"]["oban_prefix"] == "lockspire"

    managed_paths =
      manifest["managed_files"]
      |> Enum.map(& &1["path"])
      |> Enum.sort()

    assert "config/lockspire.exs" in managed_paths
    assert "lib/generated_host_app_web/router/lockspire.ex" in managed_paths
    assert "test/generated_host_app/lockspire_smoke_e2e_test.exs" in managed_paths
    refute Enum.any?(managed_paths, &String.contains?(&1, "fapi_smoke"))
    refute Enum.any?(managed_paths, &String.contains?(&1, "account_resolver.ex"))

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             ~s(import_config "lockspire.exs")

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             "account_resolver: GeneratedHostApp.Lockspire.AccountResolver"

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             ~s(storage_prefix: "lockspire")

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             ~s(oban_prefix: "lockspire")

    assert File.read!(Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex")) =~
             "forward(\"/lockspire\", Lockspire.Web.Router)"

    assert File.read!(Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex")) =~
             "get(\"/authorized-apps\", AuthorizedAppsController, :index)"

    router =
      File.read!(Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex"))

    assert router =~ "get(\"/verify\", LockspireVerificationController, :show)"
    assert router =~ "post(\"/verify\", LockspireVerificationController, :lookup)"

    assert router =~
             "post(\"/verify/:handle/approve\", LockspireVerificationController, :approve)"

    assert router =~ "post(\"/verify/:handle/deny\", LockspireVerificationController, :deny)"
    assert router =~ "prefill-only"
    assert router =~ "device-flow-host-guide.md"
    assert router =~ ~s(scope "/lockspire/admin")
    assert router =~ "pipe_through([:browser, :require_operator])"
    assert router =~
             "forward(\"/\", Lockspire.Web.AdminRouter, [], metadata: %{lockspire_operator_guard: true})"
    assert router =~ "Do not rely on Lockspire to authenticate your operators"
    assert router =~ "forward(\"/lockspire\", Lockspire.Web.Router)"

    assert router =~
             ~r/scope "\/lockspire\/admin" do\s+pipe_through\(\[:browser, :require_operator\]\).+forward\("\/", Lockspire.Web.AdminRouter, \[\], metadata: %\{lockspire_operator_guard: true\}\)\s+end/s

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

    consent_live =
      File.read!(
        Path.join(@fixture_root, "lib/generated_host_app_web/live/lockspire_consent_live.ex")
      )

    assert consent_live =~ "ConsentContext.load"
    assert consent_live =~ "phx-trigger-action"
    refute consent_live =~ "params[\"client_name\"]"
    refute consent_live =~ "interaction_id}</code>"

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

    default_smoke_path =
      Path.join(@fixture_root, "test/generated_host_app/lockspire_smoke_e2e_test.exs")

    assert File.exists?(default_smoke_path),
           "Expected default-profile smoke E2E test to be rendered to host fixture"

    default_smoke = File.read!(default_smoke_path)

    assert default_smoke =~ "defmodule GeneratedHostApp.Lockspire.SmokeE2ETest"
    assert default_smoke =~ "Lockspire-managed scaffolding"
    assert default_smoke =~ "@endpoint GeneratedHostAppWeb.Endpoint"
    assert default_smoke =~ ~s(get("/lockspire/authorize")
    assert default_smoke =~ "Lockspire.Clients.register_client"
    assert default_smoke =~ ~s(allowed_scopes: ["profile"])
    assert default_smoke =~ ~s("scope" => "openid profile")
    assert default_smoke =~ "code_challenge_method\" => \"S256"
    assert default_smoke =~ "redirect_uri must match a registered URI"

    refute default_smoke =~ "Lockspire.TestRepo"
    refute default_smoke =~ "Lockspire.Storage"
    refute default_smoke =~ "Lockspire.Domain"
    refute default_smoke =~ "Lockspire.Security"
    refute default_smoke =~ "Application.compile_env"
    refute default_smoke =~ "@endpoint Lockspire.Web.Router"
    refute default_smoke =~ "fapi_2_0"

    :code.purge(GeneratedHostApp.Lockspire.SmokeE2ETest)
    :code.delete(GeneratedHostApp.Lockspire.SmokeE2ETest)

    assert [{GeneratedHostApp.Lockspire.SmokeE2ETest, _binary} | _rest] =
             Code.compile_string(default_smoke, default_smoke_path)

    assert output =~ "Lockspire canonical onboarding next steps"
    assert output =~ "Import `config/lockspire.exs`"
    assert output =~ "auth-code + PKCE flow"
    assert output =~ "docs/device-flow-host-guide.md"
    assert output =~ "lockspire_smoke_e2e_test.exs"
    assert output =~ "--with-fapi-smoke"
  end

  test "the default install emits only the default-profile smoke while FAPI proof is explicit" do
    capture_io(fn ->
      install_fixture!()
    end)

    default_smoke_path =
      Path.join(@fixture_root, "test/generated_host_app/lockspire_smoke_e2e_test.exs")

    fapi_smoke_path =
      Path.join(@fixture_root, "test/generated_host_app/lockspire_fapi_smoke_e2e.exs")

    assert File.exists?(default_smoke_path)
    refute File.exists?(fapi_smoke_path)

    default_manifest = load_manifest!()

    assert "test/generated_host_app/lockspire_smoke_e2e_test.exs" in Enum.map(
             default_manifest["managed_files"],
             & &1["path"]
           )

    refute "test/generated_host_app/lockspire_fapi_smoke_e2e.exs" in Enum.map(
             default_manifest["managed_files"],
             & &1["path"]
           )

    reset_fixture!()

    capture_io(fn ->
      install_fixture!(["--with-fapi-smoke"])
    end)

    assert File.exists?(default_smoke_path)
    assert File.exists?(fapi_smoke_path)

    fapi_manifest = load_manifest!()

    assert "test/generated_host_app/lockspire_fapi_smoke_e2e.exs" in Enum.map(
             fapi_manifest["managed_files"],
             & &1["path"]
           )
  end

  test "the FAPI smoke flag is documented and rejects a positional value" do
    assert Mix.Tasks.Lockspire.Install.help() =~ "--with-fapi-smoke"
    assert Mix.Tasks.Lockspire.Install.help() =~ "--include fapi"

    assert_raise Mix.Error, ~r/Unknown arguments: not-a-boolean/, fn ->
      File.cd!(@fixture_root, fn ->
        Mix.Tasks.Lockspire.Install.run(["--with-fapi-smoke", "not-a-boolean"])
      end)
    end
  end

  test "rendered default and opted-in FAPI smokes execute against the generated host" do
    capture_io(fn ->
      install_fixture!()
    end)

    default_smoke_path =
      Path.join(@fixture_root, "test/generated_host_app/lockspire_smoke_e2e_test.exs")

    run_rendered_test!(
      default_smoke_path,
      GeneratedHostApp.Lockspire.SmokeE2ETest,
      "discovery and JWKS are published"
    )

    run_rendered_test!(
      default_smoke_path,
      GeneratedHostApp.Lockspire.SmokeE2ETest,
      "authorization-code requests require S256 and exact redirect matching"
    )

    reset_fixture!()

    capture_io(fn ->
      install_fixture!(["--with-fapi-smoke"])
    end)

    {:ok, policy} = Repository.get_server_policy()

    {:ok, _policy} =
      Repository.put_server_policy(%{policy | security_profile: :fapi_2_0_security})

    fapi_smoke_path =
      Path.join(@fixture_root, "test/generated_host_app/lockspire_fapi_smoke_e2e.exs")

    run_rendered_test!(
      fapi_smoke_path,
      GeneratedHostApp.Lockspire.FapiSmokeE2ETest,
      "FAPI 2.0 rejects direct authorize requests without PAR"
    )
  end

  test "the rendered router macro compiles through the generated host router" do
    capture_io(fn ->
      install_fixture!()
    end)

    rendered_router =
      File.read!(Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex"))

    assert rendered_router ==
             File.read!(Path.join(@runtime_fixture_root, "router/lockspire.ex"))

    routes = Phoenix.Router.routes(GeneratedHostAppWeb.Router)

    assert Enum.any?(routes, &(&1.path == "/verify" and &1.verb == :get))
    assert Enum.any?(routes, &(&1.path == "/authorized-apps" and &1.verb == :get))

    admin_index = route_index!(routes, "/lockspire/admin")
    public_index = route_index!(routes, "/lockspire")

    assert admin_index < public_index

    admin_route = Enum.at(routes, admin_index)
    assert admin_route.plug == Lockspire.Web.AdminRouter

    consent_route = Enum.find(routes, &(&1.path == "/lockspire/consent/:interaction_id"))

    assert consent_route.metadata[:phoenix_live_view] |> elem(0) ==
             GeneratedHostAppWeb.LockspireConsentLive

    assert_raise CompileError, fn ->
      Code.compile_string("""
      defmodule GeneratedHostAppWeb.RouterWithoutOperator do
        use Phoenix.Router
        import GeneratedHostAppWeb.Router.Lockspire

        pipeline :browser do
          plug :accepts, [\"html\"]
        end

        lockspire_routes()
      end
      """)
    end
  end

  test "the installer-rendered consent LiveView matches and compiles as the executable fixture" do
    capture_io(fn ->
      install_fixture!()
    end)

    rendered_path =
      Path.join(@fixture_root, "lib/generated_host_app_web/live/lockspire_consent_live.ex")

    rendered = File.read!(rendered_path)

    assert rendered ==
             File.read!(Path.join(@runtime_fixture_root, "live/lockspire_consent_live.ex"))

    module = GeneratedHostAppWeb.LockspireConsentLive
    :code.purge(module)
    :code.delete(module)

    assert [{^module, _binary}] = Code.compile_string(rendered, rendered_path)
  end

  test "rendered config and account resolver compile against the public host seam" do
    capture_io(fn ->
      install_fixture!()
    end)

    config_path = Path.join(@fixture_root, "config/lockspire.exs")
    {config, _imports} = Config.Reader.read_imports!(config_path)
    lockspire_config = Keyword.fetch!(config, :lockspire)

    assert Keyword.fetch!(lockspire_config, :logout_path) == "/logout"

    assert Keyword.fetch!(lockspire_config, :account_resolver) ==
             GeneratedHostApp.Lockspire.AccountResolver

    resolver_module = GeneratedHostApp.Lockspire.AccountResolver

    resolver_path =
      Path.join(@fixture_root, "lib/generated_host_app/lockspire/account_resolver.ex")

    resolver = File.read!(resolver_path)

    assert resolver =~ "id_token: %{"
    assert resolver =~ "userinfo: %{"
    refute resolver =~ "claims: %{"

    :code.purge(resolver_module)
    :code.delete(resolver_module)

    assert [{^resolver_module, _binary}] =
             Code.compile_string(resolver, resolver_path)

    previous_logout_path = Application.get_env(:lockspire, :logout_path)
    Application.put_env(:lockspire, :logout_path, "/sign-out")

    on_exit(fn ->
      if is_nil(previous_logout_path) do
        Application.delete_env(:lockspire, :logout_path)
      else
        Application.put_env(:lockspire, :logout_path, previous_logout_path)
      end
    end)

    assert %Lockspire.Host.InteractionResult{login_path: "/sign-out", return_to: "/after-logout"} =
             resolver_module.redirect_for_logout(nil, %{return_to: "/after-logout"})
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
    File.rm_rf!(Path.join(@fixture_root, "priv"))
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

  defp route_index!(routes, path) do
    Enum.find_index(routes, &(&1.path == path)) ||
      flunk(
        "expected a compiled route at #{inspect(path)}, got: #{inspect(Enum.map(routes, & &1.path))}"
      )
  end

  defp run_rendered_test!(path, module, test_name) do
    source = File.read!(path)

    :code.purge(module)
    :code.delete(module)

    assert [{^module, _binary} | _rest] = Code.compile_string(source, path)

    test_name = String.to_atom("test " <> test_name)
    assert Enum.member?(module.__info__(:functions), {test_name, 1})
    assert :ok = apply(module, test_name, [%{}])
  end
end
