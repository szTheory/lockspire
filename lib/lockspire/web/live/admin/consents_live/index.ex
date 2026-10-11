defmodule Lockspire.Web.Live.Admin.ConsentsLive.Index do
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
       page_title: "Consents",
       current_section: :consents,
       consents: [],
       consent_read_state: :loading,
       filters: @default_filters,
       total_consents: 0,
       total_consents_label: consent_count_label(0),
       consent_metrics: consent_metrics([])
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filters = normalize_filters(params)

    {:noreply, assign_consents(socket, filters)}
  end

  @impl true
  def handle_event("filter_inventory", params, socket) do
    filters = normalize_filters(params)

    {:noreply, push_patch(socket, to: consents_index_path(filters))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero
        eyebrow="Support"
        title="Consent grant investigation"
        body="Review stored consent grants by account, client, status, and scopes. Open a grant to review its permissions or revoke it."
      >
        <:summary>
          <span>Selected account: {selected_filter(:account, @filters["account"])}</span>
          <span>Selected client: {selected_filter(:client, @filters["client"])}</span>
          <span>Selected status: {selected_filter(:status, @filters["status"])}</span>
        </:summary>
      </AdminComponents.page_hero>

      <AdminComponents.section_card
        title="Filter consent grants"
        subtitle="Filters stay in the URL so you can return to the same results. Rows show the stored grant details."
      >
        <AdminComponents.filter_bar action={consents_index_path()} phx_submit="filter_inventory">
          <:fields>
            <AdminComponents.form_field id="consent_account" label="Account">
              <input id="consent_account" name="account" type="text" value={@filters["account"]} />
            </AdminComponents.form_field>

            <AdminComponents.form_field id="consent_client" label="Client">
              <input id="consent_client" name="client" type="text" value={@filters["client"]} />
            </AdminComponents.form_field>

            <AdminComponents.form_field id="consent_status" label="Status">
              <select id="consent_status" name="status">
                <option value="all" selected={@filters["status"] == "all"}>All</option>
                <option value="active" selected={@filters["status"] == "active"}>Active</option>
                <option value="revoked" selected={@filters["status"] == "revoked"}>Revoked</option>
              </select>
            </AdminComponents.form_field>
          </:fields>
          <:help>
          <p :if={@consent_read_state == :loaded}>{@total_consents_label}</p>
          </:help>
          <:actions>
            <AdminComponents.admin_button
              type="submit"
              phx-disable-with="Filtering consent grants…"
            >
              Filter consent grants
            </AdminComponents.admin_button>
          </:actions>
        </AdminComponents.filter_bar>

        <AdminComponents.metric_grid :if={@consent_read_state == :loaded}>
          <AdminComponents.summary_stat value={@consent_metrics.active} label="Active grants" />
          <AdminComponents.summary_stat value={@consent_metrics.revoked} label="Revoked grants" />
          <AdminComponents.summary_stat
            value={@total_consents}
            label={matching_grant_metric_label(@total_consents)}
          />
        </AdminComponents.metric_grid>

        <%= cond do %>
          <% @consent_read_state == :error -> %>
            <AdminComponents.empty_state
              title="Could not load consent grants"
              body="The grant inventory is unavailable. Your filters are still here; retry this support workflow or return to the overview."
            >
              <:actions>
                <AdminComponents.admin_button href={consents_index_path(@filters)}>
                  Try loading consent grants again
                </AdminComponents.admin_button>
                <AdminComponents.admin_button href={Lockspire.mount_path() <> "/admin/"}>
                  Return to overview
                </AdminComponents.admin_button>
              </:actions>
            </AdminComponents.empty_state>
          <% @consent_read_state == :loading -> %>
            <p role="status">Loading consent grants…</p>
          <% @consent_read_state == :loaded and @consents == [] -> %>
            <AdminComponents.empty_state
              title="No matching consent grants"
              body="Adjust the account, client, or status filters to review another stored grant."
            />
          <% true -> %>
          <AdminComponents.resource_list>
            <%= for consent <- @consents do %>
              <AdminComponents.dense_resource_row
                title={consent_row_title(consent)}
                subtitle={consent_row_subtitle(consent)}
              >
                <:meta>
                  <span>
                    Account
                    <AdminComponents.long_value
                      value={redacted_account_identifier(consent.grant.account_id)}
                      kind={:id}
                    />
                  </span>
                  <span>
                    Client
                    <AdminComponents.long_value
                      value={safe_identifier(consent.grant.client_id)}
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
                  <AdminComponents.status_badge status={consent.grant.kind} />
                </:status>
                <:actions>
                  <AdminComponents.admin_button
                    href={consent_show_path(consent.grant.id, @filters)}
                  >
                    View consent grant details
                  </AdminComponents.admin_button>
                </:actions>
              </AdminComponents.dense_resource_row>
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

    case read_consents(opts) do
      {:ok, consents} -> {:loaded, consents}
      {:error, _reason} -> {:error, []}
    end
  end

  defp assign_consents(socket, filters) do
    {read_state, consents} = load_consents(filters)

    assign(socket,
      filters: filters,
      consent_read_state: read_state,
      consents: consents,
      total_consents: length(consents),
      total_consents_label: consent_count_label(length(consents)),
      consent_metrics: consent_metrics(consents)
    )
  end

  defp read_consents(opts) do
    Admin.list_consents(opts)
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

  defp consent_count_label(0), do: "0 matching grants"
  defp consent_count_label(1), do: "1 matching grant"
  defp consent_count_label(count), do: "#{count} matching grants"

  defp matching_grant_metric_label(1), do: "Matching grant"
  defp matching_grant_metric_label(_count), do: "Matching grants"

  defp selected_filter(_type, ""), do: "All"
  defp selected_filter(_type, "all"), do: "All"

  defp selected_filter(type, value) when type in [:account, :client], do: safe_identifier(value)

  defp selected_filter(_type, value), do: value

  defp consent_row_title(consent),
    do: "#{status_label(consent.grant.status)} #{grant_kind_label(consent.grant.kind)} grant"

  defp consent_row_subtitle(consent) do
    case consent_title(consent) do
      "Client description unavailable" = copy -> copy
      title -> "Client #{title}"
    end
  end

  defp status_label(status) when is_atom(status) do
    status
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp status_label(status), do: to_string(status)

  defp grant_kind_label(kind) when is_atom(kind) do
    kind
    |> Atom.to_string()
    |> String.replace("_", " ")
  end

  defp grant_kind_label(kind), do: to_string(kind)

  defp consent_title(consent) do
    case consent.client do
      %{name: name} when is_binary(name) and name != "" -> name
      %{client_id: client_id} when is_binary(client_id) and client_id != "" -> client_id
      _missing -> "Client description unavailable"
    end
  end

  defp safe_identifier(nil), do: "Not recorded"
  defp safe_identifier(value) when is_binary(value), do: value
  defp safe_identifier(value) when is_integer(value), do: Integer.to_string(value)
  defp safe_identifier(value), do: to_string(value)

  defp redacted_account_identifier(nil), do: "Not recorded"
  defp redacted_account_identifier(value), do: Redaction.handle(:account, value)

  defp scope_label([]), do: "No scopes recorded"
  defp scope_label(scopes), do: Enum.join(scopes, ", ")

  defp grant_timestamp(%{revoked_at: %DateTime{} = revoked_at}), do: revoked_at
  defp grant_timestamp(%{updated_at: %DateTime{} = updated_at}), do: updated_at
  defp grant_timestamp(%{granted_at: granted_at}), do: granted_at

  defp formatted_timestamp(nil), do: "Not recorded"

  defp formatted_timestamp(%DateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")

  defp formatted_timestamp(value), do: to_string(value)

  defp consents_index_path(filters \\ @default_filters) do
    append_filter_query(consents_base_path(), filters)
  end

  defp consents_base_path, do: Lockspire.mount_path() <> "/admin/consents"

  defp append_filter_query(path, @default_filters), do: path

  defp append_filter_query(path, filters) do
    query = URI.encode_query(Map.to_list(filters))
    if query == "", do: path, else: path <> "?" <> query
  end

  defp consent_show_path(id, filters) do
    append_filter_query(consents_base_path() <> "/" <> Integer.to_string(id), filters)
  end
end
