defmodule Lockspire.Web.Live.Admin.TokensLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @token_confirm_error "Select the confirmation checkbox to revoke this token."
  @family_confirm_error "Select the confirmation checkbox to revoke this refresh family."
  @revocation_failure "Revocation could not be confirmed. The token may still be active; reload this Support workflow before retrying."
  @already_revoked_copy "This token is already revoked. No further token action is available."
  @expired_copy "This token is expired. No active token remains because its expiration time has passed."
  @no_family_copy "This token is not part of a refresh family, so family-wide revocation is unavailable."

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
        {:noreply,
         assign(socket,
           token_detail: detail,
           revoke_error: nil,
           family_error: nil,
           family_notice: nil
         )}

      {:error, _reason} ->
        {:noreply, assign(socket, revoke_error: @revocation_failure, family_error: nil)}
    end
  end

  def handle_event("revoke_token", _params, socket) do
    {:noreply,
     assign(socket,
       revoke_error: @token_confirm_error,
       family_error: nil,
       family_notice: nil
     )}
  end

  def handle_event("revoke_family", %{"family" => %{"confirm" => "true"}}, socket) do
    case Admin.revoke_token_family(socket.assigns.token_id, %{revoked_by: "operator"}) do
      {:ok, %{count: count, token: detail}} ->
        notice =
          if count == 0,
            do: "This refresh family was already fully revoked.",
            else: "Revoked #{count} currently unrevoked token(s) in this refresh family."

        {:noreply,
         assign(socket,
           token_detail: detail,
           family_notice: notice,
           family_error: nil,
           revoke_error: nil
         )}

      {:error, :no_family} ->
        {:noreply, assign(socket, family_error: @no_family_copy, revoke_error: nil)}

      {:error, _reason} ->
        {:noreply, assign(socket, family_error: @revocation_failure, revoke_error: nil)}
    end
  end

  def handle_event("revoke_family", _params, socket) do
    {:noreply,
     assign(socket,
       family_error: @family_confirm_error,
       revoke_error: nil,
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
        subtitle="Opaque tokens stay opaque here. Operator detail uses durable metadata, not JWT decoding shortcuts or bearer-value inspection."
        identifier={@token_detail.token.handle}
      >
        <:status>
          <AdminComponents.status_badge status={@token_detail.status} />
          <AdminComponents.status_badge status={@token_detail.token.token_type} />
        </:status>
      </AdminComponents.entity_header>

      <AdminComponents.decision_summary>
        <:item
          label="Token health"
          value={token_health_summary(@token_detail).value}
          detail={token_health_summary(@token_detail).detail}
          tone={token_health_summary(@token_detail).tone}
        >
        </:item>
        <:item
          label="Family lineage"
          value={family_lineage_summary(@token_detail).value}
          detail={family_lineage_summary(@token_detail).detail}
          tone={family_lineage_summary(@token_detail).tone}
        >
        </:item>
        <:item
          label="Reuse pressure"
          value={reuse_pressure_summary(@token_detail).value}
          detail={reuse_pressure_summary(@token_detail).detail}
          tone={reuse_pressure_summary(@token_detail).tone}
        >
        </:item>
        <:item
          label="Smallest safe action"
          value={token_detail_smallest_safe_action(@token_detail).value}
          detail={token_detail_smallest_safe_action(@token_detail).detail}
          tone={token_detail_smallest_safe_action(@token_detail).tone}
        >
        </:item>
      </AdminComponents.decision_summary>

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
        <p :if={@family_notice}>{@family_notice}</p>

        <AdminComponents.confirmation_panel
          title="Revoke token"
          variant={:danger}
          errors={token_revoke_errors(@revoke_error)}
        >
          <:body>
            <form class="lockspire-admin-form-stack" phx-submit="revoke_token">
              <p :if={token_revoked?(@token_detail)}>{already_revoked_copy()}</p>
              <p :if={token_expired?(@token_detail) and not token_revoked?(@token_detail)}>
                {expired_copy()}
              </p>
              <label class="lockspire-admin-checkbox-field">
                <input
                  type="checkbox"
                  name="revoke[confirm]"
                  value="true"
                  disabled={token_action_disabled?(@token_detail)}
                />
                <span>
                  Revoke only this {@token_detail.token.token_type} token for client
                  {@token_detail.token.client_display}, subject
                  {@token_detail.token.account_handle || "not recorded"}, expiring
                  <AdminComponents.timestamp value={@token_detail.token.expires_at} />.
                </span>
              </label>
              <AdminComponents.action_bar>
                <AdminComponents.admin_button
                  type="submit"
                  variant={:danger}
                  disabled={token_action_disabled?(@token_detail)}
                >
                  {token_revoke_button_label(@token_detail)}
                </AdminComponents.admin_button>
              </AdminComponents.action_bar>
            </form>
          </:body>
        </AdminComponents.confirmation_panel>

        <AdminComponents.confirmation_panel
          title="Revoke token family"
          variant={:danger}
          errors={family_revoke_errors(@family_error)}
        >
          <:body>
            <form class="lockspire-admin-form-stack" phx-submit="revoke_family">
              <p :if={not refresh_family_present?(@token_detail)}>
                {no_family_copy()}
              </p>
              <p :if={family_already_closed?(@token_detail)}>
                This refresh family has no currently unrevoked tokens, so family-wide revocation is already closed.
              </p>
              <label class="lockspire-admin-checkbox-field">
                <input
                  type="checkbox"
                  name="family[confirm]"
                  value="true"
                  disabled={family_action_disabled?(@token_detail)}
                />
                <span>
                  Revoke token family
                  <AdminComponents.long_value
                    value={@token_detail.token.family_handle || "not recorded"}
                    kind={:id}
                  />
                  for client {@token_detail.token.client_display} and subject
                  {@token_detail.token.account_handle || "not recorded"}. This family-wide action
                  revokes currently unrevoked tokens in the refresh family. It is irreversible and
                  does not expose token plaintext.
                </span>
              </label>
              <AdminComponents.action_bar>
                <AdminComponents.admin_button
                  type="submit"
                  variant={:danger}
                  disabled={family_action_disabled?(@token_detail)}
                >
                  {family_revoke_button_label(@token_detail)}
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
    {:ok, token_detail} = Admin.get_token(token_id)
    assign(socket, token_detail: token_detail)
  end

  defp parse_id(value) when is_integer(value), do: value

  defp parse_id(value) when is_binary(value) do
    case Integer.parse(value) do
      {id, _rest} -> id
      :error -> nil
    end
  end

  defp parse_id(_value), do: nil

  defp already_revoked_copy, do: @already_revoked_copy
  defp expired_copy, do: @expired_copy
  defp no_family_copy, do: @no_family_copy

  defp token_revoked?(token_detail),
    do: match?(%DateTime{}, token_detail.token.revoked_at)

  defp token_expired?(token_detail) do
    case token_detail.token.expires_at do
      %DateTime{} = expires_at -> DateTime.compare(expires_at, DateTime.utc_now()) != :gt
      _other -> false
    end
  end

  defp token_reuse_detected?(token_detail),
    do: match?(%DateTime{}, token_detail.token.reuse_detected_at)

  defp refresh_family_present?(token_detail),
    do: is_binary(token_detail.token.family_id) and token_detail.token.family_id != ""

  defp token_action_disabled?(token_detail),
    do: token_revoked?(token_detail) or token_expired?(token_detail)

  defp family_action_disabled?(token_detail),
    do: not refresh_family_present?(token_detail) or family_already_closed?(token_detail)

  defp family_already_closed?(token_detail),
    do: refresh_family_present?(token_detail) and family_unrevoked_count(token_detail) == 0

  defp family_unrevoked_count(token_detail) do
    Enum.count(token_detail.family_tokens, fn entry ->
      not match?(%DateTime{}, Map.get(entry.token, :revoked_at))
    end)
  end

  defp token_health_summary(token_detail) do
    cond do
      token_revoked?(token_detail) ->
        summary("Revoked", @already_revoked_copy, :danger)

      token_expired?(token_detail) ->
        summary("Expired", @expired_copy, :warning)

      token_reuse_detected?(token_detail) ->
        summary(
          "Reuse detected",
          "Reuse evidence is present; review family-wide revocation before metadata.",
          :danger
        )

      true ->
        summary("Active", "Token is not revoked or expired.", :success)
    end
  end

  defp family_lineage_summary(token_detail) do
    cond do
      not refresh_family_present?(token_detail) ->
        summary("No refresh family", @no_family_copy, :warning)

      family_already_closed?(token_detail) ->
        summary(
          "Family closed",
          "No currently unrevoked tokens remain in the refresh family.",
          :warning
        )

      token_detail.family_status == :reuse_detected ->
        summary(
          "Reuse evidence in family",
          "#{family_unrevoked_count(token_detail)} currently unrevoked tokens in the refresh family.",
          :danger
        )

      true ->
        summary(
          "Family present",
          "#{family_unrevoked_count(token_detail)} currently unrevoked tokens in the refresh family.",
          :info
        )
    end
  end

  defp reuse_pressure_summary(token_detail) do
    if token_reuse_detected?(token_detail) or
         match?(%DateTime{}, token_detail.family_reuse_detected_at) do
      summary(
        "Reuse pressure present",
        "Reuse evidence means family-wide revocation is the safest available token action.",
        :danger
      )
    else
      summary("No reuse evidence", "No reuse signal is recorded for this token family.", :success)
    end
  end

  defp token_detail_smallest_safe_action(token_detail) do
    family_reuse? =
      token_reuse_detected?(token_detail) or token_detail.family_status == :reuse_detected

    cond do
      family_reuse? and refresh_family_present?(token_detail) and
          family_unrevoked_count(token_detail) > 0 ->
        summary(
          "Revoke token family",
          "Reuse evidence means family-wide revocation is the safest available token action.",
          :danger
        )

      token_revoked?(token_detail) ->
        summary("No token action", @already_revoked_copy, :warning)

      token_expired?(token_detail) ->
        summary("No token action", @expired_copy, :warning)

      not refresh_family_present?(token_detail) ->
        summary(
          "Revoke token only",
          "Family-wide revocation is unavailable; only this token can be revoked if still active.",
          :info
        )

      true ->
        summary(
          "Revoke token if needed",
          "Start with this token before using family-wide revocation.",
          :info
        )
    end
  end

  defp token_revoke_errors(nil), do: []
  defp token_revoke_errors(error), do: [error]

  defp family_revoke_errors(nil), do: []
  defp family_revoke_errors(error), do: [error]

  defp token_revoke_button_label(token_detail) do
    cond do
      token_revoked?(token_detail) -> "Token already revoked"
      token_expired?(token_detail) -> "Token expired"
      true -> "Revoke token"
    end
  end

  defp family_revoke_button_label(token_detail) do
    cond do
      not refresh_family_present?(token_detail) -> "Family-wide revocation unavailable"
      family_already_closed?(token_detail) -> "Token family already revoked"
      true -> "Revoke token family"
    end
  end

  defp summary(value, detail, tone), do: %{value: value, detail: detail, tone: tone}

  defp tokens_index_path, do: Lockspire.mount_path() <> "/admin/tokens"
end
