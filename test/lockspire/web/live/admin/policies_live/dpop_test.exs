defmodule Lockspire.Web.Live.Admin.PoliciesLive.DpopTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
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
    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(Lockspire.TestRepo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(owner) end)

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
    routes = Lockspire.Web.AdminRouteTestHelpers.admin_routes()

    assert Enum.any?(routes, &live_route?(&1, "/admin/policies/dpop", Dpop))
  end

  test "global DPoP policy page renders current mode and override summary" do
    assert {:ok, _policy} = ServerPolicy.put_dpop_policy(:bearer)

    assert {:ok, view, html} = live(conn_for_admin(), "/admin/policies/dpop")

    assert html =~ "Default for apps"
    assert html =~ "Token proof settings"
    refute html =~ "Current choice:"

    assert has_element?(
             view,
             ~s(input[type="radio"][name="policy[dpop_policy]"][value="bearer"][checked])
           )

    assert html =~ "Access token proof"
    assert html =~ "DPoP ties an access token to an"
    assert html =~ "DPoP-bound access tokens required"
    assert html =~ "app uses provider default"
    assert html =~ "app uses bearer tokens"
    assert html =~ "app requires DPoP"
  end

  test "failed policy read is shown as unavailable and can be reloaded" do
    prior_repo = Application.get_env(:lockspire, :repo)
    unavailable_repo = Module.concat(__MODULE__, "UnavailablePolicyReadRepo")

    try do
      Application.put_env(:lockspire, :repo, unavailable_repo)

      assert {:ok, view, html} = live(conn_for_admin(), "/admin/policies/dpop")

      assert html =~ "Could not load token proof settings"
      assert html =~ "Reload settings"
      refute html =~ ~s(name="policy[dpop_policy]")
      refute html =~ "Save token proof settings"

      Application.put_env(:lockspire, :repo, prior_repo)
      html = render_click(view, "reload_policy")

      assert html =~ "Default for apps"
      assert html =~ "Save token proof settings"
    after
      Application.put_env(:lockspire, :repo, prior_repo)
    end
  end

  test "unavailable client counts do not promise a retry control" do
    assert {:ok, socket} =
             Dpop.mount(%{}, %{}, %Phoenix.LiveView.Socket{
               assigns: %{live_action: :index, __changed__: %{}}
             })

    socket = Phoenix.Component.assign(socket, :summary, nil)
    html = rendered_to_string(Dpop.render(socket.assigns))

    assert html =~ "App settings are unavailable."
    refute html =~ "Reload this page to try again."
  end

  test "DPoP setting explains proof of possession and provider-default scope" do
    assert {:ok, _policy} = ServerPolicy.put_dpop_policy(:dpop)

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/dpop")

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_links_have_hrefs(html)
    HtmlAssertions.assert_label_targets_exist(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_no_text(html, forbidden_secret_samples())

    assert html =~ "Token proof settings"
    assert html =~ "Access token proof"
    assert html =~ "Save token proof settings"
    assert html =~ "Apps may have their own setting."
    assert html =~ "must prove they hold the key"

    for href <- policy_nav_hrefs() do
      HtmlAssertions.assert_has_link(html, href)
    end

    HtmlAssertions.assert_no_text(html, [
      "Reset nonce",
      "Inspect proof",
      "Debug token",
      "Fetch remote key",
      "Remote key fetch",
      "Raw proof",
      "Proof replay",
      "Add app",
      "Disable app",
      "Enable app",
      "Rotate client secret",
      "Rotate registration access token",
      "per-client mutation",
      "host tenant policy",
      "host-owned product policy",
      "Tenant policy editor",
      "developer portal",
      "public theming",
      "AI judge",
      "AI gate",
      "browser gate",
      "Reveal token",
      "Export credential",
      "Postgrex",
      "Ecto.Changeset",
      "Lockspire.Storage"
    ])
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

    assert html =~
             "Choose whether apps using the provider default may use bearer tokens or must prove key possession with DPoP."

    refute html =~ "invalid_dpop_policy"
    HtmlAssertions.assert_no_text(html, forbidden_secret_samples() ++ backend_leak_samples())
    assert {:ok, %{dpop_policy: :bearer}} = ServerPolicy.get_server_policy()
  end

  test "failed global DPoP policy save stays unconfirmed" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/dpop")

    prior_repo = Application.get_env(:lockspire, :repo)
    unavailable_repo = Module.concat(__MODULE__, "UnavailablePolicySaveRepo")

    try do
      Application.put_env(:lockspire, :repo, unavailable_repo)
      html = render_submit(view, "save_policy", %{policy: %{dpop_policy: "dpop"}})

      assert html =~ "Token proof settings could not be confirmed."
      assert html =~ "Reload this page to check the saved value."
      refute html =~ "request_failed"
      refute html =~ "UnavailablePolicySaveRepo"
    after
      Application.put_env(:lockspire, :repo, prior_repo)
    end
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end

  defp forbidden_secret_samples do
    [
      "real-client-secret",
      "production-secret",
      "prod-access-token",
      "prod-refresh-token",
      "sk_live_",
      "pk_live_",
      "eyJhbGci",
      "BEGIN PRIVATE KEY"
    ]
  end

  defp backend_leak_samples do
    [
      "Postgrex",
      "Ecto.Changeset",
      "Lockspire.Storage",
      "stacktrace",
      "constraint violation",
      "private_jwk_encrypted"
    ]
  end

  defp policy_nav_hrefs do
    [
      "/admin/policies/par",
      "/admin/policies/security-profile",
      "/admin/policies/dpop",
      "/admin/policies/dcr"
    ]
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
