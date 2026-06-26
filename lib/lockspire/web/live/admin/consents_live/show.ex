defmodule Lockspire.Web.Live.Admin.ConsentsLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Redaction
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Consent detail",
       current_section: :consents,
       consent_id: parse_id(id),
       consent: nil,
       revoke_error: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    consent_id = parse_id(Map.get(params, "id", socket.assigns.consent_id))

    {:noreply,
     socket
     |> assign(consent_id: consent_id, revoke_error: nil)
     |> load_consent(consent_id)}
  end

  @impl true
  def handle_event("revoke_consent", %{"revoke" => %{"confirm" => "true"}}, socket) do
    case Admin.revoke_consent(socket.assigns.consent_id, %{
           revoked_by: "operator",
           revoked_reason: "operator_revoked"
         }) do
      {:ok, consent} ->
        {:noreply, assign(socket, consent: consent, revoke_error: nil)}

      {:error, _reason} ->
        {:noreply, assign(socket, revoke_error: "Consent could not be revoked.")}
    end
  end

  def handle_event("revoke_consent", _params, socket) do
    {:noreply,
     assign(socket,
       revoke_error: "Confirm the revoke action before changing durable consent state."
     )}
  end

  @impl true
  def render(%{consent: nil} = assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.empty_state
        title="Consent not found"
        body="Lockspire could not load that durable consent grant."
      />
    </AdminLayoutLive.shell>
    """
  end

  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero
        eyebrow="Support"
        title="Stored grant decision"
        body="Review whether this consent grant remains healthy and whether revocation is the next safe action."
      >
        <:summary>
          <span>Status: <AdminComponents.status_badge status={@consent.grant.status} /></span>
          <span>Scopes: {scope_label(@consent.grant.scopes)}</span>
        </:summary>
        <:actions>
          <AdminComponents.admin_button href={consents_index_path()}>
            Review stored grant
          </AdminComponents.admin_button>
        </:actions>
      </AdminComponents.page_hero>

      <AdminComponents.entity_header
        title={@consent.client && (@consent.client.name || @consent.client.client_id) || @consent.grant.client_id}
        subtitle="Durable consent truth for support workflows. This screen does not infer from event history."
        identifier={redacted_handle(:consent_grant, @consent.grant.id)}
      >
        <:status>
          <AdminComponents.status_badge status={@consent.grant.status} />
          <AdminComponents.status_badge status={@consent.grant.kind} />
        </:status>
      </AdminComponents.entity_header>

      <AdminComponents.pane
        title="Durable grant identity and current state"
        subtitle="Use redacted grant, account, and client handles as support pivots without exposing raw credential material."
      >
        <AdminComponents.description_list>
          <:item label="Grant ID">
            <AdminComponents.long_value
              value={redacted_handle(:consent_grant, @consent.grant.id)}
              kind={:id}
            />
          </:item>
          <:item label="Account">
            <AdminComponents.long_value
              value={redacted_handle(:account, @consent.grant.account_id)}
              kind={:id}
            />
          </:item>
          <:item label="Client ID">
            <AdminComponents.long_value
              value={redacted_handle(:client, @consent.grant.client_id)}
              kind={:id}
            />
          </:item>
          <:item label="Grant kind"><AdminComponents.status_badge status={@consent.grant.kind} /></:item>
          <:item label="Status"><AdminComponents.status_badge status={@consent.grant.status} /></:item>
          <:item label="Granted at">
            <AdminComponents.timestamp value={@consent.grant.granted_at} />
          </:item>
          <:item label="Revoked at">
            <AdminComponents.timestamp value={@consent.grant.revoked_at} />
          </:item>
          <:item label="Revoked by"><code>{@consent.grant.revoked_by || "Not recorded"}</code></:item>
          <:item label="Revoked reason">
            <code>{@consent.grant.revoked_reason || "Not recorded"}</code>
          </:item>
        </AdminComponents.description_list>
      </AdminComponents.pane>

      <AdminComponents.pane
        title="Scope context"
        subtitle="Scopes explain what this remembered grant may authorize if it remains active."
      >
        <AdminComponents.long_value value={scope_label(@consent.grant.scopes)} kind={:text} />
      </AdminComponents.pane>

      <AdminComponents.pane
        title="Revoke consent grant"
        subtitle="Use this only when the durable grant should stop authorizing future reuse."
      >
        <p :if={@consent.grant.status == :revoked}>This consent is already revoked. Repeating the action is safe.</p>
        <p :if={@revoke_error}>{@revoke_error}</p>

        <AdminComponents.confirmation_panel title="Revoke consent grant" variant={:danger}>
          <:body>
            <form class="lockspire-admin-form-stack" phx-submit="revoke_consent">
              <label class="lockspire-admin-checkbox-field">
                <input type="checkbox" name="revoke[confirm]" value="true" />
                <span>
                  Revoke consent grant for client
                  {client_display(@consent)}, subject
                  {redacted_handle(:account, @consent.grant.account_id)}, and scopes
                  {scope_label(@consent.grant.scopes)}. This remembered grant will no longer
                  authorize future remembered-consent reuse.
                </span>
              </label>
              <AdminComponents.action_bar>
                <AdminComponents.admin_button type="submit" variant={:danger}>
                  {if @consent.grant.status == :revoked,
                    do: "Consent grant already revoked",
                    else: "Revoke consent grant"}
                </AdminComponents.admin_button>
              </AdminComponents.action_bar>
            </form>
          </:body>
        </AdminComponents.confirmation_panel>
      </AdminComponents.pane>
    </AdminLayoutLive.shell>
    """
  end

  defp load_consent(socket, nil), do: assign(socket, consent: nil)

  defp load_consent(socket, consent_id) do
    case Admin.get_consent(consent_id) do
      {:ok, consent} -> assign(socket, consent: consent)
      {:error, _reason} -> assign(socket, consent: nil)
    end
  end

  defp parse_id(value) when is_integer(value), do: value

  defp parse_id(value) when is_binary(value) do
    case Integer.parse(value) do
      {id, _rest} -> id
      :error -> nil
    end
  end

  defp parse_id(_value), do: nil

  defp client_display(consent) do
    (consent.client && (consent.client.name || consent.client.client_id)) ||
      redacted_handle(:client, consent.grant.client_id)
  end

  defp redacted_handle(_type, nil), do: "Not recorded"
  defp redacted_handle(type, value), do: Redaction.handle(type, value)

  defp scope_label([]), do: "No scopes recorded"
  defp scope_label(scopes), do: Enum.join(scopes, ", ")

  defp consents_index_path, do: Lockspire.mount_path() <> "/admin/consents"
end
