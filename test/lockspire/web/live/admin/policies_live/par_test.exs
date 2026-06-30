defmodule Lockspire.Web.Live.Admin.PoliciesLive.ParTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.PoliciesLive.Par

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

    # Register a few clients with different overrides to test summary counts
    {:ok, _c1} =
      Repository.register_client(%Client{
        client_id: "c1",
        client_type: :confidential,
        par_policy: :inherit
      })

    {:ok, _c2} =
      Repository.register_client(%Client{
        client_id: "c2",
        client_type: :public,
        par_policy: :required
      })

    {:ok, _c3} =
      Repository.register_client(%Client{
        client_id: "c3",
        client_type: :public,
        par_policy: :optional
      })

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

  test "CONFIG-01 CONFIG-03 D-03 D-04 D-05 D-09 D-10 PAR posture explains global scope before save" do
    assert {:ok, _policy} = ServerPolicy.put_server_policy(:required)

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/par")

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_links_have_hrefs(html)
    HtmlAssertions.assert_label_targets_exist(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_no_text(html, forbidden_secret_samples())

    assert html =~ "Configure"
    assert html =~ "Global PAR policy"
    assert html =~ "Global posture"
    assert html =~ "Clients that inherit"
    assert html =~ "Next safe action"
    assert html =~ "Save global PAR policy"
    assert html =~ "global issuer PAR default"
    assert html =~ "future authorization requests"
    assert html =~ "Existing client overrides stay on their client policy routes."

    for href <- policy_nav_hrefs() do
      HtmlAssertions.assert_has_link(html, href)
    end

    HtmlAssertions.assert_no_text(html, [
      "Create client",
      "Disable client",
      "Enable client",
      "Rotate client secret",
      "Rotate registration access token",
      "Reset nonce",
      "Inspect proof",
      "Debug token",
      "Fetch remote key",
      "Remote key fetch",
      "Raw proof",
      "Per-client mutation",
      "mutate existing clients",
      "update existing client records",
      "host tenant policy",
      "host-owned product policy",
      "Tenant policy editor",
      "developer portal",
      "public theming",
      "AI judge",
      "AI gate",
      "browser gate",
      "Reveal secret",
      "Export credential",
      "Postgrex",
      "Ecto.Changeset",
      "Lockspire.Storage"
    ])
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
    HtmlAssertions.assert_no_text(html, forbidden_secret_samples() ++ backend_leak_samples())

    # Ensure policy didn't change
    assert {:ok, %{par_policy: :optional}} = ServerPolicy.get_server_policy()
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
