defmodule Lockspire.Web.Live.Admin.DeviceAuthorizationsLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Redaction
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.DeviceAuthorizationsLive.Index

  @endpoint Lockspire.Web.Endpoint

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "")

    on_exit(fn ->
      Application.put_env(:lockspire, :mount_path, "/lockspire")
    end)

    Application.put_env(:lockspire, Lockspire.Web.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      render_errors: [view: Lockspire.Web.ErrorView, accepts: ~w(html json)],
      live_view: [signing_salt: "lockspire_salt"]
    )

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Lockspire.Web.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    authorizations = [
      device_authorization_fixture(:pending, now),
      device_authorization_fixture(:approved, now),
      device_authorization_fixture(:denied, now),
      device_authorization_fixture(:expired, now),
      device_authorization_fixture(:consumed, now)
    ]

    %{authorizations: authorizations}
  end

  test "router exposes admin device authorizations" do
    routes = Lockspire.Web.AdminRouteTestHelpers.admin_routes()
    assert Enum.any?(routes, &live_route?(&1, "/admin/device_authorizations", Index))
  end

  test "device authorizations index renders pressure rows without code material", %{
    authorizations: authorizations
  } do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/device_authorizations")
    page_html = page_markup(html)
    [pending, approved, denied, _expired, consumed] = authorizations

    HtmlAssertions.assert_page_contract!(html)

    HtmlAssertions.assert_no_duplicate_ids(page_html)
    HtmlAssertions.assert_describedby_targets_exist(page_html)
    HtmlAssertions.assert_no_generic_cta_text(page_html)

    HtmlAssertions.assert_no_text(page_html, [
      "raw-device-code-pending",
      "raw-user-code-pending",
      "device-code-hash-pending",
      "user-code-hash-pending",
      "verification-handle-pending",
      "verification-handle-approved",
      "verification-handle-denied",
      "verification-handle-expired",
      "verification-handle-consumed",
      "device_code",
      "user_code",
      "device_code_hash",
      "user_code_hash",
      "verification_handle",
      "authorization_code",
      "access_token",
      "refresh_token",
      "id_token",
      "token material",
      "pkce",
      "raw params",
      "SQL row",
      "database failure",
      "backend storage"
    ])

    refute_protocol_field_context(page_html, "state")
    refute_protocol_field_context(page_html, "nonce")

    HtmlAssertions.assert_no_interactive_controls(page_html,
      text: unsupported_queue_control_text()
    )

    assert page_html =~ "Activity"
    assert page_html =~ "Device authorization requests"
    assert page_html =~ "All requests"

    assert page_html =~
             "See which devices are waiting for the user to confirm sign-in and when each request expires."

    refute page_html =~ "Device authorization queue"
    refute page_html =~ "polling details"
    refute page_html =~ "polling context"
    assert page_html =~ "Pending"
    assert page_html =~ "Approved"
    assert page_html =~ "Denied"
    assert page_html =~ "Expired"
    assert page_html =~ "Completed"
    assert summary_stat?(page_html, "Pending", 1)
    assert summary_stat?(page_html, "Approved", 1)
    assert summary_stat?(page_html, "Denied", 1)
    assert summary_stat?(page_html, "Expired", 1)
    assert summary_stat?(page_html, "Completed", 1)
    assert page_html =~ "lockspire-admin-pane"
    assert page_html =~ "lockspire-admin-resource-list"
    assert page_html =~ "lockspire-admin-dense-resource-row"
    assert page_html =~ "lockspire-admin-long-value"
    assert page_html =~ "Waiting for user confirmation"
    assert page_html =~ "Approved by the user"
    assert page_html =~ "Denied by the user"
    assert page_html =~ "Expired before completion"
    assert page_html =~ "Completed"
    refute rendered_text(page_html) =~ "Consumed"
    assert page_html =~ "The user still needs to confirm this request."

    assert page_html =~
             "The user approved this request. The app has not collected the result yet."

    assert page_html =~ "The user denied this request."
    assert page_html =~ "This request expired before it was completed."
    assert page_html =~ "The app received the result after the user approved it."

    assert page_html =~ "Client"
    assert page_html =~ "Account"
    assert page_html =~ "Request reference"
    assert page_html =~ "Expires"
    assert page_html =~ "App check interval"
    assert page_html =~ "App may check again"
    assert page_html =~ "Last status change"
    assert page_html =~ "5 seconds"
    assert page_html =~ "10 seconds"
    assert page_html =~ "Not recorded"
    assert rendered_text(page_html) =~ "Showing 5 device requests"

    assert rendered_text(page_html) =~ pending.client_id
    assert rendered_text(page_html) =~ approved.client_id
    assert rendered_text(page_html) =~ denied.client_id
    assert rendered_text(page_html) =~ Redaction.handle(:account, approved.subject_id)
    assert rendered_text(page_html) =~ Redaction.handle(:account, denied.subject_id)
    refute rendered_text(page_html) =~ approved.subject_id
    refute rendered_text(page_html) =~ denied.subject_id
    assert rendered_text(page_html) =~ Integer.to_string(pending.id)
    assert page_html =~ Redaction.handle(:device_authorization, pending.verification_handle)
    assert page_html =~ Redaction.handle(:device_authorization, consumed.verification_handle)

    refute rendered_text(page_html) =~ pending.verification_handle
    refute page_html =~ "<table"
    refute page_html =~ "lockspire-admin-table-wrap"
    refute page_html =~ "phx-click"
    refute page_html =~ "phx-submit"
    HtmlAssertions.assert_has_link(page_html, "/admin/clients/#{pending.client_id}")

    refute_unsupported_queue_controls(page_html)
  end

  test "pending filter shows only requests waiting for the user and links to full history", %{
    authorizations: [pending, approved, denied, expired, consumed]
  } do
    assert {:ok, _view, html} =
             live(conn_for_admin(), "/admin/device_authorizations?status=pending")

    page_html = page_markup(html)
    text = rendered_text(page_html)

    assert text =~ "1 device request awaiting user approval"
    assert text =~ pending.client_id

    for authorization <- [approved, denied, expired, consumed] do
      refute text =~ authorization.client_id
    end

    assert page_html =~ ~s(href="/admin/device_authorizations")
    assert page_html =~ "View all device requests"
    assert page_html =~ "Waiting for a user"
    refute page_html =~ ~s(<div class="lockspire-admin-metric-grid")

    HtmlAssertions.assert_no_interactive_controls(page_html,
      text: unsupported_queue_control_text()
    )

    refute_unsupported_queue_controls(page_html)

    assert {:ok, _view, all_html} = live(conn_for_admin(), "/admin/device_authorizations")
    all_text = rendered_text(page_markup(all_html))

    for authorization <- [pending, approved, denied, expired, consumed] do
      assert all_text =~ authorization.client_id
    end

    assert all_text =~ "Showing 5 device requests"
  end

  test "unknown device status filters safely show the full history", %{
    authorizations: authorizations
  } do
    assert {:ok, _view, html} =
             live(conn_for_admin(), "/admin/device_authorizations?status=unknown")

    page_html = page_markup(html)
    text = rendered_text(page_html)

    for authorization <- authorizations do
      assert text =~ authorization.client_id
    end

    assert text =~ "Showing 5 device requests"
    assert summary_stat?(page_html, "Pending", 1)
  end

  test "empty pending-device view keeps its count and link to full history" do
    page_html = render_queue(:loaded, [], :pending)

    assert rendered_text(page_html) =~ "0 device requests awaiting user approval"
    assert page_html =~ "No requests waiting for a user"
    assert page_html =~ "View all device requests"
    assert page_html =~ ~s(href="/admin/device_authorizations")
    refute page_html =~ "lockspire-admin-summary-value"
  end

  test "device authorization empty state names the absent records and next route" do
    html = render_queue(:loaded, [])

    assert html =~ "No device authorization requests"
    assert html =~ "There are no device requests to review."
    assert html =~ "Return to overview"
    assert html =~ ~s(href="/admin/overview")
    refute html =~ "operator"
    assert rendered_text(html) =~ "Showing no device requests"
    refute html =~ "phx-click"
    refute html =~ "phx-submit"
    HtmlAssertions.assert_no_interactive_controls(html, text: unsupported_queue_control_text())
  end

  test "device queue loading and failed reads remain distinct from successful empty" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))
    assert socket.assigns.page_title == "Device authorization requests"

    loading_html = socket.assigns |> Index.render() |> rendered_to_string() |> page_markup()
    loading_text = rendered_text(loading_html)

    assert loading_text =~ "Loading device requests"
    refute loading_text =~ "No device authorization requests"
    refute Regex.match?(~r/summary-value\">\s*\d+/, loading_html)

    with_failed_read(fn ->
      assert {:noreply, failed_socket} =
               Index.handle_params(%{}, "/admin/device_authorizations", socket)

      failed_html =
        failed_socket.assigns
        |> Index.render()
        |> rendered_to_string()
        |> page_markup()

      failed_text = rendered_text(failed_html)
      assert failed_text =~ "Could not load device requests"
      assert failed_text =~ "The current results are unavailable"
      refute failed_text =~ "No count or empty result"
      assert failed_text =~ "Reload device authorization requests"
      refute failed_text =~ "No device authorization requests"
      refute failed_text =~ "Showing no device requests"
      HtmlAssertions.assert_has_link(failed_html, "/admin/device_authorizations")

      HtmlAssertions.assert_no_interactive_controls(failed_html,
        text: unsupported_queue_control_text()
      )

      assert {:noreply, filtered_failed_socket} =
               Index.handle_params(
                 %{"status" => "pending"},
                 "/admin/device_authorizations?status=pending",
                 socket
               )

      filtered_failed_html =
        filtered_failed_socket.assigns
        |> Index.render()
        |> rendered_to_string()
        |> page_markup()

      assert filtered_failed_socket.assigns.device_read_state == :unavailable
      assert filtered_failed_html =~ "Could not load device requests"
      refute filtered_failed_html =~ "0 device requests waiting for a user"
      refute filtered_failed_html =~ "No device authorization requests"
      assert filtered_failed_html =~ ~s(href="/admin/device_authorizations?status=pending")
    end)
  end

  test "device queue count copy is accurate for zero, one, and many records", %{
    authorizations: authorizations
  } do
    [pending | _rest] = authorizations

    for {records, expected} <- [
          {[], "Showing no device requests"},
          {[pending], "Showing 1 device request"},
          {authorizations, "Showing 5 device requests"}
        ] do
      html = render_queue(:loaded, records)
      assert rendered_text(html) =~ expected
    end
  end

  test "device rows omit the next-check line when no next check is recorded", %{
    authorizations: authorizations
  } do
    [pending | _rest] = authorizations

    refute render_queue(:loaded, [%{pending | next_poll_allowed_at: nil}]) =~
             "App may check again"

    assert render_queue(:loaded, [pending]) =~ "App may check again"
  end

  test "device authorization review keeps queue evidence redaction-safe and read-only", %{
    authorizations: authorizations
  } do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(%{}, "/admin/device_authorizations", socket)

    page_html =
      socket.assigns
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    [pending, approved, denied, expired, consumed] = authorizations

    assert_operate_route_guardrails(page_html, [
      "raw-device-code-pending",
      "raw-user-code-pending",
      "device-code-hash-pending",
      "user-code-hash-pending",
      "device-code-hash-approved",
      "user-code-hash-approved",
      "device-code-hash-denied",
      "user-code-hash-denied",
      "device-code-hash-expired",
      "user-code-hash-expired",
      "device-code-hash-consumed",
      "user-code-hash-consumed",
      "verification-handle-pending",
      "verification-handle-approved",
      "verification-handle-denied",
      "verification-handle-expired",
      "verification-handle-consumed",
      "device_code",
      "user_code",
      "authorization_code",
      "access_token",
      "refresh_token",
      "raw params",
      "SQL row",
      "database failure",
      "backend storage"
    ])

    assert page_html =~ "All requests"
    assert page_html =~ "Waiting for user confirmation"
    assert page_html =~ "Approved by the user"
    assert page_html =~ "Denied by the user"
    assert page_html =~ "Expired before completion"
    assert page_html =~ "Completed"
    assert page_html =~ "The app received the result after the user approved it."

    assert page_html =~ "Not recorded"
    assert page_html =~ "lockspire-admin-long-value"
    assert rendered_text(page_html) =~ pending.client_id
    assert rendered_text(page_html) =~ approved.client_id
    assert rendered_text(page_html) =~ denied.client_id
    assert page_html =~ Redaction.handle(:device_authorization, expired.verification_handle)
    assert page_html =~ Redaction.handle(:device_authorization, consumed.verification_handle)
    assert rendered_text(page_html) =~ Redaction.handle(:account, approved.subject_id)
    assert rendered_text(page_html) =~ Redaction.handle(:account, denied.subject_id)
    refute rendered_text(page_html) =~ approved.subject_id
    refute rendered_text(page_html) =~ denied.subject_id
    refute rendered_text(page_html) =~ pending.verification_handle
    refute_protocol_field_context(page_html, "state")
    refute_protocol_field_context(page_html, "nonce")
    refute_unsupported_queue_controls(page_html)
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end

  defp device_authorization_fixture(status, now) do
    attrs = device_authorization_attrs(status, now)

    {:ok, authorization} =
      attrs
      |> then(&struct(DeviceAuthorization, &1))
      |> Repository.put_device_authorization()

    authorization
  end

  defp device_authorization_attrs(:pending, now) do
    %{
      device_code: "raw-device-code-pending",
      user_code: "raw-user-code-pending",
      device_code_hash: "device-code-hash-pending",
      user_code_hash: "user-code-hash-pending",
      verification_handle: "verification-handle-pending",
      client_id: "client-with-a-very-long-safe-fixture-value-pending",
      status: :pending,
      subject_id: nil,
      effective_poll_interval_seconds: 5,
      next_poll_allowed_at: DateTime.add(now, 15, :second),
      expires_at: DateTime.add(now, 600, :second)
    }
  end

  defp device_authorization_attrs(:approved, now) do
    %{
      device_code_hash: "device-code-hash-approved",
      user_code_hash: "user-code-hash-approved",
      verification_handle: "verification-handle-approved",
      client_id: "client-with-a-very-long-safe-fixture-value-approved",
      status: :approved,
      subject_id: "account-with-a-very-long-safe-fixture-value-approved",
      approved_at: DateTime.add(now, -120, :second),
      effective_poll_interval_seconds: 10,
      next_poll_allowed_at: DateTime.add(now, 20, :second),
      expires_at: DateTime.add(now, 480, :second)
    }
  end

  defp device_authorization_attrs(:denied, now) do
    %{
      device_code_hash: "device-code-hash-denied",
      user_code_hash: "user-code-hash-denied",
      verification_handle: "verification-handle-denied",
      client_id: "client-denied-safe-fixture",
      status: :denied,
      subject_id: "account-with-a-very-long-safe-fixture-value-denied",
      denied_at: DateTime.add(now, -90, :second),
      effective_poll_interval_seconds: 5,
      next_poll_allowed_at: DateTime.add(now, -60, :second),
      expires_at: DateTime.add(now, 300, :second)
    }
  end

  defp device_authorization_attrs(:expired, now) do
    %{
      device_code_hash: "device-code-hash-expired",
      user_code_hash: "user-code-hash-expired",
      verification_handle: "verification-handle-expired",
      client_id: "client-expired-safe-fixture",
      status: :expired,
      subject_id: nil,
      expired_at: DateTime.add(now, -60, :second),
      effective_poll_interval_seconds: 5,
      next_poll_allowed_at: DateTime.add(now, -120, :second),
      expires_at: DateTime.add(now, -60, :second)
    }
  end

  defp device_authorization_attrs(:consumed, now) do
    %{
      device_code_hash: "device-code-hash-consumed",
      user_code_hash: "user-code-hash-consumed",
      verification_handle: "verification-handle-consumed",
      client_id: "client-consumed-safe-fixture",
      status: :consumed,
      subject_id: "account-consumed-safe-fixture",
      approved_at: DateTime.add(now, -180, :second),
      consumed_at: DateTime.add(now, -30, :second),
      effective_poll_interval_seconds: 5,
      next_poll_allowed_at: DateTime.add(now, -15, :second),
      expires_at: DateTime.add(now, 300, :second)
    }
  end

  defp summary_stat?(html, label, value) do
    Regex.match?(
      ~r/<span class="lockspire-admin-summary-value">\s*#{value}\s*<\/span>\s*<span class="lockspire-admin-summary-label">\s*#{Regex.escape(label)}\s*<\/span>/,
      html
    )
  end

  defp refute_protocol_field_context(html, field_name) do
    refute Regex.match?(
             ~r/(?:\b#{Regex.escape(field_name)}=|"#{Regex.escape(field_name)}"\s*:|\b#{Regex.escape(field_name)}:)/i,
             html
           )
  end

  defp refute_unsupported_queue_controls(html) do
    refute Regex.match?(
             ~r/\b(Retry|Discard|Approve|Deny|Logout now|Worker control|Requeue|Pause|Resume)\b/i,
             html
           )
  end

  defp unsupported_queue_control_text do
    [
      "Retry",
      "Discard",
      "Approve",
      "Deny",
      "Logout now",
      "Worker control",
      "Requeue",
      "Pause",
      "Resume"
    ]
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

    HtmlAssertions.assert_no_interactive_controls(html, text: unsupported_queue_control_text())

    refute html =~ "<table"
    refute html =~ "lockspire-admin-table-wrap"

    html
  end

  defp render_queue(state, authorizations, filter \\ :all) do
    %{
      current_section: :device_authorizations,
      page_title: "Device authorization requests",
      device_read_state: state,
      device_authorization_filter: filter,
      device_authorizations: authorizations,
      __changed__: %{}
    }
    |> Index.render()
    |> rendered_to_string()
    |> page_markup()
  end

  defp with_failed_read(fun) do
    previous_repo = Application.get_env(:lockspire, :repo)

    try do
      Application.put_env(
        :lockspire,
        :repo,
        Lockspire.Web.Live.Admin.DeviceAuthorizationsLiveTest.ReadRepo
      )

      fun.()
    after
      Application.put_env(:lockspire, :repo, previous_repo)
    end
  end

  defp rendered_text(html) do
    html
    |> String.replace(~r/<style\b[^>]*>.*?<\/style>/s, " ")
    |> String.replace(~r/<script\b[^>]*>.*?<\/script>/s, " ")
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
  end

  defp page_markup(html), do: Regex.replace(~r/<style>.*?<\/style>/s, html, "")
end

defmodule Lockspire.Web.Live.Admin.DeviceAuthorizationsLiveTest.ReadRepo do
  @moduledoc false

  def all(_query, _options \\ []), do: raise("synthetic device authorization read failure")
end
