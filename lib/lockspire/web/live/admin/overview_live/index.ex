defmodule Lockspire.Web.Live.Admin.OverviewLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Admin.InitialAccessTokens
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Overview",
       current_section: :overview,
       summary: loading_summary()
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
      <AdminComponents.page_hero
        eyebrow="Operator cockpit"
        title="Run the embedded provider with the important state in view."
        body="Start with client posture, issuer security, token incidents, key readiness, and live protocol work. Each card points to the workflow that owns the next action."
      >
        <:actions>
          <AdminComponents.admin_button href={admin_path("/clients")} variant={:primary}>
            Review clients
          </AdminComponents.admin_button>
        </:actions>
      </AdminComponents.page_hero>

      <AdminComponents.metric_grid wide>
        <div>
          <AdminComponents.summary_stat
            value={observation_value(@summary.clients, :total)}
            label={count_label(@summary.clients, :total, "client", "clients")}
          />
          <p role="status">{observation_note(@summary.clients, "client inventory")}</p>
        </div>
        <div>
          <AdminComponents.summary_stat
            value={observation_value(@summary.clients, :self_registered)}
            label={
              count_label(
                @summary.clients,
                :self_registered,
                "self-registered client",
                "self-registered clients"
              )
            }
          />
          <p role="status">{observation_note(@summary.clients, "client inventory")}</p>
        </div>
        <div>
          <AdminComponents.summary_stat
            value={observation_value(@summary.tokens, :reuse_detected)}
            label={count_label(@summary.tokens, :reuse_detected, "reuse incident", "reuse incidents")}
          />
          <p role="status">{observation_note(@summary.tokens, "token inventory")}</p>
        </div>
        <div>
          <AdminComponents.summary_stat
            value={observation_value(@summary.logouts, :failed)}
            label={count_label(@summary.logouts, :failed, "logout failure", "logout failures")}
          />
          <p role="status">{observation_note(@summary.logouts, "logout delivery inventory")}</p>
        </div>
      </AdminComponents.metric_grid>

      <div class="lockspire-admin-dashboard-grid">
        <AdminComponents.section_card
          title="Security posture"
          subtitle="Issuer-wide defaults and client overrides that shape protocol behavior."
        >
          <p role="status">{policy_observation_note(@summary.policy)}</p>
          <dl class="lockspire-admin-description-list">
            <div>
              <dt>PAR</dt>
              <dd>{policy_value(@summary.policy, :par_policy)}</dd>
            </div>
            <div>
              <dt>DPoP</dt>
              <dd>{policy_value(@summary.policy, :dpop_policy)}</dd>
            </div>
            <div>
              <dt>Security profile</dt>
              <dd>{policy_value(@summary.policy, :security_profile)}</dd>
            </div>
            <div>
              <dt>Access token format</dt>
              <dd>{policy_value(@summary.policy, :access_token_format)}</dd>
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
          <p role="status">{observation_note(@summary.keys, "signing-key inventory")}</p>
          <dl class="lockspire-admin-description-list">
            <div>
              <dt>Active keys</dt>
              <dd>{observation_value(@summary.keys, :active)}</dd>
            </div>
            <div>
              <dt>Upcoming keys</dt>
              <dd>{observation_value(@summary.keys, :upcoming)}</dd>
            </div>
            <div>
              <dt>Retiring keys</dt>
              <dd>{observation_value(@summary.keys, :retiring)}</dd>
            </div>
          </dl>
          <AdminComponents.action_bar>
            <AdminComponents.admin_button href={admin_path("/keys")}>Manage keys</AdminComponents.admin_button>
          </AdminComponents.action_bar>
        </AdminComponents.section_card>

        <AdminComponents.section_card
          title="Support queue"
          subtitle="Source-backed support counts with direct links to their investigation routes."
        >
          <div class="lockspire-admin-resource-list">
            <a href={admin_path("/tokens?status=reuse_detected")}>
              <span>Refresh reuse incidents</span>
              <strong>{observation_value(@summary.tokens, :reuse_detected)}</strong>
              <small>{observation_note(@summary.tokens, "token inventory")}</small>
            </a>
            <a href={admin_path("/consents?status=active")}>
              <span>Active consent grants</span>
              <strong>{observation_value(@summary.consents, :active)}</strong>
              <small>{observation_note(@summary.consents, "consent inventory")}</small>
            </a>
            <a href={admin_path("/logouts")}>
              <span>Retryable or discarded logouts</span>
              <strong>{observation_value(@summary.logouts, :failed)}</strong>
              <small>{observation_note(@summary.logouts, "logout delivery inventory")}</small>
            </a>
          </div>
        </AdminComponents.section_card>

        <AdminComponents.section_card
          title="Live operations"
          subtitle="Source-backed protocol observations with direct links to their read-only queues."
        >
          <div class="lockspire-admin-resource-list">
            <a href={admin_path("/interactions")}>
              <span>Open interactions</span>
              <strong>{observation_value(@summary.interactions, :open)}</strong>
              <small>{observation_note(@summary.interactions, "interaction inventory")}</small>
            </a>
            <a href={admin_path("/device_authorizations")}>
              <span>Pending device requests</span>
              <strong>{observation_value(@summary.devices, :pending)}</strong>
              <small>{observation_note(@summary.devices, "device authorization inventory")}</small>
            </a>
            <a href={admin_path("/dcr")}>
              <span>Active initial access tokens</span>
              <strong>{observation_value(@summary.iats, :active)}</strong>
              <small>{observation_note(@summary.iats, "Initial Access Token inventory")}</small>
            </a>
          </div>
        </AdminComponents.section_card>
      </div>
    </AdminLayoutLive.shell>
    """
  end

  defp load_summary do
    %{
      clients:
        observe_list(fn -> Admin.list_clients() end, fn clients ->
          %{
            total: length(clients),
            self_registered: Enum.count(clients, &(&1.provenance == :self_registered))
          }
        end),
      tokens:
        observe_list(fn -> Admin.list_tokens() end, fn tokens ->
          %{
            active: Enum.count(tokens, &(&1.status == :active)),
            reuse_detected: Enum.count(tokens, &(&1.status == :reuse_detected))
          }
        end),
      consents:
        observe_list(fn -> Admin.list_consents() end, fn consents ->
          %{active: Enum.count(consents, &(&1.grant.status == :active))}
        end),
      keys:
        observe_list(fn -> Admin.list_keys() end, fn keys ->
          %{
            active: count_keys(keys, :active),
            upcoming: count_keys(keys, :upcoming),
            retiring: count_keys(keys, :retiring)
          }
        end),
      iats:
        observe_list(fn -> Lockspire.Admin.InitialAccessTokens.list_iats() end, fn iats ->
          now = DateTime.utc_now()

          %{active: Enum.count(iats, &(InitialAccessTokens.lifecycle_status(&1, now) == :active))}
        end),
      interactions:
        observe_list(fn -> Admin.list_interactions() end, fn interactions ->
          %{open: Enum.count(interactions, &(&1.status in [:pending_login, :pending_consent]))}
        end),
      devices:
        observe_list(fn -> Admin.list_device_authorizations() end, fn device_authorizations ->
          %{pending: Enum.count(device_authorizations, &(&1.status == :pending))}
        end),
      logouts:
        observe_list(fn -> Admin.list_logout_deliveries() end, fn logouts ->
          %{failed: Enum.count(logouts, &(&1.status in [:retryable, :discarded]))}
        end),
      policy: observe_policy()
    }
  end

  defp loading_summary do
    loading = %{state: :loading}

    %{
      clients: loading,
      tokens: loading,
      consents: loading,
      keys: loading,
      iats: loading,
      interactions: loading,
      devices: loading,
      logouts: loading,
      policy: loading
    }
  end

  defp observe_list(reader, calculate) do
    case reader.() do
      {:ok, rows} when is_list(rows) -> %{state: :loaded, values: calculate.(rows)}
      _other -> %{state: :unavailable}
    end
  rescue
    _error -> %{state: :unavailable}
  end

  defp observe_policy do
    case Admin.get_server_policy() do
      {:ok, %ServerPolicy{} = policy} ->
        %{
          state: :loaded,
          provenance: if(is_nil(policy.id), do: :configured_default, else: :stored),
          values: %{
            par_policy: policy.par_policy,
            dpop_policy: policy.dpop_policy,
            security_profile: policy.security_profile,
            access_token_format: policy.access_token_format
          }
        }

      _other ->
        %{state: :unavailable}
    end
  rescue
    _error -> %{state: :unavailable}
  end

  defp observation_value(%{state: :loaded, values: values}, key), do: Map.fetch!(values, key)
  defp observation_value(%{state: :loading}, _key), do: "Loading"
  defp observation_value(_observation, _key), do: "Unavailable"

  defp observation_note(%{state: :loaded}, source), do: "Measured from #{source}."
  defp observation_note(%{state: :loading}, source), do: "Loading #{source}…"
  defp observation_note(_observation, source), do: "#{String.capitalize(source)} unavailable."

  defp policy_value(%{state: :loaded, values: values}, key), do: Map.fetch!(values, key)
  defp policy_value(%{state: :loading}, _key), do: "Loading"
  defp policy_value(_observation, _key), do: "Unavailable"

  defp policy_observation_note(%{state: :loading}), do: "Loading server policy…"

  defp policy_observation_note(%{state: :loaded, provenance: :configured_default}),
    do: "Configured defaults; no stored server policy row was found."

  defp policy_observation_note(%{state: :loaded, provenance: :stored}),
    do: "Stored server policy."

  defp policy_observation_note(_observation), do: "Security policy unavailable."

  defp count_label(%{state: :loaded, values: values}, key, singular, plural) do
    if Map.fetch!(values, key) == 1, do: singular, else: plural
  end

  defp count_label(_observation, _key, _singular, plural), do: plural

  defp count_keys(keys, status), do: Enum.count(keys, &(&1.key.status == status))

  defp admin_path(path), do: Lockspire.mount_path() <> "/admin" <> path
end
