defmodule Lockspire.Web.Live.Admin.LogoutDeliveriesLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Web.Live.Admin.LogoutDeliveriesLive.Index
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

    # persist_logout_propagation expects an event and creates deliveries for clients
    # but we can just use Repository.put_logout_delivery directly if available, or simulate it.
    # Actually, Repository doesn't expose put_logout_delivery publicly, it's private.
    # Wait, how does one create a logout delivery for test?
    # I can use Lockspire.Storage.Ecto.Repository to insert a logout event and deliveries.
    # Let's check `persist_logout_propagation/1` in `Repository` or create the records
    # via Ecto directly since we are in `TestRepo`.

    # Wait, we can just insert via Repo for the test data.
    result =
      Ecto.Adapters.SQL.query!(
        Lockspire.TestRepo,
        "INSERT INTO lockspire_logout_events (event_id, sid, initiated_by, " <>
          "inserted_at, updated_at) VALUES ('test-logout-event-123', " <>
          "'test-sid', 'rp_initiated_logout', $1, $1) RETURNING id",
        [now]
      )

    event_id = result.rows |> hd() |> hd()

    Ecto.Adapters.SQL.query!(
      Lockspire.TestRepo,
      "INSERT INTO lockspire_logout_deliveries (delivery_id, " <>
        "logout_event_id, client_id, channel, target_uri, status, " <>
        "attempt_count, session_required, inserted_at, updated_at) " <>
        "VALUES ('test-delivery-123', $1, 'test-client', 'backchannel', " <>
        "'http://example.com/logout', 'pending', 0, false, $2, $2)",
      [event_id, now]
    )

    :ok
  end

  test "router exposes admin logout deliveries routes" do
    routes = Router.routes(Lockspire.Web.Router)

    assert Enum.any?(routes, &live_route?(&1, "/admin/logouts", Index))
  end

  test "logout deliveries index renders deliveries list" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(
               %{},
               "/lockspire/admin/logouts",
               socket
             )

    html = rendered_to_string(Index.render(socket.assigns))

    assert html =~ "Logout deliveries"
    assert html =~ "test-delivery-123"
    assert html =~ "test-client"
    assert html =~ "Pending"
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
