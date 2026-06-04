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

      <AdminComponents.section_card
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
            title="No device authorizations"
            body="There are no device flow requests waiting for operator review."
          />
        <% else %>
          <AdminComponents.resource_list>
            <%= for auth <- @device_authorizations do %>
              <AdminComponents.resource_item
                title="Device authorization"
                subtitle="Review device authorizations"
              >
                <:meta>
                  <span>Client <AdminComponents.long_value value={redacted_handle(:client, auth.client_id)} kind={:id} /></span>
                  <span>Subject <AdminComponents.long_value value={redacted_handle(:account, auth.subject_id)} kind={:id} /></span>
                  <span>Handle <AdminComponents.long_value value={redacted_handle(:device_authorization, auth.id || auth.verification_handle)} kind={:id} /></span>
                  <span>Expires <AdminComponents.long_value value={formatted_timestamp(auth.expires_at)} kind={:timestamp} /></span>
                </:meta>
                <:status>
                  <AdminComponents.status_badge status={auth.status} />
                </:status>
              </AdminComponents.resource_item>
            <% end %>
          </AdminComponents.resource_list>
        <% end %>
      </AdminComponents.section_card>
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

  defp redacted_handle(_type, nil), do: "Not recorded"
  defp redacted_handle(type, value), do: Redaction.handle(type, value)

  defp formatted_timestamp(nil), do: "Not recorded"

  defp formatted_timestamp(%DateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")

  defp formatted_timestamp(value), do: to_string(value)
end
