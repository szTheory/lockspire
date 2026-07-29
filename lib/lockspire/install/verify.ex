defmodule Lockspire.Install.Verify do
  @moduledoc """
  Install-time diagnostics for the canonical embedded Lockspire host integration.
  """

  alias Lockspire.Install.Verify.Check

  @verify_routes [
    {:get, "/verify"},
    {:post, "/verify"},
    {:post, "/verify/:handle/approve"},
    {:post, "/verify/:handle/deny"}
  ]

  @type result :: %{ok?: boolean(), checks: [Check.result()]}

  @spec run(keyword()) :: result()
  def run(opts \\ []) do
    router = Keyword.fetch!(opts, :router)
    resolver_module = Keyword.fetch!(opts, :resolver_module)
    interaction_handler_module = Keyword.fetch!(opts, :interaction_handler_module)
    repo = Keyword.get(opts, :repo, Lockspire.Config.repo!())
    mount_path = Keyword.get(opts, :mount_path, Lockspire.Config.mount_path())

    checks = [
      config_check(),
      seam_modules_check(resolver_module, interaction_handler_module),
      router_check(router, mount_path),
      migrations_check(repo),
      supervision_children_check()
    ]

    %{ok?: Enum.all?(checks, &(&1.status == :ok)), checks: checks}
  end

  defp config_check do
    repo = Lockspire.Config.repo!()
    account_resolver = Lockspire.Config.account_resolver!()
    issuer = Lockspire.Config.issuer!()
    mount_path = Lockspire.Config.mount_path()
    oban = Lockspire.Oban.runtime_config!()

    Check.ok(
      :config,
      "Runtime config is present",
      "repo=#{inspect(repo)} account_resolver=#{inspect(account_resolver)} issuer=#{issuer} mount_path=#{mount_path} oban_repo=#{inspect(Keyword.get(oban, :repo))}",
      "Keep config/lockspire.exs imported and provide the required :lockspire keys in runtime config."
    )
  rescue
    error in [ArgumentError, RuntimeError] ->
      Check.error(
        :config,
        "Runtime config is incomplete or invalid",
        Exception.message(error),
        "Import config/lockspire.exs and fix the reported :lockspire repo, issuer, mount_path, account_resolver, or Oban settings."
      )
  end

  defp seam_modules_check(resolver_module, interaction_handler_module) do
    missing =
      [
        {resolver_module, "account resolver"},
        {interaction_handler_module, "interaction handler"}
      ]
      |> Enum.reject(fn {module, _label} -> Code.ensure_loaded?(module) end)

    case missing do
      [] ->
        Check.ok(
          :seams,
          "Host seam modules are available",
          "resolver=#{inspect(resolver_module)} interaction_handler=#{inspect(interaction_handler_module)}",
          "Keep the generated seam modules compiled inside the host app."
        )

      _ ->
        details =
          Enum.map_join(missing, ", ", fn {module, label} ->
            "#{label}=#{inspect(module)}"
          end)

        Check.error(
          :seams,
          "Host seam modules are missing",
          details,
          "Generate or compile the expected host seam modules before relying on Lockspire routes."
        )
    end
  end

  defp router_check(router, mount_path) do
    routes = Phoenix.Router.routes(router)

    missing_verify_routes =
      Enum.reject(@verify_routes, fn {verb, path} ->
        Enum.any?(routes, fn route ->
          route.verb == verb and route.path == path
        end)
      end)

    admin_mount_path = admin_mount_path(mount_path)

    public_mount_index =
      Enum.find_index(routes, &public_mount_route?(&1, mount_path))

    admin_mount_index =
      Enum.find_index(routes, &admin_mount_route?(&1, admin_mount_path))

    has_public_mount? = is_integer(public_mount_index)
    has_admin_mount? = is_integer(admin_mount_index)

    cond do
      missing_verify_routes != [] ->
        Check.error(
          :router,
          "Host router is missing required /verify routes",
          Enum.map_join(missing_verify_routes, ", ", fn {verb, path} -> "#{verb} #{path}" end),
          "Import your generated Lockspire router helper and keep the host-owned /verify routes mounted under the browser pipeline."
        )

      not has_admin_mount? ->
        Check.error(
          :router,
          "Host router is missing the guarded Lockspire admin mount",
          "expected forward #{admin_mount_path} -> Lockspire.Web.AdminRouter in #{inspect(router)}",
          "Mount `Lockspire.Web.AdminRouter` at #{admin_mount_path} behind your host-owned operator auth pipeline before the public Lockspire forward."
        )

      admin_mount_shadowed?(public_mount_index, admin_mount_index) ->
        Check.error(
          :router,
          "Host router mounts the public Lockspire forward before the guarded admin mount",
          "public forward #{mount_path} -> Lockspire.Web.Router appears before admin forward #{admin_mount_path} -> Lockspire.Web.AdminRouter in #{inspect(router)}",
          "Move the guarded `Lockspire.Web.AdminRouter` mount above the general `Lockspire.Web.Router` forward so /admin requests cannot be swallowed by the public router."
        )

      not has_public_mount? ->
        Check.error(
          :router,
          "Host router is missing the Lockspire forward mount",
          "expected forward #{mount_path} -> Lockspire.Web.Router in #{inspect(router)}",
          "Add `forward #{inspect(mount_path)}, Lockspire.Web.Router` to the host router through the generated lockspire_routes helper."
        )

      true ->
        Check.ok(
          :router,
          "Host router wiring is present",
          "router=#{inspect(router)} public_mount=#{mount_path} admin_mount=#{admin_mount_path}",
          "Keep the generated /verify routes, guarded admin mount, and public Lockspire forward mounted together."
        )
    end
  rescue
    error in [UndefinedFunctionError] ->
      Check.error(
        :router,
        "Host router module is unavailable",
        Exception.message(error),
        "Compile the host router module and rerun `mix lockspire.verify`."
      )
  end

  defp admin_mount_path(""), do: "/admin"
  defp admin_mount_path("/"), do: "/admin"
  defp admin_mount_path(mount_path), do: String.trim_trailing(mount_path, "/") <> "/admin"

  defp public_mount_route?(route, mount_path) do
    route.verb == :* and route.path == mount_path and route.plug == Lockspire.Web.Router
  end

  defp admin_mount_route?(route, admin_mount_path) do
    route.verb == :* and route.path == admin_mount_path and
      route.plug == Lockspire.Web.AdminRouter
  end

  defp admin_mount_shadowed?(public_mount_index, admin_mount_index)
       when is_integer(public_mount_index) and is_integer(admin_mount_index) do
    public_mount_index < admin_mount_index
  end

  defp admin_mount_shadowed?(_public_mount_index, _admin_mount_index), do: false

  @doc """
  Reports whether Lockspire's supervision children are running for the given readiness state.

  This is a pure decision function separated from the live process lookups in
  `supervision_children_check/0` so the OK and error rendering can be exercised directly
  without starting or stopping the host's supervision tree.
  """
  @spec evaluate_supervision_children(boolean(), boolean(), boolean()) :: Check.result()
  def evaluate_supervision_children(oban_running?, jwks_cache_running?, key_cache_running?) do
    missing =
      [
        {oban_running?, "Lockspire.Oban"},
        {jwks_cache_running?, ":lockspire_jwks_cache"},
        {key_cache_running?, "Lockspire.KeyCache"}
      ]
      |> Enum.reject(fn {running?, _name} -> running? end)
      |> Enum.map(fn {_running?, name} -> name end)

    case missing do
      [] ->
        Check.ok(
          :supervision,
          "Lockspire's supervision children are running",
          "Lockspire.Oban, :lockspire_jwks_cache, Lockspire.KeyCache",
          "Keep Lockspire's Oban child, the :lockspire_jwks_cache Cachex child, and Lockspire.KeyCache in your host's Application.start/2 child list, ordered after your own Repo."
        )

      _ ->
        Check.error(
          :supervision,
          "Lockspire's supervision children are not all running",
          "missing: #{Enum.join(missing, ", ")}",
          "Add the missing children to your host's application.ex child list, ordered after your own Repo: the Oban child built from Lockspire.Oban.runtime_config!/0, the Cachex child named :lockspire_jwks_cache, and Lockspire.KeyCache."
        )
    end
  end

  defp supervision_children_check do
    # `mix lockspire.verify` declares @requirements ["app.config"], which loads configuration
    # without starting any application, so on a host that has not been started none of these
    # children can be running no matter how correctly application.ex lists them. Reporting
    # "children are missing" there names the wrong cause and sends an adopter to edit a file
    # that is already right. Distinguish the two cases.
    if lockspire_application_started?() do
      evaluate_supervision_children(
        oban_child_running?(),
        jwks_cache_running?(),
        key_cache_running?()
      )
    else
      Check.error(
        :supervision,
        "Lockspire's supervision children cannot be checked from a non-started application",
        "the :lockspire application is not running in this VM",
        "Run this check against a started application -- `iex -S mix` on the host, or a booted release -- rather than a config-only Mix task. This result says nothing about whether your application.ex lists Lockspire's children correctly."
      )
    end
  end

  defp lockspire_application_started? do
    Enum.any?(Application.started_applications(), &(elem(&1, 0) == :lockspire))
  end

  # Each of these answers "is this child running?" about a host that may not have wired it
  # yet -- which is precisely the state this check exists to report -- so none of them may
  # raise. `Oban.whereis/1` raises `ArgumentError: unknown registry: Oban.Registry` when the
  # :oban application is not started, and `Cachex.size/1` can fail the same way, so a bare
  # call crashes `mix lockspire.verify` on exactly the unwired host it is meant to diagnose.
  defp oban_child_running? do
    running?(fn -> is_pid(Oban.whereis(Lockspire.Oban)) end)
  end

  defp jwks_cache_running? do
    running?(fn -> match?({:ok, _size}, Cachex.size(:lockspire_jwks_cache)) end)
  end

  defp key_cache_running? do
    running?(fn -> is_pid(Process.whereis(Lockspire.KeyCache)) end)
  end

  defp running?(probe) do
    probe.()
  rescue
    _ -> false
  catch
    :exit, _ -> false
  end

  defp migrations_path do
    Application.app_dir(:lockspire, "priv/repo/migrations")
  end

  @doc """
  Renders the migrations check from an already-gathered migration state.

  A pure decision function separated from the live database probes in `migration_state/1` so
  every branch -- including the shadowed-bookkeeping branch, whose real-world trigger is a
  PostgreSQL role name -- can be exercised without manufacturing that state in a shared test
  database.
  """
  @spec evaluate_migration_state(map(), module()) :: Check.result()
  def evaluate_migration_state(state, repo), do: migration_result(state, repo)

  defp migrations_check(repo) do
    repo
    |> migration_state()
    |> migration_result(repo)
  rescue
    error ->
      Check.error(
        :migrations,
        "Could not inspect migration state",
        Exception.message(error),
        "Ensure the configured repo is reachable and the database exists before rerunning verification."
      )
  end

  defp migration_state(repo) do
    migrations_path = migrations_path()
    storage_prefix = Lockspire.Config.storage_prefix()
    oban_prefix = Lockspire.Config.oban_prefix()

    {:ok, {statuses, storage_table_exists?, oban_table_exists?, shadowed_bookkeeping?}, _apps} =
      Ecto.Migrator.with_repo(repo, fn started_repo ->
        statuses = Ecto.Migrator.migrations(started_repo, migrations_path)
        pending = pending_migrations(statuses)

        # Probed unconditionally (it is one cheap catalogue lookup) but only ever reported
        # alongside a non-empty pending list -- a host that deliberately keeps its bookkeeping in
        # the prefixed schema has no pending migrations and must not be warned at all.
        shadowed_bookkeeping? =
          storage_prefix != nil and
            table_exists?(started_repo, storage_prefix, "schema_migrations")

        storage_table_exists? =
          if pending == [] and storage_prefix do
            table_exists?(started_repo, storage_prefix, "lockspire_clients")
          end

        oban_table_exists? =
          if pending == [] and oban_prefix do
            table_exists?(started_repo, oban_prefix, "oban_jobs")
          end

        {statuses, storage_table_exists?, oban_table_exists?, shadowed_bookkeeping?}
      end)

    pending = pending_migrations(statuses)

    %{
      oban_prefix: oban_prefix,
      oban_table_exists?: oban_table_exists?,
      pending: pending,
      shadowed_bookkeeping?: shadowed_bookkeeping?,
      statuses: statuses,
      storage_prefix: storage_prefix,
      storage_table_exists?: storage_table_exists?
    }
  end

  # Must be matched before the generic pending-migrations clause: this is the one cause of a
  # pending list that running the migrations again cannot clear, so reporting it as ordinary
  # pending work sends the adopter into a loop that fails on "table already exists".
  #
  # PostgreSQL's default search_path is `"$user", public`, so a database role whose name equals
  # :storage_prefix (a role named `lockspire` is an entirely natural choice) puts Lockspire's own
  # schema ahead of public for every unqualified table reference. Lockspire's own DDL is always
  # prefix-qualified and is unaffected -- but Ecto's schema_migrations bookkeeping is not
  # qualified, so the moment Lockspire's first migration creates the schema, the next connection's
  # `CREATE TABLE IF NOT EXISTS schema_migrations` resolves to the prefixed schema, finds nothing
  # there, and creates a second, empty bookkeeping table. Every migration then reads back as
  # pending forever while its tables plainly exist, and Phoenix.Ecto rejects every request with
  # PendingMigrationError. Verified against PostgreSQL 16 and observed in CI (adopter walk run
  # 30484208316) with a role named `lockspire`.
  defp migration_result(
         %{
           shadowed_bookkeeping?: true,
           storage_prefix: storage_prefix,
           pending: [_ | _] = pending
         },
         repo
       )
       when is_binary(storage_prefix) do
    Check.error(
      :migrations,
      "Migration bookkeeping is split across two schema_migrations tables",
      "found #{storage_prefix}.schema_migrations alongside public.schema_migrations in #{inspect(repo)}; #{length(pending)} migration(s) read back as pending (#{repo_target(repo)})",
      "PostgreSQL's default search_path is `\"$user\", public`, so a database role named #{inspect(storage_prefix)} shadows public for unqualified table names and forks Ecto's schema_migrations. Running the migrations again will not fix this. Point the role at public explicitly (`ALTER ROLE #{storage_prefix} SET search_path TO public`), or connect as a role whose name differs from config :lockspire, storage_prefix, then drop the empty #{storage_prefix}.schema_migrations table."
    )
  end

  defp migration_result(%{pending: [_ | _] = pending}, repo) do
    details =
      Enum.map_join(pending, ", ", fn {:down, version, name} ->
        "#{version}:#{name}"
      end)

    Check.error(
      :migrations,
      "Pending Lockspire or Oban migrations detected",
      "#{details} (#{repo_target(repo)})",
      "Run `mix ecto.migrate --migrations-path #{migrations_path()}` before using the embedded Lockspire surfaces."
    )
  end

  defp migration_result(%{storage_prefix: storage_prefix, storage_table_exists?: false}, repo)
       when is_binary(storage_prefix) do
    Check.error(
      :migrations,
      "Lockspire storage prefix is configured but core tables are missing",
      "expected #{storage_prefix}.lockspire_clients in #{inspect(repo)}",
      "Run `mix ecto.migrate --migrations-path #{migrations_path()}` with config :lockspire, storage_prefix: #{inspect(storage_prefix)} before booting."
    )
  end

  defp migration_result(%{oban_prefix: oban_prefix, oban_table_exists?: false}, repo)
       when is_binary(oban_prefix) do
    Check.error(
      :migrations,
      "Lockspire Oban prefix is configured but oban_jobs is missing",
      "expected #{oban_prefix}.oban_jobs in #{inspect(repo)}",
      "Run `mix ecto.migrate --migrations-path #{migrations_path()}` with config :lockspire, oban_prefix: #{inspect(oban_prefix)} before enabling Lockspire jobs."
    )
  end

  defp migration_result(state, repo) do
    Check.ok(
      :migrations,
      "Lockspire and Oban migrations are up to date",
      "repo=#{inspect(repo)} #{repo_target(repo)} applied_migrations=#{length(state.statuses)} storage_prefix=#{inspect(state.storage_prefix)} oban_prefix=#{inspect(state.oban_prefix)}",
      "Keep running `mix ecto.migrate --migrations-path #{migrations_path()}` before booting new Lockspire features."
    )
  end

  # "there are N pending migrations" is uninterpretable on its own: the single most common cause
  # is that the command that applied them and the check that reads them back resolved different
  # databases (a differing MIX_ENV, a runtime.exs override, a DATABASE_URL in the environment).
  # Naming the connection target turns that from a guess into a one-line diff. Best-effort by
  # construction -- `repo.config/0` reads runtime config and may raise on a partially configured
  # host, which is exactly the host most likely to reach this line, so it must never be the thing
  # that breaks the diagnostic it is annotating.
  defp repo_target(repo) do
    config = repo.config()

    database = Keyword.get(config, :database)
    hostname = Keyword.get(config, :hostname)
    port = Keyword.get(config, :port)

    "database=#{inspect(database)} hostname=#{inspect(hostname)} port=#{inspect(port)}"
  rescue
    _ -> "database=<unavailable>"
  catch
    :exit, _ -> "database=<unavailable>"
  end

  defp table_exists?(repo, prefix, table_name) do
    case Ecto.Adapters.SQL.query(
           repo,
           """
           SELECT 1
           FROM information_schema.tables
           WHERE table_schema = $1 AND table_name = $2
           LIMIT 1
           """,
           [prefix, table_name]
         ) do
      {:ok, %{num_rows: 1}} -> true
      {:ok, _result} -> false
      {:error, error} -> raise error
    end
  end

  defp pending_migrations(statuses) do
    Enum.filter(statuses, fn
      {:down, _version, _name} -> true
      _other -> false
    end)
  end
end
