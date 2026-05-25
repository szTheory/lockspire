defmodule Lockspire.Install.Verify do
  @moduledoc """
  Install-time diagnostics for the canonical embedded Lockspire host integration.
  """

  alias Lockspire.Install.Verify.Check
  alias Lockspire.RemoteJwksDiagnostics
  alias Lockspire.Storage.Ecto.Repository

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
      migrations_check(repo)
    ]
    |> maybe_append_remote_jwks_check(opts)

    %{ok?: Enum.all?(checks, &(&1.status == :ok)), checks: checks}
  end

  defp maybe_append_remote_jwks_check(checks, opts) do
    case Keyword.get(opts, :remote_jwks_client_id) do
      client_id when is_binary(client_id) and client_id != "" ->
        checks ++ [remote_jwks_check(client_id, opts)]

      _other ->
        checks
    end
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

    has_mount? =
      Enum.any?(routes, fn route ->
        route.verb == :* and route.path == mount_path and route.plug == Lockspire.Web.Router
      end)

    cond do
      missing_verify_routes != [] ->
        Check.error(
          :router,
          "Host router is missing required /verify routes",
          Enum.map_join(missing_verify_routes, ", ", fn {verb, path} -> "#{verb} #{path}" end),
          "Import your generated Lockspire router helper and keep the host-owned /verify routes mounted under the browser pipeline."
        )

      not has_mount? ->
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
          "router=#{inspect(router)} mount_path=#{mount_path}",
          "Keep the generated /verify routes and Lockspire forward mounted together."
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

  defp migrations_check(repo) do
    migrations_path = Application.app_dir(:lockspire, "priv/repo/migrations")

    {:ok, _started, statuses} =
      Ecto.Migrator.with_repo(repo, fn started_repo ->
        Ecto.Migrator.migrations(started_repo, migrations_path)
      end)

    pending =
      Enum.filter(statuses, fn
        {:down, _version, _name} -> true
        _other -> false
      end)

    if pending == [] do
      Check.ok(
        :migrations,
        "Lockspire and Oban migrations are up to date",
        "repo=#{inspect(repo)} applied_migrations=#{length(statuses)}",
        "Keep running `mix ecto.migrate` before booting new Lockspire features."
      )
    else
      details =
        Enum.map_join(pending, ", ", fn {:down, version, name} ->
          "#{version}:#{name}"
        end)

      Check.error(
        :migrations,
        "Pending Lockspire or Oban migrations detected",
        details,
        "Run `mix ecto.migrate` in the host app before using the embedded Lockspire surfaces."
      )
    end
  rescue
    error ->
      Check.error(
        :migrations,
        "Could not inspect migration state",
        Exception.message(error),
        "Ensure the configured repo is reachable and the database exists before rerunning verification."
      )
  end

  defp remote_jwks_check(client_id, opts) do
    case Repository.fetch_client_by_id(client_id) do
      {:ok, nil} ->
        Check.error(
          :remote_jwks,
          "Remote JWKS client not found",
          "client_id=#{client_id}",
          "Register or select a client that currently uses remote `jwks_uri`."
        )

      {:ok, client} ->
        remote_jwks_client_check(client, opts)

      {:error, reason} ->
        Check.error(
          :remote_jwks,
          "Remote JWKS diagnostic lookup failed",
          inspect(reason),
          "Ensure the configured repo is reachable before running targeted remote-JWKS diagnostics."
        )
    end
  end

  defp remote_jwks_client_check(%{jwks_uri: jwks_uri}, _opts) when not is_binary(jwks_uri) do
    Check.error(
      :remote_jwks,
      "Selected client is not using remote JWKS",
      "The target client does not have a `jwks_uri` configured.",
      "Pass a client that uses remote `jwks_uri` if you want targeted remote-key diagnostics."
    )
  end

  defp remote_jwks_client_check(client, opts) do
    diagnosis =
      case RemoteJwksDiagnostics.diagnose_client(client, opts) do
        {:ok, result} -> result
        {:error, result} when is_map(result) -> result
      end

    details =
      [
        "client_id=#{client.client_id}",
        "posture=#{diagnosis.posture}",
        "category=#{diagnosis.category}",
        diagnosis.detail
      ]
      |> Enum.join(" | ")

    fix =
      diagnosis.remediation
      |> List.first()
      |> Kernel.||("Review the configured `jwks_uri` support posture and retry after remediation.")

    if diagnosis.supported? do
      Check.ok(:remote_jwks, "Remote JWKS posture is inside the supported contract", details, fix)
    else
      Check.error(:remote_jwks, "Remote JWKS posture needs remediation", details, fix)
    end
  end
end
