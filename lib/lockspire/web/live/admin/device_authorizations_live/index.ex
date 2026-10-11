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
       page_title: "Device Authorizations",
       current_section: :device_authorizations,
       device_read_state: :loading,
       device_authorizations: []
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {read_state, authorizations} = load_device_authorizations()

    {:noreply,
     assign(socket,
       device_read_state: read_state,
       device_authorizations: authorizations
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero
        eyebrow="Operate"
        title="Device authorization queue"
        body="See each device authorization's recorded status, client, subject, expiry, and polling details without showing device or user codes."
      />

      <AdminComponents.pane
        title="Recorded device authorizations"
        subtitle="Read-only records show saved request status, client, subject, expiry, and polling context."
      >
        <AdminComponents.metric_grid :if={@device_read_state == :loaded}>
          <AdminComponents.summary_stat
            value={count_status(@device_authorizations, :pending)}
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
          {device_authorization_count_copy(length(@device_authorizations))}
        </p>

        <%= cond do %>
          <% @device_read_state == :loading -> %>
            <p role="status">Loading device authorizations…</p>
          <% @device_read_state == :unavailable -> %>
            <AdminComponents.empty_state
              title="Could not load device authorizations"
              body="Lockspire could not read device authorization records, so the current results are unavailable."
            >
              <:actions>
                <AdminComponents.admin_button href={device_authorizations_path()}>
                  Try loading device authorizations again
                </AdminComponents.admin_button>
                <AdminComponents.admin_button href={admin_path("/overview")}>
                  Return to overview
                </AdminComponents.admin_button>
              </:actions>
            </AdminComponents.empty_state>
          <% @device_authorizations == [] -> %>
          <AdminComponents.empty_state
            title="No device authorization records"
            body="No device authorization records are currently stored. Return to the overview to choose another investigation."
          >
            <:actions>
              <AdminComponents.admin_button href={admin_path("/overview")}>
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
                  <span>Client <AdminComponents.long_value value={safe_identifier(auth.client_id)} kind={:id} /></span>
                  <span>Subject <AdminComponents.long_value value={redacted_subject_identifier(auth.subject_id)} kind={:id} /></span>
                  <span>Handle <AdminComponents.long_value value={redacted_authorization_handle(auth)} kind={:id} /></span>
                  <span>Expires <AdminComponents.long_value value={formatted_timestamp(auth.expires_at)} kind={:timestamp} /></span>
                  <span>Poll interval {poll_interval_label(auth.effective_poll_interval_seconds)}</span>
                  <span :if={next_poll_context(auth)}>
                    Next poll <AdminComponents.long_value value={next_poll_context(auth)} kind={:timestamp} />
                  </span>
                  <span>Last activity <AdminComponents.long_value value={device_activity_context(auth)} kind={:timestamp} /></span>
                </:meta>
                <:status>
                  <AdminComponents.status_badge status={auth.status} domain={:device_authorization} />
                </:status>
                <:actions>
                  <AdminComponents.admin_button
                    :if={client_detail_path_available?(auth)}
                    href={client_detail_path(auth.client_id)}
                  >
                    View client details
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

  defp load_device_authorizations do
    case Admin.list_device_authorizations() do
      {:ok, auths} when is_list(auths) -> {:loaded, auths}
      _other -> {:unavailable, []}
    end
  rescue
    _error -> {:unavailable, []}
  end

  defp count_status(auths, status), do: Enum.count(auths, &(&1.status == status))

  defp device_authorization_title(%{status: :pending}), do: "Pending device authorization"
  defp device_authorization_title(%{status: :approved}), do: "Approved device authorization"
  defp device_authorization_title(%{status: :denied}), do: "Denied device authorization"
  defp device_authorization_title(%{status: :expired}), do: "Expired device authorization"
  defp device_authorization_title(%{status: :consumed}), do: "Completed device authorization"
  defp device_authorization_title(_auth), do: "Device authorization"

  defp device_authorization_count_copy(0), do: "0 device authorizations recorded"
  defp device_authorization_count_copy(1), do: "1 device authorization recorded"

  defp device_authorization_count_copy(count),
    do: "#{count} device authorizations recorded"

  defp device_authorization_pressure(%{status: :pending}),
    do: "Waiting for the user to finish verification before expiry."

  defp device_authorization_pressure(%{status: :approved}),
    do: "Approved, waiting for token polling to consume the authorization."

  defp device_authorization_pressure(%{status: :denied}),
    do:
      "The request was denied before completion. Its recorded details remain available for follow-up."

  defp device_authorization_pressure(%{status: :expired}),
    do: "The request expired before completion. Its recorded details remain available for review."

  defp device_authorization_pressure(%{status: :consumed}),
    do:
      "Token polling consumed this authorization. Its recorded status and timing remain available for review."

  defp device_authorization_pressure(_auth),
    do: "Review the recorded device authorization status."

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
       when status in [:pending, :approved] do
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
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")

  defp formatted_timestamp(value), do: to_string(value)

  defp client_detail_path_available?(%{client_id: client_id})
       when is_binary(client_id) and byte_size(client_id) <= 64,
       do: true

  defp client_detail_path_available?(_auth), do: false

  defp client_detail_path(client_id),
    do: admin_path("/clients/" <> URI.encode(client_id, &URI.char_unreserved?/1))

  defp device_authorizations_path, do: admin_path("/device_authorizations")
  defp admin_path(path), do: Lockspire.mount_path() <> "/admin" <> path
end
