defmodule Lockspire.Web.Live.Admin.TokensLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.Live.Admin.TokensLive.Index
  alias Lockspire.Web.Live.Admin.TokensLive.Show
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
        client_id: "token-ui-client",
        client_secret_hash: "sha256:token-ui:hash",
        client_type: :confidential,
        name: "Token UI Client",
        redirect_uris: ["https://token-ui.example.com/callback"],
        allowed_scopes: ["openid", "offline_access"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    now = DateTime.utc_now()

    {:ok, refresh_token} =
      Repository.store_token(%Token{
        token_hash: "token-ui-refresh-hash",
        token_type: :refresh_token,
        family_id: "family-ui-123",
        generation: 0,
        client_id: "token-ui-client",
        account_id: "account-token-ui",
        scopes: ["offline_access"],
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      })

    {:ok, _access_token} =
      Repository.store_token(%Token{
        token_hash: "token-ui-access-hash",
        token_type: :access_token,
        family_id: "family-ui-123",
        generation: 1,
        parent_token_id: refresh_token.id,
        client_id: "token-ui-client",
        account_id: "account-token-ui",
        scopes: ["openid"],
        issued_at: DateTime.add(now, 5, :second),
        expires_at: DateTime.add(now, 3600, :second)
      })

    %{refresh_token: refresh_token}
  end

  test "router exposes admin token routes" do
    routes = Router.routes(Lockspire.Web.Router)

    assert Enum.any?(routes, &live_route?(&1, "/admin/tokens", Index))
    assert Enum.any?(routes, &live_route?(&1, "/admin/tokens/:id", Show))
  end

  test "token index filters durable lifecycle state without exposing raw token hashes" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(
               %{"account" => "account-token-ui", "status" => "active"},
               "/lockspire/admin/tokens?account=account-token-ui&status=active",
               socket
             )

    html = rendered_to_string(Index.render(socket.assigns))

    assert html =~ "Support"
    assert html =~ "Token investigation"
    assert html =~ "Selected account: account-token-ui"
    assert html =~ "Selected status: active"
    assert html =~ "Filter tokens"
    assert html =~ "Review token"
    assert html =~ "lockspire-admin-resource-list__item"
    assert html =~ "lockspire-admin-long-value"
    assert html =~ "Token UI Client"
    assert html =~ "Account"
    assert html =~ "Family"
    assert html =~ "Expires"
    assert html =~ "Keys"
    assert html =~ "Overview"
    assert html =~ "DCR"
    refute html =~ "token-ui-refresh-hash"
    refute html =~ "client_secret"
    refute html =~ "verifier"
    refute html =~ "user_code"
  end

  test "token detail shows lineage and guarded single-token and family revoke flows", %{
    refresh_token: refresh_token
  } do
    assert {:ok, socket} =
             Show.mount(%{"id" => Integer.to_string(refresh_token.id)}, %{}, socket_for(:show))

    assert {:noreply, socket} =
             Show.handle_params(
               %{"id" => Integer.to_string(refresh_token.id)},
               "/lockspire/admin/tokens/#{refresh_token.id}",
               socket
             )

    html = rendered_to_string(Show.render(socket.assigns))

    assert html =~ "Support"
    assert html =~ "Token health decision"
    assert html =~ "Opaque tokens stay opaque here"
    assert html =~ "Token identity and current state"
    assert html =~ "Refresh family lineage"
    assert html =~ "Corrective actions"
    assert html =~ "lockspire-admin-entity-header"
    assert html =~ "lockspire-admin-pane"
    assert html =~ "lockspire-admin-dense-resource-row"
    assert html =~ "lockspire-admin-description-list"
    assert html =~ "lockspire-admin-long-value"
    assert html =~ "Client"
    assert html =~ "Token UI Client"
    assert html =~ "account_"
    assert html =~ "family_"
    assert html =~ "Session ID"
    assert html =~ "Not recorded"
    assert html =~ "Parent token"
    assert html =~ "lockspire-admin-confirmation-panel"
    assert html =~ ~s(phx-submit="revoke_token")
    assert html =~ ~s(phx-submit="revoke_family")
    assert html =~ "Revoke token"
    assert html =~ "Revoke token family"
    assert html =~ "family-wide action"
    assert html =~ "family-wide refresh-token invalidation"
    assert html =~ "revokes every active token"
    refute html =~ "token-ui-refresh-hash"
    refute html =~ "family-ui-123"
    refute html =~ "account-token-ui"
    refute html =~ "Token ##{refresh_token.id}"

    assert {:noreply, socket} =
             Show.handle_event("revoke_token", %{"revoke" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.token_detail.token.revoked_at
    assert socket.assigns.token_detail.token.family_handle =~ "family_"

    assert {:noreply, socket} =
             Show.handle_event("revoke_family", %{"family" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.family_notice =~ "Revoked"

    assert {:noreply, socket} = Show.handle_event("revoke_family", %{}, socket)

    assert socket.assigns.family_error =~ "Confirm the family-wide action"
    assert is_nil(socket.assigns.family_notice)
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
