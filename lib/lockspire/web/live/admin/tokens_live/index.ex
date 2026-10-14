defmodule Lockspire.Web.Live.Admin.TokensLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Redaction
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @default_filters %{"account" => "", "client" => "", "status" => "all"}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Tokens",
       current_section: :tokens,
       tokens: [],
       inventory_state: :loading,
       filters: %{"account" => "", "client" => "", "status" => "all"},
       total_tokens: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filters = normalize_filters(params)

    {:noreply, assign_tokens(socket, filters)}
  end

  @impl true
  def handle_event("filter_inventory", params, socket) do
    filters = normalize_filters(params)

    {:noreply, push_patch(socket, to: tokens_index_path(filters))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero
        body="Find access or refresh tokens by account, app, or status. Token values stay hidden."
      />

      <AdminComponents.section_card
        title="Find tokens"
      >
        <AdminComponents.filter_bar action={tokens_index_path()} phx_submit="filter_inventory">
          <:fields>
            <AdminComponents.form_field id="token_account" label="Account">
              <input id="token_account" name="account" type="text" value={@filters["account"]} />
            </AdminComponents.form_field>

            <AdminComponents.form_field id="token_client" label="App">
              <input id="token_client" name="client" type="text" value={@filters["client"]} />
            </AdminComponents.form_field>

            <AdminComponents.form_field id="token_status" label="Status">
              <AdminComponents.select_control id="token_status" name="status">
                <option value="all" selected={@filters["status"] == "all"}>All</option>
                <option value="active" selected={@filters["status"] == "active"}>Active</option>
                <option value="revoked" selected={@filters["status"] == "revoked"}>Revoked</option>
                <option value="expired" selected={@filters["status"] == "expired"}>Expired</option>
                <option value="reuse_detected" selected={@filters["status"] == "reuse_detected"}>
                  Used after replacement
                </option>
              </AdminComponents.select_control>
            </AdminComponents.form_field>
          </:fields>
          <:help>
            <p :if={@inventory_state == :loaded}>{matching_count_label(@total_tokens)}</p>
            <p :if={@inventory_state == :error}>Matching token count is unavailable.</p>
          </:help>
          <:actions>
            <AdminComponents.admin_button type="submit" phx-disable-with="Filtering tokens…">
              Filter tokens
            </AdminComponents.admin_button>
          </:actions>
        </AdminComponents.filter_bar>

        <div class="lockspire-admin-token-inventory__results" aria-live="polite" aria-atomic="true">
        <%= case @inventory_state do %>
        <% :loading -> %>
          <p role="status">Loading tokens…</p>
        <% :error -> %>
          <AdminComponents.empty_state
            title="Could not load tokens"
            body="Lockspire could not read the token inventory. The selected filters are still available; retry the read or change them."
          >
            <:actions>
              <AdminComponents.admin_button href={token_filter_path(@filters)}>
                Try loading tokens again
              </AdminComponents.admin_button>
            </:actions>
          </AdminComponents.empty_state>
        <% :loaded when @tokens == [] -> %>
          <AdminComponents.empty_state
            title="No matching tokens"
            body="No token records match the selected account, app, and status filters. Change a filter or clear the filters to search again."
          >
            <:actions>
              <AdminComponents.admin_button href={tokens_index_path()}>
                Clear filters
              </AdminComponents.admin_button>
            </:actions>
          </AdminComponents.empty_state>
        <% :loaded -> %>
          <AdminComponents.resource_list>
            <%= for entry <- @tokens do %>
              <AdminComponents.dense_resource_row
                title={token_row_title(entry)}
                subtitle={token_row_subtitle(entry)}
                class="lockspire-admin-token-row"
              >
                <:meta>
                  <dl class="lockspire-admin-token-row__facts">
                  <div>
                    <dt>Token</dt>
                    <dd>
                    <AdminComponents.long_value
                      value={Lockspire.Redaction.handle(:token, entry.token.id)}
                      kind={:id}
                    />
                    </dd>
                  </div>
                  <div>
                    <dt>Account</dt>
                    <dd>
                    <AdminComponents.long_value
                      value={redacted_handle(:account, entry.token.account_id)}
                      kind={:id}
                    />
                    </dd>
                  </div>
                  </dl>
                </:meta>
                <:actions>
                  <AdminComponents.admin_button href={token_show_path(entry.token.id, @filters)}>
                    View token details
                  </AdminComponents.admin_button>
                </:actions>
              </AdminComponents.dense_resource_row>
            <% end %>
          </AdminComponents.resource_list>
        <% end %>
        </div>

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
      {:ok, tokens} -> {:ok, tokens}
      {:error, reason} -> {:error, reason}
    end
  end

  defp assign_tokens(socket, filters) do
    case load_tokens(filters) do
      {:ok, tokens} ->
        assign(socket,
          filters: filters,
          tokens: tokens,
          inventory_state: :loaded,
          total_tokens: length(tokens)
        )

      {:error, _reason} ->
        assign(socket,
          filters: filters,
          tokens: [],
          inventory_state: :error,
          total_tokens: nil
        )
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

  defp matching_count_label(1), do: "Matching token: 1"
  defp matching_count_label(count), do: "Matching tokens: #{count}"

  defp token_row_title(%{status: :reuse_detected, token: token}),
    do: "#{String.capitalize(token_type_label(token.token_type))} used after replacement"

  defp token_row_title(entry),
    do: "#{status_label(entry.status)} #{token_type_label(entry.token.token_type)}"

  defp token_row_subtitle(entry) do
    "App #{token_title(entry)}"
  end

  defp status_label(status) when is_atom(status) do
    status
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp status_label(status), do: to_string(status)

  defp token_type_label(type) when is_atom(type) do
    type
    |> Atom.to_string()
    |> String.replace("_", " ")
  end

  defp token_type_label(type), do: to_string(type)

  defp token_title(entry) do
    (entry.client && (entry.client.name || entry.client.client_id)) ||
      redacted_handle(:client, entry.token.client_id)
  end

  defp redacted_handle(_type, nil), do: "Not recorded"
  defp redacted_handle(type, value), do: Redaction.handle(type, value)

  defp tokens_index_path, do: Lockspire.mount_path() <> "/admin/tokens"
  defp tokens_index_path(filters), do: tokens_index_path() <> "?" <> URI.encode_query(filters)

  defp token_show_path(id, filters) do
    path = tokens_index_path() <> "/" <> Integer.to_string(id)
    append_filter_query(path, filters)
  end

  defp token_filter_path(filters) do
    append_filter_query(tokens_index_path(), filters)
  end

  defp append_filter_query(path, @default_filters), do: path

  defp append_filter_query(path, filters),
    do: path <> "?" <> URI.encode_query(filters)
end
