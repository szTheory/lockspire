defmodule Lockspire.Web.Live.Admin.DcrLive.Index do
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
     socket
     |> assign(
       page_title: "Dynamic Registration",
       current_section: :dcr,
       policy_observation: %{state: :loading, policy: nil},
       client_observation: %{state: :loading, clients: nil, count: nil},
       iat_observation: %{state: :loading, counts: nil}
     )
     |> load_observations()}
  end

  @impl true
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_event("reload_dcr_status", _params, socket) do
    {:noreply,
     socket
     |> assign(
       policy_observation: %{state: :loading, policy: nil},
       client_observation: %{state: :loading, clients: nil, count: nil},
       iat_observation: %{state: :loading, counts: nil}
     )
     |> load_observations()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero
        eyebrow="Configure"
        title="DCR onboarding"
        body="Initial Access Tokens authorize initial registration requests. Registration Access Tokens manage one registered client's configuration endpoint. Client secrets authenticate confidential clients at the token endpoint."
      >
        <:actions>
          <AdminComponents.admin_button type="button" phx-click="reload_dcr_status">
            Reload DCR status
          </AdminComponents.admin_button>
        </:actions>
        <:summary>
          <AdminComponents.decision_summary>
            <:item
              :for={item <- decision_summary_items(@policy_observation, @iat_observation, @client_observation)}
              label={item.label}
              value={item.value}
              detail={item.detail}
              tone={item.tone}
            >
            </:item>
          </AdminComponents.decision_summary>
        </:summary>
      </AdminComponents.page_hero>

      <AdminComponents.metric_grid>
        <AdminComponents.summary_stat
          value={policy_metric(@policy_observation)}
          label="registration gate"
        />
        <AdminComponents.summary_stat
          value={active_iat_metric(@iat_observation)}
          label="active Initial Access Tokens"
        />
        <AdminComponents.summary_stat
          value={client_metric(@client_observation)}
          label="self-registered clients"
        />
      </AdminComponents.metric_grid>

      <div class="lockspire-admin-dashboard-grid">
        <AdminComponents.section_card
          title="DCR policy"
          subtitle="Issuer policy controls who may start dynamic registration and which requested metadata is accepted."
        >
          <AdminComponents.alert
            :if={@policy_observation.state == :unavailable}
            variant={:danger}
            title="Registration policy unavailable"
          >
            Lockspire could not confirm the current registration gate. No mode is assumed; reload this status or review issuer policy before partner onboarding.
          </AdminComponents.alert>

          <div :if={@policy_observation.state == :loaded}>
            <p class="lockspire-admin-help">
              Current gate: <strong>{registration_policy_label(@policy_observation.policy.registration_policy)}</strong>.
              {registration_policy_detail(@policy_observation.policy.registration_policy)}
            </p>
            <p class="lockspire-admin-help">
              Open registration still follows issuer metadata allowlists and configured lifetimes.
            </p>
          </div>

          <AdminComponents.action_bar>
            <AdminComponents.admin_button href={admin_path("/policies/dcr")}>
              Edit DCR policy
            </AdminComponents.admin_button>
          </AdminComponents.action_bar>
        </AdminComponents.section_card>

        <AdminComponents.section_card
          title="Initial Access Token inventory"
          subtitle="An Initial Access Token authorizes an initial registration request; it does not manage an existing client."
        >
          <AdminComponents.alert
            :if={@iat_observation.state == :unavailable}
            variant={:danger}
            title="Initial Access Token inventory unavailable"
          >
            Lockspire could not read intake-token status, so no count is shown. Review the inventory or reload this status before handing a token to a partner.
          </AdminComponents.alert>

          <dl
            :if={@iat_observation.state == :loaded}
            class="lockspire-admin-description-list"
          >
            <div>
              <dt>Active</dt>
              <dd>{@iat_observation.counts.active}</dd>
            </div>
            <div>
              <dt>Revoked</dt>
              <dd>{@iat_observation.counts.revoked}</dd>
            </div>
            <div>
              <dt>Expired or used</dt>
              <dd>{@iat_observation.counts.closed}</dd>
            </div>
          </dl>

          <AdminComponents.action_bar>
            <AdminComponents.admin_button href={admin_path("/iats")}>
              Review initial access tokens
            </AdminComponents.admin_button>
            <AdminComponents.admin_button href={admin_path("/iats/new")} variant={:primary}>
              Create initial access token
            </AdminComponents.admin_button>
          </AdminComponents.action_bar>
        </AdminComponents.section_card>

        <AdminComponents.section_card
          title="Review self-registered clients"
          subtitle="Registration Access Tokens manage one registered client's configuration endpoint. Open a client record to review its safe identity and supported follow-up actions."
        >
          <AdminComponents.alert
            :if={@client_observation.state == :unavailable}
            variant={:danger}
            title="Self-registered client inventory unavailable"
          >
            Lockspire could not read the client inventory, so no count or empty state is shown. Reload this status to try again.
          </AdminComponents.alert>

          <div
            :if={@client_observation.state == :loaded and @client_observation.clients != []}
            class="lockspire-admin-resource-list"
          >
            <a
              :for={client <- @client_observation.clients}
              href={admin_path("/clients/" <> URI.encode(client.client_id, &URI.char_unreserved?/1))}
            >
              <span>
                <strong>{client.name || client.client_id}</strong>
                <small>{client.client_id}</small>
              </span>
              <strong>{if client.active, do: "Active", else: "Disabled"}</strong>
            </a>
          </div>

          <AdminComponents.empty_state
            :if={@client_observation.state == :loaded and @client_observation.clients == []}
            title="No self-registered clients yet"
            body="When DCR creates clients, review each registered client's details here."
          />
        </AdminComponents.section_card>
      </div>
    </AdminLayoutLive.shell>
    """
  end

  defp load_observations(socket) do
    assign(socket,
      policy_observation: load_policy_observation(),
      client_observation: load_client_observation(),
      iat_observation: load_iat_observation()
    )
  end

  defp load_policy_observation do
    case safe_read(fn -> Admin.get_server_policy() end) do
      {:ok, %ServerPolicy{} = policy} -> %{state: :loaded, policy: policy}
      _result -> %{state: :unavailable, policy: nil}
    end
  end

  defp load_client_observation do
    case safe_read(fn -> Admin.list_clients() end) do
      {:ok, clients} when is_list(clients) ->
        self_registered_clients = Enum.filter(clients, &(&1.provenance == :self_registered))

        %{
          state: :loaded,
          clients: self_registered_clients,
          count: length(self_registered_clients)
        }

      _result ->
        %{state: :unavailable, clients: nil, count: nil}
    end
  end

  defp load_iat_observation do
    case safe_read(fn -> InitialAccessTokens.list_iats() end) do
      {:ok, iats} when is_list(iats) ->
        counts = %{
          active: Enum.count(iats, &(iat_status(&1) == :active)),
          revoked: Enum.count(iats, &(iat_status(&1) == :revoked)),
          closed: Enum.count(iats, &(iat_status(&1) in [:expired, :used]))
        }

        %{state: :loaded, counts: counts}

      _result ->
        %{state: :unavailable, counts: nil}
    end
  end

  defp safe_read(fun) do
    fun.()
  rescue
    _error -> {:error, :unavailable}
  catch
    _kind, _reason -> {:error, :unavailable}
  end

  defp decision_summary_items(policy, iats, clients) do
    [
      %{
        label: "Registration gate",
        value: policy_metric(policy),
        detail: policy_detail(policy),
        tone: policy_tone(policy)
      },
      %{
        label: "Initial Access Tokens",
        value: active_iat_metric(iats),
        detail: iat_detail(iats),
        tone: iat_tone(iats)
      },
      %{
        label: "Self-registered clients",
        value: client_metric(clients),
        detail: client_detail(clients),
        tone: client_tone(clients)
      },
      %{
        label: "Next safe action",
        value: next_safe_action(policy, iats, clients),
        detail: next_safe_action_detail(policy, iats, clients),
        tone: :info
      }
    ]
  end

  defp policy_metric(%{state: :loaded, policy: %ServerPolicy{registration_policy: mode}}),
    do: registration_policy_label(mode)

  defp policy_metric(_policy), do: "Unavailable"

  defp active_iat_metric(%{state: :loaded, counts: %{active: count}}), do: count
  defp active_iat_metric(_iats), do: "Unavailable"

  defp client_metric(%{state: :loaded, count: count}), do: count
  defp client_metric(_clients), do: "Unavailable"

  defp policy_detail(%{state: :loaded, policy: %ServerPolicy{registration_policy: mode}}),
    do: registration_policy_detail(mode)

  defp policy_detail(_policy),
    do: "The issuer gate could not be read; confirm it before partner onboarding."

  defp iat_detail(%{state: :loaded, counts: counts}) do
    "#{counts.revoked} revoked, #{counts.closed} expired or used. An IAT authorizes initial registration only."
  end

  defp iat_detail(_iats), do: "The inventory could not be read; no token count is assumed."

  defp client_detail(%{state: :loaded, count: count}) do
    "#{count} self-registered #{if count == 1, do: "client is", else: "clients are"} available for client-detail review."
  end

  defp client_detail(_clients), do: "The client inventory could not be read; no count is assumed."

  defp policy_tone(%{
         state: :loaded,
         policy: %ServerPolicy{registration_policy: :initial_access_token}
       }),
       do: :success

  defp policy_tone(%{state: :loaded, policy: %ServerPolicy{registration_policy: :open}}),
    do: :warning

  defp policy_tone(%{state: :loaded}), do: nil
  defp policy_tone(_policy), do: nil

  defp iat_tone(%{state: :loaded, counts: %{active: active}}) when active > 0, do: :success
  defp iat_tone(%{state: :loaded}), do: :info
  defp iat_tone(_iats), do: nil

  defp client_tone(%{state: :loaded, count: count}) when count > 0, do: :success
  defp client_tone(%{state: :loaded}), do: :info
  defp client_tone(_clients), do: nil

  defp next_safe_action(%{state: :unavailable}, _iats, _clients), do: "Review issuer policy"

  defp next_safe_action(
         %{state: :loaded, policy: %{registration_policy: :disabled}},
         _iats,
         _clients
       ),
       do: "Edit DCR policy"

  defp next_safe_action(
         %{state: :loaded, policy: %{registration_policy: :open}},
         _iats,
         _clients
       ),
       do: "Review DCR policy"

  defp next_safe_action(
         %{state: :loaded, policy: %{registration_policy: :initial_access_token}},
         %{state: :loaded, counts: %{active: active}},
         _clients
       )
       when active > 0,
       do: "Review initial access tokens"

  defp next_safe_action(%{state: :loaded}, %{state: :unavailable}, _clients),
    do: "Review intake token inventory"

  defp next_safe_action(_policy, _iats, %{state: :loaded, count: count}) when count > 0,
    do: "Review self-registered clients"

  defp next_safe_action(_policy, _iats, _clients), do: "Mint initial access token"

  defp next_safe_action_detail(%{state: :unavailable}, _iats, _clients),
    do: "Confirm the issuer registration gate before partner intake."

  defp next_safe_action_detail(
         %{state: :loaded, policy: %{registration_policy: :disabled}},
         _iats,
         _clients
       ),
       do: "Registration is disabled until issuer policy is intentionally changed."

  defp next_safe_action_detail(
         %{state: :loaded, policy: %{registration_policy: :open}},
         _iats,
         _clients
       ),
       do:
         "Open registration does not require an Initial Access Token. Review issuer metadata allowlists before partner onboarding."

  defp next_safe_action_detail(_policy, %{state: :unavailable}, _clients),
    do: "The intake-token status is unavailable; verify it before a partner handoff."

  defp next_safe_action_detail(_policy, _iats, %{state: :loaded, count: count}) when count > 0,
    do: "Open a self-registered client record for safe identity and supported follow-up actions."

  defp next_safe_action_detail(_policy, _iats, _clients),
    do: "Mint a bounded Initial Access Token, then review self-registered clients here."

  defp registration_policy_label(:initial_access_token), do: "Initial Access Token required"
  defp registration_policy_label(:open), do: "Open registration"
  defp registration_policy_label(:disabled), do: "Registration disabled"
  defp registration_policy_label(_policy), do: "Registration mode unknown"

  defp registration_policy_detail(:initial_access_token),
    do: "Partners need a short-lived intake token before dynamic registration can create clients."

  defp registration_policy_detail(:open),
    do:
      "Unauthenticated registration requests are accepted within issuer metadata allowlists and lifetime settings."

  defp registration_policy_detail(:disabled),
    do: "Dynamic registration is closed until the DCR policy is intentionally changed."

  defp registration_policy_detail(_policy), do: "Review issuer policy before partner intake."

  defp iat_status(token) do
    cond do
      token.revoked_at != nil ->
        :revoked

      token.used_at != nil ->
        :used

      token.expires_at != nil and DateTime.compare(token.expires_at, DateTime.utc_now()) != :gt ->
        :expired

      true ->
        :active
    end
  end

  defp admin_path(path), do: Lockspire.mount_path() <> "/admin" <> path
end
