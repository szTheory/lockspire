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
  @default_filters %{"account" => "", "client" => "", "status" => "all"}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Token detail",
       current_section: :tokens,
       token_id: parse_id(id),
       filters: @default_filters,
       token_detail: nil,
       detail_state: :loading,
       revoke_error: nil,
       family_error: nil,
       family_notice: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    token_id = parse_id(Map.get(params, "id", socket.assigns.token_id))
    filters = normalize_filters(params)

    {:noreply,
     socket
     |> assign(
       token_id: token_id,
       filters: filters,
       revoke_error: nil,
       family_error: nil,
       family_notice: nil
     )
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
          case count do
            0 -> "This refresh family was already fully revoked."
            1 -> "Revoked 1 currently unrevoked token in this refresh family."
            count -> "Revoked #{count} currently unrevoked tokens in this refresh family."
          end

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
      <%= if @detail_state == :error do %>
        <AdminComponents.empty_state
          title="Could not load token details"
          body="The token detail read failed, so its current state is unknown. Retry this read or return to the inventory."
        >
          <:actions>
            <AdminComponents.admin_button
              :if={is_integer(@token_id)}
              href={token_detail_path(@token_id, @filters)}
            >
              Try loading token details again
            </AdminComponents.admin_button>
            <AdminComponents.admin_button href={tokens_index_path(@filters)}>
              Review token investigation
            </AdminComponents.admin_button>
          </:actions>
        </AdminComponents.empty_state>
      <% else %>
        <AdminComponents.empty_state
          title="Token not found"
          body="Lockspire could not find that supported access or refresh token in durable storage."
        >
          <:actions>
            <AdminComponents.admin_button href={tokens_index_path(@filters)}>
              Review token investigation
            </AdminComponents.admin_button>
          </:actions>
        </AdminComponents.empty_state>
      <% end %>
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
          <AdminComponents.admin_button href={tokens_index_path(@filters)}>
            Review token investigation
          </AdminComponents.admin_button>
        </:actions>
      </AdminComponents.page_hero>

      <AdminComponents.entity_header
        title={@token_detail.token.handle}
        subtitle="Access and refresh token values and stored hashes stay hidden; this page shows their stored metadata."
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
            <AdminComponents.admin_button
              :if={client_detail_path_available?(@token_detail)}
              href={client_detail_path(@token_detail.client.client_id)}
            >
              View client details
            </AdminComponents.admin_button>
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
          <:item label="Consent grant">
            <AdminComponents.admin_button
              :if={is_integer(@token_detail.token.consent_grant_id)}
              href={consent_detail_path(@token_detail.token.consent_grant_id)}
            >
              View consent grant
            </AdminComponents.admin_button>
            <span :if={!is_integer(@token_detail.token.consent_grant_id)}>Not recorded</span>
          </:item>
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
              title={
                if(entry.current?,
                  do:
                    "Current #{token_kind_label(entry.token.token_type)} generation #{entry.token.generation}",
                  else: entry.token.handle
                )
              }
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
                <span>{single_token_confirmation(@token_detail)}</span>
              </label>
              <AdminComponents.action_bar>
                <AdminComponents.admin_button
                  type="submit"
                  variant={:danger}
                  disabled={token_action_disabled?(@token_detail)}
                  phx-disable-with={token_pending_label(@token_detail)}
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
                  Revoke this refresh token family? This revokes the currently unrevoked tokens in this family.
                  Family
                  <AdminComponents.long_value
                    value={@token_detail.token.family_handle || "not recorded"}
                    kind={:id}
                  />
                  for client {@token_detail.token.client_display} and subject
                  {@token_detail.token.account_handle || "not recorded"}. This family-wide action
                  is irreversible and does not expose token plaintext.
                </span>
              </label>
              <AdminComponents.action_bar>
                <AdminComponents.admin_button
                  type="submit"
                  variant={:danger}
                  disabled={family_action_disabled?(@token_detail)}
                  phx-disable-with="Revoking this refresh token family…"
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

  defp load_token(socket, nil), do: assign(socket, token_detail: nil, detail_state: :missing)

  defp load_token(socket, token_id) do
    case read_token_detail(token_id) do
      {:ok, nil} -> assign(socket, token_detail: nil, detail_state: :missing)
      {:ok, token_detail} -> assign(socket, token_detail: token_detail, detail_state: :loaded)
      {:error, _reason} -> assign(socket, token_detail: nil, detail_state: :error)
    end
  end

  defp read_token_detail(token_id) do
    Admin.get_token(token_id)
  rescue
    _error -> {:error, :unavailable}
  end

  defp normalize_filters(params) do
    %{
      "account" => normalize_filter(Map.get(params, "account")),
      "client" => normalize_filter(Map.get(params, "client")),
      "status" => normalize_status(Map.get(params, "status"))
    }
  end

  defp normalize_filter(value) when is_binary(value), do: value
  defp normalize_filter(_value), do: ""

  defp normalize_status(status)
       when status in ["all", "active", "revoked", "expired", "reuse_detected"],
       do: status

  defp normalize_status(_status), do: "all"

  defp parse_id(value) when is_integer(value) and value > 0, do: value

  defp parse_id(value) when is_binary(value) do
    case Integer.parse(value) do
      {id, ""} when id > 0 -> id
      :error -> nil
      _other -> nil
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

  defp single_token_confirmation(%{token: %{token_type: :access_token}}),
    do:
      "Revoke this access token? This revokes only this token; other tokens in its refresh family remain unchanged."

  defp single_token_confirmation(%{token: %{token_type: :refresh_token}}),
    do:
      "Revoke this refresh token? This revokes only this token; other tokens in its refresh family remain unchanged."

  defp token_pending_label(%{token: %{token_type: :access_token}}),
    do: "Revoking this access token…"

  defp token_pending_label(%{token: %{token_type: :refresh_token}}),
    do: "Revoking this refresh token…"

  defp token_kind_label(:access_token), do: "access token"
  defp token_kind_label(:refresh_token), do: "refresh token"

  defp family_revoke_button_label(token_detail) do
    cond do
      not refresh_family_present?(token_detail) -> "Family-wide revocation unavailable"
      family_already_closed?(token_detail) -> "Token family already revoked"
      true -> "Revoke token family"
    end
  end

  defp summary(value, detail, tone), do: %{value: value, detail: detail, tone: tone}

  defp tokens_index_path, do: Lockspire.mount_path() <> "/admin/tokens"

  defp tokens_index_path(filters),
    do: append_filter_query(tokens_index_path(), filters)

  defp token_detail_path(id, filters),
    do: append_filter_query(tokens_index_path() <> "/#{id}", filters)

  defp append_filter_query(path, @default_filters), do: path

  defp append_filter_query(path, filters),
    do: path <> "?" <> URI.encode_query(filters)

  defp client_detail_path_available?(%{client: %{client_id: client_id}}),
    do: is_binary(client_id) and byte_size(client_id) <= 64

  defp client_detail_path_available?(_detail), do: false

  defp client_detail_path(client_id),
    do:
      Lockspire.mount_path() <>
        "/admin/clients/" <> URI.encode(client_id, &URI.char_unreserved?/1)

  defp consent_detail_path(id), do: Lockspire.mount_path() <> "/admin/consents/" <> to_string(id)
end
