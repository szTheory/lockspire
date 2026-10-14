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
       page_title: "Token details",
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
              Back to tokens
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
              Back to tokens
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
      <div class="lockspire-admin-token-detail">
        <a class="lockspire-admin-back-link" href={tokens_index_path(@filters)}>Back to tokens</a>

        <AdminComponents.pane title={token_type_title(@token_detail.token.token_type)}>
          <:status><AdminComponents.status_badge status={@token_detail.status} /></:status>
          <p class="lockspire-admin-token-detail__outcome" role="status">{token_outcome(@token_detail)}</p>
          <p :if={reuse_recorded?(@token_detail)} class="lockspire-admin-help">
            Repeat use can indicate theft or a repeated app request; it does not prove theft. Review the app and related records to investigate.
          </p>
          <AdminComponents.description_list>
            <:item label="App">
              <a :if={client_detail_path_available?(@token_detail)} href={client_detail_path(@token_detail.client.client_id)}>
                {@token_detail.token.client_display}
              </a>
              <span :if={!client_detail_path_available?(@token_detail)}>{@token_detail.token.client_display}</span>
            </:item>
            <:item label="Account">
              <AdminComponents.long_value value={@token_detail.token.account_handle || "Not recorded"} kind={:id} />
            </:item>
            <:item label="Expires at"><AdminComponents.timestamp format={:readable} value={@token_detail.token.expires_at} /></:item>
            <:item :if={token_reuse_detected?(@token_detail)} label="Used again at">
              <AdminComponents.timestamp format={:readable} value={@token_detail.token.reuse_detected_at} />
            </:item>
            <:item :if={token_revoked?(@token_detail)} label="Revoked at">
              <AdminComponents.timestamp format={:readable} value={@token_detail.token.revoked_at} />
            </:item>
            <:item label="Scopes">{Enum.join(@token_detail.token.scopes, ", ")}</:item>
            <:item :if={is_integer(@token_detail.token.consent_grant_id)} label="Consent grant">
              <a href={consent_detail_path(@token_detail.token.consent_grant_id)}>View consent grant</a>
            </:item>
          </AdminComponents.description_list>

          <details class="lockspire-admin-record-details">
            <summary>Record identifiers</summary>
            <AdminComponents.description_list>
              <:item label="Token"><AdminComponents.long_value value={@token_detail.token.handle} kind={:id} /></:item>
              <:item label="Client handle"><AdminComponents.long_value value={@token_detail.token.client_handle} kind={:id} /></:item>
              <:item label="Session ID"><AdminComponents.long_value value={Map.get(@token_detail.token, :sid) || "Not recorded"} kind={:id} /></:item>
              <:item label="Family"><AdminComponents.long_value value={@token_detail.token.family_handle || "Not recorded"} kind={:id} /></:item>
              <:item label="Generation">{@token_detail.token.generation}</:item>
              <:item label="Parent token"><AdminComponents.long_value value={@token_detail.token.parent_handle || "Not recorded"} kind={:id} /></:item>
            </AdminComponents.description_list>
            <p class="lockspire-admin-help">These handles identify records without revealing token values.</p>
          </details>
        </AdminComponents.pane>

        <AdminComponents.pane :if={refresh_family_present?(@token_detail)} title="Related tokens" subtitle={active_family_count_copy(@token_detail.family_active_count)}>
          <details class="lockspire-admin-record-details">
            <summary>Token history ({length(@token_detail.family_tokens)})</summary>
            <AdminComponents.resource_list>
              <%= for entry <- @token_detail.family_tokens do %>
                <AdminComponents.dense_resource_row
                  class="lockspire-admin-token-row"
                  title={if(entry.current?, do: "This #{token_kind_label(entry.token.token_type)}", else: token_type_title(entry.token.token_type))}
                  subtitle={"Generation #{entry.token.generation}"}
                >
                  <:meta><AdminComponents.long_value value={entry.token.handle} kind={:id} /></:meta>
                  <:status><AdminComponents.status_badge status={entry.status} /></:status>
                </AdminComponents.dense_resource_row>
              <% end %>
            </AdminComponents.resource_list>
          </details>
        </AdminComponents.pane>

        <p :if={@family_notice} role="status">{@family_notice}</p>
        <AdminComponents.pane :if={!token_action_disabled?(@token_detail) or !family_action_disabled?(@token_detail)} title="Revoke access" subtitle="Choose how much access to block. Revocation cannot be undone.">
          <AdminComponents.confirmation_panel :if={!token_action_disabled?(@token_detail)} title="Revoke token" variant={:danger} errors={token_revoke_errors(@revoke_error)}>
            <:body>
              <form class="lockspire-admin-form-stack" phx-submit="revoke_token">
                <label class="lockspire-admin-checkbox-field">
                  <input type="checkbox" name="revoke[confirm]" value="true" />
                  <span>{single_token_confirmation(@token_detail)}</span>
                </label>
                <AdminComponents.action_bar>
                  <AdminComponents.admin_button type="submit" variant={:danger} phx-disable-with={token_pending_label(@token_detail)}>Revoke token</AdminComponents.admin_button>
                </AdminComponents.action_bar>
              </form>
            </:body>
          </AdminComponents.confirmation_panel>

          <AdminComponents.confirmation_panel :if={!family_action_disabled?(@token_detail)} title="Revoke token family" variant={:danger} errors={family_revoke_errors(@family_error)}>
            <:body>
              <form class="lockspire-admin-form-stack" phx-submit="revoke_family">
                <p>{active_family_count_copy(@token_detail.family_active_count)}</p>
                <label class="lockspire-admin-checkbox-field">
                  <input type="checkbox" name="family[confirm]" value="true" />
                  <span>
                    Revoke this refresh token family? This revokes the currently unrevoked tokens in this family.
                    App {@token_detail.token.client_display}; account {@token_detail.token.account_handle || "not recorded"}.
                  </span>
                </label>
                <AdminComponents.action_bar>
                  <AdminComponents.admin_button type="submit" variant={:danger} phx-disable-with="Revoking this refresh token family…">Revoke token family</AdminComponents.admin_button>
                </AdminComponents.action_bar>
              </form>
            </:body>
          </AdminComponents.confirmation_panel>
        </AdminComponents.pane>
      </div>
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
    do:
      token_revoked?(token_detail) or token_expired?(token_detail) or
        token_reuse_detected?(token_detail)

  defp family_action_disabled?(token_detail),
    do: not refresh_family_present?(token_detail) or family_has_no_active_tokens?(token_detail)

  defp family_has_no_active_tokens?(token_detail),
    do: refresh_family_present?(token_detail) and token_detail.family_active_count == 0

  defp family_all_revoked?(token_detail),
    do:
      refresh_family_present?(token_detail) and
        token_detail.family_revoked_count == length(token_detail.family_tokens)

  defp family_revoked_summary_detail(%{family_revoked_count: 1}),
    do: "1 token in this family is revoked."

  defp family_revoked_summary_detail(%{family_revoked_count: count}),
    do: "#{count} tokens in this family are revoked."

  defp token_type_title(:refresh_token), do: "Refresh token"
  defp token_type_title(:access_token), do: "Access token"
  defp token_type_title(_type), do: "Token"

  defp active_family_count_copy(0), do: "No active tokens remain in this refresh-token family."
  defp active_family_count_copy(1), do: "1 active token remains in this refresh-token family."

  defp active_family_count_copy(count),
    do: "#{count} active tokens remain in this refresh-token family."

  defp reuse_recorded?(detail),
    do: token_reuse_detected?(detail) or match?(%DateTime{}, detail.family_reuse_detected_at)

  @reuse_outcome_prefix "A refresh token was presented again after replacement or revocation."

  defp token_outcome(detail) do
    cond do
      reuse_recorded?(detail) -> reuse_outcome(detail)
      token_revoked?(detail) -> @already_revoked_copy
      token_expired?(detail) -> @expired_copy
      true -> "This token is active. Token values stay hidden."
    end
  end

  defp reuse_outcome(detail) do
    cond do
      not refresh_family_present?(detail) ->
        @reuse_outcome_prefix <>
          " This token is no longer active; no related token records are available."

      detail.family_active_count > 0 ->
        @reuse_outcome_prefix <>
          " Revoke all active family tokens to block the remaining access."

      family_all_revoked?(detail) ->
        @reuse_outcome_prefix <>
          " " <> family_revoked_summary_detail(detail) <> " No active tokens to revoke."

      true ->
        @reuse_outcome_prefix <> " No active tokens to revoke."
    end
  end

  defp token_revoke_errors(nil), do: []
  defp token_revoke_errors(error), do: [error]

  defp family_revoke_errors(nil), do: []
  defp family_revoke_errors(error), do: [error]

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
