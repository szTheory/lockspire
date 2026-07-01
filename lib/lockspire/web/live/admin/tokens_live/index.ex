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
          label="Token health"
          value={token_health_summary(@token_metrics)}
          detail={"#{@total_tokens} matching token lifecycle records in this support view."}
          tone={token_health_tone(@token_metrics)}
        >
        </:item>
        <:item
          label="Family pressure"
          value={family_pressure_summary(@tokens)}
          detail="Refresh-family context appears as redacted handles before the detail route."
          tone={family_pressure_tone(@tokens)}
        >
        </:item>
        <:item
          label="Smallest safe action"
          value={token_smallest_safe_action(@tokens)}
          detail="Open one token before choosing any revocation path."
          tone={if @tokens == [], do: :neutral, else: :info}
        >
        </:item>
      </AdminComponents.decision_summary>

      <AdminComponents.section_card
        title="Filter token investigation"
        subtitle="URL filters preserve the support case context while rows stay limited to durable non-secret metadata."
      >
        <AdminComponents.filter_bar action={tokens_index_path()}>
          <:fields>
            <AdminComponents.form_field id="token_account" label="Account">
              <input id="token_account" name="account" type="text" value={@filters["account"]} />
            </AdminComponents.form_field>

            <AdminComponents.form_field id="token_client" label="Client">
              <input id="token_client" name="client" type="text" value={@filters["client"]} />
            </AdminComponents.form_field>

            <AdminComponents.form_field id="token_status" label="Status">
              <select id="token_status" name="status">
                <option value="all" selected={@filters["status"] == "all"}>All</option>
                <option value="active" selected={@filters["status"] == "active"}>Active</option>
                <option value="revoked" selected={@filters["status"] == "revoked"}>Revoked</option>
                <option value="expired" selected={@filters["status"] == "expired"}>Expired</option>
                <option value="reuse_detected" selected={@filters["status"] == "reuse_detected"}>
                  Reuse detected
                </option>
              </select>
            </AdminComponents.form_field>
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
            body="Adjust the account, client, status, or scope filters, or return to the overview to choose a different Support workflow."
          />
        <% else %>
          <AdminComponents.resource_list>
            <%= for entry <- @tokens do %>
              <AdminComponents.dense_resource_row
                title={token_row_title(entry)}
                subtitle={token_row_subtitle(entry)}
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
              </AdminComponents.dense_resource_row>
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
      [] -> "All token lifecycle records"
      parts -> Enum.join(parts, " | ")
    end
  end

  defp selected_filter_part(_label, _type, value) when value in [nil, "", "all"], do: nil

  defp selected_filter_part(label, type, value),
    do: "#{label} #{redacted_handle(type, value)}"

  defp selected_status_filter_part(status) when status in [nil, "", "all"], do: nil
  defp selected_status_filter_part(status), do: "Status #{status}"

  defp token_health_summary(metrics) do
    "#{metrics.active} active, #{metrics.revoked} revoked, #{metrics.expired} expired, #{metrics.reuse_detected} reuse detected"
  end

  defp token_health_tone(%{reuse_detected: count}) when count > 0, do: :danger

  defp token_health_tone(%{revoked: revoked, expired: expired}) when revoked + expired > 0,
    do: :warning

  defp token_health_tone(%{active: active}) when active > 0, do: :success
  defp token_health_tone(_metrics), do: :neutral

  defp family_pressure_summary([]), do: "No matching refresh families"

  defp family_pressure_summary(tokens) do
    cond do
      Enum.any?(tokens, &(&1.status == :reuse_detected)) ->
        "Reuse evidence in matching family"

      family_count(tokens) == 0 ->
        "No refresh families in matching records"

      family_count(tokens) == 1 ->
        "1 refresh family in view"

      true ->
        "#{family_count(tokens)} refresh families in view"
    end
  end

  defp family_pressure_tone(tokens) do
    cond do
      Enum.any?(tokens, &(&1.status == :reuse_detected)) -> :danger
      family_count(tokens) > 0 -> :info
      true -> :neutral
    end
  end

  defp family_count(tokens) do
    tokens
    |> Enum.map(& &1.token.family_id)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> length()
  end

  defp token_smallest_safe_action([]), do: "Adjust filters"

  defp token_smallest_safe_action(tokens) do
    if Enum.any?(tokens, &(&1.status == :reuse_detected)),
      do: "Review affected token",
      else: "Review token"
  end

  defp token_row_title(entry),
    do: "#{status_label(entry.status)} #{token_type_label(entry.token.token_type)}"

  defp token_row_subtitle(entry) do
    "Client #{token_title(entry)}"
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

  defp formatted_timestamp(nil), do: "Not recorded"

  defp formatted_timestamp(%DateTime{} = value),
    do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")

  defp formatted_timestamp(value), do: to_string(value)

  defp tokens_index_path, do: Lockspire.mount_path() <> "/admin/tokens"
  defp token_show_path(id), do: tokens_index_path() <> "/" <> Integer.to_string(id)
end
