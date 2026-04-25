defmodule Lockspire.Web.Live.Admin.PoliciesLive.ParTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.Live.Admin.PoliciesLive.Par
  alias Lockspire.Web.Router

  @endpoint Lockspire.Web.Endpoint

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "")

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

    # Register a few clients with different overrides to test summary counts
    {:ok, _c1} = Repository.register_client(%Client{client_id: "c1", client_type: :confidential, par_policy: :inherit})
    {:ok, _c2} = Repository.register_client(%Client{client_id: "c2", client_type: :public, par_policy: :required})
    {:ok, _c3} = Repository.register_client(%Client{client_id: "c3", client_type: :public, par_policy: :optional})

    :ok
  end

  test "router exposes global PAR policy management route" do
    routes = Phoenix.Router.routes(Lockspire.Web.Router)

    assert Enum.any?(routes, &live_route?(&1, "/admin/policies/par", Par))
  end

  test "global PAR policy page renders current mode and override summary" do
    assert {:ok, _policy} = ServerPolicy.put_server_policy(:optional)

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/par")

    assert html =~ "Global PAR policy"
    assert html =~ "Save global PAR policy"
    assert html =~ "Current mode is optional"

    # Summary counts
    assert html =~ "client inherits"
    assert html =~ "client requires PAR"
    assert html =~ "client marks PAR optional"
  end

  test "saving global PAR policy persists change" do
    assert {:ok, _policy} = ServerPolicy.put_server_policy(:optional)

    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/par")

    view
    |> form("form[phx-submit=save_policy]", %{policy: %{par_policy: "required"}})
    |> render_submit()

    assert {:ok, %{par_policy: :required}} = ServerPolicy.get_server_policy()
  end

  test "invalid global PAR policy values return field errors" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/par")

    html =
      view
      |> render_submit("save_policy", %{policy: %{par_policy: "invalid"}})

    assert html =~ "par_policy"
    assert html =~ "invalid_par_policy"

    # Ensure policy didn't change
    assert {:ok, %{par_policy: :optional}} = ServerPolicy.get_server_policy()
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
