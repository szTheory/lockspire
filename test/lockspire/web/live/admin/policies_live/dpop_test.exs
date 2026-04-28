defmodule Lockspire.Web.Live.Admin.PoliciesLive.DpopTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.Live.Admin.PoliciesLive.Dpop

  @endpoint Lockspire.Web.Endpoint

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "")

    on_exit(fn ->
      Application.put_env(:lockspire, :mount_path, "/lockspire")
    end)

    Application.put_env(:lockspire, Lockspire.Web.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      render_errors: [view: Lockspire.Web.ErrorView, accepts: ~w(html json)],
      live_view: [signing_salt: "lockspire_salt"]
    )

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Lockspire.Web.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, _c1} =
      Repository.register_client(%Client{
        client_id: "dpop-inherit",
        client_type: :confidential,
        dpop_policy: :inherit
      })

    {:ok, _c2} =
      Repository.register_client(%Client{
        client_id: "dpop-bearer",
        client_type: :public,
        dpop_policy: :bearer
      })

    {:ok, _c3} =
      Repository.register_client(%Client{
        client_id: "dpop-required",
        client_type: :public,
        dpop_policy: :dpop
      })

    :ok
  end

  test "router exposes global DPoP policy management route" do
    routes = Phoenix.Router.routes(Lockspire.Web.Router)

    assert Enum.any?(routes, &live_route?(&1, "/admin/policies/dpop", Dpop))
  end

  test "global DPoP policy page renders current mode and override summary" do
    assert {:ok, _policy} = ServerPolicy.put_dpop_policy(:bearer)

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/dpop")

    assert html =~ "Global DPoP policy"
    assert html =~ "Save global DPoP policy"
    assert html =~ "Current mode is bearer"
    assert html =~ "client inherits"
    assert html =~ "client uses bearer"
    assert html =~ "client requires DPoP"
  end

  test "saving global DPoP policy persists change" do
    assert {:ok, _policy} = ServerPolicy.put_dpop_policy(:bearer)

    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/dpop")

    view
    |> form("form[phx-submit=save_policy]", %{policy: %{dpop_policy: "dpop"}})
    |> render_submit()

    assert {:ok, %{dpop_policy: :dpop}} = ServerPolicy.get_server_policy()
  end

  test "invalid global DPoP policy values return field errors" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/dpop")

    html =
      view
      |> render_submit("save_policy", %{policy: %{dpop_policy: "invalid"}})

    assert html =~ "dpop_policy"
    assert html =~ "invalid_dpop_policy"
    assert {:ok, %{dpop_policy: :bearer}} = ServerPolicy.get_server_policy()
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
