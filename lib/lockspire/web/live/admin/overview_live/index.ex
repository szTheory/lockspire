defmodule Lockspire.Web.Live.Admin.OverviewLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Overview",
       current_section: :overview,
       summary: load_summary()
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, summary: load_summary())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <section class="lockspire-admin-hero">
        <div>
          <p class="lockspire-admin-eyebrow">Operator cockpit</p>
          <h2>Run the embedded provider with the important state in view.</h2>
          <p>
            Start with client posture, issuer security, token incidents, key readiness, and live
            protocol work. Each card points to the workflow that owns the next action.
          </p>
        </div>
        <AdminComponents.admin_button href={admin_path("/clients")} variant={:primary}>
          Review clients
        </AdminComponents.admin_button>
      </section>

      <div class="lockspire-admin-summary-grid lockspire-admin-summary-grid-wide">
        <div class="lockspire-admin-summary-stat">
          <span class="lockspire-admin-summary-value">{@summary.clients.total}</span>
          <span class="lockspire-admin-summary-label">clients</span>
        </div>
        <div class="lockspire-admin-summary-stat">
          <span class="lockspire-admin-summary-value">{@summary.clients.self_registered}</span>
          <span class="lockspire-admin-summary-label">self-registered</span>
        </div>
        <div class="lockspire-admin-summary-stat">
          <span class="lockspire-admin-summary-value">{@summary.tokens.reuse_detected}</span>
          <span class="lockspire-admin-summary-label">reuse incidents</span>
        </div>
        <div class="lockspire-admin-summary-stat">
          <span class="lockspire-admin-summary-value">{@summary.logouts.failed}</span>
          <span class="lockspire-admin-summary-label">logout failures</span>
        </div>
      </div>

      <div class="lockspire-admin-dashboard-grid">
        <AdminComponents.section_card
          title="Security posture"
          subtitle="Issuer-wide defaults and client overrides that shape protocol behavior."
        >
          <dl class="lockspire-admin-description-list">
            <div>
              <dt>PAR</dt>
              <dd>{@summary.policy.par_policy}</dd>
            </div>
            <div>
              <dt>DPoP</dt>
              <dd>{@summary.policy.dpop_policy}</dd>
            </div>
            <div>
              <dt>Security profile</dt>
              <dd>{@summary.policy.security_profile}</dd>
            </div>
            <div>
              <dt>Access token format</dt>
              <dd>{@summary.policy.access_token_format}</dd>
            </div>
          </dl>
          <AdminComponents.action_bar>
            <AdminComponents.admin_button href={admin_path("/policies")}>
              Open security
            </AdminComponents.admin_button>
          </AdminComponents.action_bar>
        </AdminComponents.section_card>

        <AdminComponents.section_card
          title="Key readiness"
          subtitle="JWKS-visible material and rollover state."
        >
          <dl class="lockspire-admin-description-list">
            <div>
              <dt>Active keys</dt>
              <dd>{@summary.keys.active}</dd>
            </div>
            <div>
              <dt>Upcoming keys</dt>
              <dd>{@summary.keys.upcoming}</dd>
            </div>
            <div>
              <dt>Retiring keys</dt>
              <dd>{@summary.keys.retiring}</dd>
            </div>
          </dl>
          <AdminComponents.action_bar>
            <AdminComponents.admin_button href={admin_path("/keys")}>Manage keys</AdminComponents.admin_button>
          </AdminComponents.action_bar>
        </AdminComponents.section_card>

        <AdminComponents.section_card
          title="Support queue"
          subtitle="State most likely to drive an operator investigation."
        >
          <div class="lockspire-admin-resource-list">
            <a href={admin_path("/tokens?status=reuse_detected")}>
              <span>Refresh reuse incidents</span>
              <strong>{@summary.tokens.reuse_detected}</strong>
            </a>
            <a href={admin_path("/consents?status=active")}>
              <span>Active consent grants</span>
              <strong>{@summary.consents.active}</strong>
            </a>
            <a href={admin_path("/logouts")}>
              <span>Retryable or discarded logouts</span>
              <strong>{@summary.logouts.failed}</strong>
            </a>
          </div>
        </AdminComponents.section_card>

        <AdminComponents.section_card
          title="Live operations"
          subtitle="Protocol state currently waiting on a user, client, or worker."
        >
          <div class="lockspire-admin-resource-list">
            <a href={admin_path("/interactions")}>
              <span>Open interactions</span>
              <strong>{@summary.operations.interactions}</strong>
            </a>
            <a href={admin_path("/device_authorizations")}>
              <span>Pending device requests</span>
              <strong>{@summary.operations.device_authorizations}</strong>
            </a>
            <a href={admin_path("/dcr")}>
              <span>Active initial access tokens</span>
              <strong>{@summary.dcr.active_iats}</strong>
            </a>
          </div>
        </AdminComponents.section_card>
      </div>
    </AdminLayoutLive.shell>
    """
  end

  defp load_summary do
    clients = ok_list(Admin.list_clients())
    tokens = ok_list(Admin.list_tokens())
    consents = ok_list(Admin.list_consents())
    keys = ok_list(Admin.list_keys())
    iats = ok_list(Lockspire.Admin.InitialAccessTokens.list_iats())
    interactions = ok_list(Repository.list_interactions())
    device_authorizations = ok_list(Admin.list_device_authorizations())
    logouts = ok_list(Repository.list_all_logout_deliveries())
    policy = ok_policy(Admin.get_server_policy())

    %{
      clients: %{
        total: length(clients),
        self_registered: Enum.count(clients, &(&1.provenance == :self_registered))
      },
      policy: %{
        par_policy: policy.par_policy,
        dpop_policy: policy.dpop_policy,
        security_profile: policy.security_profile,
        access_token_format: policy.access_token_format
      },
      keys: %{
        active: count_keys(keys, :active),
        upcoming: count_keys(keys, :upcoming),
        retiring: count_keys(keys, :retiring)
      },
      tokens: %{
        active: Enum.count(tokens, &(&1.status == :active)),
        reuse_detected: Enum.count(tokens, &(&1.status == :reuse_detected))
      },
      consents: %{active: Enum.count(consents, &(&1.grant.status == :active))},
      logouts: %{failed: Enum.count(logouts, &(&1.status in [:retryable, :discarded]))},
      operations: %{
        interactions:
          Enum.count(interactions, &(&1.status in [:pending_login, :pending_consent])),
        device_authorizations: Enum.count(device_authorizations, &(&1.status == :pending))
      },
      dcr: %{active_iats: Enum.count(iats, &(iat_status(&1) == :active))}
    }
  end

  defp ok_list({:ok, list}) when is_list(list), do: list
  defp ok_list(_result), do: []

  defp ok_policy({:ok, %ServerPolicy{} = policy}), do: policy
  defp ok_policy(_result), do: %ServerPolicy{}

  defp count_keys(keys, status), do: Enum.count(keys, &(&1.key.status == status))

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
