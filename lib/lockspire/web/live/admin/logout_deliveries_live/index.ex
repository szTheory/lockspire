defmodule Lockspire.Web.Live.Admin.LogoutDeliveriesLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Redaction
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
       deliveries: deliveries,
       delivery_metrics: delivery_metrics(deliveries)
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
        title="Logout propagation queue"
        body="Triage waiting, retrying, failed, discarded, and completed logout delivery work without adding worker controls."
      />

      <AdminComponents.section_card
        title="Review logout deliveries"
        subtitle="Read-only delivery rows expose status pressure, client, endpoint, attempts, and durable delivery context."
      >
        <AdminComponents.metric_grid>
          <AdminComponents.summary_stat value={@delivery_metrics.waiting} label="Waiting" />
          <AdminComponents.summary_stat value={@delivery_metrics.retrying} label="Retrying" />
          <AdminComponents.summary_stat value={@delivery_metrics.failed} label="Failed" />
          <AdminComponents.summary_stat value={@delivery_metrics.discarded} label="Discarded" />
          <AdminComponents.summary_stat value={@delivery_metrics.completed} label="Completed" />
        </AdminComponents.metric_grid>

        <%= if @deliveries == [] do %>
          <AdminComponents.empty_state
            title="No logout deliveries"
            body="There are no logout propagation records waiting for operator review."
          />
        <% else %>
          <div class="lockspire-admin-table-wrap">
            <AdminComponents.resource_list>
              <%= for delivery <- @deliveries do %>
                <AdminComponents.resource_item
                  title={"#{delivery.channel} logout delivery"}
                  subtitle="Review logout deliveries"
                >
                  <:meta>
                    <span>Delivery <AdminComponents.long_value value={delivery.delivery_id} kind={:id} /></span>
                    <span>Client <AdminComponents.long_value value={redacted_handle(:client, delivery.client_id)} kind={:id} /></span>
                    <span>Endpoint <AdminComponents.long_value value={delivery.target_uri} kind={:url} /></span>
                    <span>Attempts {delivery.attempt_count}</span>
                    <span>Timestamp <AdminComponents.long_value value={formatted_timestamp(delivery_timestamp(delivery))} kind={:timestamp} /></span>
                  </:meta>
                  <:status>
                    <AdminComponents.status_badge status={delivery.status} />
                  </:status>
                </AdminComponents.resource_item>
              <% end %>
            </AdminComponents.resource_list>
          </div>
        <% end %>
      </AdminComponents.section_card>
    </AdminLayoutLive.shell>
    """
  end

  defp delivery_metrics(deliveries) do
    %{
      waiting: Enum.count(deliveries, &(&1.status in [:pending, :enqueued])),
      retrying: Enum.count(deliveries, &(&1.status in [:attempted, :retryable])),
      failed: Enum.count(deliveries, &(&1.status == :retryable)),
      discarded: Enum.count(deliveries, &(&1.status in [:discarded, :skipped])),
      completed: Enum.count(deliveries, &(&1.status in [:succeeded, :rendered]))
    }
  end

  defp delivery_timestamp(delivery) do
    delivery.delivered_at || delivery.rendered_at || delivery.finalized_at ||
      delivery.last_attempted_at || delivery.updated_at || delivery.inserted_at
  end

  defp redacted_handle(_type, nil), do: "Not recorded"
  defp redacted_handle(type, value), do: Redaction.handle(type, value)

  defp formatted_timestamp(nil), do: "Not recorded"

  defp formatted_timestamp(%DateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")

  defp formatted_timestamp(value), do: to_string(value)
end
