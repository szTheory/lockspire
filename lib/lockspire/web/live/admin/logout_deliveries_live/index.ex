defmodule Lockspire.Web.Live.Admin.LogoutDeliveriesLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Redaction
  alias Lockspire.Admin
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok, deliveries} = Admin.list_logout_deliveries()

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

      <AdminComponents.pane
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
            title="No logout deliveries waiting for review"
            body="There are no logout propagation records waiting for operator review."
          />
        <% else %>
          <AdminComponents.resource_list>
            <%= for delivery <- @deliveries do %>
              <AdminComponents.dense_resource_row
                title={"#{channel_label(delivery.channel)} logout delivery"}
                subtitle={delivery_pressure(delivery)}
              >
                <:meta>
                  <span>Delivery <AdminComponents.long_value value={delivery.delivery_id} kind={:id} /></span>
                  <span>Client <AdminComponents.long_value value={redacted_handle(:client, delivery.client_id)} kind={:id} /></span>
                  <span>Channel <AdminComponents.long_value value={channel_label(delivery.channel)} kind={:text} /></span>
                  <span>Endpoint <AdminComponents.long_value value={delivery.target_uri} kind={:url} /></span>
                  <span>Attempts {delivery.attempt_count}</span>
                  <span :if={delivery_failure_context(delivery)}>
                    Failure context <AdminComponents.long_value
                      value={delivery_failure_context(delivery)}
                      kind={:text}
                    />
                  </span>
                  <span>Last activity <AdminComponents.long_value value={formatted_timestamp(delivery_timestamp(delivery))} kind={:timestamp} /></span>
                  <span class="lockspire-admin-dense-resource-row__note">
                    {delivery_support_note(delivery)}
                  </span>
                </:meta>
                <:status>
                  <AdminComponents.status_badge status={delivery.status} />
                </:status>
              </AdminComponents.dense_resource_row>
            <% end %>
          </AdminComponents.resource_list>
        <% end %>
      </AdminComponents.pane>
    </AdminLayoutLive.shell>
    """
  end

  defp delivery_metrics(deliveries) do
    %{
      waiting: Enum.count(deliveries, &(&1.status in [:pending, :enqueued])),
      retrying: Enum.count(deliveries, &(&1.status == :attempted)),
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

  defp channel_label(:backchannel), do: "Back-channel"
  defp channel_label(:frontchannel), do: "Front-channel"
  defp channel_label("backchannel"), do: "Back-channel"
  defp channel_label("frontchannel"), do: "Front-channel"
  defp channel_label(nil), do: "Unknown channel"

  defp channel_label(value) do
    value
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp delivery_pressure(%{status: status}) when status in [:pending, :enqueued],
    do: "Waiting for the protocol worker to attempt delivery."

  defp delivery_pressure(%{status: :attempted}),
    do: "Delivery has been attempted and remains under observation."

  defp delivery_pressure(%{status: :retryable}),
    do: "Retryable failure; verify the RP endpoint and preserve the delivery record."

  defp delivery_pressure(%{status: :discarded}),
    do: "Terminal queue outcome; discarded after retry exhaustion and kept as support truth."

  defp delivery_pressure(%{status: :skipped}),
    do: "Terminal queue outcome; skipped because no delivery action was required."

  defp delivery_pressure(%{status: :succeeded}),
    do: "Delivery work completed; the back-channel endpoint accepted the logout."

  defp delivery_pressure(%{status: :rendered}),
    do: "Delivery work completed; front-channel logout was rendered for browser delivery."

  defp delivery_pressure(_delivery), do: "Review durable delivery state."

  defp delivery_failure_context(delivery) do
    [http_status_context(delivery.http_status), failure_class_context(delivery.failure_reason)]
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      parts -> Enum.join(parts, " · ")
    end
  end

  defp http_status_context(nil), do: nil
  defp http_status_context(status) when is_integer(status), do: "HTTP #{status}"

  defp http_status_context(status) do
    case Integer.parse(to_string(status)) do
      {parsed, ""} -> "HTTP #{parsed}"
      _other -> nil
    end
  end

  defp failure_class_context(nil), do: nil
  defp failure_class_context(""), do: nil

  defp failure_class_context("request_failed:" <> detail),
    do: "Failure class Request failed / #{safe_failure_detail(detail)}"

  defp failure_class_context("http_error:" <> detail),
    do: "Failure class HTTP error / #{safe_failure_detail(detail)}"

  defp failure_class_context("invalid_signing_key"),
    do: "Failure class Invalid signing key"

  defp failure_class_context("missing_signing_key"),
    do: "Failure class Missing signing key"

  defp failure_class_context(_reason), do: "Failure class Recorded delivery failure"

  defp safe_failure_detail(detail) do
    detail
    |> to_string()
    |> String.split(~r/\s+/, parts: 2)
    |> List.first()
    |> String.replace("_", " ")
    |> String.replace(~r/[^A-Za-z0-9 -]/, "")
    |> String.trim()
    |> case do
      "" -> "unspecified"
      value -> value
    end
  end

  defp delivery_support_note(%{status: :retryable}),
    do:
      "Support note: confirm endpoint availability and client logout configuration before changing issuer policy."

  defp delivery_support_note(%{status: :discarded}),
    do:
      "Support note: this discarded delivery is read-only historical truth; no worker action is exposed from this page."

  defp delivery_support_note(%{status: :skipped}),
    do:
      "Support note: skipped delivery rows explain why no endpoint work was needed; no worker action is exposed from this page."

  defp delivery_support_note(%{status: :succeeded}),
    do:
      "Support note: confirm the accepted timestamp and endpoint when answering partner questions."

  defp delivery_support_note(%{status: :rendered}),
    do:
      "Support note: confirm the rendered timestamp and front-channel endpoint when answering partner questions."

  defp delivery_support_note(_delivery),
    do:
      "Support note: use client, endpoint, attempts, and timestamp to triage without exposing secrets."

  defp formatted_timestamp(nil), do: "Not recorded"

  defp formatted_timestamp(%DateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")

  defp formatted_timestamp(value), do: to_string(value)
end
