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

    result =
      Ecto.Adapters.SQL.query!(
        Lockspire.TestRepo,
        "INSERT INTO lockspire_logout_events (event_id, sid, initiated_by, " <>
          "inserted_at, updated_at) VALUES ('test-logout-event-123', " <>
          "'test-sid', 'rp_initiated_logout', $1, $1) RETURNING id",
        [now]
      )

    event_id = result.rows |> hd() |> hd()

    long_endpoint =
      "https://rp.test.invalid/logout/backchannel/" <>
        "tenant-safe-wrap-proof/" <>
        "delivery-endpoint-with-an-intentionally-long-path-for-mobile-reflow"

    deliveries = [
      %{
        delivery_id: "test-delivery-pending",
        client_id: "test-client-pending",
        channel: "backchannel",
        target_uri: "https://rp.test.invalid/logout/pending",
        status: "pending",
        attempt_count: 0,
        timestamp: now
      },
      %{
        delivery_id: "test-delivery-attempted",
        client_id: "test-client-attempted",
        channel: "backchannel",
        target_uri: "https://rp.test.invalid/logout/attempted",
        status: "attempted",
        attempt_count: 1,
        last_attempted_at: DateTime.add(now, -90, :second),
        timestamp: DateTime.add(now, -1, :second)
      },
      %{
        delivery_id: "test-delivery-retryable",
        client_id: "test-client-retryable",
        channel: "backchannel",
        target_uri: long_endpoint,
        status: "retryable",
        attempt_count: 3,
        last_attempted_at: DateTime.add(now, -180, :second),
        http_status: 503,
        failure_reason:
          "request_failed:timeout raw response cookie endpoint secret SQL row worker internals",
        logout_token_jti: "logout_token_jti_secret_fixture",
        oban_job_id: 4_242_424,
        timestamp: DateTime.add(now, -2, :second)
      },
      %{
        delivery_id: "test-delivery-discarded",
        client_id: "test-client-discarded",
        channel: "backchannel",
        target_uri: "https://rp.test.invalid/logout/discarded",
        status: "discarded",
        attempt_count: 4,
        last_attempted_at: DateTime.add(now, -240, :second),
        finalized_at: DateTime.add(now, -220, :second),
        http_status: 400,
        failure_reason: "http_error:400 raw response",
        timestamp: DateTime.add(now, -3, :second)
      },
      %{
        delivery_id: "test-delivery-skipped",
        client_id: "test-client-skipped",
        channel: "frontchannel",
        target_uri: "https://rp.test.invalid/logout/skipped",
        status: "skipped",
        attempt_count: 0,
        finalized_at: DateTime.add(now, -300, :second),
        timestamp: DateTime.add(now, -4, :second)
      },
      %{
        delivery_id: "test-delivery-rendered",
        client_id: "test-client-rendered",
        channel: "frontchannel",
        target_uri: "https://rp.test.invalid/logout/rendered",
        status: "rendered",
        attempt_count: 0,
        rendered_at: DateTime.add(now, -360, :second),
        timestamp: DateTime.add(now, -5, :second)
      },
      %{
        delivery_id: "test-delivery-succeeded",
        client_id: "test-client-succeeded",
        channel: "backchannel",
        target_uri: "https://rp.test.invalid/logout/succeeded",
        status: "succeeded",
        attempt_count: 2,
        last_attempted_at: DateTime.add(now, -420, :second),
        delivered_at: DateTime.add(now, -400, :second),
        http_status: 200,
        timestamp: DateTime.add(now, -6, :second)
      }
    ]

    for delivery <- deliveries do
      delivery = Map.merge(default_delivery_fields(), delivery)

      Ecto.Adapters.SQL.query!(
        Lockspire.TestRepo,
        "INSERT INTO lockspire_logout_deliveries (delivery_id, " <>
          "logout_event_id, client_id, channel, target_uri, status, " <>
          "attempt_count, session_required, last_attempted_at, delivered_at, " <>
          "rendered_at, finalized_at, http_status, failure_reason, " <>
          "logout_token_jti, oban_job_id, inserted_at, updated_at) " <>
          "VALUES ($1, $2, $3, $4, $5, $6, $7, false, $8, $9, $10, " <>
          "$11, $12, $13, $14, $15, $16, $16)",
        [
          delivery.delivery_id,
          event_id,
          delivery.client_id,
          delivery.channel,
          delivery.target_uri,
          delivery.status,
          delivery.attempt_count,
          delivery.last_attempted_at,
          delivery.delivered_at,
          delivery.rendered_at,
          delivery.finalized_at,
          delivery.http_status,
          delivery.failure_reason,
          delivery.logout_token_jti,
          delivery.oban_job_id,
          delivery.timestamp
        ]
      )
    end

    %{long_endpoint: long_endpoint}
  end

  defp default_delivery_fields do
    %{
      last_attempted_at: nil,
      delivered_at: nil,
      rendered_at: nil,
      finalized_at: nil,
      http_status: nil,
      failure_reason: nil,
      logout_token_jti: nil,
      oban_job_id: nil
    }
  end

  test "router exposes admin logout deliveries routes" do
    routes = Router.routes(Lockspire.Web.Router)

    assert Enum.any?(routes, &live_route?(&1, "/admin/logouts", Index))
  end

  test "logout deliveries index renders operate queue buckets and resource rows", %{
    long_endpoint: long_endpoint
  } do
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
      "private_key",
      "logout_token_jti",
      "oban_job_id",
      "4_242_424",
      "4242424",
      "raw response",
      "cookie",
      "endpoint secret",
      "SQL row",
      "worker internals"
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
    assert summary_stat?(page_html, "Discarded", 2)
    assert summary_stat?(page_html, "Completed", 2)
    assert page_html =~ "lockspire-admin-pane"
    assert page_html =~ "lockspire-admin-resource-list"
    assert page_html =~ "lockspire-admin-dense-resource-row"
    assert page_html =~ "lockspire-admin-long-value"
    assert page_html =~ "Delivery"
    assert page_html =~ "Client"
    assert page_html =~ "Channel"
    assert page_html =~ "Endpoint"
    assert page_html =~ "Attempts"
    assert page_html =~ "Last activity"
    assert page_html =~ "Support note"

    for delivery_id <- [
          "test-delivery-pending",
          "test-delivery-attempted",
          "test-delivery-retryable",
          "test-delivery-discarded",
          "test-delivery-skipped",
          "test-delivery-rendered",
          "test-delivery-succeeded"
        ] do
      assert page_html =~ delivery_id
    end

    assert page_html =~ long_endpoint
    assert page_html =~ "Pending"
    assert page_html =~ "Attempted"
    assert page_html =~ "Retryable"
    assert page_html =~ "Discarded"
    assert page_html =~ "Skipped"
    assert page_html =~ "Rendered"
    assert page_html =~ "Succeeded"
    assert page_html =~ "Waiting for the protocol worker to attempt delivery."
    assert page_html =~ "Delivery has been attempted and remains under observation."
    assert page_html =~ "Retryable failure"
    assert page_html =~ "HTTP 503"
    assert page_html =~ "Failure class Request failed / timeout"
    assert page_html =~ "Terminal queue outcome"
    assert page_html =~ "Delivery work completed"
    refute page_html =~ "<table"
    refute page_html =~ "lockspire-admin-table-wrap"
    refute page_html =~ "phx-click"
    refute page_html =~ "phx-submit"
    refute_unsupported_worker_controls(page_html)
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

  test "phase 125 logout delivery proof keeps incident review sanitized and read-only", %{
    long_endpoint: long_endpoint
  } do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(%{}, "/lockspire/admin/logouts", socket)

    page_html =
      socket.assigns
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert_operate_route_guardrails(page_html, [
      "authorization_code",
      "refresh_token",
      "access_token",
      "private_key",
      "logout_token_jti",
      "logout_token_jti_secret_fixture",
      "oban_job_id",
      "4_242_424",
      "4242424",
      "raw response",
      "cookie",
      "endpoint secret",
      "SQL row",
      "worker internals"
    ])

    assert page_html =~ "Review logout deliveries"
    assert page_html =~ "Waiting"
    assert page_html =~ "Retrying"
    assert page_html =~ "Failed"
    assert page_html =~ "Discarded"
    assert page_html =~ "Completed"
    assert page_html =~ "Pending"
    assert page_html =~ "Attempted"
    assert page_html =~ "Retryable"
    assert page_html =~ "Skipped"
    assert page_html =~ "Rendered"
    assert page_html =~ "Succeeded"
    assert page_html =~ "Retryable failure"
    assert page_html =~ "HTTP 503"
    assert page_html =~ "Failure class Request failed / timeout"
    assert page_html =~ "Terminal queue outcome"
    assert page_html =~ "Delivery work completed"
    assert page_html =~ "lockspire-admin-long-value"
    assert page_html =~ long_endpoint
    refute_unsupported_worker_controls(page_html)
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

  defp assert_operate_route_guardrails(html, denied_values) do
    html
    |> HtmlAssertions.assert_no_duplicate_ids()
    |> HtmlAssertions.assert_describedby_targets_exist()
    |> HtmlAssertions.assert_aria_targets_exist("aria-labelledby")
    |> HtmlAssertions.assert_aria_targets_exist("aria-controls")
    |> HtmlAssertions.assert_links_have_hrefs()
    |> HtmlAssertions.assert_disabled_links_have_semantics()
    |> HtmlAssertions.assert_no_generic_cta_text()
    |> HtmlAssertions.assert_no_token_like_text()
    |> HtmlAssertions.assert_no_text(denied_values)

    HtmlAssertions.assert_no_interactive_controls(html, text: unsupported_worker_control_text())

    refute html =~ "<table"
    refute html =~ "lockspire-admin-table-wrap"

    html
  end

  defp page_markup(html), do: Regex.replace(~r/<style>.*?<\/style>/s, html, "")
end
