defmodule Lockspire.DiscoveryRoutesTest.AlternateController do
  use Phoenix.Controller, formats: [:json]

  def create(conn, _params), do: json(conn, %{})
end

defmodule Lockspire.DiscoveryRoutesTest.AlternateRouter do
  use Phoenix.Router

  scope "/" do
    post("/token", Lockspire.DiscoveryRoutesTest.AlternateController, :create)
  end
end

defmodule Lockspire.DiscoveryRoutesTest do
  use ExUnit.Case, async: false

  alias Lockspire.DiscoveryRoutes

  setup do
    original_router = Application.get_env(:lockspire, :discovery_router)
    original_paths = Application.get_env(:lockspire, :discovery_route_paths)

    on_exit(fn ->
      restore_env(:discovery_router, original_router)
      restore_env(:discovery_route_paths, original_paths)
    end)
  end

  test "paths/0 resolves the legacy discovery_router override at the delivery edge" do
    Application.put_env(
      :lockspire,
      :discovery_router,
      Lockspire.DiscoveryRoutesTest.AlternateRouter
    )

    assert DiscoveryRoutes.paths() == MapSet.new(["/token"])
  end

  test "paths/0 accepts a configured neutral path capability before legacy router compatibility" do
    Application.put_env(
      :lockspire,
      :discovery_router,
      Lockspire.DiscoveryRoutesTest.AlternateRouter
    )

    Application.put_env(:lockspire, :discovery_route_paths, ["/authorize", "/token"])

    assert DiscoveryRoutes.paths() == MapSet.new(["/authorize", "/token"])
  end

  defp restore_env(key, nil), do: Application.delete_env(:lockspire, key)
  defp restore_env(key, value), do: Application.put_env(:lockspire, key, value)
end
