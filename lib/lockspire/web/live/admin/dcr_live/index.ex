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
      <section class="lockspire-admin-hero">
        <div>
          <p class="lockspire-admin-eyebrow">Partner onboarding</p>
          <h2>Dynamic registration policy, Initial Access Tokens, and self-registered clients.</h2>
          <p>
            DCR is an onboarding journey: decide who may register, mint short-lived intake
            tokens, review what appeared, and rotate registration access tokens when needed.
          </p>
        </div>
        <AdminComponents.admin_button href={admin_path("/iats/new")} variant={:primary}>
          Mint IAT
        </AdminComponents.admin_button>
      </section>

      <div class="lockspire-admin-summary-grid">
        <div class="lockspire-admin-summary-stat">
          <span class="lockspire-admin-summary-value">{@policy.registration_policy}</span>
          <span class="lockspire-admin-summary-label">registration mode</span>
        </div>
        <div class="lockspire-admin-summary-stat">
          <span class="lockspire-admin-summary-value">{@summary.iats.active}</span>
          <span class="lockspire-admin-summary-label">active IATs</span>
        </div>
        <div class="lockspire-admin-summary-stat">
          <span class="lockspire-admin-summary-value">{@summary.clients.self_registered}</span>
          <span class="lockspire-admin-summary-label">self-registered clients</span>
        </div>
      </div>

      <div class="lockspire-admin-dashboard-grid">
        <AdminComponents.section_card
          title="Gate registration"
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
          title="Mint and revoke IATs"
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
            <AdminComponents.admin_button href={admin_path("/iats")}>Review IATs</AdminComponents.admin_button>
            <AdminComponents.admin_button href={admin_path("/iats/new")} variant={:primary}>
              Mint IAT
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
