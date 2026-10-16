defmodule Lockspire.Web.Live.Admin.OverviewLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
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
      <div class="lockspire-admin-dashboard-grid lockspire-admin-overview-grid">
        <AdminComponents.section_card title="Security events">
          <div class="lockspire-admin-resource-list lockspire-admin-overview-review-list">
            <div class="lockspire-admin-overview-review-row">
              <span class="lockspire-admin-overview-review-label">
                <a href={admin_path("/tokens?status=reuse_detected")}>Refresh tokens used more than once</a>
                <AdminComponents.info_tooltip :if={@summary.tokens.state == :loaded} id="refresh-token-reuse-help" label="About refresh token reuse">
                  Refresh tokens let apps keep access. Reuse after replacement can indicate theft or a repeated app request; it does not prove theft.
                  <%= if observation_value(@summary.tokens, :reuse_detected) > 0 do %>
                    Lockspire revoked every token in its family. Open the records to investigate.
                  <% else %>
                    Lockspire revokes related tokens when this happens.
                  <% end %>
                  The count includes past detections, not just unresolved cases.
                </AdminComponents.info_tooltip>
              </span>
              <strong>{observation_value(@summary.tokens, :reuse_detected)}</strong>
              <small :if={@summary.tokens.state == :loaded}>
                {if observation_value(@summary.tokens, :reuse_detected) > 0, do: "Related tokens revoked", else: "No repeat use detected"}
              </small>
              <small :if={@summary.tokens.state != :loaded} role="status">
                {observation_note(@summary.tokens, "refresh token records")}
              </small>
            </div>
          </div>
        </AdminComponents.section_card>

        <AdminComponents.section_card title="Sign-out problems">
          <div class="lockspire-admin-resource-list lockspire-admin-overview-review-list">
            <div class="lockspire-admin-overview-review-row">
              <span class="lockspire-admin-overview-review-label">
                <a href={admin_path("/logouts?status=needs_review")}>App sign-out notices needing review</a>
                <AdminComponents.info_tooltip :if={@summary.logouts.state == :loaded} id="logout-delivery-help" label="About app sign-out problems">
                  <%= if observation_value(@summary.logouts, :failed) > 0 do %>
                    These notices could not be delivered successfully. An app session may still be open.
                  <% else %>
                    Sign-out notices ask apps to end their local session when a user signs out.
                  <% end %>
                  Failed notices may be retried; discarded notices will not be sent again.
                  Open the delivery records to identify the app and the failure.
                  This count includes retained failures, not a count of users still signed in.
                </AdminComponents.info_tooltip>
              </span>
              <strong>{observation_value(@summary.logouts, :failed)}</strong>
              <small :if={@summary.logouts.state == :loaded}>
                {if observation_value(@summary.logouts, :failed) > 0, do: "Sign-out notices failed or were discarded", else: "No failed notices"}
              </small>
              <small :if={@summary.logouts.state != :loaded} role="status">
                {observation_note(@summary.logouts, "app sign-out notices")}
              </small>
            </div>
          </div>
        </AdminComponents.section_card>

        <AdminComponents.section_card title="Waiting for users" subtitle="Sign-in, consent, and device approval happen in your app.">
          <div class="lockspire-admin-resource-list">
            <a href={admin_path("/interactions?status=pending")}>
              <span>{count_label(@summary.interactions, :open, "Sign-in or consent request", "Sign-in or consent requests")}</span>
              <strong>{observation_value(@summary.interactions, :open)}</strong>
              <small :if={@summary.interactions.state != :loaded} role="status">
                {observation_note(@summary.interactions, "sign-in requests")}
              </small>
            </a>
            <a href={admin_path("/device_authorizations?status=pending")}>
              <span>{count_label(@summary.devices, :pending, "Device sign-in waiting for approval", "Device sign-ins waiting for approval")}</span>
              <strong>{observation_value(@summary.devices, :pending)}</strong>
              <small :if={@summary.devices.state != :loaded} role="status">
                {observation_note(@summary.devices, "device authorization requests")}
              </small>
            </a>
          </div>
        </AdminComponents.section_card>

        <AdminComponents.section_card title="Apps and access">
          <div class="lockspire-admin-resource-list lockspire-admin-overview-review-list">
            <a href={admin_path("/clients")}>
              <span>{count_label(@summary.clients, :total, "Registered app", "Registered apps")}</span>
              <strong>{observation_value(@summary.clients, :total)}</strong>
              <small :if={@summary.clients.state != :loaded} role="status">
                {observation_note(@summary.clients, "app records")}
              </small>
            </a>
            <div class="lockspire-admin-overview-review-row">
              <span class="lockspire-admin-overview-review-label">
                <a href={admin_path("/consents?status=active")}>{count_label(@summary.consents, :active, "Active consent grant", "Active consent grants")}</a>
                <AdminComponents.info_tooltip id="consent-grant-help" label="About consent grants">
                  Each grant records a user's permission for an app to access specific data.
                  Open a grant to inspect or revoke that permission.
                </AdminComponents.info_tooltip>
              </span>
              <strong>{observation_value(@summary.consents, :active)}</strong>
              <small :if={@summary.consents.state != :loaded} role="status">
                {observation_note(@summary.consents, "consent grants")}
              </small>
            </div>
            <div class="lockspire-admin-overview-review-row">
              <span class="lockspire-admin-overview-review-label">
                <a href={admin_path("/keys")}>{count_label(@summary.keys, :active, "Active token-signing key", "Active token-signing keys")}</a>
                <AdminComponents.info_tooltip id="signing-key-help" label="About token-signing keys">
                  Apps use a signing key's public part to verify that a token came from your server.
                  Open Keys to manage keys and review upcoming or retiring keys.
                </AdminComponents.info_tooltip>
              </span>
              <strong>{observation_value(@summary.keys, :active)}</strong>
              <small :if={@summary.keys.state == :loaded && observation_value(@summary.keys, :active) == 0}>
                Review key setup before issuing tokens
              </small>
              <small :if={@summary.keys.state != :loaded} role="status">
                {observation_note(@summary.keys, "signing keys")}
              </small>
            </div>
          </div>
        </AdminComponents.section_card>
      </div>
    </AdminLayoutLive.shell>
    """
  end

  defp load_summary do
    now = DateTime.utc_now()

    %{
      clients:
        observe_list(fn -> Admin.list_clients() end, fn clients ->
          %{total: length(clients)}
        end),
      tokens:
        observe_list(fn -> Admin.list_tokens() end, fn tokens ->
          %{reuse_detected: Enum.count(tokens, &(&1.status == :reuse_detected))}
        end),
      consents:
        observe_list(fn -> Admin.list_consents() end, fn consents ->
          %{active: Enum.count(consents, &(&1.grant.status == :active))}
        end),
      keys:
        observe_list(fn -> Admin.list_keys() end, fn keys ->
          %{active: Enum.count(keys, &(&1.key.status == :active && &1.key.use == :sig))}
        end),
      interactions:
        observe_list(fn -> Admin.list_interactions() end, fn interactions ->
          %{
            open:
              Enum.count(
                interactions,
                &(&1.status in [:pending_login, :pending_consent] &&
                    DateTime.compare(&1.expires_at, now) == :gt)
              )
          }
        end),
      devices:
        observe_list(fn -> Admin.list_device_authorizations() end, fn device_authorizations ->
          %{
            pending:
              Enum.count(
                device_authorizations,
                &(&1.status == :pending && DateTime.compare(&1.expires_at, now) == :gt)
              )
          }
        end),
      logouts:
        observe_list(fn -> Admin.list_logout_deliveries() end, fn logouts ->
          %{failed: Enum.count(logouts, &(&1.status in [:retryable, :discarded]))}
        end)
    }
  end

  defp loading_summary do
    loading = %{state: :loading}

    %{
      clients: loading,
      tokens: loading,
      consents: loading,
      keys: loading,
      interactions: loading,
      devices: loading,
      logouts: loading
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

  defp observation_value(%{state: :loaded, values: values}, key), do: Map.fetch!(values, key)
  defp observation_value(%{state: :loading}, _key), do: "Loading"
  defp observation_value(_observation, _key), do: "Unavailable"

  defp observation_note(%{state: :loading}, source), do: "Loading #{source}…"

  defp observation_note(_observation, source),
    do: "Could not load #{source}. The current results are unavailable."

  defp count_label(%{state: :loaded, values: values}, key, singular, plural) do
    if Map.fetch!(values, key) == 1, do: singular, else: plural
  end

  defp count_label(_observation, _key, _singular, plural), do: plural

  defp admin_path(path), do: Lockspire.mount_path() <> "/admin" <> path
end
