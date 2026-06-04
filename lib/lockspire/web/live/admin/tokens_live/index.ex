defmodule Lockspire.Web.Live.Admin.TokensLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Redaction
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
       total_tokens: 0,
       token_metrics: token_metrics([])
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
       total_tokens: length(tokens),
       token_metrics: token_metrics(tokens)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero
        eyebrow="Support"
        title="Token investigation"
        body="Investigate account, client, status, refresh-family, expiration, and revocation state without exposing token material."
      >
        <:summary>
          <span>Selected account: {selected_filter(@filters["account"])}</span>
          <span>Selected client: {selected_filter(@filters["client"])}</span>
          <span>Selected status: {selected_filter(@filters["status"])}</span>
        </:summary>
      </AdminComponents.page_hero>

      <AdminComponents.section_card
        title="Filter token investigation"
        subtitle="URL filters preserve the support case context while rows stay limited to durable non-secret metadata."
      >
        <AdminComponents.filter_bar action={tokens_index_path()}>
          <:fields>
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
          </:fields>
          <:help>
            <p>Total matching tokens: {@total_tokens}</p>
          </:help>
          <:actions>
            <AdminComponents.admin_button type="submit">Filter tokens</AdminComponents.admin_button>
          </:actions>
        </AdminComponents.filter_bar>

        <AdminComponents.metric_grid>
          <AdminComponents.summary_stat value={@token_metrics.active} label="Active" />
          <AdminComponents.summary_stat value={@token_metrics.revoked} label="Revoked" />
          <AdminComponents.summary_stat value={@token_metrics.expired} label="Expired" />
          <AdminComponents.summary_stat
            value={@token_metrics.reuse_detected}
            label="Reuse detected"
          />
        </AdminComponents.metric_grid>

        <%= if @tokens == [] do %>
          <AdminComponents.empty_state
            title="No investigation results match these filters"
            body="Adjust the account, client, or status filters, or return to the overview to choose a different support workflow."
          />
        <% else %>
          <AdminComponents.resource_list>
            <%= for entry <- @tokens do %>
              <AdminComponents.resource_item
                href={token_show_path(entry.token.id)}
                title={token_title(entry)}
                subtitle={"#{entry.token.token_type} token"}
              >
                <:meta>
                  <span>
                    Client
                    <AdminComponents.long_value
                      value={redacted_handle(:client, entry.token.client_id)}
                      kind={:id}
                    />
                  </span>
                  <span>
                    Account
                    <AdminComponents.long_value
                      value={redacted_handle(:account, entry.token.account_id)}
                      kind={:id}
                    />
                  </span>
                  <span>
                    Family
                    <AdminComponents.long_value
                      value={redacted_handle(:family, entry.token.family_id)}
                      kind={:id}
                    />
                  </span>
                  <span>
                    Expires
                    <AdminComponents.long_value value={formatted_timestamp(entry.token.expires_at)} kind={:timestamp} />
                  </span>
                </:meta>
                <:status>
                  <AdminComponents.status_badge status={entry.status} />
                </:status>
                <:actions>
                  <AdminComponents.admin_button href={token_show_path(entry.token.id)}>
                    Review token
                  </AdminComponents.admin_button>
                </:actions>
              </AdminComponents.resource_item>
            <% end %>
          </AdminComponents.resource_list>
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

  defp token_metrics(tokens) do
    %{
      active: Enum.count(tokens, &(&1.status == :active)),
      revoked: Enum.count(tokens, &(&1.status == :revoked)),
      expired: Enum.count(tokens, &(&1.status == :expired)),
      reuse_detected: Enum.count(tokens, &(&1.status == :reuse_detected))
    }
  end

  defp selected_filter(""), do: "All"
  defp selected_filter("all"), do: "All"
  defp selected_filter(value), do: value

  defp token_title(entry) do
    (entry.client && (entry.client.name || entry.client.client_id)) ||
      redacted_handle(:client, entry.token.client_id)
  end

  defp redacted_handle(_type, nil), do: "Not recorded"
  defp redacted_handle(type, value), do: Redaction.handle(type, value)

  defp formatted_timestamp(nil), do: "Not recorded"

  defp formatted_timestamp(%DateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")

  defp formatted_timestamp(value), do: to_string(value)

  defp tokens_index_path, do: Lockspire.mount_path() <> "/admin/tokens"
  defp token_show_path(id), do: tokens_index_path() <> "/" <> Integer.to_string(id)
end
