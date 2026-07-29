defmodule Lockspire.Install.InstallInstructionsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Lockspire.Generators.Install

  @tmp_root Path.join(System.tmp_dir!(), "lockspire_install_instructions_test")

  setup do
    File.rm_rf!(@tmp_root)
    on_exit(fn -> File.rm_rf!(@tmp_root) end)
    :ok
  end

  describe "instructions/1 (installer next steps)" do
    setup do
      opts = [
        path: @tmp_root,
        web: "InstallInstructionsHostWeb",
        scope: "InstallInstructionsHost.Lockspire"
      ]

      # Pure, no I/O -- confirms build_assigns/1 resolves against a scratch path that
      # does not exist yet without requiring the directory to be present first.
      assigns = Install.build_assigns(opts)
      refute File.exists?(@tmp_root)

      output =
        capture_io(fn ->
          Install.run(opts)
        end)

      %{assigns: assigns, output: output}
    end

    test "names the host application-tree wiring the walk proved is required", %{
      output: output
    } do
      assert output =~ "included_applications: [:lockspire]"
      assert output =~ "extra_applications"
      assert output =~ ":oban"
      assert output =~ ":cachex"
      assert output =~ "Lockspire.Oban.runtime_config!/0"
      assert output =~ ":lockspire_jwks_cache"
      assert output =~ "Lockspire.KeyCache"
      assert output =~ "after your own Repo"
      assert output =~ "does not modify your `mix.exs` or `application.ex`"
    end

    test "names all three key-lifecycle stages and states publication is not sufficient to sign",
         %{output: output} do
      assert output =~ "Lockspire.Admin.generate_key/1"
      assert output =~ "Lockspire.Admin.publish_key/2"
      assert output =~ "Lockspire.Admin.activate_key/2"
      assert output =~ "publication makes the key visible in JWKS but still unable to sign"
      assert output =~ "only activation makes a published key eligible to sign tokens"
    end

    test "names the release-safe migrate invocation", %{output: output} do
      assert output =~ "mix ecto.migrate --migrations-path"
      assert output =~ Application.app_dir(:lockspire, "priv/repo/migrations")
    end

    test "does not prescribe a bare migrate command anywhere in the printed steps", %{
      output: output
    } do
      instructions_text =
        output
        |> String.split("Lockspire canonical onboarding next steps:")
        |> List.last()

      refute instructions_text =~ ~r/ecto\.migrate(?!\s+--migrations-path)/
    end

    test "the existing install_generator_test.exs =~ assertions on instruction output still hold",
         %{output: output} do
      assert output =~ "Lockspire canonical onboarding next steps"
      assert output =~ "Import `config/lockspire.exs`"
      assert output =~ "auth-code + PKCE flow"
      assert output =~ "docs/device-flow-host-guide.md"
    end
  end
end
