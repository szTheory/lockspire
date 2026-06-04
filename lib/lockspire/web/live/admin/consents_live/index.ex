defmodule Lockspire.Web.Live.Admin.ConsentsLive.Index do
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
       page_title: "Consents",
       current_section: :consents,
       consents: [],
       filters: %{"account" => "", "client" => "", "status" => "all"},
       total_consents: 0,
       consent_metrics: consent_metrics([])
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
       total_consents: length(consents),
       consent_metrics: consent_metrics(consents)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero
        eyebrow="Support"
        title="Consent grant investigation"
        body="Investigate stored grants by account, client, status, scopes, and safe revocation path without exposing secret material."
      >
        <:summary>
          <span>Selected account: {selected_filter(@filters["account"])}</span>
          <span>Selected client: {selected_filter(@filters["client"])}</span>
          <span>Selected status: {selected_filter(@filters["status"])}</span>
        </:summary>
      </AdminComponents.page_hero>

      <AdminComponents.section_card
        title="Filter consent grants"
        subtitle="URL filters preserve support case context while rows show only durable non-secret grant metadata."
      >
        <AdminComponents.filter_bar action={consents_index_path()}>
          <:fields>
            <div class="lockspire-admin-field">
              <label for="consent_account">Account</label>
              <input id="consent_account" name="account" type="text" value={@filters["account"]} />
            </div>

            <div class="lockspire-admin-field">
              <label for="consent_client">Client</label>
              <input id="consent_client" name="client" type="text" value={@filters["client"]} />
            </div>

            <div class="lockspire-admin-field">
              <label for="consent_status">Status</label>
              <select id="consent_status" name="status">
                <option value="all" selected={@filters["status"] == "all"}>All</option>
                <option value="active" selected={@filters["status"] == "active"}>Active</option>
                <option value="revoked" selected={@filters["status"] == "revoked"}>Revoked</option>
              </select>
            </div>
          </:fields>
          <:help>
            <p>Total matching consents: {@total_consents}</p>
          </:help>
          <:actions>
            <AdminComponents.admin_button type="submit">Filter consent grants</AdminComponents.admin_button>
          </:actions>
        </AdminComponents.filter_bar>

        <AdminComponents.metric_grid>
          <AdminComponents.summary_stat value={@consent_metrics.active} label="Active grants" />
          <AdminComponents.summary_stat value={@consent_metrics.revoked} label="Revoked grants" />
          <AdminComponents.summary_stat value={@total_consents} label="Matching grants" />
        </AdminComponents.metric_grid>

        <%= if @consents == [] do %>
          <AdminComponents.empty_state
            title="No investigation results match these filters"
            body="Adjust the account, client, or status filters, or return to the overview to choose a different support workflow."
          />
        <% else %>
          <AdminComponents.resource_list>
            <%= for consent <- @consents do %>
              <AdminComponents.resource_item
                href={consent_show_path(consent.grant.id)}
                title={consent_title(consent)}
                subtitle={"#{consent.grant.kind} consent grant"}
              >
                <:meta>
                  <span>
                    Account
                    <AdminComponents.long_value
                      value={redacted_handle(:account, consent.grant.account_id)}
                      kind={:id}
                    />
                  </span>
                  <span>
                    Client
                    <AdminComponents.long_value
                      value={redacted_handle(:client, consent.grant.client_id)}
                      kind={:id}
                    />
                  </span>
                  <span>
                    Scopes
                    <AdminComponents.long_value value={scope_label(consent.grant.scopes)} kind={:text} />
                  </span>
                  <span>
                    Updated
                    <AdminComponents.long_value
                      value={formatted_timestamp(grant_timestamp(consent.grant))}
                      kind={:timestamp}
                    />
                  </span>
                </:meta>
                <:status>
                  <AdminComponents.status_badge status={consent.grant.status} />
                </:status>
                <:actions>
                  <AdminComponents.admin_button href={consent_show_path(consent.grant.id)}>
                    Review stored grant
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

  defp consent_metrics(consents) do
    %{
      active: Enum.count(consents, &(&1.grant.status == :active)),
      revoked: Enum.count(consents, &(&1.grant.status == :revoked))
    }
  end

  defp selected_filter(""), do: "All"
  defp selected_filter("all"), do: "All"
  defp selected_filter(value), do: value

  defp consent_title(consent) do
    (consent.client && (consent.client.name || consent.client.client_id)) ||
      redacted_handle(:client, consent.grant.client_id)
  end

  defp redacted_handle(_type, nil), do: "Not recorded"
  defp redacted_handle(type, value), do: Redaction.handle(type, value)

  defp scope_label([]), do: "No scopes recorded"
  defp scope_label(scopes), do: Enum.join(scopes, ", ")

  defp grant_timestamp(%{revoked_at: %DateTime{} = revoked_at}), do: revoked_at
  defp grant_timestamp(%{updated_at: %DateTime{} = updated_at}), do: updated_at
  defp grant_timestamp(%{granted_at: granted_at}), do: granted_at

  defp formatted_timestamp(nil), do: "Not recorded"

  defp formatted_timestamp(%DateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")

  defp formatted_timestamp(value), do: to_string(value)

  defp consents_index_path, do: Lockspire.mount_path() <> "/admin/consents"
  defp consent_show_path(id), do: consents_index_path() <> "/" <> Integer.to_string(id)
end
