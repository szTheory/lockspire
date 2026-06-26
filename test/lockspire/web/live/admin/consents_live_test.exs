defmodule Lockspire.Web.Live.Admin.ConsentsLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.ConsentsLive.Index
  alias Lockspire.Web.Live.Admin.ConsentsLive.Show
  alias Phoenix.Router

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, _client} =
      Repository.register_client(%Client{
        client_id: "consent-ui-client",
        client_secret_hash: "sha256:consent-ui:hash",
        client_type: :confidential,
        name: "Consent UI Client",
        redirect_uris: ["https://consent-ui.example.com/callback"],
        allowed_scopes: ["openid", "email"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    {:ok, grant} =
      Repository.grant_consent(%ConsentGrant{
        account_id: "account-consent-ui",
        client_id: "consent-ui-client",
        scopes: ["openid", "email"],
        granted_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{grant: grant}
  end

  test "router exposes admin consent routes" do
    routes = Router.routes(Lockspire.Web.Router)

    assert Enum.any?(routes, &live_route?(&1, "/admin/consents", Index))
    assert Enum.any?(routes, &live_route?(&1, "/admin/consents/:id", Show))
  end

  test "consent index renders support grant investigation filters and rows without secrets" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(
               %{
                 "account" => "account-consent-ui",
                 "client" => "consent-ui-client",
                 "status" => "active"
               },
               "/lockspire/admin/consents?account=account-consent-ui&client=consent-ui-client&status=active",
               socket
             )

    html = rendered_to_string(Index.render(socket.assigns))

    assert html =~ "Support"
    assert html =~ "Consent grant investigation"
    assert html =~ "Selected account: account-consent-ui"
    assert html =~ "Selected client: consent-ui-client"
    assert html =~ "Selected status: active"
    assert html =~ "Filter consent grants"
    assert html =~ "Review stored grant"
    assert html =~ "lockspire-admin-resource-list__item"
    assert html =~ "lockspire-admin-long-value"
    assert html =~ "Consent UI Client"
    assert html =~ "Scopes"
    assert html =~ "openid, email"
    assert html =~ "Keys"
    assert html =~ "Overview"
    assert html =~ "DCR"
    refute html =~ "sha256:consent-ui:hash"
    refute html =~ "client_secret"
    refute html =~ "refresh_token"
    refute html =~ "user_code"
    refute html =~ "verifier"
  end

  test "consent detail renders support-grade detail and guarded revoke action", %{grant: grant} do
    assert {:ok, socket} =
             Show.mount(%{"id" => Integer.to_string(grant.id)}, %{}, socket_for(:show))

    assert {:noreply, socket} =
             Show.handle_params(
               %{"id" => Integer.to_string(grant.id)},
               "/lockspire/admin/consents/#{grant.id}",
               socket
             )

    html = rendered_to_string(Show.render(socket.assigns))

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_describedby_targets_exist(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_has_link(html, "/lockspire/admin/consents")
    HtmlAssertions.assert_no_text(html, ["account-consent-ui", "sha256:consent-ui:hash"])

    assert html =~ "Support"
    assert html =~ "Stored grant decision"
    assert html =~ "Durable consent truth"
    assert html =~ "Durable grant identity and current state"
    assert html =~ "Scope context"
    assert html =~ "Review stored grant"
    assert html =~ "Revoke consent grant"
    assert html =~ "lockspire-admin-entity-header"
    assert html =~ "lockspire-admin-pane"
    assert html =~ ~s(phx-submit="revoke_consent")
    assert html =~ "remembered grant will no longer"
    assert html =~ "future remembered-consent reuse"
    assert html =~ "openid, email"
    assert html =~ "lockspire-admin-long-value"
    refute html =~ "account-consent-ui"
    refute html =~ "sha256:consent-ui:hash"

    assert {:noreply, socket} =
             Show.handle_event("revoke_consent", %{"revoke" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.consent.grant.status == :revoked

    assert {:noreply, socket} = Show.handle_event("revoke_consent", %{}, socket)

    assert socket.assigns.revoke_error =~ "Confirm the revoke action"
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
