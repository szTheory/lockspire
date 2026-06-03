defmodule Lockspire.Web.Live.Admin.TokensLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Token detail",
       current_section: :tokens,
       token_id: parse_id(id),
       token_detail: nil,
       revoke_error: nil,
       family_error: nil,
       family_notice: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    token_id = parse_id(Map.get(params, "id", socket.assigns.token_id))

    {:noreply,
     socket
     |> assign(token_id: token_id, revoke_error: nil, family_error: nil, family_notice: nil)
     |> load_token(token_id)}
  end

  @impl true
  def handle_event("revoke_token", %{"revoke" => %{"confirm" => "true"}}, socket) do
    case Admin.revoke_token(socket.assigns.token_id, %{revoked_by: "operator"}) do
      {:ok, detail} ->
        {:noreply, assign(socket, token_detail: detail, revoke_error: nil)}

      {:error, _reason} ->
        {:noreply, assign(socket, revoke_error: "Token could not be revoked.")}
    end
  end

  def handle_event("revoke_token", _params, socket) do
    {:noreply,
     assign(socket,
       revoke_error: "Confirm the single-token action before changing lifecycle state.",
       family_notice: nil
     )}
  end

  def handle_event("revoke_family", %{"family" => %{"confirm" => "true"}}, socket) do
    case Admin.revoke_token_family(socket.assigns.token_id, %{revoked_by: "operator"}) do
      {:ok, %{count: count, token: detail}} ->
        notice =
          if count == 0,
            do: "This refresh family was already fully revoked.",
            else: "Revoked #{count} token(s) in this refresh family."

        {:noreply,
         assign(socket,
           token_detail: detail,
           family_notice: notice,
           family_error: nil
         )}

      {:error, :no_family} ->
        {:noreply,
         assign(socket, family_error: "This token does not belong to a refresh family.")}

      {:error, _reason} ->
        {:noreply, assign(socket, family_error: "Refresh family could not be revoked.")}
    end
  end

  def handle_event("revoke_family", _params, socket) do
    {:noreply,
     assign(socket,
       family_error: "Confirm the family-wide action before revoking the lineage.",
       family_notice: nil
     )}
  end

  @impl true
  def render(%{token_detail: nil} = assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.empty_state
        title="Token not found"
        body="Lockspire could not load that lifecycle token from durable storage."
      />
    </AdminLayoutLive.shell>
    """
  end

  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.section_card
        title={@token_detail.token.handle}
        subtitle="Opaque tokens stay opaque here. Operator detail uses durable metadata, not JWT decoding shortcuts."
      >
        <AdminComponents.description_list>
          <:item label="Client"><code>{@token_detail.token.client_display}</code></:item>
          <:item label="Client handle"><code>{@token_detail.token.client_handle}</code></:item>
          <:item label="Account">
            <code>{@token_detail.token.account_handle || "Not recorded"}</code>
          </:item>
          <:item label="Type"><code>{@token_detail.token.token_type}</code></:item>
          <:item label="Status"><AdminComponents.status_badge status={@token_detail.status} /></:item>
          <:item label="Expires at">
            <AdminComponents.timestamp value={@token_detail.token.expires_at} />
          </:item>
          <:item label="Revoked at">
            <AdminComponents.timestamp value={@token_detail.token.revoked_at} />
          </:item>
          <:item label="Reuse detected at">
            <AdminComponents.timestamp value={@token_detail.token.reuse_detected_at} />
          </:item>
          <:item label="Session ID">
            <code>{Map.get(@token_detail.token, :sid) || "Not recorded"}</code>
          </:item>
          <:item label="Family"><code>{@token_detail.token.family_handle || "Not recorded"}</code></:item>
          <:item label="Generation"><code>{@token_detail.token.generation}</code></:item>
          <:item label="Parent token">
            <code>{@token_detail.token.parent_handle || "Not recorded"}</code>
          </:item>
          <:item label="Scopes">{Enum.join(@token_detail.token.scopes, ", ")}</:item>
        </AdminComponents.description_list>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="Refresh family lineage"
        subtitle="Family status is derived from the stored lineage used by refresh, revocation, and introspection."
      >
        <AdminComponents.description_list>
          <:item label="Family status">
            <AdminComponents.status_badge status={@token_detail.family_status} />
          </:item>
          <:item label="Active tokens in family">{@token_detail.family_active_count}</:item>
          <:item label="Revoked tokens in family">{@token_detail.family_revoked_count}</:item>
          <:item label="Family reuse signal">
            <AdminComponents.timestamp value={@token_detail.family_reuse_detected_at} />
          </:item>
        </AdminComponents.description_list>

        <ul class="lockspire-admin-resource-list lockspire-admin-section-spaced">
          <%= for entry <- @token_detail.family_tokens do %>
            <li>
              <strong>
                {if entry.current?,
                  do: "Current token",
                  else: entry.token.handle}
              </strong>
              <span>Type {entry.token.token_type}</span>
              <span>Generation {entry.token.generation}</span>
              <AdminComponents.status_badge status={entry.status} />
            </li>
          <% end %>
        </ul>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="Corrective actions"
        subtitle="Choose the smallest safe action first. Single-token revoke and family revoke stay distinct."
      >
        <p :if={@revoke_error}>{@revoke_error}</p>
        <p :if={@family_error}>{@family_error}</p>
        <p :if={@family_notice}>{@family_notice}</p>

        <AdminComponents.confirmation_panel title="Revoke token" variant={:danger}>
          <:body>
            <form class="lockspire-admin-form-stack" phx-submit="revoke_token">
              <label class="lockspire-admin-checkbox-field">
                <input type="checkbox" name="revoke[confirm]" value="true" />
                <span>Revoke only this token record.</span>
              </label>
              <AdminComponents.action_bar>
                <AdminComponents.admin_button type="submit" variant={:danger}>
                  {if @token_detail.status == :revoked,
                    do: "Token already revoked",
                    else: "Revoke token"}
                </AdminComponents.admin_button>
              </AdminComponents.action_bar>
            </form>
          </:body>
        </AdminComponents.confirmation_panel>

        <AdminComponents.confirmation_panel title="Revoke refresh family" variant={:danger}>
          <:body>
            <form class="lockspire-admin-form-stack" phx-submit="revoke_family">
              <label class="lockspire-admin-checkbox-field">
                <input type="checkbox" name="family[confirm]" value="true" />
                <span>Revoke the full refresh family linked to this token.</span>
              </label>
              <AdminComponents.action_bar>
                <AdminComponents.admin_button type="submit" variant={:danger}>
                  Revoke family
                </AdminComponents.admin_button>
              </AdminComponents.action_bar>
            </form>
          </:body>
        </AdminComponents.confirmation_panel>
      </AdminComponents.section_card>
    </AdminLayoutLive.shell>
    """
  end

  defp load_token(socket, nil), do: assign(socket, token_detail: nil)

  defp load_token(socket, token_id) do
    case Admin.get_token(token_id) do
      {:ok, token_detail} -> assign(socket, token_detail: token_detail)
      {:error, _reason} -> assign(socket, token_detail: nil)
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
