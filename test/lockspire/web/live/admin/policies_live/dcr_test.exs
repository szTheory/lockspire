defmodule Lockspire.Web.Live.Admin.PoliciesLive.DcrTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Web.Live.Admin.PoliciesLive.Dcr

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

    assert {:ok, _policy} =
             Lockspire.Storage.Ecto.Repository.put_server_policy(%Lockspire.Domain.ServerPolicy{
               id: 1
             })

    :ok
  end

  test "router exposes global DCR policy management route" do
    routes = Phoenix.Router.routes(Lockspire.Web.Router)

    assert Enum.any?(routes, &live_route?(&1, "/admin/policies/dcr", Dcr))
  end

  test "global DCR policy page renders current mode" do
    assert {:ok, _policy} =
             ServerPolicy.put_dcr_policy(%{registration_policy: :initial_access_token})

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/dcr")

    assert html =~ "Global DCR policy"
    assert html =~ "Save global DCR policy"
    assert html =~ "Current mode is initial_access_token"
  end

  test "global DCR policy page explains private_key_jwt registration posture and algorithms" do
    assert {:ok, _policy} =
             ServerPolicy.put_dcr_policy(%{
               registration_policy: :open,
               dcr_allowed_token_endpoint_auth_methods: ["private_key_jwt", "client_secret_basic"]
             })

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/dcr")

    assert html =~ "private_key_jwt"
    assert html =~ "Self-registered clients may use private_key_jwt"
    assert html =~ "RS256, ES256, PS256, EdDSA"
    assert html =~ "jwks_uri"
  end

  test "global DCR policy page explains the narrow client_secret_jwt posture" do
    assert {:ok, _policy} =
             ServerPolicy.put_dcr_policy(%{
               registration_policy: :open,
               dcr_allowed_token_endpoint_auth_methods: ["client_secret_jwt", "client_secret_basic"]
             })

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/dcr")

    assert html =~ "client_secret_jwt"
    assert html =~ "shared direct-client token and revocation surfaces"
    assert html =~ "HS256"
  end

  test "saving global DCR policy persists change" do
    assert {:ok, _policy} = ServerPolicy.put_dcr_policy(%{registration_policy: :disabled})

    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/dcr")

    view
    |> form("form[phx-submit=save_policy]", %{
      policy: %{registration_policy: "open", dcr_allowed_scopes: "openid, email"}
    })
    |> render_submit()

    assert {:ok, policy} = ServerPolicy.get_server_policy()
    assert policy.registration_policy == :open
    assert policy.dcr_allowed_scopes == ["openid", "email"]
  end

  test "invalid input shows form errors" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/dcr")

    html =
      view
      |> render_submit("save_policy", %{
        policy: %{registration_policy: "open", dcr_default_client_lifetime_seconds: "-100"}
      })

    assert html =~ "must be greater than or equal to 0"
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
