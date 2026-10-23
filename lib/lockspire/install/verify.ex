defmodule Lockspire.Install.Verify do
  @moduledoc """
  Install-time diagnostics for the canonical embedded Lockspire host integration.

  Verification is deliberately aggregate: a malformed host seam must not hide a
  separate router, migration, or configuration defect that an adopter can fix in
  the same edit cycle.
  """

  alias Lockspire.Admin.Keys.EncryptionStatus
  alias Lockspire.Install.Migrations
  alias Lockspire.Install.RepoRunner
  alias Lockspire.Install.Verify.Check

  @host_routes [
    {:get, "/verify"},
    {:post, "/verify"},
    {:post, "/verify/:handle/approve"},
    {:post, "/verify/:handle/deny"},
    {:get, "/authorized-apps"},
    {:delete, "/authorized-apps/:id"}
  ]

  @policy_limit "Structural checks do not prove arbitrary host authorization policy. Verify host-owned request and LiveView behavior with host tests; packaged browser transport and exact-floor runtime proof belong to Phase 170."

  @type result :: %{ok?: boolean(), checks: [Check.result()]}

  @doc """
  Checks each documented host seam without stopping at the first failure.

  `:project_root` defaults to the host Mix project. It is injectable so package
  and generated-host tests can verify the exact `priv/repo/migrations` delivery
  path without changing process working directories.
  """
  @spec run(keyword()) :: result()
  def run(opts \\ []) do
    router = Keyword.get(opts, :router)
    resolver_module = Keyword.get(opts, :resolver_module)
    interaction_handler_module = Keyword.get(opts, :interaction_handler_module)
    project_root = opts |> Keyword.get(:project_root, File.cwd!()) |> Path.expand()
    mount_path = Keyword.get(opts, :mount_path, Application.get_env(:lockspire, :mount_path))
    repo = Keyword.get(opts, :repo, Application.get_env(:lockspire, :repo))

    checks =
      config_checks() ++
        seam_module_checks(resolver_module, interaction_handler_module) ++
        [
          router_check(router, mount_path),
          migrations_check(repo, project_root),
          key_storage_check(repo, opts)
        ]

    %{ok?: Enum.all?(checks, &(&1.status == :ok)), checks: checks}
  end

  defp config_checks do
    [
      config_check(:repo, "repo", &Lockspire.Config.repo!/0),
      config_check(:account_resolver, "account_resolver", &Lockspire.Config.account_resolver!/0),
      config_check(:issuer, "issuer", &issuer_value/0),
      config_check(:mount_path, "mount_path", &Lockspire.Config.mount_path/0),
      config_check(:logout_path, "logout_path", &Lockspire.Config.logout_path/0),
      config_check(:oban, "oban", &Lockspire.Oban.runtime_config!/0),
      key_encryption_check()
    ]
  end

  # Validates fresh (never the cached accessor) so edits are seen. Details carry key ids,
  # the current id and the legacy mode only, never key material.
  defp key_encryption_check do
    case safely(&Lockspire.Config.key_encryption!/0) do
      {:ok, %Lockspire.Security.KeyEncryption.KeySet{} = keyset} ->
        Check.ok(
          :key_encryption,
          "Runtime config :key_encryption is present",
          "current=#{keyset.current_id} ids=#{Enum.join(keyset.ids, ",")} legacy_plaintext=#{keyset.legacy_plaintext}",
          "Keep :key_encryption in config/runtime.exs and retain every key id still referenced by stored signing keys."
        )

      {:ok, nil} ->
        Check.error(
          :key_encryption,
          "Runtime config :key_encryption is missing",
          "config :lockspire, :key_encryption is not set",
          key_encryption_fix()
        )

      {:error, message} ->
        Check.error(
          :key_encryption,
          "Runtime config :key_encryption is invalid",
          message,
          key_encryption_fix()
        )
    end
  end

  defp key_encryption_fix do
    "Add config :lockspire, :key_encryption with keys: [{id, base64 of 32 random bytes}], current: id in config/runtime.exs (create a key with `mix lockspire.gen.kek`), then rerun `mix lockspire.verify`."
  end

  defp config_check(id, key, fetch) do
    case safely(fetch) do
      {:ok, value} ->
        Check.ok(
          id,
          "Runtime config :#{key} is present",
          config_details(id, value),
          "Keep config/lockspire.exs imported and retain :#{key} in config :lockspire."
        )

      {:error, message} ->
        Check.error(
          id,
          "Runtime config :#{key} is missing or invalid",
          message,
          "Add a valid :#{key} entry to config/lockspire.exs under config :lockspire, then rerun `mix lockspire.verify`."
        )
    end
  end

  # Issuer validation normally also validates the mount path. Keep the two
  # diagnostics independent when the mount path itself is the missing seam.
  defp issuer_value do
    issuer = Application.get_env(:lockspire, :issuer)

    if valid_issuer?(issuer) do
      issuer
    else
      raise ArgumentError, "missing or invalid required config :issuer for :lockspire"
    end
  end

  defp valid_issuer?(issuer) when is_binary(issuer) do
    case URI.new(issuer) do
      {:ok, %URI{scheme: scheme, host: host, query: nil, fragment: nil}}
      when scheme in ["http", "https"] and is_binary(host) ->
        true

      _ ->
        false
    end
  end

  defp valid_issuer?(_issuer), do: false

  defp config_details(:repo, repo), do: "repo=#{inspect(repo)}"
  defp config_details(:account_resolver, resolver), do: "account_resolver=#{inspect(resolver)}"
  defp config_details(:issuer, issuer), do: "issuer=#{issuer}"
  defp config_details(:mount_path, mount_path), do: "mount_path=#{mount_path}"
  defp config_details(:logout_path, logout_path), do: "logout_path=#{logout_path}"
  defp config_details(:oban, oban), do: "oban_repo=#{inspect(Keyword.get(oban, :repo))}"

  defp seam_module_checks(resolver_module, interaction_handler_module) do
    [
      seam_module_check(:resolver_module, resolver_module, "account resolver"),
      seam_module_check(
        :interaction_handler_module,
        interaction_handler_module,
        "interaction handler"
      )
    ]
  end

  defp seam_module_check(id, module, label) when is_atom(module) do
    if Code.ensure_loaded?(module) do
      Check.ok(
        id,
        "Host #{label} module is available",
        "module=#{inspect(module)}",
        "Keep the generated host #{label} module compiled inside the host app."
      )
    else
      Check.error(
        id,
        "Host #{label} module is missing",
        "module=#{inspect(module)}",
        "Generate or compile the expected host #{label} module, then rerun `mix lockspire.verify`."
      )
    end
  end

  defp seam_module_check(id, _module, label) do
    Check.error(
      id,
      "Host #{label} module is missing",
      "no module was supplied for the generated #{label} seam",
      "Generate the host seam and rerun `mix lockspire.verify` with the documented --scope option."
    )
  end

  defp router_check(router, mount_path) when is_atom(router) do
    routes =
      try do
        {:ok, Phoenix.Router.routes(router)}
      rescue
        _error -> :unavailable
      catch
        _kind, _reason -> :unavailable
      end

    case routes do
      {:ok, routes} when is_list(routes) ->
        router_result(router, routes, mount_path)

      _unavailable ->
        Check.error(
          :router,
          "Host router metadata is unavailable",
          "compiled routes could not be inspected safely",
          "Compile the host router module and rerun `mix lockspire.verify`."
        )
    end
  end

  defp router_check(_router, _mount_path) do
    Check.error(
      :router,
      "Host router module is unavailable",
      "no host router module was supplied",
      "Pass --web YourAppWeb (or compile YourAppWeb.Router) before rerunning `mix lockspire.verify`."
    )
  end

  defp router_result(router, routes, mount_path) when is_binary(mount_path) do
    normalized_mount = Lockspire.Config.normalize_mount_path!(mount_path)
    admin_mount = admin_mount_path(normalized_mount)
    inventory = Lockspire.Web.AdminRoutes.__route_inventory__()

    expected =
      Enum.map(inventory, fn {path, view, action} ->
        {admin_route_path(admin_mount, path), view, action}
      end)

    host_route_errors = missing_host_route_errors(missing_host_routes(routes))
    namespace_routes = Enum.filter(routes, &path_in_namespace?(&1, admin_mount))
    native_errors = native_inventory_errors(namespace_routes, expected, router)
    dispatch_errors = dispatch_errors(router, expected)

    consent_index = route_index(routes, &consent_route?(&1, normalized_mount))
    admin_index = route_index(routes, &native_admin_root_route?(&1, admin_mount))
    public_index = route_index(routes, &public_mount_route?(&1, normalized_mount))

    errors =
      host_route_errors ++
        missing_route_error(
          consent_index,
          "generated consent LiveView #{consent_path(normalized_mount)}"
        ) ++
        native_errors ++
        dispatch_errors ++
        missing_route_error(
          public_index,
          "public forward #{public_route_path(normalized_mount)} -> Lockspire.Web.Router"
        ) ++
        ordering_errors(consent_index, admin_index, public_index)

    case errors do
      [] ->
        Check.ok(
          :router,
          "Host router wiring is present",
          "native_admin_routes=#{length(expected)} public_mount=#{public_route_path(normalized_mount)} admin_mount=#{admin_mount} session=:lockspire_admin; #{@policy_limit}",
          "Keep the canonical native admin routes, host authorization pipeline/hook, and separate public forward together. #{@policy_limit}"
        )

      _ ->
        Check.error(
          :router,
          "Host router wiring is incomplete",
          Enum.join(Enum.uniq(errors), "; ") <> ". " <> @policy_limit,
          "Import `Lockspire.Web.AdminRoutes`, call `lockspire_admin_routes/2` after defining nonempty host pipelines and host `on_mount` hooks, then keep the separate public forward after the consent and admin routes. Verify host authorization with host request and LiveView tests. #{@policy_limit}"
        )
    end
  rescue
    _error ->
      Check.error(
        :router,
        "Host router metadata is malformed",
        "compiled route structure could not be inspected safely. #{@policy_limit}",
        "Compile the host router with the canonical `Lockspire.Web.AdminRoutes` macro, then rerun `mix lockspire.verify`. #{@policy_limit}"
      )
  end

  defp router_result(_router, _routes, _mount_path) do
    Check.error(
      :router,
      "Host router wiring is incomplete",
      "the configured :mount_path is missing or invalid",
      "Set :mount_path in config/lockspire.exs, compile the host router, then rerun `mix lockspire.verify`."
    )
  end

  defp missing_host_routes(routes) do
    Enum.reject(@host_routes, fn {verb, path} ->
      Enum.any?(routes, &(&1.verb == verb and &1.path == path))
    end)
  end

  defp missing_host_route_errors(routes) do
    Enum.map(routes, fn {verb, path} -> "missing host route #{verb} #{path}" end)
  end

  defp missing_route_error(index, _description) when is_integer(index), do: []
  defp missing_route_error(_index, description), do: ["missing #{description}"]

  defp ordering_errors(consent_index, admin_index, public_index)
       when is_integer(public_index) do
    []
    |> append_if(
      is_integer(consent_index) and consent_index > public_index,
      "generated consent route appears after the public Lockspire forward"
    )
    |> append_if(
      is_integer(admin_index) and admin_index > public_index,
      "canonical admin route appears after the public Lockspire forward"
    )
  end

  defp ordering_errors(_consent_index, _admin_index, _public_index), do: []

  defp append_if(errors, true, error), do: errors ++ [error]
  defp append_if(errors, false, _error), do: errors

  defp route_index(routes, predicate), do: Enum.find_index(routes, predicate)

  defp consent_route?(%{path: path, metadata: metadata}, mount_path) when is_map(metadata),
    do: path == consent_path(mount_path) and is_tuple(metadata[:phoenix_live_view])

  defp consent_route?(_route, _mount_path), do: false

  defp consent_path(""), do: "/consent/:interaction_id"
  defp consent_path("/"), do: "/consent/:interaction_id"

  defp consent_path(mount_path),
    do: String.trim_trailing(mount_path, "/") <> "/consent/:interaction_id"

  defp admin_mount_path(""), do: "/admin"
  defp admin_mount_path("/"), do: "/admin"
  defp admin_mount_path(mount_path), do: String.trim_trailing(mount_path, "/") <> "/admin"

  defp public_route_path(""), do: "/"
  defp public_route_path(path), do: path

  defp admin_route_path(admin_mount, "/"), do: admin_mount
  defp admin_route_path(admin_mount, relative), do: admin_mount <> relative

  defp public_mount_route?(%{verb: :*, path: path, plug: Lockspire.Web.Router}, mount_path),
    do: path == public_route_path(mount_path)

  defp public_mount_route?(_route, _mount_path), do: false

  defp native_admin_root_route?(
         %{verb: :get, path: path, plug: Phoenix.LiveView.Plug},
         admin_mount
       ),
       do: path == admin_mount

  defp native_admin_root_route?(_route, _admin_mount), do: false

  defp path_in_namespace?(%{path: path}, namespace) when is_binary(path),
    do: path == namespace or String.starts_with?(path, namespace <> "/")

  defp path_in_namespace?(_route, _namespace), do: false

  defp native_inventory_errors(routes, expected, expected_router) do
    expected_by_path = Map.new(expected, fn {path, view, action} -> {path, {view, action}} end)

    counts = Enum.frequencies_by(routes, &route_path/1)

    missing_or_duplicate =
      Enum.flat_map(expected, fn {path, view, action} ->
        case Map.get(counts, path, 0) do
          0 -> ["missing native admin route GET #{path} -> #{inspect(view)} action #{action}"]
          1 -> []
          _count -> ["duplicate native admin route GET #{path}"]
        end
      end)

    tuple_errors =
      Enum.flat_map(routes, fn route ->
        path = route_path(route)

        case Map.fetch(expected_by_path, path) do
          :error ->
            ["unexpected route in the canonical admin namespace"]

          {:ok, {expected_view, expected_action}} ->
            route_shape_errors(route, path, expected_view, expected_action, expected_router)
        end
      end)

    missing_or_duplicate ++ tuple_errors
  end

  defp route_path(%{path: path}) when is_binary(path), do: path
  defp route_path(_route), do: nil

  defp route_shape_errors(route, path, expected_view, expected_action, expected_router) do
    case live_view_metadata(route) do
      {:ok, view, action, session} ->
        log_module = Map.get(Map.get(route, :metadata, %{}), :log_module)

        target_errors =
          if Map.get(route, :plug) == Phoenix.LiveView.Plug and log_module == expected_view and
               view == expected_view and action == expected_action do
            []
          else
            [
              "wrong native admin target or action at GET #{path}; expected #{inspect(expected_view)} action #{expected_action}"
            ]
          end

        target_errors ++ admin_session_errors(route, path, session, expected_router)

      :error ->
        ["malformed native admin metadata at GET #{path}; expected a LiveView route"]
    end
  end

  defp live_view_metadata(%{metadata: metadata}) when is_map(metadata) do
    case Map.get(metadata, :phoenix_live_view) do
      {view, action, _options, session} when is_atom(view) and is_atom(action) ->
        {:ok, view, action, session}

      _other ->
        :error
    end
  end

  defp live_view_metadata(_route), do: :error

  defp admin_session_errors(_route, path, session, expected_router) when is_map(session) do
    session_errors =
      if Map.get(session, :name) == :lockspire_admin do
        []
      else
        ["wrong native admin LiveView session at GET #{path}; expected :lockspire_admin"]
      end

    session_errors ++ admin_hook_errors(session, path, expected_router)
  end

  defp admin_session_errors(_route, path, _session, _expected_router),
    do: ["malformed native admin session metadata at GET #{path}"]

  defp admin_hook_errors(%{extra: %{on_mount: hooks}}, path, expected_router)
       when is_list(hooks) do
    hook_ids = Enum.map(hooks, &hook_id/1)

    case List.last(hook_ids) do
      {Lockspire.Web.AdminMount, {:mount_path, ^expected_router}} ->
        host_hooks = Enum.drop(hook_ids, -1)

        if host_hooks != [] and
             Enum.all?(host_hooks, &match?({module, _arg} when is_atom(module), &1)) do
          []
        else
          [
            "missing host LiveView authorization hook before Lockspire.Web.AdminMount at GET #{path}"
          ]
        end

      _other ->
        [
          "Lockspire.Web.AdminMount guard is missing, misordered, or has the wrong router argument at GET #{path}"
        ]
    end
  end

  defp admin_hook_errors(_session, path, _expected_router),
    do: ["malformed native admin on_mount metadata at GET #{path}"]

  defp hook_id(%{id: {module, argument}}) when is_atom(module), do: {module, argument}
  defp hook_id(_hook), do: :invalid

  defp dispatch_errors(router, expected) do
    Enum.flat_map(expected, fn {path, view, action} ->
      concrete = concrete_route_path(path)

      selected =
        try do
          Phoenix.Router.route_info(router, "GET", concrete, "localhost")
        rescue
          _error -> :unavailable
        catch
          _kind, _reason -> :unavailable
        end

      case selected do
        %{
          route: ^path,
          plug: Phoenix.LiveView.Plug,
          log_module: ^view,
          phoenix_live_view: {^view, ^action, _opts, session}
        } ->
          dispatch_metadata_errors(selected, path, session, router)

        _other ->
          ["first-match dispatch does not select the canonical admin route GET #{path}"]
      end
    end)
  end

  defp dispatch_metadata_errors(selected, path, session, router) do
    pipes = Map.get(selected, :pipe_through)

    pipeline_errors =
      if is_list(pipes) and pipes != [] and List.last(pipes) == :lockspire_admin_mount and
           Enum.all?(Enum.drop(pipes, -1), &(is_atom(&1) and &1 != :lockspire_admin_mount)) do
        []
      else
        ["missing host authorization pipeline before :lockspire_admin_mount at GET #{path}"]
      end

    pipeline_errors ++ admin_session_errors(selected, path, session, router)
  end

  defp concrete_route_path(path) do
    path
    |> String.replace(":client_id", "lockspire-probe-client")
    |> String.replace(":id", "lockspire-probe-id")
    |> String.replace(":interaction_id", "lockspire-probe-interaction")
  end

  defp migrations_check(repo, project_root) do
    {delivery_errors, migration_path} = migration_delivery(project_root)
    status_errors = migration_status_errors(repo, migration_path)
    errors = delivery_errors ++ status_errors

    case errors do
      [] ->
        Check.ok(
          :migrations,
          "Lockspire and Oban migrations are up to date",
          "repo=#{inspect(repo)} host_migrations=#{migration_path}",
          "Keep running `mix ecto.migrate` from the host app before booting new Lockspire features."
        )

      _ ->
        Check.error(
          :migrations,
          "Host migration delivery or database state is incomplete",
          Enum.join(errors, "; "),
          "Run `mix lockspire.install` (or `mix lockspire.upgrade`) to copy missing files into priv/repo/migrations, then run `mix ecto.migrate` from the host app."
        )
    end
  end

  defp migration_delivery(project_root) do
    migration_path = Path.join(project_root, "priv/repo/migrations")

    case Migrations.plan(project_root: project_root) do
      {:ok, plan} ->
        missing =
          for %{status: :copy, relative_path: relative_path} <- plan.operations,
              do: "missing packaged migration #{relative_path}"

        {missing, migration_path}

      {:error, errors} ->
        {Enum.map(errors, &Map.fetch!(&1, :message)), migration_path}
    end
  rescue
    error -> {[Exception.message(error)], Path.join(project_root, "priv/repo/migrations")}
  end

  defp migration_status_errors(repo, migration_path) when is_atom(repo) do
    case safely(fn -> migration_status(repo, migration_path) end) do
      {:ok, statuses} ->
        for {:down, version, name} <- statuses,
            do: "pending migration #{version}:#{name} in #{migration_path}"

      {:error, message} ->
        ["could not inspect database migration state: #{message}"]
    end
  end

  defp migration_status_errors(_repo, _migration_path),
    do: ["configured :repo is missing or invalid"]

  defp migration_status(repo, migration_path) do
    result =
      RepoRunner.run(repo, fn started_repo ->
        Ecto.Migrator.migrations(started_repo, migration_path, skip_table_creation: true)
      end)

    case result do
      {:ok, statuses} -> statuses
      {:error, :repo_unavailable} -> raise "the database is not reachable"
    end
  end

  # Reports only what is broken now. Rows that still need re-encryption are fine while the
  # decoder may read them, so legacy rows are an error only under `legacy_plaintext: :reject`.
  # A database that cannot be read is a skipped check: the migrations check already reports it.
  defp key_storage_check(repo, opts) do
    status_fun =
      Keyword.get(opts, :key_storage_status, fn -> default_key_storage_status(repo) end)

    case safe_status(status_fun) do
      {:ok, status} -> key_storage_result(status)
      {:error, _reason} -> key_storage_skipped()
    end
  end

  defp safe_status(status_fun) do
    case status_fun.() do
      {:ok, %{} = status} -> {:ok, status}
      _other -> {:error, :unavailable}
    end
  rescue
    _error -> {:error, :unavailable}
  catch
    _kind, _reason -> {:error, :unavailable}
  end

  defp default_key_storage_status(repo) do
    case RepoRunner.run(repo, fn _repo -> Lockspire.Admin.Keys.encryption_status() end) do
      {:ok, {:ok, status}} -> {:ok, status}
      _other -> {:error, :unavailable}
    end
  end

  defp key_storage_skipped do
    Check.ok(
      :key_storage,
      "Stored signing keys were not inspected",
      "skipped: database unreadable, migrations pending, or key encryption config invalid; " <>
        "see the migrations and key_encryption checks",
      key_storage_fix()
    )
  end

  defp key_storage_result(status) do
    stranded = stranded_details(status.stranded_retired)

    cond do
      not EncryptionStatus.broken_now?(status) ->
        Check.ok(
          :key_storage,
          "Stored signing keys can be read",
          key_storage_counts(status) <> stranded,
          key_storage_fix()
        )

      status.unknown_kek != %{} or status.undecryptable > 0 ->
        Check.error(
          :key_storage,
          "Stored signing keys use an unknown key-encryption key or cannot be decrypted",
          "unknown_kek=#{kek_counts(status.unknown_kek)} undecryptable=#{status.undecryptable}" <>
            stranded,
          key_storage_fix()
        )

      true ->
        Check.error(
          :key_storage,
          "legacy_plaintext is :reject but #{status.legacy} stored signing keys are still legacy",
          key_storage_counts(status) <> stranded,
          key_storage_fix()
        )
    end
  end

  defp key_storage_counts(status) do
    on_current = Map.get(status.by_kek_id, status.current_kek_id, 0)
    other = status.by_kek_id |> Map.drop([status.current_kek_id]) |> Map.values() |> Enum.sum()

    "total=#{status.total} on_current=#{on_current} other_kek=#{other} legacy=#{status.legacy} " <>
      "legacy_plaintext=#{status.legacy_plaintext}"
  end

  defp kek_counts(counts) when counts == %{}, do: "none"

  defp kek_counts(counts),
    do: counts |> Enum.sort() |> Enum.map_join(",", fn {id, count} -> "#{id}(#{count})" end)

  defp stranded_details(%{count: 0}), do: ""

  defp stranded_details(%{count: count, kids: kids}) do
    " stranded_retired=#{count} kids=#{Enum.join(kids, ",")}; these retired keys do not block " <>
      "readiness"
  end

  defp key_storage_fix do
    "Add back any missing key-encryption key id to :keys, or run `mix lockspire.keys.reencrypt` " <>
      "and then `mix lockspire.keys.reencrypt --check` before setting `legacy_plaintext: :reject`."
  end

  defp safely(fun) do
    {:ok, fun.()}
  rescue
    error in [
      ArgumentError,
      RuntimeError,
      UndefinedFunctionError,
      FunctionClauseError,
      MatchError,
      DBConnection.ConnectionError,
      Postgrex.Error
    ] ->
      {:error, safe_message(error)}
  end

  # `Exception.message/1` of a `MatchError` inspects the unmatched term, which could hold
  # connection options or key rows, so that one error gets a fixed message.
  defp safe_message(%MatchError{}), do: "unexpected result"
  defp safe_message(error), do: Exception.message(error)
end
