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

    test "run/1 reports rather than raises when Oban is not started" do
      # Regression: `Oban.whereis/1` raises `ArgumentError: unknown registry: Oban.Registry`
      # when the :oban application is down, so the supervision check crashed
      # `mix lockspire.verify` on exactly the unwired host it exists to diagnose. Observed
      # against a real generated host in CI (adopter walk run 30482090338), where
      # step-05-verify aborted with that ArgumentError instead of reporting a missing child.
      # Stopping :oban takes Lockspire's own supervision tree down with it, so both
      # applications have to come back before any sibling test observes the gap.
      :ok = Application.stop(:oban)

      on_exit(fn ->
        {:ok, _} = Application.ensure_all_started(:oban)
        {:ok, _} = Application.ensure_all_started(:lockspire)
      end)

      result =
        Verify.run(
          router: __MODULE__.NoopRouter,
          resolver_module: __MODULE__.NoopResolver,
          interaction_handler_module: __MODULE__.NoopInteractionHandler,
          repo: Lockspire.TestRepo,
          mount_path: "/lockspire"
        )

      supervision = Enum.find(result.checks, &(&1.id == :supervision))

      refute is_nil(supervision)
      assert supervision.status == :error

      # Either honest outcome is acceptable; a raised ArgumentError is not. Which branch
      # applies depends on whether :lockspire itself survived :oban going down.
      assert supervision.details =~ "Lockspire.Oban" or
               supervision.details =~ "not running in this VM"

      refute supervision.summary =~ "unknown registry"
    end
  end

  describe "Verify migrations check: shadowed schema_migrations bookkeeping" do
    alias Lockspire.Install.Verify

    defp state(overrides) do
      Map.merge(
        %{
          oban_prefix: nil,
          oban_table_exists?: nil,
          pending: [],
          shadowed_bookkeeping?: false,
          statuses: [],
          storage_prefix: "lockspire",
          storage_table_exists?: nil
        },
        Map.new(overrides)
      )
    end

    test "explains an unclearable pending list rather than telling the adopter to migrate again" do
      result =
        Verify.evaluate_migration_state(
          state(
            shadowed_bookkeeping?: true,
            pending: [{:down, 20_260_422_000_100, "create_lockspire_core_tables"}]
          ),
          Lockspire.TestRepo
        )

      assert result.status == :error
      assert result.summary =~ "two schema_migrations tables"
      assert result.details =~ "lockspire.schema_migrations"

      # The remediation must name the actual cause. Re-running the migrations is what an adopter
      # does on their own, and it fails on "table already exists" -- so the fix text has to say
      # so explicitly and name search_path.
      assert result.fix =~ "search_path"
      assert result.fix =~ "Running the migrations again will not fix this"
    end

    test "stays silent for a host that deliberately keeps bookkeeping in the prefixed schema" do
      # Shadow table present but nothing pending: the bookkeeping is wherever this host put it and
      # is working. Warning here would fire on a legitimate setup.
      result =
        Verify.evaluate_migration_state(
          state(shadowed_bookkeeping?: true, pending: [], statuses: [{:up, 1, "x"}]),
          Lockspire.TestRepo
        )

      assert result.status == :ok
    end

    @tag :integration
    test "PostgreSQL really does create a second bookkeeping table when the prefix shadows public" do
      # Pins the platform behaviour the whole check rests on. If this ever stops reproducing, the
      # remediation text above is wrong and the check should be reconsidered -- not silently kept.
      schema = "lockspire_shadow_probe_#{System.unique_integer([:positive])}"

      # Its own dedicated Postgrex connection, not the repo's pool: this test needs one
      # connection for the whole sequence (a `SET search_path` on a pooled connection would
      # otherwise leak into an unrelated later test), and Lockspire.TestRepo is not started in
      # this suite at all.
      conn_opts =
        Application.get_env(:lockspire, Lockspire.TestRepo)
        |> Keyword.take([:username, :password, :hostname, :port, :database])

      {:ok, conn} = Postgrex.start_link(conn_opts)
      query = fn sql -> Postgrex.query!(conn, sql, []) end

      on_exit(fn ->
        {:ok, cleanup} = Postgrex.start_link(conn_opts)
        Postgrex.query!(cleanup, "DROP SCHEMA IF EXISTS \"#{schema}\" CASCADE", [])
      end)

      query.("CREATE SCHEMA \"#{schema}\"")
      query.("CREATE TABLE IF NOT EXISTS public.schema_migrations (version bigint primary key)")

      # Simulates a role named after the schema: PostgreSQL's default search_path is
      # `"$user", public`, so the role's own schema precedes public for unqualified names.
      query.("SET search_path TO \"#{schema}\", public")
      query.("CREATE TABLE IF NOT EXISTS schema_migrations (version bigint primary key)")

      %{rows: rows} =
        query.("""
        SELECT table_schema FROM information_schema.tables
        WHERE table_name = 'schema_migrations' AND table_schema = '#{schema}'
        """)

      assert rows == [[schema]],
             "expected CREATE TABLE IF NOT EXISTS to resolve into #{schema} despite public.schema_migrations already existing"
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
