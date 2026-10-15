defmodule Lockspire.Web.Live.Admin.LogoutDeliveriesLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.LogoutDeliveriesLive.Index

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
        delivery_id: "test-delivery-enqueued",
        client_id: "test-client-enqueued",
        channel: "backchannel",
        target_uri: "https://rp.test.invalid/logout/enqueued",
        status: "enqueued",
        attempt_count: 0,
        timestamp: DateTime.add(now, -1, :second)
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

    %{long_endpoint: long_endpoint, event_id: event_id}
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

  test "router exposes admin app sign-out notices routes" do
    routes = Lockspire.Web.AdminRouteTestHelpers.admin_routes()

    assert Enum.any?(routes, &live_route?(&1, "/admin/logouts", Index))
  end

  test "app sign-out notices index renders operate queue buckets and resource rows", %{
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

    HtmlAssertions.assert_no_text(page_html, [
      "Logout propagation queue",
      "Back-channel delivery uses a durable queue",
      "front-channel logout is best-effort browser work",
      "relying-party session termination",
      "Support note:",
      "Failure class",
      "worker action is exposed"
    ])

    HtmlAssertions.assert_no_interactive_controls(page_html,
      text: unsupported_worker_control_text()
    )

    assert page_html =~ "App sign-out notices"
    assert page_html =~ "Delivery records"

    assert page_html =~
             "See which apps Lockspire notified during sign-out and what response it recorded."

    assert page_html =~ "Queued"
    assert page_html =~ "Attempted"
    assert page_html =~ "Retryable"
    assert page_html =~ "Discarded"
    assert page_html =~ "Skipped"
    assert page_html =~ "Endpoint accepted"
    assert page_html =~ "Browser page rendered"
    assert summary_stat?(page_html, "Queued", 2)
    assert summary_stat?(page_html, "Attempted", 1)
    assert summary_stat?(page_html, "Retryable", 1)
    assert summary_stat?(page_html, "Discarded", 1)
    assert summary_stat?(page_html, "Skipped", 1)
    assert summary_stat?(page_html, "Endpoint accepted", 1)
    assert summary_stat?(page_html, "Browser page rendered", 1)
    assert page_html =~ "8 app sign-out notices recorded"
    assert page_html =~ "lockspire-admin-pane"
    assert page_html =~ "lockspire-admin-resource-list"
    assert page_html =~ "lockspire-admin-dense-resource-row"
    assert page_html =~ "lockspire-admin-long-value"
    assert page_html =~ "Delivery"
    assert page_html =~ "Client ID"
    assert page_html =~ "Sign-out method"
    assert page_html =~ "Endpoint"
    assert page_html =~ "Attempts"
    assert page_html =~ "Last activity"
    assert page_html =~ "Client ID"

    for delivery_id <- [
          "test-delivery-pending",
          "test-delivery-enqueued",
          "test-delivery-attempted",
          "test-delivery-retryable",
          "test-delivery-discarded",
          "test-delivery-skipped",
          "test-delivery-rendered",
          "test-delivery-succeeded"
        ] do
      assert page_html =~ delivery_id
    end

    assert page_html =~ "test-client-pending"
    assert page_html =~ ~s(href="/lockspire/admin/clients/test-client-pending")
    assert page_html =~ "Review app settings"

    assert page_html =~ long_endpoint
    assert page_html =~ "Pending"
    assert page_html =~ "Attempted"
    assert page_html =~ "Retryable"
    assert page_html =~ "Discarded"
    assert page_html =~ "Skipped"
    assert page_html =~ "Rendered"
    assert page_html =~ "Accepted by app"

    assert page_html =~ "Lockspire is preparing the request; it has not been sent yet."

    assert page_html =~
             "The request is ready to send; no response is recorded yet."

    assert page_html =~
             "Lockspire began sending the request; no response is recorded."

    assert page_html =~ "The request failed and may be tried again automatically."
    assert page_html =~ "HTTP 503"
    assert page_html =~ "Request failed: timeout"
    assert page_html =~ "The app rejected the request, so Lockspire stopped trying."
    assert page_html =~ "No server or browser sign-out request was recorded for this app."

    assert page_html =~
             "The app accepted the server request. This does not confirm the person was signed out."

    assert page_html =~
             "Lockspire showed a sign-out page in the browser. This does not confirm the app signed the person out."

    refute page_html =~ "<table"
    refute page_html =~ "lockspire-admin-table-wrap"
    refute page_html =~ "phx-click"
    refute page_html =~ "phx-submit"
    refute_unsupported_worker_controls(page_html)
  end

  test "needs-review filter shows only retryable and discarded deliveries" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(
               %{"status" => "needs_review"},
               "/lockspire/admin/logouts?status=needs_review",
               socket
             )

    assert socket.assigns.delivery_filter == :needs_review

    assert Enum.map(socket.assigns.deliveries, & &1.delivery_id) |> Enum.sort() ==
             ["test-delivery-discarded", "test-delivery-retryable"]

    page_html =
      socket.assigns
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    text = rendered_text(page_html)
    assert text =~ "2 app sign-out notices need review"
    assert text =~ "test-delivery-retryable"
    assert text =~ "test-delivery-discarded"

    for excluded_id <- [
          "test-delivery-pending",
          "test-delivery-enqueued",
          "test-delivery-attempted",
          "test-delivery-skipped",
          "test-delivery-rendered",
          "test-delivery-succeeded"
        ] do
      refute text =~ excluded_id
    end

    assert page_html =~ "Delivery records"
    assert page_html =~ "View all app sign-out notices"
    assert page_html =~ ~s(href="/lockspire/admin/logouts")
    refute summary_stat?(page_html, "Queued", 2)
    refute page_html =~ "Skipped"

    HtmlAssertions.assert_no_interactive_controls(page_html,
      text: unsupported_worker_control_text()
    )

    refute_unsupported_worker_controls(page_html)
  end

  test "unknown logout status filters safely show the full history" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(
               %{"status" => "unknown"},
               "/lockspire/admin/logouts?status=unknown",
               socket
             )

    page_html =
      socket.assigns
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert socket.assigns.delivery_filter == :all
    assert rendered_text(page_html) =~ "8 app sign-out notices recorded"

    for delivery_id <- [
          "test-delivery-pending",
          "test-delivery-enqueued",
          "test-delivery-attempted",
          "test-delivery-retryable",
          "test-delivery-discarded",
          "test-delivery-skipped",
          "test-delivery-rendered",
          "test-delivery-succeeded"
        ] do
      assert page_html =~ delivery_id
    end

    assert summary_stat?(page_html, "Queued", 2)
    refute page_html =~ "View all app sign-out notices"
  end

  test "empty needs-review view keeps its count and link to full history" do
    page_html =
      %{
        current_section: :logouts,
        page_title: "App sign-out notices",
        delivery_read_state: :loaded,
        delivery_filter: :needs_review,
        deliveries: [],
        delivery_metrics: nil,
        __changed__: %{}
      }
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert rendered_text(page_html) =~ "0 app sign-out notices need review"
    assert page_html =~ "No app sign-out notices need review"
    assert page_html =~ "View all app sign-out notices"
    assert page_html =~ ~s(href="/lockspire/admin/logouts")
    refute page_html =~ "lockspire-admin-summary-value"
  end

  test "app sign-out notices empty state names operator review without controls" do
    html =
      %{
        current_section: :logouts,
        page_title: "App sign-out notices",
        delivery_read_state: :loaded,
        delivery_filter: :all,
        deliveries: [],
        delivery_metrics: %{
          queued: 0,
          attempted: 0,
          retryable: 0,
          discarded: 0,
          skipped: 0,
          accepted: 0,
          rendered: 0
        },
        delivery_count: 0,
        __changed__: %{}
      }
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert html =~ "No app sign-out notices recorded"
    assert html =~ "No app sign-out notices are currently recorded."
    assert html =~ "Return to overview"
    assert html =~ ~s(href="/lockspire/admin/overview")
    assert html =~ "0 app sign-out notices recorded"
    refute html =~ "phx-click"
    refute html =~ "phx-submit"
    HtmlAssertions.assert_no_interactive_controls(html, text: unsupported_worker_control_text())
    refute_unsupported_worker_controls(html)
  end

  test "logout delivery page shows loading before reading the queue" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert socket.assigns.delivery_read_state == :loading

    page_html =
      socket.assigns
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert page_html =~ "App sign-out notices"
    assert page_html =~ "Loading app sign-out notices…"
    refute page_html =~ "Queued"
    refute page_html =~ "No app sign-out notices recorded"
    refute page_html =~ "app sign-out notices recorded"
  end

  test "failed logout reads show unavailable and a same-route retry" do
    with_failed_read(fn ->
      assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

      assert {:noreply, socket} = Index.handle_params(%{}, "/lockspire/admin/logouts", socket)

      page_html =
        socket.assigns
        |> Index.render()
        |> rendered_to_string()
        |> page_markup()

      assert socket.assigns.delivery_read_state == :unavailable
      assert page_html =~ "Could not load app sign-out notices"
      assert page_html =~ "Lockspire could not read app sign-out notice records"
      assert page_html =~ "the current results are unavailable"
      refute page_html =~ "No count or empty result"
      assert page_html =~ "Reload app sign-out notices"
      assert page_html =~ ~s(href="/lockspire/admin/logouts")
      refute page_html =~ "Queued"
      refute page_html =~ "No app sign-out notices waiting for review"
      refute page_html =~ "0 app sign-out notices recorded"

      assert {:noreply, filtered_socket} =
               Index.handle_params(
                 %{"status" => "needs_review"},
                 "/lockspire/admin/logouts?status=needs_review",
                 socket
               )

      filtered_html =
        filtered_socket.assigns
        |> Index.render()
        |> rendered_to_string()
        |> page_markup()

      assert filtered_socket.assigns.delivery_read_state == :unavailable
      assert filtered_html =~ "Could not load app sign-out notices"
      refute filtered_html =~ "0 app sign-out notices needing review"
      refute filtered_html =~ "No app sign-out notices recorded"
      assert filtered_html =~ ~s(href="/lockspire/admin/logouts?status=needs_review")
    end)
  end

  test "successful empty logout read shows measured zero" do
    clear_deliveries()

    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))
    assert {:noreply, socket} = Index.handle_params(%{}, "/lockspire/admin/logouts", socket)

    page_html =
      socket.assigns
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert socket.assigns.delivery_read_state == :loaded
    assert page_html =~ "0 app sign-out notices recorded"
    assert summary_stat?(page_html, "Queued", 0)
    assert page_html =~ "No app sign-out notices recorded"
    assert page_html =~ "No app sign-out notices are currently recorded."
    refute page_html =~ "Could not load app sign-out notices"
  end

  test "one logout delivery uses singular count copy and the supported client pivot", %{
    event_id: event_id
  } do
    clear_deliveries()
    insert_delivery(event_id, "single-safe-delivery-id", "client-single")

    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))
    assert {:noreply, socket} = Index.handle_params(%{}, "/lockspire/admin/logouts", socket)

    page_html =
      socket.assigns
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert page_html =~ "1 app sign-out notice recorded"
    assert page_html =~ "single-safe-delivery-id"
    assert page_html =~ "client-single"
    assert page_html =~ ~s(href="/lockspire/admin/clients/client-single")
    refute page_html =~ "1 app sign-out notices recorded"
    refute_unsupported_worker_controls(page_html)
  end

  test "logout delivery review keeps incident evidence sanitized and read-only", %{
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

    assert page_html =~ "Delivery records"
    assert page_html =~ "Queued"
    assert page_html =~ "Attempted"
    assert page_html =~ "Retryable"
    assert page_html =~ "Discarded"
    assert page_html =~ "Skipped"
    assert page_html =~ "Endpoint accepted"
    assert page_html =~ "Browser page rendered"
    assert page_html =~ "Pending"
    assert page_html =~ "Attempted"
    assert page_html =~ "Retryable"
    assert page_html =~ "Skipped"
    assert page_html =~ "Rendered"
    assert page_html =~ "Accepted by app"
    assert page_html =~ "The request failed and may be tried again automatically."
    assert page_html =~ "HTTP 503"
    assert page_html =~ "Request failed: timeout"
    assert page_html =~ "The app rejected the request, so Lockspire stopped trying."

    assert page_html =~
             "The app accepted the server request. This does not confirm the person was signed out."

    assert page_html =~
             "Lockspire showed a sign-out page in the browser. This does not confirm the app signed the person out."

    assert page_html =~ "lockspire-admin-long-value"
    assert page_html =~ long_endpoint
    refute_unsupported_worker_controls(page_html)
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
  end

  defp rendered_text(html) do
    html
    |> String.replace(~r/<style\b[^>]*>.*?<\/style>/s, " ")
    |> String.replace(~r/<script\b[^>]*>.*?<\/script>/s, " ")
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
  end

  defp clear_deliveries do
    Ecto.Adapters.SQL.query!(Lockspire.TestRepo, "DELETE FROM lockspire_logout_deliveries", [])
  end

  defp insert_delivery(event_id, delivery_id, client_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Ecto.Adapters.SQL.query!(
      Lockspire.TestRepo,
      "INSERT INTO lockspire_logout_deliveries (delivery_id, logout_event_id, " <>
        "client_id, channel, target_uri, status, attempt_count, session_required, " <>
        "last_attempted_at, delivered_at, rendered_at, finalized_at, http_status, " <>
        "failure_reason, logout_token_jti, oban_job_id, inserted_at, updated_at) " <>
        "VALUES ($1, $2, $3, 'backchannel', 'https://rp.test.invalid/logout', " <>
        "'pending', 0, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, $4, $4)",
      [delivery_id, event_id, client_id, now]
    )
  end

  defp with_failed_read(fun) do
    previous_repo = Application.get_env(:lockspire, :repo)

    try do
      Application.put_env(
        :lockspire,
        :repo,
        Lockspire.Web.Live.Admin.LogoutDeliveriesLiveTest.FailingRepo
      )

      fun.()
    after
      Application.put_env(:lockspire, :repo, previous_repo)
    end
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

defmodule Lockspire.Web.Live.Admin.LogoutDeliveriesLiveTest.FailingRepo do
  @moduledoc false

  def all(_query, _options \\ []), do: raise("synthetic logout delivery read failure")
end
