defmodule Lockspire.Web.Live.Admin.DeviceAuthorizationsLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
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
      <AdminComponents.section_card
        title="Device Authorizations"
        subtitle="Operator view of active and pending device flow requests."
      >
        <%= if @device_authorizations == [] do %>
          <AdminComponents.empty_state
            title="No device authorizations"
            body="There are currently no device flow requests."
          />
        <% else %>
          <ul class="lockspire-admin-list">
            <%= for auth <- @device_authorizations do %>
              <li>
                <span>Client: {auth.client_id}</span>
                <AdminComponents.status_badge status={auth.status} />
                <span>Expires: {auth.expires_at}</span>
              </li>
            <% end %>
          </ul>
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
end
