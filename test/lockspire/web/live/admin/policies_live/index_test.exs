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

  test "CONFIG-01 policy overview uses route-specific policy review labels" do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies")

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_links_have_hrefs(html)
    HtmlAssertions.assert_no_generic_cta_text(html)

    assert html =~ "Configure"
    assert html =~ "Policy posture"
    assert html =~ "issuer-level policy route"
    assert html =~ "Current setting"
    assert html =~ "Review issuer PAR defaults and client override pressure."
    assert html =~ "Review inherited security profile posture and strict readiness."
    assert html =~ "Review sender-constrained token defaults and client exceptions."
    assert html =~ "Review future registration gates, metadata allowlists, and DCR lifetimes."
    assert html =~ "0 clients require PAR; 0 mark it optional."
    assert html =~ "0 self-registered clients and 0 active IATs."

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

    HtmlAssertions.assert_no_text(html, forbidden_secret_samples() ++ backend_leak_samples())

    HtmlAssertions.assert_no_text(html, [
      "Save global PAR policy",
      "Save global security profile",
      "Save global DPoP policy",
      "Save global DCR policy",
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
