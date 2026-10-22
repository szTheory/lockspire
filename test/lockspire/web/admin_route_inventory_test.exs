defmodule Lockspire.Web.AdminRouteInventoryTest do
  use ExUnit.Case, async: false

  alias Lockspire.Web.AdminRouteHost

  @inventory [
    {"/", :get, Lockspire.Web.Live.Admin.OverviewLive.Index, :index},
    {"/overview", :get, Lockspire.Web.Live.Admin.OverviewLive.Index, :index},
    {"/clients", :get, Lockspire.Web.Live.Admin.ClientsLive.Index, :index},
    {"/clients/new", :get, Lockspire.Web.Live.Admin.ClientsLive.Index, :new},
    {"/clients/:client_id", :get, Lockspire.Web.Live.Admin.ClientsLive.Show, :show},
    {"/consents", :get, Lockspire.Web.Live.Admin.ConsentsLive.Index, :index},
    {"/consents/:id", :get, Lockspire.Web.Live.Admin.ConsentsLive.Show, :show},
    {"/tokens", :get, Lockspire.Web.Live.Admin.TokensLive.Index, :index},
    {"/tokens/:id", :get, Lockspire.Web.Live.Admin.TokensLive.Show, :show},
    {"/keys", :get, Lockspire.Web.Live.Admin.KeysLive.Index, :index},
    {"/keys/:id", :get, Lockspire.Web.Live.Admin.KeysLive.Show, :show},
    {"/interactions", :get, Lockspire.Web.Live.Admin.InteractionsLive.Index, :index},
    {"/logouts", :get, Lockspire.Web.Live.Admin.LogoutDeliveriesLive.Index, :index},
    {"/iats", :get, Lockspire.Web.Live.Admin.IatLive.Index, :index},
    {"/iats/new", :get, Lockspire.Web.Live.Admin.IatLive.New, :new},
    {"/device_authorizations", :get, Lockspire.Web.Live.Admin.DeviceAuthorizationsLive.Index,
     :index},
    {"/clients/:client_id/edit", :get, Lockspire.Web.Live.Admin.ClientsLive.Show, :edit},
    {"/clients/:client_id/par-policy", :get, Lockspire.Web.Live.Admin.ClientsLive.Show,
     :par_policy},
    {"/clients/:client_id/security-profile", :get, Lockspire.Web.Live.Admin.ClientsLive.Show,
     :security_profile},
    {"/clients/:client_id/redirects", :get, Lockspire.Web.Live.Admin.ClientsLive.Show,
     :redirects},
    {"/clients/:client_id/logout-uris", :get, Lockspire.Web.Live.Admin.ClientsLive.Show,
     :logout_uris},
    {"/clients/:client_id/rotate-secret", :get, Lockspire.Web.Live.Admin.ClientsLive.Show,
     :rotate_secret},
    {"/clients/:client_id/rotate-registration-access-token", :get,
     Lockspire.Web.Live.Admin.ClientsLive.Show, :rotate_registration_access_token},
    {"/dcr", :get, Lockspire.Web.Live.Admin.DcrLive.Index, :index},
    {"/policies", :get, Lockspire.Web.Live.Admin.PoliciesLive.Index, :index},
    {"/policies/par", :get, Lockspire.Web.Live.Admin.PoliciesLive.Par, :show},
    {"/policies/security-profile", :get, Lockspire.Web.Live.Admin.PoliciesLive.SecurityProfile,
     :show},
    {"/policies/dpop", :get, Lockspire.Web.Live.Admin.PoliciesLive.Dpop, :show},
    {"/policies/dcr", :get, Lockspire.Web.Live.Admin.PoliciesLive.Dcr, :show}
  ]

  @mounts [
    {AdminRouteHost.DefaultRouter, "/lockspire/admin"},
    {AdminRouteHost.NestedRouter, "/teams/ops/identity/admin"},
    {AdminRouteHost.RootRouter, "/admin"}
  ]

  test "the literal original inventory matches all routers in order" do
    assert length(@inventory) == 29
    assert length(Enum.uniq(@inventory)) == 29
    assert normalized_inventory(Lockspire.Web.AdminRouter, "/") == @inventory

    for {router, mount} <- @mounts do
      assert normalized_inventory(router, mount) == @inventory
    end
  end

  test "each concrete route selects the expected LiveView action and protected metadata" do
    for {relative_path, :get, view, action} <- @inventory do
      route = route_info!(Lockspire.Web.AdminRouter, concrete_path(relative_path))
      {selected_view, selected_action, _opts, _session} = route.phoenix_live_view

      assert route.log_module == view
      assert selected_view == view
      assert selected_action == action
    end

    for {router, mount} <- @mounts, {relative_path, :get, view, action} <- @inventory do
      path = mount <> concrete_path(relative_path)
      route = route_info!(router, path)
      {selected_view, selected_action, _opts, live_session} = route.phoenix_live_view

      assert route.plug == Phoenix.LiveView.Plug
      assert route.log_module == view
      assert selected_view == view
      assert selected_action == action
      assert route.pipe_through == [:browser, :lockspire_admin_mount]
      assert live_session.name == :lockspire_admin

      assert hook_modules(live_session) == [
               AdminRouteHost.LiveAuthorization,
               Lockspire.Web.AdminMount
             ]
    end
  end

  test "literal and parameterized routes preserve native matching boundaries" do
    for {router, mount} <- @mounts do
      assert route_info!(router, mount <> "/clients/new").phoenix_live_view
             |> elem(1) == :new

      refute match?(
               %{plug: Phoenix.LiveView.Plug},
               Phoenix.Router.route_info(router, "POST", mount <> "/clients/new", "localhost")
             )

      for path <- [mount <> "foo", mount <> "-extra", mount <> "/nested/admin"] do
        refute match?(
                 %{plug: Phoenix.LiveView.Plug},
                 Phoenix.Router.route_info(router, "GET", path, "localhost")
               )
      end
    end
  end

  test "repeated and concurrent matching does not alter the route inventory" do
    for {router, mount} <- @mounts do
      before = normalized_inventory(router, mount)
      paths = Enum.map(@inventory, fn {path, :get, _, _} -> mount <> concrete_path(path) end)
      expected = Enum.map(paths, &selected_metadata(router, &1))

      concurrent =
        paths
        |> Task.async_stream(&selected_metadata(router, &1), max_concurrency: 8, timeout: 5_000)
        |> Enum.map(fn {:ok, metadata} -> metadata end)

      assert concurrent == expected
      assert normalized_inventory(router, mount) == before
      assert normalized_inventory(router, mount) == before
    end
  end

  defp normalized_inventory(router, "/") do
    router
    |> Phoenix.Router.routes()
    |> Enum.filter(&admin_live_route?(&1, "/"))
    |> Enum.map(&route_tuple(&1, "/"))
  end

  defp normalized_inventory(router, mount) do
    router
    |> Phoenix.Router.routes()
    |> Enum.filter(&admin_live_route?(&1, mount))
    |> Enum.map(&route_tuple(&1, mount))
  end

  defp admin_live_route?(route, "/") do
    route.plug == Phoenix.LiveView.Plug and String.starts_with?(route.path, "/")
  end

  defp admin_live_route?(route, mount) do
    route.plug == Phoenix.LiveView.Plug and
      (route.path == mount or String.starts_with?(route.path, mount <> "/"))
  end

  defp route_tuple(route, "/") do
    {normalize_relative(route.path), route.verb, elem(live_view(route), 0),
     elem(live_view(route), 1)}
  end

  defp route_tuple(route, mount) do
    relative = String.replace_prefix(route.path, mount, "")

    {normalize_relative(relative), route.verb, elem(live_view(route), 0),
     elem(live_view(route), 1)}
  end

  defp normalize_relative(""), do: "/"
  defp normalize_relative("/"), do: "/"
  defp normalize_relative(path), do: path

  defp live_view(route) do
    {view, action, _opts, _session} = Map.fetch!(route.metadata, :phoenix_live_view)
    {view, action}
  end

  defp concrete_path(path) do
    path
    |> String.replace(":client_id", "client-123")
    |> String.replace(":id", "record-123")
  end

  defp route_info!(router, path) do
    Phoenix.Router.route_info(router, "GET", path, "localhost")
  end

  defp hook_modules(live_session) do
    Enum.map(live_session.extra.on_mount, fn %{id: {module, _arg}} -> module end)
  end

  defp selected_metadata(router, path) do
    route = route_info!(router, path)
    {view, action, _opts, session} = route.phoenix_live_view
    {route.route, :get, route.log_module, view, action, route.pipe_through, session.name}
  end
end
