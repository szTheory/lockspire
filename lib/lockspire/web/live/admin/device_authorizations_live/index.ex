defmodule Lockspire.Web.Live.Admin.DeviceAuthorizationsLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Redaction
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Device authorization requests",
       current_section: :device_authorizations,
       device_read_state: :loading,
       device_authorization_filter: :all,
       device_authorizations: []
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    device_authorization_filter = device_authorization_filter(params)
    {read_state, authorizations} = load_device_authorizations(device_authorization_filter)

    {:noreply,
     assign(socket,
       device_read_state: read_state,
       device_authorization_filter: device_authorization_filter,
       device_authorizations: authorizations
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero
        body="See which devices are waiting for the user to confirm sign-in and when each request expires."
      />

      <AdminComponents.pane
        title={device_authorization_list_title(@device_authorization_filter)}
      >
        <:actions :if={@device_authorization_filter == :pending}>
          <AdminComponents.admin_button href={device_authorizations_path(:all)}>
            View all device requests
          </AdminComponents.admin_button>
        </:actions>

        <AdminComponents.metric_grid
          :if={@device_read_state == :loaded and @device_authorization_filter == :all}
        >
          <AdminComponents.summary_stat
            value={count_waiting(@device_authorizations)}
            label="Pending"
          />
          <AdminComponents.summary_stat
            value={count_status(@device_authorizations, :approved)}
            label="Approved"
          />
          <AdminComponents.summary_stat
            value={count_status(@device_authorizations, :denied)}
            label="Denied"
          />
          <AdminComponents.summary_stat
            value={count_status(@device_authorizations, :expired)}
            label="Expired"
          />
          <AdminComponents.summary_stat
            value={count_status(@device_authorizations, :consumed)}
            label="Completed"
          />
        </AdminComponents.metric_grid>

        <p :if={@device_read_state == :loaded} role="status">
          {device_authorization_count_copy(
            length(@device_authorizations),
            @device_authorization_filter
          )}
        </p>

        <%= cond do %>
          <% @device_read_state == :loading -> %>
            <p role="status">Loading device requests…</p>
          <% @device_read_state == :unavailable -> %>
            <AdminComponents.empty_state
              title="Could not load device requests"
              body="The current results are unavailable."
            >
              <:actions>
                <AdminComponents.admin_button
                  href={device_authorizations_path(@device_authorization_filter)}
                >
                  Reload device authorization requests
                </AdminComponents.admin_button>
                <AdminComponents.admin_button href={admin_path("/overview")}>
                  Return to overview
                </AdminComponents.admin_button>
              </:actions>
            </AdminComponents.empty_state>
          <% @device_authorizations == [] -> %>
          <AdminComponents.empty_state
            title={empty_device_authorizations_title(@device_authorization_filter)}
            body={empty_device_authorizations_body(@device_authorization_filter)}
          >
            <:actions>
              <AdminComponents.admin_button
                :if={@device_authorization_filter == :pending}
                href={device_authorizations_path(:all)}
              >
                View all device requests
              </AdminComponents.admin_button>
              <AdminComponents.admin_button
                :if={@device_authorization_filter == :all}
                href={admin_path("/overview")}
              >
                Return to overview
              </AdminComponents.admin_button>
            </:actions>
          </AdminComponents.empty_state>
          <% true -> %>
          <AdminComponents.resource_list>
            <%= for auth <- @device_authorizations do %>
              <AdminComponents.dense_resource_row
                title={device_authorization_title(auth)}
                subtitle={device_authorization_pressure(auth)}
              >
                <:meta>
                  <span>Request ID <AdminComponents.long_value value={safe_identifier(auth.id)} kind={:id} /></span>
                  <span>Client ID <AdminComponents.long_value value={safe_identifier(auth.client_id)} kind={:id} /></span>
                  <span>Account <AdminComponents.long_value value={redacted_subject_identifier(auth.subject_id)} kind={:id} /></span>
                  <span>Request reference <AdminComponents.long_value value={redacted_authorization_handle(auth)} kind={:id} /></span>
                  <span>Expires <AdminComponents.long_value value={formatted_timestamp(auth.expires_at)} kind={:timestamp} /></span>
                  <span>App check interval {poll_interval_label(auth.effective_poll_interval_seconds)}</span>
                  <span :if={next_poll_context(auth)}>
                    App may check again <AdminComponents.long_value value={next_poll_context(auth)} kind={:timestamp} />
                  </span>
                  <span>Last status change <AdminComponents.long_value value={device_activity_context(auth)} kind={:timestamp} /></span>
                </:meta>
                <:status>
                  <AdminComponents.status_badge
                    status={device_authorization_badge_status(auth.status)}
                    domain={:device_authorization}
                  />
                </:status>
                <:actions>
                  <AdminComponents.admin_button
                    :if={client_detail_path_available?(auth)}
                    href={client_detail_path(auth.client_id)}
                  >
                    View app details
                  </AdminComponents.admin_button>
                </:actions>
              </AdminComponents.dense_resource_row>
            <% end %>
          </AdminComponents.resource_list>
        <% end %>
      </AdminComponents.pane>
    </AdminLayoutLive.shell>
    """
  end

  # Filtering runs inside the rescue so a malformed row shows the read as
  # unavailable instead of crashing the page.
  defp load_device_authorizations(filter) do
    case Admin.list_device_authorizations() do
      {:ok, auths} when is_list(auths) ->
        {:loaded, auths |> filter_device_authorizations(filter) |> Enum.map(&displayed_status/1)}

      _other ->
        {:unavailable, []}
    end
  rescue
    _error -> {:unavailable, []}
  end

  defp count_status(auths, status), do: Enum.count(auths, &(&1.status == status))

  defp device_authorization_title(%{status: :pending}), do: "Waiting for user confirmation"
  defp device_authorization_title(%{status: :approved}), do: "Approved by the user"
  defp device_authorization_title(%{status: :denied}), do: "Denied by the user"
  defp device_authorization_title(%{status: :expired}), do: "Expired before completion"
  defp device_authorization_title(%{status: :consumed}), do: "Completed"
  defp device_authorization_title(_auth), do: "Device request"

  defp device_authorization_badge_status(:consumed), do: :completed
  defp device_authorization_badge_status(status), do: status

  defp device_authorization_filter(%{"status" => "pending"}), do: :pending
  defp device_authorization_filter(_params), do: :all

  defp filter_device_authorizations(authorizations, :pending) do
    now = DateTime.utc_now()
    Enum.filter(authorizations, &waiting?(&1, now))
  end

  defp filter_device_authorizations(authorizations, :all), do: authorizations

  # Matches the overview and the pending filter: a request past its expiry is no
  # longer waiting, even before its status is swept to expired.
  defp count_waiting(auths) do
    now = DateTime.utc_now()
    Enum.count(auths, &waiting?(&1, now))
  end

  defp waiting?(%{status: :pending, expires_at: %DateTime{} = expires_at}, now),
    do: DateTime.compare(expires_at, now) == :gt

  defp waiting?(_auth, _now), do: false

  # A pending request past its expiry is shown as expired, even before the
  # sweeper updates its stored status.
  defp displayed_status(%{status: :pending} = auth) do
    if waiting?(auth, DateTime.utc_now()), do: auth, else: %{auth | status: :expired}
  end

  defp displayed_status(auth), do: auth

  defp device_authorization_count_copy(0, :all), do: "Showing no device requests"
  defp device_authorization_count_copy(1, :all), do: "Showing 1 device request"

  defp device_authorization_count_copy(count, :all),
    do: "Showing #{count} device requests"

  defp device_authorization_count_copy(0, :pending),
    do: "0 device requests awaiting user approval"

  defp device_authorization_count_copy(1, :pending),
    do: "1 device request awaiting user approval"

  defp device_authorization_count_copy(count, :pending),
    do: "#{count} device requests awaiting user approval"

  defp device_authorization_list_title(:all), do: "All requests"
  defp device_authorization_list_title(:pending), do: "Waiting for a user"

  defp empty_device_authorizations_title(:all),
    do: "No device authorization requests recorded"

  defp empty_device_authorizations_title(:pending),
    do: "No requests waiting for a user"

  defp empty_device_authorizations_body(:all),
    do: "There are no device requests to review."

  defp empty_device_authorizations_body(:pending),
    do: "Other request statuses are available in the full history."

  defp device_authorization_pressure(%{status: :pending}),
    do: "The user still needs to confirm this request."

  defp device_authorization_pressure(%{status: :approved}),
    do: "The user approved this request. The app has not collected the result yet."

  defp device_authorization_pressure(%{status: :denied}),
    do: "The user denied this request."

  defp device_authorization_pressure(%{status: :expired}),
    do: "This request expired before it was completed."

  defp device_authorization_pressure(%{status: :consumed}),
    do: "The app received the result after the user approved it."

  defp device_authorization_pressure(_auth),
    do: "Review this device request."

  defp safe_identifier(nil), do: "Not recorded"
  defp safe_identifier(value) when is_binary(value), do: value
  defp safe_identifier(value) when is_integer(value), do: Integer.to_string(value)
  defp safe_identifier(value), do: to_string(value)

  defp redacted_subject_identifier(nil), do: "Not recorded"
  defp redacted_subject_identifier(value), do: Redaction.handle(:account, value)

  defp redacted_authorization_handle(%{verification_handle: handle})
       when is_binary(handle) and handle != "" do
    Redaction.handle(:device_authorization, handle)
  end

  defp redacted_authorization_handle(%{id: id}) when not is_nil(id) do
    Redaction.handle(:device_authorization, id)
  end

  defp redacted_authorization_handle(_auth), do: "Not recorded"

  defp poll_interval_label(nil), do: "Not recorded"
  defp poll_interval_label(1), do: "1 second"
  defp poll_interval_label(seconds) when is_integer(seconds), do: "#{seconds} seconds"
  defp poll_interval_label(value), do: to_string(value)

  defp next_poll_context(%{status: status, next_poll_allowed_at: next_poll_allowed_at})
       when status in [:pending, :approved] and not is_nil(next_poll_allowed_at) do
    formatted_timestamp(next_poll_allowed_at)
  end

  defp next_poll_context(_auth), do: nil

  defp device_activity_context(%{status: :approved, approved_at: approved_at}),
    do: formatted_timestamp(approved_at)

  defp device_activity_context(%{status: :denied, denied_at: denied_at}),
    do: formatted_timestamp(denied_at)

  defp device_activity_context(%{status: :expired, expired_at: expired_at}),
    do: formatted_timestamp(expired_at)

  defp device_activity_context(%{status: :consumed, consumed_at: consumed_at}),
    do: formatted_timestamp(consumed_at)

  defp device_activity_context(_auth), do: "Not recorded"

  defp formatted_timestamp(nil), do: "Not recorded"

  defp formatted_timestamp(%DateTime{} = value),
    do: value

  defp formatted_timestamp(value), do: to_string(value)

  defp client_detail_path_available?(%{client_id: client_id})
       when is_binary(client_id) and byte_size(client_id) > 0 and byte_size(client_id) <= 64,
       do: true

  defp client_detail_path_available?(_auth), do: false

  defp client_detail_path(client_id),
    do: admin_path("/clients/" <> URI.encode(client_id, &URI.char_unreserved?/1))

  defp device_authorizations_path(:pending),
    do: admin_path("/device_authorizations?status=pending")

  defp device_authorizations_path(_filter), do: admin_path("/device_authorizations")

  defp admin_path(path), do: Lockspire.mount_path() <> "/admin" <> path
end
