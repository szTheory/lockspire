defmodule Lockspire.InstallGeneratorTest do
  use ExUnit.Case, async: false

  @fixture_root Path.expand("../support/fixtures/generated_host_app", __DIR__)

  setup do
    reset_fixture!()
    on_exit(&reset_fixture!/0)
    :ok
  end

  test "mix lockspire.install writes the host-owned integration files" do
    File.cd!(@fixture_root, fn ->
      Mix.Task.reenable("lockspire.install")

      Mix.Tasks.Lockspire.Install.run([
        "--web",
        "GeneratedHostAppWeb",
        "--scope",
        "GeneratedHostApp.Lockspire"
      ])
    end)

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             "config :lockspire"

    assert File.read!(Path.join(@fixture_root, "config/lockspire.exs")) =~
             "account_resolver: GeneratedHostApp.Lockspire.AccountResolver"

    assert File.read!(Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex")) =~
             ~s(forward "/lockspire", Lockspire.Web.Router)

    assert File.read!(
             Path.join(@fixture_root, "lib/generated_host_app/lockspire/account_resolver.ex")
           ) =~ "@behaviour Lockspire.Host.AccountResolver"

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
  end

  test "mix lockspire.install refuses to overwrite host edits" do
    File.cd!(@fixture_root, fn ->
      Mix.Task.reenable("lockspire.install")

      Mix.Tasks.Lockspire.Install.run([
        "--web",
        "GeneratedHostAppWeb",
        "--scope",
        "GeneratedHostApp.Lockspire"
      ])
    end)

    router_path = Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex")
    File.write!(router_path, File.read!(router_path) <> "\n# host customization\n")

    assert_raise Mix.Error, ~r/Refusing to overwrite modified file/, fn ->
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
  end

  defp reset_fixture! do
    File.rm_rf!(Path.join(@fixture_root, "config"))
    File.rm_rf!(Path.join(@fixture_root, "lib"))
    File.mkdir_p!(@fixture_root)
    File.write!(Path.join(@fixture_root, ".keep"), "")
  end
end
