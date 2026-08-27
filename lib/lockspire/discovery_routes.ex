defmodule Lockspire.DiscoveryRoutes do
  @moduledoc """
  Resolves the mounted route capability used by OIDC discovery at the delivery edge.

  Hosts may configure `:discovery_route_paths` with a path collection, a zero-arity
  function, or a module exporting `paths/0`. The legacy `:discovery_router` option
  remains a compatibility fallback while hosts migrate to the neutral capability.
  """

  @spec paths() :: MapSet.t(String.t())
  def paths do
    case Application.get_env(:lockspire, :discovery_route_paths) do
      nil -> legacy_paths()
      capability -> normalize_paths(capability)
    end
  end

  @doc false
  @spec install_default_capability() :: :ok
  def install_default_capability do
    if is_nil(Application.get_env(:lockspire, :discovery_route_paths)) do
      # Store the Phoenix-aware compatibility resolver at the configuration edge.
      # Protocol code consumes only this zero-arity route-path capability.
      Application.put_env(:lockspire, :discovery_route_paths, fn -> legacy_paths() end)
    end

    :ok
  end

  defp router_paths(router) do
    router
    |> Phoenix.Router.routes()
    |> Enum.map(& &1.path)
    |> MapSet.new()
  end

  defp legacy_paths, do: router_paths(discovery_router())

  defp discovery_router do
    Application.get_env(:lockspire, :discovery_router, default_router())
  end

  # Keep the shipped Phoenix router choice outside protocol and resolve it at runtime so
  # the router does not become an xref dependency of this delivery capability.
  defp default_router, do: Module.concat(["Lockspire", "Web", "Router"])

  defp normalize_paths(paths) when is_struct(paths, MapSet), do: paths
  defp normalize_paths(paths) when is_list(paths), do: MapSet.new(paths)

  defp normalize_paths(paths) when is_function(paths, 0), do: paths.() |> normalize_paths()

  defp normalize_paths(module) when is_atom(module) do
    if function_exported?(module, :paths, 0) do
      module.paths() |> normalize_paths()
    else
      MapSet.new()
    end
  end

  defp normalize_paths(_unsupported), do: MapSet.new()
end
