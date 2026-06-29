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
       device_authorizations: load_device_authorizations()
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, device_authorizations: load_device_authorizations())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero
        eyebrow="Operate"
        title="Device authorization queue"
        body="Triage pending, approved, denied, expired, and completed device-flow state without exposing device or user code material."
      />

      <AdminComponents.pane
        title="Review device authorizations"
        subtitle="Read-only queue rows expose client, status, subject, expiration, and durable non-secret identifiers."
      >
        <AdminComponents.metric_grid>
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

        <%= if @device_authorizations == [] do %>
          <AdminComponents.empty_state
            title="No device authorizations waiting for review"
            body="There are no device authorization records waiting for operator review."
          />
        <% else %>
          <AdminComponents.resource_list>
            <%= for auth <- @device_authorizations do %>
              <AdminComponents.dense_resource_row
                title={device_authorization_title(auth)}
                subtitle={device_authorization_pressure(auth)}
              >
                <:meta>
                  <span>Client <AdminComponents.long_value value={redacted_handle(:client, auth.client_id)} kind={:id} /></span>
                  <span>Subject <AdminComponents.long_value value={redacted_handle(:account, auth.subject_id)} kind={:id} /></span>
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
      {:ok, auths} -> auths
      {:error, _reason} -> []
    end
  end

  defp count_status(auths, status), do: Enum.count(auths, &(&1.status == status))

  defp device_authorization_title(%{status: :pending}), do: "Pending device authorization"
  defp device_authorization_title(%{status: :approved}), do: "Approved device authorization"
  defp device_authorization_title(%{status: :denied}), do: "Denied device authorization"
  defp device_authorization_title(%{status: :expired}), do: "Expired device authorization"
  defp device_authorization_title(%{status: :consumed}), do: "Completed device authorization"
  defp device_authorization_title(_auth), do: "Device authorization"

  defp device_authorization_pressure(%{status: :pending}),
    do: "Waiting for the user to finish verification before expiry."

  defp device_authorization_pressure(%{status: :approved}),
    do: "Approved, waiting for token polling to consume the authorization."

  defp device_authorization_pressure(%{status: :denied}),
    do: "Denied before completion; preserve the durable handle for support follow-up."

  defp device_authorization_pressure(%{status: :expired}),
    do: "Expired before completion; no device authorization action is exposed from this page."

  defp device_authorization_pressure(%{status: :consumed}),
    do: "Consumed by the token flow; use the record as read-only support truth."

  defp device_authorization_pressure(_auth), do: "Review durable device authorization state."

  defp redacted_handle(_type, nil), do: "Not recorded"
  defp redacted_handle(type, value), do: Redaction.handle(type, value)

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
end
