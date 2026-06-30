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
    routes = Phoenix.Router.routes(Lockspire.Web.Router)
    assert Enum.any?(routes, &live_route?(&1, "/admin/device_authorizations", Index))
  end

  test "device authorizations index renders pressure rows without code material", %{
    authorizations: authorizations
  } do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/device_authorizations")
    page_html = page_markup(html)
    [pending, approved, denied, _expired, consumed] = authorizations

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

    assert page_html =~ "Operate"
    assert page_html =~ "Device authorization queue"
    assert page_html =~ "Review device authorizations"
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
    assert page_html =~ "Pending device authorization"
    assert page_html =~ "Approved device authorization"
    assert page_html =~ "Denied device authorization"
    assert page_html =~ "Expired device authorization"
    assert page_html =~ "Completed device authorization"
    assert page_html =~ "Approved, waiting"

    assert page_html =~
             "Waiting for the user to finish verification before expiry."

    assert page_html =~
             "Approved, waiting for token polling to consume the authorization."

    assert page_html =~
             "Denied before completion; preserve the durable handle for support follow-up."

    assert page_html =~
             "Expired before completion; no device authorization action is exposed from this page."

    assert page_html =~
             "Consumed by the token flow; use the record as read-only support truth."

    assert page_html =~ "Client"
    assert page_html =~ "Subject"
    assert page_html =~ "Handle"
    assert page_html =~ "Expires"
    assert page_html =~ "Poll interval"
    assert page_html =~ "Next poll"
    assert page_html =~ "Last activity"
    assert page_html =~ "5 seconds"
    assert page_html =~ "10 seconds"
    assert page_html =~ "Not recorded"

    assert page_html =~ Redaction.handle(:client, pending.client_id)
    assert page_html =~ Redaction.handle(:client, approved.client_id)
    assert page_html =~ Redaction.handle(:client, denied.client_id)
    assert page_html =~ Redaction.handle(:account, approved.subject_id)
    assert page_html =~ Redaction.handle(:account, denied.subject_id)
    assert page_html =~ Redaction.handle(:device_authorization, pending.verification_handle)
    assert page_html =~ Redaction.handle(:device_authorization, consumed.verification_handle)

    refute page_html =~ "client-with-a-very-long-safe-fixture-value"
    refute page_html =~ "account-with-a-very-long-safe-fixture-value"
    refute page_html =~ "<table"
    refute page_html =~ "lockspire-admin-table-wrap"
    refute page_html =~ "phx-click"
    refute page_html =~ "phx-submit"

    refute_unsupported_queue_controls(page_html)
  end

  test "device authorization empty state names operator review without controls" do
    html =
      %{
        current_section: :device_authorizations,
        page_title: "Device Authorizations",
        device_authorizations: [],
        __changed__: %{}
      }
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert html =~ "No device authorizations waiting for review"
    assert html =~ "There are no device authorization records waiting for operator review."
    refute html =~ "phx-click"
    refute html =~ "phx-submit"
    HtmlAssertions.assert_no_interactive_controls(html, text: unsupported_queue_control_text())
  end

  test "phase 125 device authorization proof keeps queue review redaction-safe and read-only", %{
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

    assert page_html =~ "Review device authorizations"
    assert page_html =~ "Pending device authorization"
    assert page_html =~ "Approved device authorization"
    assert page_html =~ "Denied device authorization"
    assert page_html =~ "Expired device authorization"
    assert page_html =~ "Completed device authorization"
    assert page_html =~ "Approved, waiting"
    assert page_html =~ "Waiting for the user to finish verification before expiry."

    assert page_html =~
             "Denied before completion; preserve the durable handle for support follow-up."

    assert page_html =~
             "Expired before completion; no device authorization action is exposed from this page."

    assert page_html =~ "Consumed by the token flow; use the record as read-only support truth."
    assert page_html =~ "Not recorded"
    assert page_html =~ "lockspire-admin-long-value"
    assert page_html =~ Redaction.handle(:client, pending.client_id)
    assert page_html =~ Redaction.handle(:client, approved.client_id)
    assert page_html =~ Redaction.handle(:client, denied.client_id)
    assert page_html =~ Redaction.handle(:device_authorization, expired.verification_handle)
    assert page_html =~ Redaction.handle(:device_authorization, consumed.verification_handle)
    refute page_html =~ "client-with-a-very-long-safe-fixture-value"
    refute page_html =~ "account-with-a-very-long-safe-fixture-value"
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

  defp page_markup(html), do: Regex.replace(~r/<style>.*?<\/style>/s, html, "")
end
