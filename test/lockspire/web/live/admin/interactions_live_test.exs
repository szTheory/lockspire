defmodule Lockspire.Web.Live.Admin.InteractionsLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Domain.Interaction
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.Live.Admin.InteractionsLive.Index
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

    now = DateTime.utc_now()
    expires_at = DateTime.add(now, 600, :second)

    {:ok, interaction} =
      Repository.put_interaction(%Interaction{
        interaction_id: "test-interaction-123",
        client_id: "test-client",
        status: :pending_login,
        return_to: "http://example.com/return",
        expires_at: expires_at,
        inserted_at: now,
        updated_at: now
      })

    %{interaction: interaction}
  end

  test "router exposes admin interactions routes" do
    routes = Router.routes(Lockspire.Web.Router)

    assert Enum.any?(routes, &live_route?(&1, "/admin/interactions", Index))
  end

  test "interactions index renders interactions list" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(
               %{},
               "/lockspire/admin/interactions",
               socket
             )

    html = rendered_to_string(Index.render(socket.assigns))

    assert html =~ "Active interactions"
    assert html =~ "test-interaction-123"
    assert html =~ "test-client"
    assert html =~ "pending_login"
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
