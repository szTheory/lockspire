defmodule Lockspire.Web.Live.Admin.LogoutDeliveriesLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Logout deliveries",
       current_section: :logouts,
       delivery_read_state: :loading,
       deliveries: [],
       delivery_metrics: nil
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {read_state, deliveries} = load_deliveries()

    {:noreply,
     assign(socket,
       delivery_read_state: read_state,
       deliveries: deliveries,
       delivery_metrics: if(read_state == :loaded, do: delivery_metrics(deliveries), else: nil)
     )}
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
        <AdminComponents.metric_grid :if={@delivery_read_state == :loaded}>
          <AdminComponents.summary_stat value={@delivery_metrics.waiting} label="Waiting" />
          <AdminComponents.summary_stat value={@delivery_metrics.retrying} label="Retrying" />
          <AdminComponents.summary_stat value={@delivery_metrics.failed} label="Failed" />
          <AdminComponents.summary_stat value={@delivery_metrics.discarded} label="Discarded" />
          <AdminComponents.summary_stat value={@delivery_metrics.completed} label="Completed" />
        </AdminComponents.metric_grid>

        <p :if={@delivery_read_state == :loaded} role="status">
          {delivery_count_copy(length(@deliveries))}
        </p>

        <%= cond do %>
          <% @delivery_read_state == :loading -> %>
            <p role="status">Loading logout deliveries…</p>
          <% @delivery_read_state == :unavailable -> %>
            <AdminComponents.empty_state
              title="Could not load logout deliveries"
              body="The logout delivery queue is unavailable. No count or empty result is available. Reload this route or return to the overview."
            >
              <:actions>
                <AdminComponents.admin_button href={logout_deliveries_path()}>
                  Try loading logout deliveries again
                </AdminComponents.admin_button>
                <AdminComponents.admin_button href={Lockspire.mount_path() <> "/admin/overview"}>
                  Return to overview
                </AdminComponents.admin_button>
              </:actions>
            </AdminComponents.empty_state>
          <% @delivery_read_state == :loaded and @deliveries == [] -> %>
          <AdminComponents.empty_state
            title="No logout deliveries waiting for review"
            body="There are no logout propagation records waiting for operator review."
          />
          <% true -> %>
          <AdminComponents.resource_list>
            <%= for delivery <- @deliveries do %>
              <AdminComponents.dense_resource_row
                title={"#{channel_label(delivery.channel)} logout delivery"}
                subtitle={delivery_pressure(delivery)}
              >
                <:meta>
                  <span>Delivery <AdminComponents.long_value value={safe_identifier(delivery.delivery_id)} kind={:id} /></span>
                  <span>Client <AdminComponents.long_value value={safe_identifier(delivery.client_id)} kind={:id} /></span>
                  <span>Channel <AdminComponents.long_value value={channel_label(delivery.channel)} kind={:text} /></span>
                  <span>Endpoint <AdminComponents.long_value value={safe_identifier(delivery.target_uri)} kind={:url} /></span>
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
                <:actions>
                  <AdminComponents.admin_button
                    :if={client_detail_path_available?(delivery)}
                    href={client_detail_path(delivery.client_id)}
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

  defp load_deliveries do
    case Admin.list_logout_deliveries() do
      {:ok, deliveries} when is_list(deliveries) -> {:loaded, deliveries}
      _other -> {:unavailable, []}
    end
  rescue
    _error -> {:unavailable, []}
  end

  defp delivery_count_copy(0), do: "0 logout deliveries recorded"
  defp delivery_count_copy(1), do: "1 logout delivery recorded"

  defp delivery_count_copy(count), do: "#{count} logout deliveries recorded"

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
      delivery.last_attempted_at
  end

  defp client_detail_path_available?(%{client_id: client_id})
       when is_binary(client_id) and byte_size(client_id) > 0 and byte_size(client_id) <= 64,
       do: true

  defp client_detail_path_available?(_delivery), do: false

  defp client_detail_path(client_id),
    do:
      Lockspire.mount_path() <>
        "/admin/clients/" <> URI.encode(client_id, &URI.char_unreserved?/1)

  defp logout_deliveries_path, do: Lockspire.mount_path() <> "/admin/logouts"

  defp safe_identifier(nil), do: "Not recorded"
  defp safe_identifier(value) when is_binary(value), do: value
  defp safe_identifier(value) when is_integer(value), do: Integer.to_string(value)
  defp safe_identifier(value), do: to_string(value)

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
    do:
      "Back-channel endpoint accepted the request; end-user session termination is not confirmed."

  defp delivery_pressure(%{status: :rendered}),
    do:
      "Front-channel logout was rendered for browser delivery; end-user session termination is not confirmed."

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
      "Support note: confirm the accepted timestamp and endpoint when answering partner questions; acceptance does not confirm the user session ended."

  defp delivery_support_note(%{status: :rendered}),
    do:
      "Support note: confirm the rendered timestamp and front-channel endpoint when answering partner questions; rendering does not confirm the user session ended."

  defp delivery_support_note(_delivery),
    do:
      "Support note: use client, endpoint, attempts, and timestamp to triage without exposing secrets."

  defp formatted_timestamp(nil), do: "Not recorded"

  defp formatted_timestamp(%DateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")

  defp formatted_timestamp(value), do: to_string(value)
end
