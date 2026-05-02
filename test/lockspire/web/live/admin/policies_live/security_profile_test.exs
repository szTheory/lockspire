defmodule Lockspire.Web.Live.Admin.PoliciesLive.SecurityProfileTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Admin
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.Live.Admin.PoliciesLive.SecurityProfile

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

    {:ok, _inherit_client} =
      Repository.register_client(%Client{
        client_id: "security-inherit",
        client_type: :confidential,
        security_profile: :inherit
      })

    {:ok, _fapi_client} =
      Repository.register_client(%Client{
        client_id: "security-fapi",
        client_type: :public,
        security_profile: :fapi_2_0_security
      })

    {:ok, _none_client} =
      Repository.register_client(%Client{
        client_id: "security-none",
        client_type: :public,
        security_profile: :none
      })

    :ok
  end

  test "router exposes global security profile management route" do
    routes = Phoenix.Router.routes(Lockspire.Web.Router)

    assert Enum.any?(
             routes,
             &live_route?(&1, "/admin/policies/security-profile", SecurityProfile)
           )
  end

  test "global security profile page renders current mode nav and override summary" do
    assert {:ok, _policy} = Admin.put_security_profile(:none)

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/security-profile")

    assert html =~ "Global security profile"
    assert html =~ "Save global security profile"
    assert html =~ "Current profile is None (Standard OIDC)"
    assert html =~ "PAR"
    assert html =~ "Security Profile"
    assert html =~ "DPoP"
    assert html =~ "DCR"
    assert html =~ "client inherits"
    assert html =~ "client requires FAPI 2.0"
    assert html =~ "client forces None"
  end

  test "saving global security profile persists change across reload" do
    assert {:ok, _policy} = Admin.put_security_profile(:none)
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/security-profile")

    view
    |> form("form[phx-submit=save_policy]", %{policy: %{security_profile: "fapi_2_0_security"}})
    |> render_submit()

    assert {:ok, %{security_profile: :fapi_2_0_security}} = Admin.get_server_policy()

    assert {:ok, _reloaded_view, html} =
             live(conn_for_admin(), "/admin/policies/security-profile")

    assert html =~ "Current profile is FAPI 2.0 Security Profile"
  end

  test "invalid global security profile values return field errors" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/security-profile")

    html =
      view
      |> render_submit("save_policy", %{policy: %{security_profile: "invalid"}})

    assert html =~ "security_profile"
    assert html =~ "invalid_security_profile"
    assert {:ok, %{security_profile: :none}} = Admin.get_server_policy()
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
