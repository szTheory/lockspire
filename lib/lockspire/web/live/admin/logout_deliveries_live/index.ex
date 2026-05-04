defmodule Lockspire.Web.Live.Admin.LogoutDeliveriesLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok, deliveries} = Repository.list_all_logout_deliveries()

    {:ok,
     assign(socket,
       page_title: "Logout deliveries",
       current_section: :logouts,
       deliveries: deliveries
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.section_card
        title="Logout deliveries"
        subtitle="View and manage backchannel logout propagation deliveries."
      >
        <%= if @deliveries == [] do %>
          <AdminComponents.empty_state
            title="No logout deliveries"
            body="There are no logout deliveries at this time."
          />
        <% else %>
          <table class="lockspire-admin-table">
            <thead>
              <tr>
                <th>Delivery ID</th>
                <th>Client</th>
                <th>Channel</th>
                <th>Status</th>
                <th>Attempts</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              <%= for delivery <- @deliveries do %>
                <tr>
                  <td>{delivery.delivery_id}</td>
                  <td>{delivery.client_id}</td>
                  <td>{delivery.channel}</td>
                  <td><AdminComponents.status_badge status={delivery.status} /></td>
                  <td>{delivery.attempt_count}</td>
                  <td>{delivery.inserted_at}</td>
                </tr>
              <% end %>
            </tbody>
          </table>
        <% end %>
      </AdminComponents.section_card>
    </AdminLayoutLive.shell>
    """
  end
end
