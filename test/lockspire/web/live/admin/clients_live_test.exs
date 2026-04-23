defmodule Lockspire.Web.Live.Admin.ClientsLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.Live.Admin.ClientsLive.Index
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

    {:ok, _alpha} =
      Repository.register_client(%Client{
        client_id: "alpha-client",
        client_secret_hash: "sha256:alpha:hash",
        client_type: :confidential,
        name: "Alpha Client",
        redirect_uris: ["https://alpha.example.com/callback"],
        allowed_scopes: ["email"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    {:ok, _beta} =
      Repository.register_client(%Client{
        client_id: "beta-client",
        client_type: :public,
        name: "Beta Client",
        redirect_uris: ["https://beta.example.com/callback"],
        allowed_scopes: ["profile"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    :ok
  end

  test "router exposes admin clients as the default operator entrypoint without an overview route" do
    routes = Router.routes(Lockspire.Web.Router)

    assert Enum.any?(routes, &live_route?(&1, "/admin", Index))
    assert Enum.any?(routes, &live_route?(&1, "/admin/clients", Index))
    refute Enum.any?(routes, &(&1.path == "/admin/overview"))
  end

  test "clients index renders durable client truth and URL-driven filters" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(%{"q" => "Alpha"}, "/lockspire/admin?q=Alpha", socket)

    html = rendered_to_string(Index.render(socket.assigns))

    assert html =~ "Client inventory"
    assert html =~ "Alpha Client"
    assert html =~ "Keys"
    refute html =~ "Beta Client"
    refute html =~ "Overview"
    assert html =~ "Register client"
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
