defmodule Lockspire.Web.Live.Admin.InteractionsLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok, interactions} = Repository.list_interactions()

    {:ok,
     assign(socket,
       page_title: "Active interactions",
       current_section: :interactions,
       interactions: interactions
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
        title="Active interactions"
        subtitle="View and manage current authorization interactions."
      >
        <%= if @interactions == [] do %>
          <AdminComponents.empty_state
            title="No active interactions"
            body="There are no interactions at this time."
          />
        <% else %>
          <table class="lockspire-admin-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Client</th>
                <th>Status</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              <%= for interaction <- @interactions do %>
                <tr>
                  <td>{interaction.interaction_id}</td>
                  <td>{interaction.client_id}</td>
                  <td><AdminComponents.status_badge status={interaction.status} /></td>
                  <td>{interaction.inserted_at}</td>
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
