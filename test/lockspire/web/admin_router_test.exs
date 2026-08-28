defmodule Lockspire.Web.AdminRouterTest do
  use ExUnit.Case, async: true

  test "admin router exposes operator LiveViews without public OAuth endpoints" do
    assert %{
             plug: Phoenix.LiveView.Plug,
             log_module: Lockspire.Web.Live.Admin.OverviewLive.Index,
             phoenix_live_view: {_, :index, _, _}
           } =
             Phoenix.Router.route_info(Lockspire.Web.AdminRouter, "GET", "/", "")

    assert %{
             plug: Phoenix.LiveView.Plug,
             log_module: Lockspire.Web.Live.Admin.ClientsLive.Index,
             phoenix_live_view: {_, :index, _, _}
           } =
             Phoenix.Router.route_info(Lockspire.Web.AdminRouter, "GET", "/clients", "")

    assert %{
             plug: Phoenix.LiveView.Plug,
             log_module: Lockspire.Web.Live.Admin.PoliciesLive.Index,
             phoenix_live_view: {_, :index, _, _}
           } =
             Phoenix.Router.route_info(Lockspire.Web.AdminRouter, "GET", "/policies", "")

    assert %{
             plug: Phoenix.LiveView.Plug,
             log_module: Lockspire.Web.Live.Admin.DcrLive.Index,
             phoenix_live_view: {_, :index, _, _}
           } =
             Phoenix.Router.route_info(Lockspire.Web.AdminRouter, "GET", "/dcr", "")

    assert %{
             plug: Phoenix.LiveView.Plug,
             log_module: Lockspire.Web.Live.Admin.PoliciesLive.Dcr,
             phoenix_live_view: {_, :show, _, _}
           } =
             Phoenix.Router.route_info(
               Lockspire.Web.AdminRouter,
               "GET",
               "/policies/dcr",
               ""
             )

    assert :error =
             Phoenix.Router.route_info(Lockspire.Web.AdminRouter, "GET", "/authorize", "")

    assert :error = Phoenix.Router.route_info(Lockspire.Web.AdminRouter, "POST", "/token", "")
    assert :error = Phoenix.Router.route_info(Lockspire.Web.AdminRouter, "GET", "/jwks", "")
  end

  test "public OAuth router does not expose operator LiveViews" do
    refute Enum.any?(Phoenix.Router.routes(Lockspire.Web.Router), fn route ->
             route.verb == :get and String.starts_with?(route.path, "/admin")
           end)

    assert :error = Phoenix.Router.route_info(Lockspire.Web.Router, "GET", "/admin", "")
    assert :error = Phoenix.Router.route_info(Lockspire.Web.Router, "GET", "/admin/clients", "")
    assert :error = Phoenix.Router.route_info(Lockspire.Web.Router, "GET", "/admin/keys", "")
  end

  test "browser route truth keeps logout propagation as query workflow evidence" do
    source_routes = source_derived_admin_routes()
    browser_matrix_routes = browser_matrix_routes()

    assert "/admin/logouts" in source_routes
    refute "/admin/logout-deliveries" in source_routes

    assert "/admin/clients/:client_id/edit" in source_routes
    refute "/admin/clients/:client_id/edit?workflow=logout-propagation" in source_routes

    assert "/admin/clients/:client_id/edit?workflow=logout-propagation" in browser_matrix_routes

    assert Enum.filter(browser_matrix_routes, &String.contains?(&1, "?")) == [
             "/admin/clients/:client_id/edit?workflow=logout-propagation"
           ]
  end

  defp browser_matrix_routes do
    source_derived_admin_routes() ++
      ["/admin/clients/:client_id/edit?workflow=logout-propagation"]
  end

  defp source_derived_admin_routes do
    Lockspire.Web.AdminRouter
    |> Phoenix.Router.routes()
    |> Enum.filter(&(&1.verb == :get))
    |> Enum.map(&("/admin" <> &1.path))
  end
end
