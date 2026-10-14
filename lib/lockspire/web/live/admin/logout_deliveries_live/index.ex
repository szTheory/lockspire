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
       page_title: "App sign-out notices",
       current_section: :logouts,
       delivery_read_state: :loading,
       delivery_filter: :all,
       deliveries: [],
       delivery_metrics: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    delivery_filter = delivery_filter(params)
    {read_state, all_deliveries} = load_deliveries()
    deliveries = filter_deliveries(all_deliveries, delivery_filter)

    {:noreply,
     assign(socket,
       delivery_read_state: read_state,
       delivery_filter: delivery_filter,
       deliveries: deliveries,
       delivery_metrics:
         if(read_state == :loaded and delivery_filter == :all,
           do: delivery_metrics(all_deliveries),
           else: nil
         )
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero
        body="See which apps Lockspire notified during sign-out and what response it recorded."
      />

      <AdminComponents.pane
        title="Delivery records"
        subtitle="Each record covers one app and one sign-out method."
      >
        <:actions :if={@delivery_filter == :needs_review}>
          <AdminComponents.admin_button href={logout_deliveries_path(:all)}>
            View all app sign-out notices
          </AdminComponents.admin_button>
        </:actions>

        <AdminComponents.metric_grid
          :if={@delivery_read_state == :loaded and @delivery_filter == :all}
        >
          <AdminComponents.summary_stat value={@delivery_metrics.queued} label="Queued" />
          <AdminComponents.summary_stat value={@delivery_metrics.attempted} label="Attempted" />
          <AdminComponents.summary_stat value={@delivery_metrics.retryable} label="Retryable" />
          <AdminComponents.summary_stat value={@delivery_metrics.discarded} label="Discarded" />
          <AdminComponents.summary_stat value={@delivery_metrics.skipped} label="Skipped" />
          <AdminComponents.summary_stat value={@delivery_metrics.accepted} label="Endpoint accepted" />
          <AdminComponents.summary_stat value={@delivery_metrics.rendered} label="Browser page rendered" />
        </AdminComponents.metric_grid>

        <p :if={@delivery_read_state == :loaded} role="status">
          {delivery_count_copy(length(@deliveries), @delivery_filter)}
        </p>

        <%= cond do %>
          <% @delivery_read_state == :loading -> %>
            <p role="status">Loading app sign-out notices…</p>
          <% @delivery_read_state == :unavailable -> %>
            <AdminComponents.empty_state
              title="Could not load app sign-out notices"
              body="Lockspire could not read app sign-out notice records, so the current results are unavailable."
            >
              <:actions>
                <AdminComponents.admin_button href={logout_deliveries_path(@delivery_filter)}>
                  Reload app sign-out notices
                </AdminComponents.admin_button>
                <AdminComponents.admin_button href={Lockspire.mount_path() <> "/admin/overview"}>
                  Return to overview
                </AdminComponents.admin_button>
              </:actions>
            </AdminComponents.empty_state>
          <% @delivery_read_state == :loaded and @deliveries == [] -> %>
          <AdminComponents.empty_state
            title={empty_deliveries_title(@delivery_filter)}
            body={empty_deliveries_body(@delivery_filter)}
          >
            <:actions>
              <AdminComponents.admin_button
                :if={@delivery_filter == :needs_review}
                href={logout_deliveries_path(:all)}
              >
                View all app sign-out notices
              </AdminComponents.admin_button>
              <AdminComponents.admin_button
                :if={@delivery_filter == :all}
                href={Lockspire.mount_path() <> "/admin/overview"}
              >
                Return to overview
              </AdminComponents.admin_button>
            </:actions>
          </AdminComponents.empty_state>
          <% true -> %>
          <AdminComponents.resource_list>
            <%= for delivery <- @deliveries do %>
              <AdminComponents.dense_resource_row
                title={delivery_title(delivery)}
                subtitle={delivery_pressure(delivery)}
              >
                <:meta>
                  <span>Delivery ID <AdminComponents.long_value value={safe_identifier(delivery.delivery_id)} kind={:id} /></span>
                  <span>Client ID <AdminComponents.long_value value={safe_identifier(delivery.client_id)} kind={:id} /></span>
                  <span>Sign-out method <AdminComponents.long_value value={channel_label(delivery.channel)} kind={:text} /></span>
                  <span>Endpoint <AdminComponents.long_value value={safe_identifier(delivery.target_uri)} kind={:url} /></span>
                  <span>Attempts {delivery.attempt_count}</span>
                  <span :if={delivery_failure_context(delivery)}>
                    Recorded result <AdminComponents.long_value
                      value={delivery_failure_context(delivery)}
                      kind={:text}
                    />
                  </span>
                  <span>Last activity <AdminComponents.long_value value={formatted_timestamp(delivery_timestamp(delivery))} kind={:timestamp} /></span>
                </:meta>
                <:status>
                  <AdminComponents.status_badge status={delivery.status} />
                </:status>
                <:actions>
                  <AdminComponents.admin_button
                    :if={client_detail_path_available?(delivery)}
                    href={client_detail_path(delivery.client_id)}
                  >
                    Review app settings
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
    end
  rescue
    _error -> {:unavailable, []}
  end

  defp delivery_filter(%{"status" => "needs_review"}), do: :needs_review
  defp delivery_filter(_params), do: :all

  defp filter_deliveries(deliveries, :needs_review),
    do: Enum.filter(deliveries, &(&1.status in [:retryable, :discarded]))

  defp filter_deliveries(deliveries, :all), do: deliveries

  defp delivery_count_copy(0, :all), do: "0 app sign-out notices recorded"
  defp delivery_count_copy(1, :all), do: "1 logout delivery recorded"

  defp delivery_count_copy(count, :all), do: "#{count} app sign-out notices recorded"

  defp delivery_count_copy(0, :needs_review),
    do: "0 app sign-out notices need review"

  defp delivery_count_copy(1, :needs_review),
    do: "1 logout delivery needs review"

  defp delivery_count_copy(count, :needs_review),
    do: "#{count} app sign-out notices need review"

  defp empty_deliveries_title(:all), do: "No app sign-out notices recorded"
  defp empty_deliveries_title(:needs_review), do: "No app sign-out notices need review"

  defp empty_deliveries_body(:all),
    do:
      "No app sign-out notices are currently recorded. Return to the overview to choose another investigation."

  defp empty_deliveries_body(:needs_review),
    do: "There are no app sign-out notices that need review."

  defp delivery_metrics(deliveries) do
    %{
      queued: Enum.count(deliveries, &(&1.status in [:pending, :enqueued])),
      attempted: Enum.count(deliveries, &(&1.status == :attempted)),
      retryable: Enum.count(deliveries, &(&1.status == :retryable)),
      discarded: Enum.count(deliveries, &(&1.status == :discarded)),
      skipped: Enum.count(deliveries, &(&1.status == :skipped)),
      accepted: Enum.count(deliveries, &(&1.status == :succeeded)),
      rendered: Enum.count(deliveries, &(&1.status == :rendered))
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

  defp logout_deliveries_path(:needs_review),
    do: Lockspire.mount_path() <> "/admin/logouts?status=needs_review"

  defp logout_deliveries_path(_filter), do: Lockspire.mount_path() <> "/admin/logouts"

  defp safe_identifier(nil), do: "Not recorded"
  defp safe_identifier(value) when is_binary(value), do: value
  defp safe_identifier(value) when is_integer(value), do: Integer.to_string(value)
  defp safe_identifier(value), do: to_string(value)

  defp channel_label(:backchannel), do: "Server-to-server"
  defp channel_label(:frontchannel), do: "Browser"
  defp channel_label("backchannel"), do: "Server-to-server"
  defp channel_label("frontchannel"), do: "Browser"
  defp channel_label(nil), do: "Unknown channel"

  defp channel_label(value) do
    value
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp delivery_title(%{channel: :backchannel}), do: "Server sign-out request"
  defp delivery_title(%{channel: :frontchannel}), do: "Browser sign-out page"
  defp delivery_title(_delivery), do: "Sign-out record"

  defp delivery_pressure(%{status: :pending, channel: :backchannel}),
    do: "Lockspire is preparing the request; it has not been sent yet."

  defp delivery_pressure(%{status: :enqueued, channel: :backchannel}),
    do: "The request is ready to send; no response is recorded yet."

  defp delivery_pressure(%{status: :attempted, channel: :backchannel}),
    do: "Lockspire began sending the request; no response is recorded."

  defp delivery_pressure(%{status: :retryable, channel: :backchannel}),
    do:
      "The request failed and may be tried again automatically. Check this app's endpoint and sign-out settings."

  defp delivery_pressure(%{status: :discarded, http_status: status})
       when is_integer(status) and status in 400..499,
       do:
         "The app rejected the request, so Lockspire stopped trying. Review the response and this app's settings."

  defp delivery_pressure(%{status: :discarded, failure_reason: reason})
       when reason in ["invalid_signing_key", "missing_signing_key"],
       do:
         "Lockspire could not sign the request, so it stopped. Review the signing key and app settings."

  defp delivery_pressure(%{status: :discarded}),
    do:
      "Lockspire stopped trying to send this request. Review the recorded reason and app settings."

  defp delivery_pressure(%{status: :skipped}),
    do: "No server or browser sign-out request was recorded for this app."

  defp delivery_pressure(%{status: :succeeded, channel: :backchannel}),
    do: "The app accepted the server request. This does not confirm the person was signed out."

  defp delivery_pressure(%{status: :rendered, channel: :frontchannel}),
    do:
      "Lockspire showed a sign-out page in the browser. This does not confirm the app signed the person out."

  defp delivery_pressure(_delivery),
    do: "Review the recorded status; no result is assumed."

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
    do: "Request failed: #{safe_failure_detail(detail)}"

  defp failure_class_context("http_error:" <> _detail), do: nil

  defp failure_class_context("invalid_signing_key"),
    do: "Signing key is invalid"

  defp failure_class_context("missing_signing_key"),
    do: "Signing key is missing"

  defp failure_class_context(_reason), do: "Request failed"

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

  defp formatted_timestamp(nil), do: "Not recorded"

  defp formatted_timestamp(%DateTime{} = value),
    do: value

  defp formatted_timestamp(value), do: to_string(value)
end
