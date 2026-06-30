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
    routes = Phoenix.Router.routes(Lockspire.Web.Router)

    assert Enum.any?(routes, &live_route?(&1, "/admin/policies", Index))
  end

  test "CONFIG-01 policy overview uses route-specific policy review labels" do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies")

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_links_have_hrefs(html)
    HtmlAssertions.assert_no_generic_cta_text(html)

    assert html =~ "Configure"
    assert html =~ "Policy posture"

    for {label, href} <- [
          {"Review PAR policy", "/admin/policies/par"},
          {"Review security profile", "/admin/policies/security-profile"},
          {"Review DPoP policy", "/admin/policies/dpop"},
          {"Review DCR policy", "/admin/policies/dcr"}
        ] do
      assert html =~ label
      HtmlAssertions.assert_has_link(html, href)
    end

    refute html =~ "Open workflow"
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
