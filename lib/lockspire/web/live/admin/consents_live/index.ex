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
          <span>Selected account: {selected_filter(:account, @filters["account"])}</span>
          <span>Selected client: {selected_filter(:client, @filters["client"])}</span>
          <span>Selected status: {selected_filter(:status, @filters["status"])}</span>
        </:summary>
      </AdminComponents.page_hero>

      <AdminComponents.decision_summary>
        <:item
          label="Selected filters"
          value={selected_filter_summary(@filters)}
          detail="Raw URL filters stay editable below while summaries use redacted handles."
          tone={:info}
        >
        </:item>
        <:item
          label="Grant status"
          value={grant_status_summary(@consent_metrics)}
          detail={"#{@total_consents} matching stored grants in this support view."}
          tone={grant_status_tone(@consent_metrics)}
        >
        </:item>
        <:item
          label="Scope context"
          value={scope_context_summary(@consents)}
          detail="Scope values wrap in rows so long grant context stays scannable."
          tone={scope_context_tone(@consents)}
        >
        </:item>
        <:item
          label="Smallest safe action"
          value={consent_smallest_safe_action(@consents)}
          detail="Open one stored grant before choosing any revocation path."
          tone={if @consents == [], do: :neutral, else: :info}
        >
        </:item>
      </AdminComponents.decision_summary>

      <AdminComponents.section_card
        title="Filter consent grants"
        subtitle="URL filters preserve support case context while rows show only durable non-secret grant metadata."
      >
        <AdminComponents.filter_bar action={consents_index_path()}>
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
            body="Adjust the account, client, status, or scope filters, or return to the overview to choose a different Support workflow."
          />
        <% else %>
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
                  <AdminComponents.status_badge status={consent.grant.kind} />
                </:status>
                <:actions>
                  <AdminComponents.admin_button href={consent_show_path(consent.grant.id)}>
                    Review stored grant
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

  defp selected_filter(_type, ""), do: "All"
  defp selected_filter(_type, "all"), do: "All"

  defp selected_filter(type, value) when type in [:account, :client],
    do: redacted_handle(type, value)

  defp selected_filter(_type, value), do: value

  defp selected_filter_summary(filters) do
    [
      selected_filter_part("Account", :account, filters["account"]),
      selected_filter_part("Client", :client, filters["client"]),
      selected_status_filter_part(filters["status"])
    ]
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> "All stored consent grants"
      parts -> Enum.join(parts, " | ")
    end
  end

  defp selected_filter_part(_label, _type, value) when value in [nil, "", "all"], do: nil

  defp selected_filter_part(label, type, value),
    do: "#{label} #{redacted_handle(type, value)}"

  defp selected_status_filter_part(status) when status in [nil, "", "all"], do: nil
  defp selected_status_filter_part(status), do: "Status #{status}"

  defp grant_status_summary(metrics),
    do: "#{metrics.active} active, #{metrics.revoked} revoked"

  defp grant_status_tone(%{revoked: revoked}) when revoked > 0, do: :warning
  defp grant_status_tone(%{active: active}) when active > 0, do: :success
  defp grant_status_tone(_metrics), do: :neutral

  defp scope_context_summary([]), do: "No scopes in matching grants"

  defp scope_context_summary(consents) do
    case unique_scope_count(consents) do
      0 -> "No scopes in matching grants"
      1 -> "1 scope across matching grants"
      count -> "#{count} scopes across matching grants"
    end
  end

  defp scope_context_tone([]), do: :neutral
  defp scope_context_tone(consents) when is_list(consents), do: :info

  defp unique_scope_count(consents) do
    consents
    |> Enum.flat_map(& &1.grant.scopes)
    |> Enum.uniq()
    |> length()
  end

  defp consent_smallest_safe_action([]), do: "Adjust filters"
  defp consent_smallest_safe_action(_consents), do: "Review stored grant"

  defp consent_row_title(consent),
    do: "#{status_label(consent.grant.status)} #{grant_kind_label(consent.grant.kind)} grant"

  defp consent_row_subtitle(consent) do
    "Client #{consent_title(consent)}"
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
