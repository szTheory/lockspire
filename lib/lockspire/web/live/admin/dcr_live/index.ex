defmodule Lockspire.Web.Live.Admin.DcrLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Dynamic Registration",
       current_section: :dcr,
       policy: load_policy(),
       summary: load_summary()
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, policy: load_policy(), summary: load_summary())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero
        eyebrow="Configure"
        title="DCR onboarding"
        body="DCR onboarding is the partner intake journey: mint short-lived initial access tokens, review self-registered clients, and route issuer posture changes to DCR policy."
      >
        <:actions>
          <AdminComponents.admin_button href={admin_path("/iats/new")} variant={:primary}>
            Mint initial access token
          </AdminComponents.admin_button>
          <AdminComponents.admin_button href={admin_path("/iats")}>
            Review initial access tokens
          </AdminComponents.admin_button>
          <AdminComponents.admin_button href={admin_path("/policies/dcr")}>
            Edit DCR policy
          </AdminComponents.admin_button>
        </:actions>
      </AdminComponents.page_hero>

      <AdminComponents.decision_summary>
        <:item
          :for={item <- dcr_decision_summary_items(%{policy: @policy, summary: @summary})}
          label={item.label}
          value={item.value}
          detail={item.detail}
          tone={item.tone}
        >
        </:item>
      </AdminComponents.decision_summary>

      <AdminComponents.metric_grid>
        <AdminComponents.summary_stat
          value={@policy.registration_policy}
          label="registration mode"
        />
        <AdminComponents.summary_stat value={@summary.iats.active} label="active IATs" />
        <AdminComponents.summary_stat
          value={@summary.clients.self_registered}
          label="self-registered clients"
        />
      </AdminComponents.metric_grid>

      <div class="lockspire-admin-dashboard-grid">
        <AdminComponents.section_card
          title="DCR policy"
          subtitle="Set whether registration is disabled, IAT-gated, or open."
        >
          <p class="lockspire-admin-help">
            Current policy: <strong>{@policy.registration_policy}</strong>. Keep open registration rare;
            the safer onboarding path is short-lived Initial Access Tokens.
          </p>
          <AdminComponents.action_bar>
            <AdminComponents.admin_button href={admin_path("/policies/dcr")}>
              Edit DCR policy
            </AdminComponents.admin_button>
          </AdminComponents.action_bar>
        </AdminComponents.section_card>

        <AdminComponents.section_card
          title="Initial access token inventory"
          subtitle="Plaintext is shown once; durable rows let operators revoke intake."
        >
          <dl class="lockspire-admin-description-list">
            <div>
              <dt>Active</dt>
              <dd>{@summary.iats.active}</dd>
            </div>
            <div>
              <dt>Revoked</dt>
              <dd>{@summary.iats.revoked}</dd>
            </div>
            <div>
              <dt>Expired or used</dt>
              <dd>{@summary.iats.closed}</dd>
            </div>
          </dl>
          <AdminComponents.action_bar>
            <AdminComponents.admin_button href={admin_path("/iats")}>
              Review initial access tokens
            </AdminComponents.admin_button>
            <AdminComponents.admin_button href={admin_path("/iats/new")} variant={:primary}>
              Mint initial access token
            </AdminComponents.admin_button>
          </AdminComponents.action_bar>
        </AdminComponents.section_card>

        <AdminComponents.section_card
          title="Review self-registered clients"
          subtitle="DCR-created clients keep provenance and RAT rotation visible in client detail."
        >
          <div class="lockspire-admin-resource-list">
            <%= for client <- @summary.clients.self_registered_clients do %>
              <a href={admin_path("/clients/" <> client.client_id)}>
                <span>{client.name || client.client_id}</span>
                <strong>{if client.active, do: "Active", else: "Disabled"}</strong>
              </a>
            <% end %>
          </div>
          <AdminComponents.empty_state
            :if={@summary.clients.self_registered_clients == []}
            title="No self-registered clients yet"
            body="When DCR creates clients, review and support them from this journey."
          />
        </AdminComponents.section_card>
      </div>
    </AdminLayoutLive.shell>
    """
  end

  defp load_policy do
    case Admin.get_server_policy() do
      {:ok, %ServerPolicy{} = policy} -> policy
      _result -> %ServerPolicy{}
    end
  end

  defp load_summary do
    clients = ok_list(Admin.list_clients())
    iats = ok_list(Lockspire.Admin.InitialAccessTokens.list_iats())
    self_registered_clients = Enum.filter(clients, &(&1.provenance == :self_registered))

    %{
      clients: %{
        self_registered: length(self_registered_clients),
        self_registered_clients: self_registered_clients
      },
      iats: %{
        active: Enum.count(iats, &(iat_status(&1) == :active)),
        revoked: Enum.count(iats, &(iat_status(&1) == :revoked)),
        closed: Enum.count(iats, &(iat_status(&1) in [:expired, :used]))
      }
    }
  end

  defp ok_list({:ok, list}) when is_list(list), do: list
  defp ok_list(_result), do: []

  defp dcr_decision_summary_items(%{policy: policy, summary: summary}) do
    [
      %{
        label: "Registration gate",
        value: registration_policy_label(policy.registration_policy),
        detail: registration_policy_detail(policy.registration_policy),
        tone: registration_policy_tone(policy.registration_policy)
      },
      %{
        label: "Intake tokens",
        value: "#{summary.iats.active} active",
        detail:
          "#{summary.iats.revoked} revoked, #{summary.iats.closed} expired or used. Mint or review intake tokens before partner handoff.",
        tone: if(summary.iats.active > 0, do: :success, else: :info)
      },
      %{
        label: "Self-registered clients",
        value: "#{summary.clients.self_registered} visible",
        detail:
          "Review DCR-created clients from client detail before RAT support or policy follow-up.",
        tone: if(summary.clients.self_registered > 0, do: :success, else: :info)
      },
      %{
        label: "Next safe action",
        value: next_safe_action(policy, summary),
        detail: next_safe_action_detail(policy, summary),
        tone: :info
      }
    ]
  end

  defp registration_policy_label(:initial_access_token), do: "Initial access token gated"
  defp registration_policy_label(:open), do: "Open registration"
  defp registration_policy_label(:disabled), do: "Registration disabled"
  defp registration_policy_label(policy), do: to_string(policy)

  defp registration_policy_detail(:initial_access_token),
    do: "Partners need a short-lived intake token before dynamic registration can create clients."

  defp registration_policy_detail(:open),
    do: "Open registration is broad; narrow allowlists and lifetimes before partner intake."

  defp registration_policy_detail(:disabled),
    do: "Dynamic registration is closed until the DCR policy is intentionally changed."

  defp registration_policy_detail(_policy),
    do: "Review DCR policy before issuing partner onboarding credentials."

  defp registration_policy_tone(:initial_access_token), do: :success
  defp registration_policy_tone(:open), do: :info
  defp registration_policy_tone(_policy), do: nil

  defp next_safe_action(_policy, %{iats: %{active: active}}) when active > 0,
    do: "Review initial access tokens"

  defp next_safe_action(%{registration_policy: :disabled}, _summary), do: "Edit DCR policy"
  defp next_safe_action(_policy, _summary), do: "Mint initial access token"

  defp next_safe_action_detail(_policy, %{iats: %{active: active}}) when active > 0,
    do:
      "Review active intake tokens and revoke any handoff that should no longer register clients."

  defp next_safe_action_detail(%{registration_policy: :disabled}, _summary),
    do: "Open or gate registration in policy before partner intake starts."

  defp next_safe_action_detail(_policy, _summary),
    do: "Mint a bounded intake token, then return here to review self-registered clients."

  defp iat_status(token) do
    cond do
      token.revoked_at != nil ->
        :revoked

      token.used_at != nil ->
        :used

      token.expires_at != nil and DateTime.compare(token.expires_at, DateTime.utc_now()) == :lt ->
        :expired

      true ->
        :active
    end
  end

  defp admin_path(path), do: Lockspire.mount_path() <> "/admin" <> path
end
