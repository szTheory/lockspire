defmodule Lockspire.Web.Live.Admin.ConsentsLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Consents",
       current_section: :consents,
       consents: [],
       filters: %{"account" => "", "client" => "", "status" => "all"},
       total_consents: 0
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filters = normalize_filters(params)
    consents = load_consents(filters)

    {:noreply,
     assign(socket,
       filters: filters,
       consents: consents,
       total_consents: length(consents)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.section_card
        title="Consent review"
        subtitle="Answer who granted what, to which client, and whether the durable grant is still active."
      >
        <form method="get" action={consents_index_path()}>
          <label for="consent_account">Account</label>
          <input id="consent_account" name="account" type="text" value={@filters["account"]} />

          <label for="consent_client">Client</label>
          <input id="consent_client" name="client" type="text" value={@filters["client"]} />

          <label for="consent_status">Status</label>
          <select id="consent_status" name="status">
            <option value="all" selected={@filters["status"] == "all"}>All</option>
            <option value="active" selected={@filters["status"] == "active"}>Active</option>
            <option value="revoked" selected={@filters["status"] == "revoked"}>Revoked</option>
          </select>

          <button type="submit">Apply</button>
        </form>

        <p>Total matching consents: {@total_consents}</p>

        <%= if @consents == [] do %>
          <AdminComponents.empty_state
            title="No consent grants match this view"
            body="Adjust the account, client, or status filter to continue the support review."
          />
        <% else %>
          <ul class="lockspire-admin-consent-list">
            <%= for consent <- @consents do %>
              <li>
                <a href={consent_show_path(consent.grant.id)}>
                  {consent.client && (consent.client.name || consent.client.client_id) ||
                    consent.grant.client_id}
                </a>
                <span>Account {consent.grant.account_id}</span>
                <span>Scopes {Enum.join(consent.grant.scopes, ", ")}</span>
                <AdminComponents.status_badge status={consent.grant.status} />
              </li>
            <% end %>
          </ul>
        <% end %>
      </AdminComponents.section_card>
    </AdminLayoutLive.shell>
    """
  end

  defp load_consents(filters) do
    opts =
      []
      |> put_filter(:account_id, filters["account"])
      |> put_filter(:client_id, filters["client"])
      |> put_status_filter(filters["status"])

    case Admin.list_consents(opts) do
      {:ok, consents} -> consents
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
  defp put_status_filter(opts, _status), do: opts

  defp normalize_status(status) when status in ["all", "active", "revoked"], do: status
  defp normalize_status(_status), do: "all"

  defp consents_index_path, do: Lockspire.mount_path() <> "/admin/consents"
  defp consent_show_path(id), do: consents_index_path() <> "/" <> Integer.to_string(id)
end
