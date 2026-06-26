defmodule Lockspire.Web.Live.Admin.InteractionsLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Redaction
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
      <AdminComponents.page_hero
        eyebrow="Operate"
        title="Authorization interaction queue"
        body="Review authorization interaction state by status, client, subject, age, expiration, and safe review context."
      />

      <AdminComponents.pane
        title="Review interactions"
        subtitle="Read-only interaction rows expose non-secret queue context without raw-table overload."
      >
        <AdminComponents.metric_grid>
          <AdminComponents.summary_stat
            value={count_status(@interactions, :pending_login)}
            label="Pending login"
          />
          <AdminComponents.summary_stat
            value={count_status(@interactions, :pending_consent)}
            label="Pending consent"
          />
          <AdminComponents.summary_stat
            value={count_status(@interactions, :completed)}
            label="Completed"
          />
          <AdminComponents.summary_stat value={count_status(@interactions, :denied)} label="Denied" />
          <AdminComponents.summary_stat
            value={count_status(@interactions, :expired)}
            label="Expired"
          />
        </AdminComponents.metric_grid>

        <%= if @interactions == [] do %>
          <AdminComponents.empty_state
            title="No authorization interactions waiting for review"
            body="There are no authorization interaction records waiting for operator review."
          />
        <% else %>
          <AdminComponents.resource_list>
            <%= for interaction <- @interactions do %>
              <AdminComponents.dense_resource_row
                title="Authorization interaction"
                subtitle="Review interactions"
              >
                <:meta>
                  <span>Interaction <AdminComponents.long_value value={interaction.interaction_id} kind={:id} /></span>
                  <span>Client <AdminComponents.long_value value={redacted_handle(:client, interaction.client_id)} kind={:id} /></span>
                  <span>Subject <AdminComponents.long_value value={redacted_handle(:account, interaction.account_id)} kind={:id} /></span>
                  <span>Prompt <AdminComponents.long_value value={prompt_label(interaction.prompt)} kind={:text} /></span>
                  <span>Created <AdminComponents.long_value value={formatted_timestamp(interaction.inserted_at)} kind={:timestamp} /></span>
                  <span>Expires <AdminComponents.long_value value={formatted_timestamp(interaction.expires_at)} kind={:timestamp} /></span>
                </:meta>
                <:status>
                  <AdminComponents.status_badge status={interaction.status} />
                </:status>
              </AdminComponents.dense_resource_row>
            <% end %>
          </AdminComponents.resource_list>
        <% end %>
      </AdminComponents.pane>
    </AdminLayoutLive.shell>
    """
  end

  defp count_status(interactions, status), do: Enum.count(interactions, &(&1.status == status))

  defp redacted_handle(_type, nil), do: "Not recorded"
  defp redacted_handle(type, value), do: Redaction.handle(type, value)

  defp prompt_label(nil), do: "Not recorded"
  defp prompt_label(value) when is_list(value), do: Enum.join(value, ", ")
  defp prompt_label(value), do: to_string(value)

  defp formatted_timestamp(nil), do: "Not recorded"

  defp formatted_timestamp(%DateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")

  defp formatted_timestamp(value), do: to_string(value)
end
