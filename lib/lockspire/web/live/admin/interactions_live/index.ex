defmodule Lockspire.Web.Live.Admin.InteractionsLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Redaction
  alias Lockspire.Admin
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Sign-in requests",
       current_section: :interactions,
       interaction_read_state: :loading,
       interaction_filter: :all,
       interactions: []
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    interaction_filter = interaction_filter(params)
    {read_state, interactions} = load_interactions(interaction_filter)

    {:noreply,
     assign(socket,
       page_title: "Sign-in requests",
       interaction_filter: interaction_filter,
       interaction_read_state: read_state,
       interactions: interactions
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero
        body="See requests waiting for sign-in or consent, plus the results already recorded."
      />

      <AdminComponents.pane
        title={interaction_list_title(@interaction_filter)}
      >
        <:actions :if={@interaction_filter == :pending}>
          <AdminComponents.admin_button href={interactions_path(:all)}>
            View all sign-in requests
          </AdminComponents.admin_button>
        </:actions>

        <AdminComponents.metric_grid
          :if={@interaction_read_state == :loaded and @interaction_filter == :all}
        >
          <AdminComponents.summary_stat
            value={count_waiting(@interactions, :pending_login)}
            label="Waiting for sign-in"
          />
          <AdminComponents.summary_stat
            value={count_waiting(@interactions, :pending_consent)}
            label="Waiting for consent"
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

        <p :if={@interaction_read_state == :loaded} role="status">
          {interaction_count_copy(length(@interactions), @interaction_filter)}
        </p>

        <%= cond do %>
          <% @interaction_read_state == :loading -> %>
            <p role="status">Loading sign-in requests…</p>
          <% @interaction_read_state == :unavailable -> %>
            <AdminComponents.empty_state
              title="Could not load sign-in requests"
              body="Lockspire could not read sign-in requests, so the current results are unavailable."
            >
              <:actions>
                <AdminComponents.admin_button href={interactions_path(@interaction_filter)}>
                  Reload sign-in requests
                </AdminComponents.admin_button>
                <AdminComponents.admin_button href={admin_path("/overview")}>
                  Return to overview
                </AdminComponents.admin_button>
              </:actions>
            </AdminComponents.empty_state>
          <% @interaction_read_state == :loaded and @interactions == [] -> %>
          <AdminComponents.empty_state
            title={empty_interactions_title(@interaction_filter)}
            body={empty_interactions_body(@interaction_filter)}
          >
            <:actions>
              <AdminComponents.admin_button
                :if={@interaction_filter == :pending}
                href={interactions_path(:all)}
              >
                View all sign-in requests
              </AdminComponents.admin_button>
              <AdminComponents.admin_button
                :if={@interaction_filter == :all}
                href={admin_path("/overview")}
              >
                Return to overview
              </AdminComponents.admin_button>
            </:actions>
          </AdminComponents.empty_state>
          <% true -> %>
          <AdminComponents.resource_list>
            <%= for interaction <- @interactions do %>
              <AdminComponents.dense_resource_row
                title={interaction_title(interaction)}
                subtitle={interaction_pressure(interaction)}
              >
                <:meta>
                  <span>Request ID <AdminComponents.long_value value={safe_identifier(interaction.interaction_id)} kind={:id} /></span>
                  <span>Client ID <AdminComponents.long_value value={safe_identifier(interaction.client_id)} kind={:id} /></span>
                  <span>Account <AdminComponents.long_value value={redacted_handle(:account, interaction.account_id)} kind={:id} /></span>
                  <span>Prompt <AdminComponents.long_value value={prompt_label(interaction.prompt)} kind={:text} /></span>
                  <span>Created <AdminComponents.long_value value={formatted_timestamp(interaction.inserted_at)} kind={:timestamp} /></span>
                  <span>Last activity <AdminComponents.long_value value={formatted_timestamp(interaction_activity_timestamp(interaction))} kind={:timestamp} /></span>
                  <span>Expires <AdminComponents.long_value value={formatted_timestamp(interaction.expires_at)} kind={:timestamp} /></span>
                </:meta>
                <:status>
                  <AdminComponents.status_badge status={interaction.status} />
                </:status>
                <:actions>
                  <AdminComponents.admin_button
                    :if={client_detail_path_available?(interaction)}
                    href={client_detail_path(interaction.client_id)}
                  >
                    View app details
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

  # Filtering runs inside the rescue so a malformed row shows the read as
  # unavailable instead of crashing the page.
  defp load_interactions(filter) do
    case Admin.list_interactions() do
      {:ok, interactions} when is_list(interactions) ->
        {:loaded, filter_interactions(interactions, filter)}

      _other ->
        {:unavailable, []}
    end
  rescue
    _error -> {:unavailable, []}
  end

  defp interaction_filter(%{"status" => "pending"}), do: :pending
  defp interaction_filter(_params), do: :all

  defp filter_interactions(interactions, :pending) do
    now = DateTime.utc_now()
    Enum.filter(interactions, &waiting?(&1, now))
  end

  defp filter_interactions(interactions, :all), do: interactions

  defp count_status(interactions, status), do: Enum.count(interactions, &(&1.status == status))

  # Matches the overview and the pending filter: a request past its expiry is no
  # longer waiting, even before its status is swept to expired.
  defp count_waiting(interactions, status) do
    now = DateTime.utc_now()
    Enum.count(interactions, &(&1.status == status and waiting?(&1, now)))
  end

  defp waiting?(%{status: status, expires_at: %DateTime{} = expires_at}, now)
       when status in [:pending_login, :pending_consent],
       do: DateTime.compare(expires_at, now) == :gt

  defp waiting?(_interaction, _now), do: false

  defp interaction_count_copy(0, :all), do: "0 sign-in requests recorded"
  defp interaction_count_copy(1, :all), do: "1 sign-in request recorded"

  defp interaction_count_copy(count, :all),
    do: "#{count} sign-in requests recorded"

  defp interaction_count_copy(0, :pending),
    do: "0 requests waiting for sign-in or consent"

  defp interaction_count_copy(1, :pending),
    do: "1 request waiting for sign-in or consent"

  defp interaction_count_copy(count, :pending),
    do: "#{count} requests waiting for sign-in or consent"

  defp interaction_list_title(:all), do: "Sign-in request history"
  defp interaction_list_title(:pending), do: "Waiting for sign-in or consent"

  defp empty_interactions_title(:all), do: "No sign-in requests recorded"
  defp empty_interactions_title(:pending), do: "No requests waiting for sign-in or consent"

  defp empty_interactions_body(:all),
    do: "There are no recorded authorization requests to review."

  defp empty_interactions_body(:pending),
    do:
      "There are no requests waiting for sign-in or consent. View the full sign-in request history."

  defp interaction_title(%{status: :pending_login}), do: "Waiting for sign-in"
  defp interaction_title(%{status: :pending_consent}), do: "Waiting for consent"
  defp interaction_title(%{status: :completed}), do: "Completed sign-in request"
  defp interaction_title(%{status: :denied}), do: "Denied sign-in request"
  defp interaction_title(%{status: :expired}), do: "Expired sign-in request"
  defp interaction_title(_interaction), do: "Sign-in request"

  defp interaction_pressure(%{status: :pending_login}),
    do: "The person must sign in before they can review the request."

  defp interaction_pressure(%{status: :pending_consent}),
    do: "The person has not responded to the consent request yet."

  defp interaction_pressure(%{status: :completed}),
    do: "The request was completed."

  defp interaction_pressure(%{status: :denied}),
    do: "The request was denied."

  defp interaction_pressure(%{status: :expired}),
    do: "The request expired before it was completed."

  defp interaction_pressure(_interaction), do: "Review the recorded request status."

  defp interaction_activity_timestamp(%{status: :pending_login} = interaction),
    do: interaction.login_required_at

  defp interaction_activity_timestamp(%{status: :pending_consent} = interaction),
    do: interaction.consent_requested_at

  defp interaction_activity_timestamp(%{status: :completed} = interaction),
    do: interaction.completed_at

  defp interaction_activity_timestamp(%{status: :denied} = interaction),
    do: interaction.denied_at

  defp interaction_activity_timestamp(%{status: :expired} = interaction),
    do: interaction.expired_at

  defp interaction_activity_timestamp(_interaction), do: nil

  defp client_detail_path_available?(%{client_id: client_id})
       when is_binary(client_id) and byte_size(client_id) > 0 and byte_size(client_id) <= 64,
       do: true

  defp client_detail_path_available?(_interaction), do: false

  defp client_detail_path(client_id),
    do:
      Lockspire.mount_path() <>
        "/admin/clients/" <> URI.encode(client_id, &URI.char_unreserved?/1)

  defp interactions_path(:pending),
    do: Lockspire.mount_path() <> "/admin/interactions?status=pending"

  defp interactions_path(:all), do: Lockspire.mount_path() <> "/admin/interactions"

  defp admin_path(path), do: Lockspire.mount_path() <> "/admin" <> path

  defp safe_identifier(nil), do: "Not recorded"
  defp safe_identifier(value) when is_binary(value), do: value
  defp safe_identifier(value) when is_integer(value), do: Integer.to_string(value)
  defp safe_identifier(value), do: to_string(value)

  defp redacted_handle(_type, nil), do: "Not recorded"
  defp redacted_handle(type, value), do: Redaction.handle(type, value)

  defp prompt_label(nil), do: "Not recorded"
  defp prompt_label([]), do: "Not recorded"
  defp prompt_label(value) when is_list(value), do: Enum.join(value, ", ")
  defp prompt_label(value), do: to_string(value)

  defp formatted_timestamp(nil), do: "Not recorded"

  defp formatted_timestamp(%DateTime{} = value),
    do: value

  defp formatted_timestamp(value), do: to_string(value)
end
