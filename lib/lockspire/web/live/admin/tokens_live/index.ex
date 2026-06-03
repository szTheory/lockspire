defmodule Lockspire.Web.Live.Admin.TokensLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Tokens",
       current_section: :tokens,
       tokens: [],
       filters: %{"account" => "", "client" => "", "status" => "all"},
       total_tokens: 0
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filters = normalize_filters(params)
    tokens = load_tokens(filters)

    {:noreply,
     assign(socket,
       filters: filters,
       tokens: tokens,
       total_tokens: length(tokens)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.section_card
        title="Token inspection"
        subtitle="Inspect durable token lifecycle truth by account, client, and incident status."
      >
        <form method="get" action={tokens_index_path()} class="lockspire-admin-form-shell">
          <div class="lockspire-admin-field">
            <label for="token_account">Account</label>
            <input id="token_account" name="account" type="text" value={@filters["account"]} />
          </div>

          <div class="lockspire-admin-field">
            <label for="token_client">Client</label>
            <input id="token_client" name="client" type="text" value={@filters["client"]} />
          </div>

          <div class="lockspire-admin-field">
            <label for="token_status">Status</label>
            <select id="token_status" name="status">
              <option value="all" selected={@filters["status"] == "all"}>All</option>
              <option value="active" selected={@filters["status"] == "active"}>Active</option>
              <option value="revoked" selected={@filters["status"] == "revoked"}>Revoked</option>
              <option value="expired" selected={@filters["status"] == "expired"}>Expired</option>
              <option value="reuse_detected" selected={@filters["status"] == "reuse_detected"}>
                Reuse detected
              </option>
            </select>
          </div>

          <AdminComponents.action_bar>
            <AdminComponents.admin_button type="submit">Apply</AdminComponents.admin_button>
          </AdminComponents.action_bar>
        </form>

        <p class="lockspire-admin-help lockspire-admin-help-block">
          Total matching tokens: {@total_tokens}
        </p>

        <%= if @tokens == [] do %>
          <AdminComponents.empty_state
            title="No lifecycle tokens match this view"
            body="Adjust the account, client, or status filter to inspect a different incident slice."
          />
        <% else %>
          <ul class="lockspire-admin-token-list">
            <%= for entry <- @tokens do %>
              <li>
                <a href={token_show_path(entry.token.id)}>
                  {entry.client && (entry.client.name || entry.client.client_id) || entry.token.client_id}
                </a>
                <span>Account {entry.token.account_id || "none"}</span>
                <span>Type {entry.token.token_type}</span>
                <AdminComponents.status_badge status={entry.status} />
              </li>
            <% end %>
          </ul>
        <% end %>
      </AdminComponents.section_card>
    </AdminLayoutLive.shell>
    """
  end

  defp load_tokens(filters) do
    opts =
      []
      |> put_filter(:account_id, filters["account"])
      |> put_filter(:client_id, filters["client"])
      |> put_status_filter(filters["status"])

    case Admin.list_tokens(opts) do
      {:ok, tokens} -> tokens
      {:error, _reason} -> []
    end
  end

  defp normalize_filters(params) do
    %{
      "account" => Map.get(params, "account", ""),
      "client" => Map.get(params, "client", ""),
      "status" => normalize_status(Map.get(params, "status", "all"))
    }
  end

  defp put_filter(opts, _key, nil), do: opts
  defp put_filter(opts, _key, ""), do: opts
  defp put_filter(opts, key, value), do: Keyword.put(opts, key, value)

  defp put_status_filter(opts, "active"), do: Keyword.put(opts, :status, :active)
  defp put_status_filter(opts, "revoked"), do: Keyword.put(opts, :status, :revoked)
  defp put_status_filter(opts, "expired"), do: Keyword.put(opts, :status, :expired)
  defp put_status_filter(opts, "reuse_detected"), do: Keyword.put(opts, :status, :reuse_detected)
  defp put_status_filter(opts, _status), do: opts

  defp normalize_status(status)
       when status in ["all", "active", "revoked", "expired", "reuse_detected"],
       do: status

  defp normalize_status(_status), do: "all"

  defp tokens_index_path, do: Lockspire.mount_path() <> "/admin/tokens"
  defp token_show_path(id), do: tokens_index_path() <> "/" <> Integer.to_string(id)
end
