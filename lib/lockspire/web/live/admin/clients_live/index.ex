defmodule Lockspire.Web.Live.Admin.ClientsLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.Admin.ClientsLive.FormComponent
  alias Lockspire.Web.Live.AdminLayoutLive

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Clients",
       current_section: :clients,
       clients: [],
       matching_clients: nil,
       total_clients: nil,
       inventory_state: :loading,
       filters: %{"q" => "", "status" => "all", "provenance" => "all", "page" => "1"},
       form_errors: [],
       created_result: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filters = normalize_filters(params)

    {:noreply, assign_inventory(socket, filters)}
  end

  @impl true
  def handle_event("filter_inventory", params, socket) do
    filters = normalize_filters(params)

    {:noreply, push_patch(socket, to: clients_index_path(filters))}
  end

  @impl true
  def handle_event("save_client", %{"client" => client_params}, socket) do
    case Admin.create_client(create_attrs(client_params)) do
      {:ok, result} ->
        filters = socket.assigns.filters

        {:noreply,
         socket
         |> assign_inventory(filters)
         |> assign(created_result: result, form_errors: [])}

      {:error, errors} ->
        {:noreply, assign(socket, form_errors: errors, created_result: nil)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero
        eyebrow="Configure"
        title="Client inventory"
        body="Filter clients, choose the right workspace, or create a client while keeping credential handoff copy-once."
      />

      <AdminComponents.section_card title="Find a client" subtitle="Filter the inventory, then open a client to review its current configuration.">
        <AdminComponents.filter_bar action={clients_index_path()} phx_submit="filter_inventory">
          <:fields>
            <div class="lockspire-admin-field">
              <label for="client_search">Search</label>
              <input
                id="client_search"
                name="q"
                type="text"
                value={@filters["q"]}
                autocomplete="off"
              />
            </div>

            <div class="lockspire-admin-field">
              <label for="client_status">Status</label>
              <select id="client_status" name="status">
                <option value="all" selected={@filters["status"] == "all"}>All</option>
                <option value="active" selected={@filters["status"] == "active"}>Active</option>
                <option value="disabled" selected={@filters["status"] == "disabled"}>Disabled</option>
              </select>
            </div>

            <div class="lockspire-admin-field">
              <label for="client_provenance">Provenance</label>
              <select id="client_provenance" name="provenance">
                <option value="all" selected={@filters["provenance"] == "all"}>All</option>
                <option value="operator" selected={@filters["provenance"] == "operator"}>Operator</option>
                <option value="self_registered" selected={@filters["provenance"] == "self_registered"}>
                  Self-Registered
                </option>
              </select>
            </div>
          </:fields>
          <:help>
            <p :if={@inventory_state == :loaded}>{client_count_label(@matching_clients)} of {@total_clients} total clients</p>
            <p :if={@inventory_state == :error}>Matching count unavailable while the client inventory is unavailable.</p>
          </:help>
          <:actions>
            <AdminComponents.admin_button
              variant={:secondary}
              type="submit"
              phx-disable-with="Filtering clients…"
            >
              Filter clients
            </AdminComponents.admin_button>
          </:actions>
        </AdminComponents.filter_bar>

        <div class="lockspire-admin-client-inventory__results" aria-live="polite">
          <AdminComponents.alert
            :if={@inventory_state == :error}
            variant={:danger}
            title="Could not load clients"
          >
            <p>Your filters and investigation context are still available. Reload this view or return to the inventory and try again.</p>
            <div class="lockspire-admin-client-inventory__recovery">
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={clients_index_path(@filters)}>
                Reload this view
              </.link>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={clients_index_path()}>
                Return to the inventory
              </.link>
            </div>
          </AdminComponents.alert>

          <AdminComponents.empty_state
            :if={@inventory_state == :loaded and @clients == []}
            title="No matching clients"
            body="Change or clear the filters to see other records."
          >
            <:actions>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={clients_index_path()}>
                Clear filters
              </.link>
            </:actions>
          </AdminComponents.empty_state>

          <AdminComponents.resource_list :if={@inventory_state == :loaded and @clients != []}>
            <%= for client <- @clients do %>
              <AdminComponents.resource_item
                title={client.name || client.client_id}
                subtitle={client.client_id}
              >
                <:status>
                  <AdminComponents.status_badge status={status_for(client)} />
                  <AdminComponents.status_badge status={client.provenance} />
                </:status>
                <:actions>
                  <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={client_show_path(client.client_id)}>
                    View client
                  </.link>
                </:actions>
              </AdminComponents.resource_item>
            <% end %>
          </AdminComponents.resource_list>
        </div>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="Selected client context"
        subtitle="The current URL filters remain available while you review the matching records."
      >
        <div class="lockspire-admin-detail-section">
          <p>Search: {selected_filter_label(@filters["q"], "all clients")}</p>
          <p>Status: {@filters["status"]}</p>
          <p>Provenance: {@filters["provenance"]}</p>
          <p :if={@inventory_state == :loaded}>Matching clients: {@matching_clients}</p>
          <p :if={@inventory_state == :loaded}>Total clients: {@total_clients}</p>
        </div>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="Create client"
        subtitle="Create a client through the existing Lockspire Admin API and copy any plaintext secret before leaving this state."
      >
        <FormComponent.client_form mode={:new} errors={@form_errors} />

        <div :if={@created_result}>
          <p>Client ID: <code>{@created_result.client.client_id}</code></p>
          <AdminComponents.copy_once_secret_panel
            title="Client created"
            body={
              if @created_result.client_secret,
                do:
                  "Plaintext is shown once. Lockspire stores only the hash and does not re-show it after this response.",
                else: "This public client does not use a client secret."
            }
            label="Client secret"
            value={@created_result.client_secret}
            redacted={is_nil(@created_result.client_secret)}
          />
        </div>
      </AdminComponents.section_card>
    </AdminLayoutLive.shell>
    """
  end

  defp load_clients(filters) do
    opts =
      [search: blank_to_nil(filters["q"])]
      |> put_status_filter(filters["status"])
      |> put_provenance_filter(filters["provenance"])

    case Admin.list_clients(opts) do
      {:ok, clients} -> {:ok, clients}
      {:error, reason} -> {:error, reason}
    end
  end

  defp assign_inventory(socket, filters) do
    with {:ok, clients} <- load_clients(filters),
         {:ok, all_clients} <- load_clients(base_filters()) do
      assign(socket,
        filters: filters,
        clients: paginate(clients, filters),
        matching_clients: length(clients),
        total_clients: length(all_clients),
        inventory_state: :loaded
      )
    else
      {:error, _reason} ->
        assign(socket,
          filters: filters,
          clients: [],
          matching_clients: nil,
          total_clients: nil,
          inventory_state: :error
        )
    end
  end

  defp paginate(clients, filters) do
    page = parse_page(filters["page"])
    Enum.slice(clients, (page - 1) * @per_page, @per_page)
  end

  defp normalize_filters(params) do
    %{
      "q" => Map.get(params, "q", ""),
      "status" => normalize_status(Map.get(params, "status", "all")),
      "provenance" => normalize_provenance(Map.get(params, "provenance", "all")),
      "page" => Integer.to_string(parse_page(Map.get(params, "page", "1")))
    }
  end

  defp base_filters do
    %{"q" => "", "status" => "all", "provenance" => "all", "page" => "1"}
  end

  defp create_attrs(params) do
    attrs = %{
      name: blank_to_nil(params["name"]),
      client_type: params["client_type"],
      token_endpoint_auth_method: params["token_endpoint_auth_method"],
      redirect_uris: split_lines(params["redirect_uris"]),
      allowed_scopes: split_csv(params["allowed_scopes"]),
      allowed_grant_types: ["authorization_code", "refresh_token"],
      actor: %{type: :operator, id: "admin-ui"}
    }

    if params["token_endpoint_auth_method"] == "client_secret_jwt" do
      Map.put(attrs, :token_endpoint_auth_signing_alg, "HS256")
    else
      attrs
    end
  end

  defp status_for(%{active: true}), do: :active
  defp status_for(_client), do: :disabled

  defp clients_index_path(filters \\ nil)
  defp clients_index_path(nil), do: Lockspire.mount_path() <> "/admin/clients"

  defp clients_index_path(filters),
    do: Lockspire.mount_path() <> "/admin/clients?" <> URI.encode_query(filters)

  defp client_show_path(client_id), do: Lockspire.mount_path() <> "/admin/clients/" <> client_id

  defp client_count_label(1), do: "1 matching client"
  defp client_count_label(count), do: "#{count} matching clients"

  defp put_status_filter(opts, "active"), do: Keyword.put(opts, :active, true)
  defp put_status_filter(opts, "disabled"), do: Keyword.put(opts, :active, false)
  defp put_status_filter(opts, _status), do: opts

  defp put_provenance_filter(opts, "operator"), do: Keyword.put(opts, :provenance, :operator)

  defp put_provenance_filter(opts, "self_registered"),
    do: Keyword.put(opts, :provenance, :self_registered)

  defp put_provenance_filter(opts, _provenance), do: opts

  defp normalize_status(status) when status in ["all", "active", "disabled"], do: status
  defp normalize_status(_status), do: "all"

  defp normalize_provenance(provenance) when provenance in ["all", "operator", "self_registered"],
    do: provenance

  defp normalize_provenance(_provenance), do: "all"

  defp parse_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, _rest} when value > 0 -> value
      _other -> 1
    end
  end

  defp parse_page(_page), do: 1

  defp split_lines(value) when is_binary(value) do
    value
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim/1)
  end

  defp split_lines(_value), do: []

  defp split_csv(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
  end

  defp split_csv(_value), do: []

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp selected_filter_label("", fallback), do: fallback
  defp selected_filter_label(nil, fallback), do: fallback
  defp selected_filter_label(value, _fallback), do: value
end
