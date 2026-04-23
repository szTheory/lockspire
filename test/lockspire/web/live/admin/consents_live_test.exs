defmodule Lockspire.Web.Live.Admin.ConsentsLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Storage.Ecto.Repository
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

  test "consent index renders URL-driven filters and durable grant data" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(
               %{"account" => "account-consent-ui"},
               "/lockspire/admin/consents?account=account-consent-ui",
               socket
             )

    html = rendered_to_string(Index.render(socket.assigns))

    assert html =~ "Consent review"
    assert html =~ "Consent UI Client"
    assert html =~ "account-consent-ui"
    assert html =~ "Keys"
    refute html =~ "Overview"
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

    assert html =~ "Durable consent truth"
    assert html =~ "account-consent-ui"
    assert html =~ "Revoke consent"

    assert {:noreply, socket} =
             Show.handle_event("revoke_consent", %{"revoke" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.consent.grant.status == :revoked
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
