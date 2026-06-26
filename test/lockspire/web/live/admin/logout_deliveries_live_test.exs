defmodule Lockspire.Web.Live.Admin.LogoutDeliveriesLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Web.AdminProof.HtmlAssertions
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
    page_html = page_markup(html)

    HtmlAssertions.assert_no_duplicate_ids(page_html)
    HtmlAssertions.assert_describedby_targets_exist(page_html)
    HtmlAssertions.assert_no_generic_cta_text(page_html)

    HtmlAssertions.assert_no_text(page_html, [
      "authorization_code",
      "refresh_token",
      "access_token",
      "private_key"
    ])

    HtmlAssertions.assert_no_interactive_controls(page_html,
      text: unsupported_worker_control_text()
    )

    assert page_html =~ "Operate"
    assert page_html =~ "Logout propagation queue"
    assert page_html =~ "Review logout deliveries"
    assert page_html =~ "Waiting"
    assert page_html =~ "Retrying"
    assert page_html =~ "Failed"
    assert page_html =~ "Discarded"
    assert page_html =~ "Completed"
    assert summary_stat?(page_html, "Waiting", 1)
    assert summary_stat?(page_html, "Retrying", 1)
    assert summary_stat?(page_html, "Failed", 1)
    assert page_html =~ "lockspire-admin-pane"
    assert page_html =~ "lockspire-admin-resource-list"
    assert page_html =~ "lockspire-admin-dense-resource-row"
    assert page_html =~ "lockspire-admin-long-value"
    assert page_html =~ "test-delivery-123"
    assert page_html =~ "test-delivery-attempted"
    assert page_html =~ "test-delivery-retryable"
    refute page_html =~ "<table"
    refute page_html =~ "lockspire-admin-table-wrap"
    refute page_html =~ "phx-click"
    refute page_html =~ "phx-submit"
    refute_unsupported_worker_controls(page_html)
    assert page_html =~ "Pending"
  end

  test "logout deliveries empty state names operator review without controls" do
    html =
      %{
        current_section: :logouts,
        page_title: "Logout deliveries",
        deliveries: [],
        delivery_metrics: %{waiting: 0, retrying: 0, failed: 0, discarded: 0, completed: 0},
        __changed__: %{}
      }
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert html =~ "No logout deliveries waiting for review"
    assert html =~ "There are no logout propagation records waiting for operator review."
    refute html =~ "phx-click"
    refute html =~ "phx-submit"
    HtmlAssertions.assert_no_interactive_controls(html, text: unsupported_worker_control_text())
    refute_unsupported_worker_controls(html)
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

  defp refute_unsupported_worker_controls(html) do
    refute Regex.match?(
             ~r/\b(Retry now|Discard|Logout now|Worker control|Requeue|Approve|Deny)\b/i,
             html
           )
  end

  defp unsupported_worker_control_text do
    ["Retry now", "Discard", "Logout now", "Worker control", "Requeue", "Approve", "Deny"]
  end

  defp page_markup(html), do: Regex.replace(~r/<style>.*?<\/style>/s, html, "")
end
