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
      <AdminComponents.page_hero
        eyebrow="Support"
        title="Token health decision"
        body="Review durable token state, refresh-family context, and the smallest safe revocation path."
      >
        <:summary>
          <span>Status: <AdminComponents.status_badge status={@token_detail.status} /></span>
        </:summary>
        <:actions>
          <AdminComponents.admin_button href={tokens_index_path()}>
            Review token investigation
          </AdminComponents.admin_button>
        </:actions>
      </AdminComponents.page_hero>

      <AdminComponents.entity_header
        title={@token_detail.token.handle}
        subtitle="Opaque tokens stay opaque here. Operator detail uses durable metadata, not JWT decoding shortcuts or plaintext recovery."
        identifier={@token_detail.token.handle}
      >
        <:status>
          <AdminComponents.status_badge status={@token_detail.status} />
          <AdminComponents.status_badge status={@token_detail.token.token_type} />
        </:status>
      </AdminComponents.entity_header>

      <AdminComponents.pane
        title="Token identity and current state"
        subtitle="Review the durable token pivots used by support without rendering hashes or plaintext token material."
      >
        <AdminComponents.description_list>
          <:item label="Client">
            <AdminComponents.long_value value={@token_detail.token.client_display} kind={:id} />
          </:item>
          <:item label="Client handle">
            <AdminComponents.long_value value={@token_detail.token.client_handle} kind={:id} />
          </:item>
          <:item label="Account">
            <AdminComponents.long_value
              value={@token_detail.token.account_handle || "Not recorded"}
              kind={:id}
            />
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
            <AdminComponents.long_value
              value={Map.get(@token_detail.token, :sid) || "Not recorded"}
              kind={:id}
            />
          </:item>
          <:item label="Family">
            <AdminComponents.long_value
              value={@token_detail.token.family_handle || "Not recorded"}
              kind={:id}
            />
          </:item>
          <:item label="Generation"><code>{@token_detail.token.generation}</code></:item>
          <:item label="Parent token">
            <AdminComponents.long_value
              value={@token_detail.token.parent_handle || "Not recorded"}
              kind={:id}
            />
          </:item>
          <:item label="Scopes">{Enum.join(@token_detail.token.scopes, ", ")}</:item>
        </AdminComponents.description_list>
      </AdminComponents.pane>

      <AdminComponents.pane
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

        <AdminComponents.resource_list>
          <%= for entry <- @token_detail.family_tokens do %>
            <AdminComponents.dense_resource_row
              title={if(entry.current?, do: "Current token", else: entry.token.handle)}
              subtitle={"#{entry.token.token_type} token generation #{entry.token.generation}"}
            >
              <:meta>
                <span>
                  Token
                  <AdminComponents.long_value value={entry.token.handle} kind={:id} />
                </span>
              </:meta>
              <:status>
                <AdminComponents.status_badge status={entry.status} />
              </:status>
            </AdminComponents.dense_resource_row>
          <% end %>
        </AdminComponents.resource_list>
      </AdminComponents.pane>

      <AdminComponents.pane
        title="Corrective actions"
        subtitle="Choose the smallest safe action first. Single-token revoke and family-wide refresh-token invalidation stay distinct."
      >
        <p :if={@revoke_error}>{@revoke_error}</p>
        <p :if={@family_error}>{@family_error}</p>
        <p :if={@family_notice}>{@family_notice}</p>

        <AdminComponents.confirmation_panel title="Revoke token" variant={:danger}>
          <:body>
            <form class="lockspire-admin-form-stack" phx-submit="revoke_token">
              <label class="lockspire-admin-checkbox-field">
                <input type="checkbox" name="revoke[confirm]" value="true" />
                <span>
                  Revoke only this {@token_detail.token.token_type} token for client
                  {@token_detail.token.client_display}, subject
                  {@token_detail.token.account_handle || "not recorded"}, expiring
                  <AdminComponents.timestamp value={@token_detail.token.expires_at} />.
                </span>
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

        <AdminComponents.confirmation_panel title="Revoke token family" variant={:danger}>
          <:body>
            <form class="lockspire-admin-form-stack" phx-submit="revoke_family">
              <label class="lockspire-admin-checkbox-field">
                <input type="checkbox" name="family[confirm]" value="true" />
                <span>
                  Revoke token family
                  <AdminComponents.long_value
                    value={@token_detail.token.family_handle || "not recorded"}
                    kind={:id}
                  />
                  for client {@token_detail.token.client_display} and subject
                  {@token_detail.token.account_handle || "not recorded"}. This family-wide action
                  revokes every active token in the refresh lineage and cannot recover plaintext
                  token material.
                </span>
              </label>
              <AdminComponents.action_bar>
                <AdminComponents.admin_button type="submit" variant={:danger}>
                  Revoke token family
                </AdminComponents.admin_button>
              </AdminComponents.action_bar>
            </form>
          </:body>
        </AdminComponents.confirmation_panel>
      </AdminComponents.pane>
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

  defp tokens_index_path, do: Lockspire.mount_path() <> "/admin/tokens"
end
