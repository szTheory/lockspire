defmodule Lockspire.Web.Live.Admin.InteractionsLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Redaction
  alias Lockspire.Admin
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok, interactions} = Admin.list_interactions()

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
        subtitle="Read-only interaction rows expose status pressure, prompt, client, subject, and durable review context."
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
                title={interaction_title(interaction)}
                subtitle={interaction_pressure(interaction)}
              >
                <:meta>
                  <span>Interaction <AdminComponents.long_value value={interaction.interaction_id} kind={:id} /></span>
                  <span>Client <AdminComponents.long_value value={redacted_handle(:client, interaction.client_id)} kind={:id} /></span>
                  <span>Subject <AdminComponents.long_value value={redacted_handle(:account, interaction.account_id)} kind={:id} /></span>
                  <span>Prompt <AdminComponents.long_value value={prompt_label(interaction.prompt)} kind={:text} /></span>
                  <span>Created <AdminComponents.long_value value={formatted_timestamp(interaction.inserted_at)} kind={:timestamp} /></span>
                  <span>Last activity <AdminComponents.long_value value={formatted_timestamp(interaction_activity_timestamp(interaction))} kind={:timestamp} /></span>
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

  defp interaction_title(%{status: :pending_login}), do: "Waiting for login interaction"
  defp interaction_title(%{status: :pending_consent}), do: "Waiting for consent interaction"
  defp interaction_title(%{status: :completed}), do: "Completed interaction"
  defp interaction_title(%{status: :denied}), do: "Denied interaction"
  defp interaction_title(%{status: :expired}), do: "Expired interaction"
  defp interaction_title(_interaction), do: "Authorization interaction"

  defp interaction_pressure(%{status: :pending_login}),
    do: "Waiting for login; host login must resolve the subject before consent or completion."

  defp interaction_pressure(%{status: :pending_consent}),
    do: "Waiting for consent; the account has not completed the prompt yet."

  defp interaction_pressure(%{status: :completed}),
    do: "Interaction completed; preserve the durable handle for support follow-up."

  defp interaction_pressure(%{status: :denied}),
    do:
      "Denied before completion; review prompt and subject context without changing queue state."

  defp interaction_pressure(%{status: :expired}),
    do: "Expired before completion; no interaction action is exposed from this page."

  defp interaction_pressure(_interaction), do: "Review durable interaction state."

  defp interaction_activity_timestamp(%{status: :pending_login} = interaction),
    do: interaction.login_required_at || interaction.updated_at || interaction.inserted_at

  defp interaction_activity_timestamp(%{status: :pending_consent} = interaction),
    do: interaction.consent_requested_at || interaction.updated_at || interaction.inserted_at

  defp interaction_activity_timestamp(%{status: :completed} = interaction),
    do: interaction.completed_at || interaction.updated_at || interaction.inserted_at

  defp interaction_activity_timestamp(%{status: :denied} = interaction),
    do: interaction.denied_at || interaction.updated_at || interaction.inserted_at

  defp interaction_activity_timestamp(%{status: :expired} = interaction),
    do: interaction.expired_at || interaction.updated_at || interaction.expires_at

  defp interaction_activity_timestamp(interaction),
    do: interaction.updated_at || interaction.inserted_at

  defp redacted_handle(_type, nil), do: "Not recorded"
  defp redacted_handle(type, value), do: Redaction.handle(type, value)

  defp prompt_label(nil), do: "Not recorded"
  defp prompt_label([]), do: "Not recorded"
  defp prompt_label(value) when is_list(value), do: Enum.join(value, ", ")
  defp prompt_label(value), do: to_string(value)

  defp formatted_timestamp(nil), do: "Not recorded"

  defp formatted_timestamp(%DateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")

  defp formatted_timestamp(value), do: to_string(value)
end
