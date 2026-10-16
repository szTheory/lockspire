defmodule Lockspire.Web.Live.Admin.PoliciesLive.IndexTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.PoliciesLive.Index

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
    assert {:ok, _policy} = ServerPolicy.put_server_policy(:optional)
    :ok
  end

  test "router exposes policy overview route" do
    routes = Lockspire.Web.AdminRouteTestHelpers.admin_routes()

    assert Enum.any?(routes, &live_route?(&1, "/admin/policies", Index))
  end

  test "provider settings show concise policy choices and useful destinations" do
    assert {:ok, view, html} = live(conn_for_admin(), "/admin/policies")

    HtmlAssertions.assert_page_contract!(html)
    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_links_have_hrefs(html)
    HtmlAssertions.assert_no_generic_cta_text(html)

    assert html =~ "Security settings"
    assert html =~ "Default for apps"
    assert html =~ "Optional PAR"
    assert html =~ "Bearer tokens"
    refute has_element?(view, ".lockspire-admin-display-value")

    assert html =~
             "0 apps require PAR; 0 apps choose it."

    assert html =~
             "0 apps registered themselves through the API; 0 active setup tokens are stored."

    assert has_element?(
             view,
             ~s(.lockspire-admin-secondary-nav a[href="/admin/policies"][aria-current="page"][data-phx-link="redirect"])
           )

    refute html =~ "operator action surface"

    for {label, href} <- [
          {"Authorization requests", "/admin/policies/par"},
          {"Default security settings", "/admin/policies/security-profile"},
          {"Token proof", "/admin/policies/dpop"},
          {"App self-registration", "/admin/policies/dcr"}
        ] do
      assert html =~ label
      HtmlAssertions.assert_has_link(html, href)
      assert has_element?(view, ~s(.lockspire-admin-policy-list__row h2 a[href="#{href}"]), label)
    end

    refute has_element?(view, ".lockspire-admin-policy-list__row .lockspire-admin-btn")
    refute html =~ "Open workflow"

    HtmlAssertions.assert_no_text(html, forbidden_secret_samples() ++ backend_leak_samples())

    HtmlAssertions.assert_no_text(html, [
      "Save request settings",
      "Save global security profile",
      "Save token proof settings",
      "Save app registration settings",
      "Rotate client secret",
      "Rotate registration access token",
      "Mint initial access token",
      "Reset nonce",
      "Inspect proof",
      "Debug token",
      "host tenant policy",
      "developer portal",
      "public theming",
      "browser proof API",
      "AI judge gate"
    ])
  end

  test "failed policy and inventory reads stay unavailable instead of showing zero values" do
    prior_repo = Application.get_env(:lockspire, :repo)
    unavailable_repo = Module.concat(__MODULE__, "UnavailablePolicyReadRepo")

    try do
      Application.put_env(:lockspire, :repo, unavailable_repo)

      assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies")

      assert html =~ "Default for apps"
      assert html =~ "Unavailable"
      assert html =~ "App settings could not be loaded."
      assert html =~ "App registration and setup-token counts could not be loaded."
      refute html =~ "0 apps require the request step"
      refute html =~ "0 apps registered themselves"

      for href <- ["/admin/policies/par", "/admin/policies/dpop", "/admin/policies/dcr"] do
        HtmlAssertions.assert_has_link(html, href)
      end
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
      "BEGIN PRIVATE KEY",
      "authorization_code=",
      "code_verifier="
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

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
