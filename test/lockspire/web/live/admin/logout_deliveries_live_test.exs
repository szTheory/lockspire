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

    for {delivery_id, client_id, status, attempt_count} <- [
          {"test-delivery-123", "test-client", "pending", 0},
          {"test-delivery-attempted", "test-client-attempted", "attempted", 1},
          {"test-delivery-retryable", "test-client-retryable", "retryable", 2}
        ] do
      Ecto.Adapters.SQL.query!(
        Lockspire.TestRepo,
        "INSERT INTO lockspire_logout_deliveries (delivery_id, " <>
          "logout_event_id, client_id, channel, target_uri, status, " <>
          "attempt_count, session_required, inserted_at, updated_at) " <>
          "VALUES ($1, $2, $3, 'backchannel', " <>
          "'http://example.com/logout', $4, $5, false, $6, $6)",
        [delivery_id, event_id, client_id, status, attempt_count, now]
      )
    end

    :ok
  end

  test "router exposes admin logout deliveries routes" do
    routes = Router.routes(Lockspire.Web.Router)

    assert Enum.any?(routes, &live_route?(&1, "/admin/logouts", Index))
  end

  test "logout deliveries index renders operate queue buckets and resource rows" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(
               %{},
               "/lockspire/admin/logouts",
               socket
             )

    html = rendered_to_string(Index.render(socket.assigns))

    assert html =~ "Operate"
    assert html =~ "Logout propagation queue"
    assert html =~ "Review logout deliveries"
    assert html =~ "Waiting"
    assert html =~ "Retrying"
    assert html =~ "Failed"
    assert html =~ "Discarded"
    assert html =~ "Completed"
    assert summary_stat?(html, "Waiting", 1)
    assert summary_stat?(html, "Retrying", 1)
    assert summary_stat?(html, "Failed", 1)
    assert html =~ "lockspire-admin-resource-list__item"
    assert html =~ "lockspire-admin-long-value"
    assert html =~ "test-delivery-123"
    assert html =~ "test-delivery-attempted"
    assert html =~ "test-delivery-retryable"
    refute html =~ "<table"
    refute html =~ "phx-click"
    refute html =~ "phx-submit"
    assert html =~ "Pending"
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end

  defp summary_stat?(html, label, value) do
    Regex.match?(
      ~r/lockspire-admin-summary-value[^>]*>\s*#{value}\s*<.*?#{Regex.escape(label)}/s,
      html
    )
  end
end
