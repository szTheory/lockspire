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

  describe "verify.ex migration remediation strings" do
    test "all migrate remediation sites name the migrations-path switch, not a bare invocation" do
      source =
        Path.expand("../../../lib/lockspire/install/verify.ex", __DIR__)
        |> File.read!()

      migrate_lines =
        source
        |> String.split("\n")
        |> Enum.filter(&(&1 =~ ~r/ecto\.migrate/))

      assert length(migrate_lines) >= 3

      assert Enum.all?(migrate_lines, &(&1 =~ "--migrations-path")),
             "expected every ecto.migrate remediation line to name --migrations-path, got: #{inspect(migrate_lines)}"

      refute source =~ "Run `mix ecto.migrate` in the host app"
      refute source =~ "Keep running `mix ecto.migrate` before booting"
    end
  end

  describe "Verify supervision-children check" do
    alias Lockspire.Install.Verify

    test "reports OK naming all three children when everything is running" do
      result = Verify.evaluate_supervision_children(true, true, true)

      assert result.status == :ok
      assert result.details =~ "Lockspire.Oban"
      assert result.details =~ ":lockspire_jwks_cache"
      assert result.details =~ "Lockspire.KeyCache"
    end

    test "reports the missing children by name and points at application.ex ordered after Repo" do
      result = Verify.evaluate_supervision_children(false, true, false)

      assert result.status == :error
      assert result.details =~ "Lockspire.Oban"
      assert result.details =~ "Lockspire.KeyCache"
      refute result.details =~ ":lockspire_jwks_cache"

      assert result.fix =~ "application.ex"
      assert result.fix =~ "after"
      assert result.fix =~ "Repo"
    end

    test "run/1 includes a supervision check that passes while Lockspire's own children boot" do
      result =
        Verify.run(
          router: __MODULE__.NoopRouter,
          resolver_module: __MODULE__.NoopResolver,
          interaction_handler_module: __MODULE__.NoopInteractionHandler,
          repo: Lockspire.TestRepo,
          mount_path: "/lockspire"
        )

      assert %{status: :ok} = Enum.find(result.checks, &(&1.id == :supervision))
    end
  end

  defmodule NoopRouter do
    use Phoenix.Router
  end

  defmodule NoopResolver do
    @behaviour Lockspire.Host.AccountResolver

    alias Lockspire.Host.Claims
    alias Lockspire.Host.InteractionResult

    def resolve_current_account(_conn_or_socket, _context), do: {:ok, %{id: "noop"}}
    def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

    def build_claims(account, _context) do
      {:ok, %Claims{subject: to_string(account.id), id_token: %{}, userinfo: %{}}}
    end

    def redirect_for_login(_conn_or_socket, _context),
      do: %InteractionResult{login_path: "/login", return_to: "/verify", params: %{}}
  end

  defmodule NoopInteractionHandler do
    def consent_path(interaction_id), do: "/lockspire/consent/#{interaction_id}"
  end
end
