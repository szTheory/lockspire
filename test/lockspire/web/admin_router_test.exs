defmodule Lockspire.Web.AdminRouterTest do
  use ExUnit.Case, async: true

  test "admin router exposes operator LiveViews without public OAuth endpoints" do
    assert %{
             plug: Phoenix.LiveView.Plug,
             log_module: Lockspire.Web.Live.Admin.ClientsLive.Index,
             phoenix_live_view: {_, :index, _, _}
           } =
             Phoenix.Router.route_info(Lockspire.Web.AdminRouter, "GET", "/", "")

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
end
