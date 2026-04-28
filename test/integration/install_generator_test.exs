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
    output =
      capture_io(fn ->
        install_fixture!()
      end)

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             "config :lockspire"

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             ~s(import_config "lockspire.exs")

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             "account_resolver: GeneratedHostApp.Lockspire.AccountResolver"

    assert File.read!(Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex")) =~
             ~s(forward "/lockspire", Lockspire.Web.Router)

    assert File.read!(Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex")) =~
             ~s(get "/authorized-apps", AuthorizedAppsController, :index)

    router = File.read!(Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex"))

    assert router =~ ~s(get "/verify", LockspireVerificationController, :show)
    assert router =~ ~s(post "/verify", LockspireVerificationController, :lookup)
    assert router =~ ~s(post "/verify/:handle/approve", LockspireVerificationController, :approve)
    assert router =~ ~s(post "/verify/:handle/deny", LockspireVerificationController, :deny)
    assert router =~ "prefill-only"
    assert router =~ "device-flow-host-guide.md"

    resolver =
      File.read!(Path.join(@fixture_root, "lib/generated_host_app/lockspire/account_resolver.ex"))

    assert resolver =~ "@behaviour Lockspire.Host.AccountResolver"
    assert resolver =~ "subject: to_string(account.id)"
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

    File.write!(verification_path, File.read!(verification_path) <> "\n# host verification customization\n")

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
    File.rm_rf!(Path.join(@fixture_root, "config"))
    File.rm_rf!(Path.join(@fixture_root, "lib"))
    File.mkdir_p!(@fixture_root)
    File.write!(Path.join(@fixture_root, ".keep"), "")
  end
end
