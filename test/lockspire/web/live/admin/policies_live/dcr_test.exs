defmodule Lockspire.Web.Live.Admin.PoliciesLive.DcrTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Web.AdminProof.HtmlAssertions
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

  test "global DCR policy page renders one grouped workflow form with unchanged fields" do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/dcr")

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_describedby_targets_exist(html)
    HtmlAssertions.assert_label_targets_exist(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_no_text(html, forbidden_secret_samples())

    assert occurrence_count(html, ~s(phx-submit="save_policy")) == 1
    assert html =~ "Save global DCR policy"
    assert html =~ "Configure"

    for name <- [
          "policy[registration_policy]",
          "policy[dcr_allowed_scopes]",
          "policy[dcr_allowed_grant_types]",
          "policy[dcr_allowed_response_types]",
          "policy[dcr_allowed_redirect_uri_schemes]",
          "policy[dcr_allowed_redirect_uri_hosts]",
          "policy[dcr_allowed_token_endpoint_auth_methods]",
          "policy[dcr_default_client_lifetime_seconds]",
          "policy[dcr_default_client_secret_lifetime_seconds]",
          "policy[dcr_default_registration_access_token_lifetime_seconds]"
        ] do
      assert html =~ ~s(name="#{name}")
    end

    for heading <- [
          "Registration gate",
          "Metadata allowlists",
          "Allowlist decisions",
          "Default lifetimes",
          "Lifetime defaults",
          "Token endpoint auth methods",
          "Risk and posture"
        ] do
      assert html =~ heading
    end

    assert occurrence_count(html, "lockspire-admin-workflow-shell") >= 5
    assert html =~ "Disabled"
    assert html =~ "Initial Access Token"
    assert html =~ "Open registration"
    assert html =~ "private_key_jwt posture"
    assert html =~ "client_secret_jwt posture"
    refute html =~ "extreme caution"
  end

  test "global DCR policy page keeps long allowlists wrapped and public-only" do
    long_host =
      "partner-#{String.duplicate("deep-subdomain-", 8)}registration.example.internal"

    assert {:ok, _policy} =
             ServerPolicy.put_dcr_policy(%{
               registration_policy: :open,
               dcr_allowed_scopes: ["openid", "profile", "partner.deep.audit.read"],
               dcr_allowed_grant_types: ["authorization_code", "refresh_token"],
               dcr_allowed_response_types: ["code"],
               dcr_allowed_redirect_uri_schemes: ["https"],
               dcr_allowed_redirect_uri_hosts: ["partners.example.com", long_host],
               dcr_allowed_token_endpoint_auth_methods: [
                 "private_key_jwt",
                 "client_secret_jwt",
                 "client_secret_basic"
               ],
               dcr_default_client_lifetime_seconds: 86_400,
               dcr_default_client_secret_lifetime_seconds: 3_600,
               dcr_default_registration_access_token_lifetime_seconds: 900
             })

    html = render_policy_html()

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_describedby_targets_exist(html)
    HtmlAssertions.assert_label_targets_exist(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_no_token_like_text(html)

    HtmlAssertions.assert_no_text(
      html,
      forbidden_secret_samples() ++ unsupported_policy_controls()
    )

    assert occurrence_count(html, ~s(phx-submit="save_policy")) == 1
    assert html =~ "Current mode is open"
    assert html =~ "Open registration"
    assert html =~ "partner.deep.audit.read"
    assert html =~ long_host
    assert html =~ "Default lifetimes configured"
    assert html =~ "private_key_jwt"
    assert html =~ "client_secret_jwt"
    assert html =~ "client_secret_basic"
    assert html =~ "This page is descriptive only for this slice."
    assert html =~ "does not create a remote key-fetch or algorithm-management workflow"
    refute html =~ "self-service"
  end

  test "CONFIG-03 D-01 D-02 D-03 D-04 D-09 D-10 DCR policy scope stays global and future-only" do
    html = render_policy_html()

    assert occurrence_count(html, ~s(phx-submit="save_policy")) == 1
    assert html =~ "Save global DCR policy"
    assert html =~ "future Dynamic Client Registration requests"
    assert html =~ "existing client records keep their stored configuration"
    assert html =~ "does not mint Initial Access Tokens"
    assert html =~ "rotate registration access tokens"
    assert html =~ "update existing client records"
    assert html =~ "create credential material"

    HtmlAssertions.assert_no_text(html, [
      "Mint initial access token",
      "Rotate registration access token",
      "Rotate client secret",
      "Create client",
      "Disable client",
      "Enable client",
      "host tenant policy",
      "developer portal",
      "Reveal secret",
      "Reveal token",
      "Export credential",
      "Approve DCR request",
      "Deny DCR request",
      "Fetch remote key",
      "Force publish",
      "Tenant policy editor",
      "client_secret_hash",
      "registration_access_token_hash",
      "BEGIN PRIVATE KEY",
      "Postgrex",
      "Ecto.Changeset",
      "Lockspire.Storage"
    ])
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
               dcr_allowed_token_endpoint_auth_methods: [
                 "client_secret_jwt",
                 "client_secret_basic"
               ]
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
      policy: %{
        registration_policy: "open",
        dcr_allowed_scopes: "openid, email",
        dcr_allowed_token_endpoint_auth_methods: "private_key_jwt, client_secret_basic"
      }
    })
    |> render_submit()

    assert {:ok, policy} = ServerPolicy.get_server_policy()
    assert policy.registration_policy == :open
    assert policy.dcr_allowed_scopes == ["openid", "email"]

    assert policy.dcr_allowed_token_endpoint_auth_methods == [
             "private_key_jwt",
             "client_secret_basic"
           ]
  end

  test "invalid input shows form errors" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/dcr")

    html =
      view
      |> render_submit("save_policy", %{
        policy: %{registration_policy: "open", dcr_default_client_lifetime_seconds: "-100"}
      })

    assert html =~ "must be greater than or equal to 0"
    assert html =~ "dcr_default_client_lifetime_seconds"

    HtmlAssertions.assert_no_text(html, [
      "Ecto.Changeset",
      "Postgrex",
      "Lockspire.Storage",
      "constraint",
      "stacktrace"
    ])
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end

  defp occurrence_count(html, pattern) do
    html
    |> String.split(pattern)
    |> length()
    |> Kernel.-(1)
  end

  defp render_policy_html do
    assert {:ok, socket} = Dcr.mount(%{}, %{}, socket_for(:dcr))
    rendered_to_string(Dcr.render(socket.assigns))
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
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

  defp unsupported_policy_controls do
    [
      "Mint initial access token",
      "Rotate registration access token",
      "Rotate client secret",
      "Create client",
      "Disable client",
      "Enable client",
      "host tenant policy",
      "developer portal",
      "Reveal secret",
      "Reveal token",
      "Export credential",
      "Approve DCR request",
      "Deny DCR request",
      "Fetch remote key",
      "Force publish",
      "Tenant policy editor",
      "client_secret_hash",
      "registration_access_token_hash",
      "BEGIN PRIVATE KEY",
      "Postgrex",
      "Ecto.Changeset",
      "Lockspire.Storage"
    ]
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
