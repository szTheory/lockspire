defmodule Lockspire.Install.Verify do
  @moduledoc """
  Install-time diagnostics for the canonical embedded Lockspire host integration.

  Verification is deliberately aggregate: a malformed host seam must not hide a
  separate router, migration, or configuration defect that an adopter can fix in
  the same edit cycle.
  """

  alias Lockspire.Install.Migrations
  alias Lockspire.Install.Verify.Check

  @host_routes [
    {:get, "/verify"},
    {:post, "/verify"},
    {:post, "/verify/:handle/approve"},
    {:post, "/verify/:handle/deny"},
    {:get, "/authorized-apps"},
    {:delete, "/authorized-apps/:id"}
  ]

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
        [router_check(router, mount_path), migrations_check(repo, project_root)]

    %{ok?: Enum.all?(checks, &(&1.status == :ok)), checks: checks}
  end

  defp config_checks do
    [
      config_check(:repo, "repo", &Lockspire.Config.repo!/0),
      config_check(:account_resolver, "account_resolver", &Lockspire.Config.account_resolver!/0),
      config_check(:issuer, "issuer", &issuer_value/0),
      config_check(:mount_path, "mount_path", &Lockspire.Config.mount_path/0),
      config_check(:logout_path, "logout_path", &Lockspire.Config.logout_path/0),
      config_check(:oban, "oban", &Lockspire.Oban.runtime_config!/0)
    ]
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
    case safely(fn -> Phoenix.Router.routes(router) end) do
      {:ok, routes} ->
        router_result(router, routes, mount_path)

      {:error, message} ->
        Check.error(
          :router,
          "Host router module is unavailable",
          message,
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
    admin_mount_path = admin_mount_path(mount_path)
    missing_host_routes = missing_host_routes(routes)
    consent_index = route_index(routes, &consent_route?(&1, mount_path))
    admin_index = route_index(routes, &admin_mount_route?(&1, admin_mount_path))
    public_index = route_index(routes, &public_mount_route?(&1, mount_path))

    errors =
      missing_host_route_errors(missing_host_routes) ++
        missing_route_error(
          consent_index,
          "generated consent LiveView #{mount_path}/consent/:interaction_id"
        ) ++
        missing_route_error(
          admin_index,
          "generated admin forward #{admin_mount_path} -> Lockspire.Web.AdminRouter"
        ) ++
        missing_route_error(public_index, "public forward #{mount_path} -> Lockspire.Web.Router") ++
        ordering_errors(consent_index, admin_index, public_index)

    case errors do
      [] ->
        Check.ok(
          :router,
          "Host router wiring is present",
          "router=#{inspect(router)} public_mount=#{mount_path} admin_mount=#{admin_mount_path}",
          "Keep generated host routes, admin forwarding, and public forwarding together. Verify your host-owned operator policy with host request tests."
        )

      _ ->
        Check.error(
          :router,
          "Host router wiring is incomplete",
          Enum.join(errors, "; "),
          "Import the generated Lockspire router helper and call `lockspire_routes/0` after host browser routes. The generated macro requires :require_operator at compile time; verify host operator policy with host request tests."
        )
    end
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
      "generated admin forward appears after the public Lockspire forward"
    )
  end

  defp ordering_errors(_consent_index, _admin_index, _public_index), do: []

  defp append_if(errors, true, error), do: errors ++ [error]
  defp append_if(errors, false, _error), do: errors

  defp route_index(routes, predicate), do: Enum.find_index(routes, predicate)

  defp consent_route?(route, mount_path) do
    route.path == consent_path(mount_path) and is_tuple(route.metadata[:phoenix_live_view])
  end

  defp consent_path(""), do: "/consent/:interaction_id"
  defp consent_path("/"), do: "/consent/:interaction_id"

  defp consent_path(mount_path),
    do: String.trim_trailing(mount_path, "/") <> "/consent/:interaction_id"

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
    {:ok, statuses, _apps} =
      Ecto.Migrator.with_repo(repo, fn started_repo ->
        Ecto.Migrator.migrations(started_repo, migration_path)
      end)

    statuses
  end

  defp safely(fun) do
    {:ok, fun.()}
  rescue
    error in [ArgumentError, RuntimeError, UndefinedFunctionError, FunctionClauseError] ->
      {:error, Exception.message(error)}
  end
end
