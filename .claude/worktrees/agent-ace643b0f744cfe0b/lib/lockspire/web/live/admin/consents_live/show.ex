defmodule Lockspire.Web.Live.Admin.ConsentsLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
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
      <AdminComponents.section_card
        title={@consent.client && (@consent.client.name || @consent.client.client_id) || @consent.grant.client_id}
        subtitle="Durable consent truth for support workflows. This screen does not infer from event history."
      >
        <p>Account: <code>{@consent.grant.account_id}</code></p>
        <p>Client ID: <code>{@consent.grant.client_id}</code></p>
        <p>Grant kind: <AdminComponents.status_badge status={@consent.grant.kind} /></p>
        <p>Status: <AdminComponents.status_badge status={@consent.grant.status} /></p>
        <p>Granted at: <AdminComponents.timestamp value={@consent.grant.granted_at} /></p>
        <p>Revoked at: <AdminComponents.timestamp value={@consent.grant.revoked_at} /></p>
        <p>Revoked by: <code>{@consent.grant.revoked_by || "Not recorded"}</code></p>
        <p>Revoked reason: <code>{@consent.grant.revoked_reason || "Not recorded"}</code></p>

        <h3>Scopes</h3>
        <ul>
          <%= for scope <- @consent.grant.scopes do %>
            <li>{scope}</li>
          <% end %>
        </ul>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="Revoke consent"
        subtitle="Use this only when the durable grant should stop authorizing future reuse."
      >
        <p :if={@consent.grant.status == :revoked}>This consent is already revoked. Repeating the action is safe.</p>
        <p :if={@revoke_error}>{@revoke_error}</p>

        <form phx-submit="revoke_consent">
          <label>
            <input type="checkbox" name="revoke[confirm]" value="true" />
            I understand this revokes the stored grant for this account and client.
          </label>
          <button type="submit">
            {if @consent.grant.status == :revoked, do: "Consent already revoked", else: "Revoke consent"}
          </button>
        </form>
      </AdminComponents.section_card>
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
end
