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
       page_title: "App registration",
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
      <AdminComponents.page_hero body="Choose who can register apps, create a setup token, or review apps registered by their teams.">
        <:actions>
          <AdminComponents.admin_button type="button" phx-click="reload_dcr_status">
            Reload status
          </AdminComponents.admin_button>
        </:actions>
      </AdminComponents.page_hero>

      <div class="lockspire-admin-dashboard-grid">
        <AdminComponents.section_card
          title="Who can register apps?"
          subtitle="This affects new apps only; existing apps stay as they are."
        >
          <AdminComponents.alert
            :if={@policy_observation.state == :unavailable}
            variant={:danger}
            title="Could not load registration rules"
          >
            Lockspire could not check whether new apps can register. Reload this page to try again.
          </AdminComponents.alert>

          <div :if={@policy_observation.state == :loaded}>
            <p class="lockspire-admin-help">
              <strong>{registration_policy_summary(@policy_observation.policy.registration_policy)}</strong>
              {registration_policy_detail(@policy_observation.policy.registration_policy)}
            </p>
          </div>

          <AdminComponents.action_bar>
            <AdminComponents.admin_button href={admin_path("/policies/dcr")}>
              Change registration rules
            </AdminComponents.admin_button>
          </AdminComponents.action_bar>
        </AdminComponents.section_card>

        <AdminComponents.section_card
          title="App setup tokens"
          subtitle="A one-time token lets an app register. It cannot change an existing app."
        >
          <AdminComponents.alert
            :if={@iat_observation.state == :unavailable}
            variant={:danger}
            title="Could not load setup token status"
          >
            Lockspire could not read token status, so no count is shown. Check before sharing a token.
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
              Review setup tokens
            </AdminComponents.admin_button>
            <AdminComponents.admin_button
              :if={
                @policy_observation.state == :loaded and
                  @policy_observation.policy.registration_policy == :initial_access_token
              }
              href={admin_path("/iats/new")}
              variant={:primary}
            >
              Create setup token
            </AdminComponents.admin_button>
          </AdminComponents.action_bar>
        </AdminComponents.section_card>

        <AdminComponents.section_card
          title="Apps registered by their teams"
          subtitle="Open an app to check the settings saved during registration."
        >
          <AdminComponents.alert
            :if={@client_observation.state == :unavailable}
            variant={:danger}
            title="Could not load registered apps"
          >
            Lockspire could not read the app list, so no count or empty state is shown. Reload this page to try again.
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
            title="No apps have registered here yet"
            body="Apps registered through this page will appear here."
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

  defp registration_policy_summary(:initial_access_token), do: "A setup token is required."
  defp registration_policy_summary(:open), do: "App registration is open."
  defp registration_policy_summary(:disabled), do: "Apps cannot register right now."
  defp registration_policy_summary(_policy), do: "Registration rules are unavailable."

  defp registration_policy_detail(:initial_access_token),
    do: "Create one for an app that needs to register."

  defp registration_policy_detail(:open),
    do:
      "Apps can register without a setup token; allowed app details and expiry limits still apply."

  defp registration_policy_detail(:disabled),
    do: "Turn registration on before sharing a setup token."

  defp registration_policy_detail(_policy),
    do: "Registration settings are unavailable."

  defp iat_status(token) do
    InitialAccessTokens.lifecycle_status(token)
  end

  defp admin_path(path), do: Lockspire.mount_path() <> "/admin" <> path
end
