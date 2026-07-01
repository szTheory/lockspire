defmodule Lockspire.Web.AdminRouteTestHelpers do
  @moduledoc false

  def admin_routes do
    Lockspire.Web.AdminRouter
    |> Phoenix.Router.routes()
    |> Enum.map(&with_admin_mount/1)
  end

  defp with_admin_mount(%{path: "/"} = route), do: %{route | path: "/admin"}
  defp with_admin_mount(%{path: path} = route), do: %{route | path: "/admin" <> path}
end
