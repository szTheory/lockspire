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
       page_title: "Apps",
       current_section: :clients,
       clients: [],
       matching_clients: nil,
       total_clients: nil,
       inventory_state: :loading,
       filters: %{"q" => "", "status" => "all", "provenance" => "all", "page" => "1"},
       form_errors: [],
       create_params: nil,
       created_result: nil,
       created_secret_hidden?: false
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filters = normalize_filters(params)
    page_title = if socket.assigns.live_action == :new, do: "New app", else: "Apps"

    {:noreply,
     socket
     |> assign_inventory(filters)
     |> assign(
       page_title: page_title,
       form_errors: [],
       create_params: nil,
       created_result: nil,
       created_secret_hidden?: false
     )}
  end

  @impl true
  def handle_event("filter_inventory", params, socket) do
    filters = normalize_filters(params)

    {:noreply, push_patch(socket, to: clients_index_path(filters))}
  end

  @impl true
  def handle_event("validate_client", %{"client" => client_params}, socket) do
    {:noreply, assign(socket, create_params: safe_create_params(client_params), form_errors: [])}
  end

  @impl true
  def handle_event("save_client", %{"client" => client_params}, socket) do
    safe_params = safe_create_params(client_params)

    case Admin.create_client(create_attrs(client_params)) do
      {:ok, result} ->
        filters = socket.assigns.filters

        {:noreply,
         socket
         |> assign_inventory(filters)
         |> assign(
           created_result: result,
           created_secret_hidden?: false,
           create_params: nil,
           form_errors: []
         )}

      {:error, errors} ->
        {:noreply,
         assign(socket,
           form_errors: errors,
           create_params: safe_params,
           created_result: nil,
           created_secret_hidden?: false
         )}
    end
  end

  @impl true
  def handle_event("hide_created_secret", _params, socket) do
    case socket.assigns.created_result do
      %{client_secret: secret} = result when is_binary(secret) ->
        {:noreply,
         assign(socket,
           created_result: %{result | client_secret: nil},
           created_secret_hidden?: true
         )}

      _other ->
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <%= if @live_action == :new do %>
        <div class="lockspire-admin-client-create">
          <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={clients_index_path(@filters)}>
            Back to apps
          </.link>
          <div class="lockspire-admin-help-block">
            <p class="lockspire-admin-help">Add an app that will use this service.</p>
          </div>

          <FormComponent.client_form
            mode={:new}
            errors={@form_errors}
            params={@create_params}
            show_heading={false}
          />

          <div :if={@created_result}>
            <p>Client ID: <code>{@created_result.client.client_id}</code></p>
            <.link
              class="lockspire-admin-btn lockspire-admin-btn-secondary"
              href={client_show_path(@created_result.client.client_id)}
            >
              View app details
            </.link>
            <AdminComponents.copy_once_secret_panel
              title={
                cond do
                  @created_secret_hidden? -> "Client secret hidden"
                  @created_result.client_secret -> "Copy this client secret now"
                  true -> "App created"
                end
              }
              body={
                cond do
                  @created_secret_hidden? -> "Credential hidden. It will not be shown again."
                  @created_result.client_secret ->
                    "The app uses this secret to get tokens. Copy it now. It is shown once, and Lockspire stores only a hash."
                  true -> "This app doesn't use a client secret."
                end
              }
              label="Client secret"
              value={@created_result.client_secret}
              redacted={is_nil(@created_result.client_secret)}
            />
            <AdminComponents.admin_button
              :if={@created_result.client_secret}
              type="button"
              variant={:secondary}
              phx-click="hide_created_secret"
            >
              Hide credential
            </AdminComponents.admin_button>
          </div>
        </div>
      <% else %>
      <AdminComponents.page_hero
        body="Find an app, check how it was added, or add a new one."
      >
        <:actions>
          <AdminComponents.admin_button
            :if={@inventory_state == :loaded and not first_use_empty?(@filters, @total_clients)}
            href={client_create_path(@filters)}
            variant={:primary}
          >
            Add app
          </AdminComponents.admin_button>
        </:actions>
      </AdminComponents.page_hero>

      <AdminComponents.section_card title="Find an app" subtitle="Search by name or filter by status and registration source.">
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
              <AdminComponents.select_control id="client_status" name="status">
                <option value="all" selected={@filters["status"] == "all"}>All</option>
                <option value="active" selected={@filters["status"] == "active"}>Active</option>
                <option value="disabled" selected={@filters["status"] == "disabled"}>Disabled</option>
              </AdminComponents.select_control>
            </div>

            <div class="lockspire-admin-field">
              <label for="client_provenance">Registration source</label>
              <AdminComponents.select_control id="client_provenance" name="provenance">
                <option value="all" selected={@filters["provenance"] == "all"}>All sources</option>
                <option value="operator" selected={@filters["provenance"] == "operator"}>Added directly</option>
                <option value="self_registered" selected={@filters["provenance"] == "self_registered"}>
                  Registered through API
                </option>
              </AdminComponents.select_control>
            </div>
          </:fields>
          <:help>
            <p>See which apps were added here and which were registered by another app through the API.</p>
            <p :if={@inventory_state == :loaded}>{client_count_label(@matching_clients)} of {@total_clients} total apps</p>
            <p :if={@inventory_state == :error}>Matching count unavailable while the app list is unavailable.</p>
          </:help>
          <:actions>
            <AdminComponents.admin_button
              variant={:secondary}
              type="submit"
              phx-disable-with="Filtering apps…"
            >
              Filter apps
            </AdminComponents.admin_button>
          </:actions>
        </AdminComponents.filter_bar>

        <div class="lockspire-admin-client-inventory__results" aria-live="polite">
          <p :if={@inventory_state == :loading} role="status">Loading apps…</p>

          <AdminComponents.alert
            :if={@inventory_state == :error}
            variant={:danger}
            title="Could not load apps"
          >
            <p>No matching-client result is available until this read succeeds. Reload this view or return to the inventory and try again.</p>
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
            title={
              if first_use_empty?(@filters, @total_clients),
                do: "No clients yet",
                else: "No matching apps"
            }
            body={
              if first_use_empty?(@filters, @total_clients),
                do: "Create a client to begin connecting applications.",
                else: "Change or clear the filters to see other records."
            }
          >
            <:actions>
              <.link
                :if={first_use_empty?(@filters, @total_clients)}
                class="lockspire-admin-btn lockspire-admin-btn-primary"
                href={client_create_path(@filters)}
              >
                Add app
              </.link>
              <.link
                :if={!first_use_empty?(@filters, @total_clients)}
                class="lockspire-admin-btn lockspire-admin-btn-secondary"
                href={clients_index_path()}
              >
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
                    View app
                  </.link>
                </:actions>
              </AdminComponents.resource_item>
            <% end %>
          </AdminComponents.resource_list>

          <nav
            :if={@inventory_state == :loaded and (has_previous_page?(@filters) or has_next_page?(@filters, @matching_clients))}
            class="lockspire-admin-client-inventory__pager"
            aria-label="App list pages"
          >
            <.link
              :if={has_previous_page?(@filters)}
              class="lockspire-admin-btn lockspire-admin-btn-secondary"
              href={clients_index_path(page_filters(@filters, -1))}
            >
              Previous apps
            </.link>
            <.link
              :if={has_next_page?(@filters, @matching_clients)}
              class="lockspire-admin-btn lockspire-admin-btn-secondary"
              href={clients_index_path(page_filters(@filters, 1))}
            >
              Next apps
            </.link>
          </nav>
        </div>
      </AdminComponents.section_card>

      <% end %>
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
      "q" => normalize_query(Map.get(params, "q", "")),
      "status" => normalize_status(Map.get(params, "status", "all")),
      "provenance" => normalize_provenance(Map.get(params, "provenance", "all")),
      "page" => Integer.to_string(parse_page(Map.get(params, "page", "1")))
    }
  end

  defp has_previous_page?(filters), do: parse_page(filters["page"]) > 1

  defp has_next_page?(filters, matching_clients) when is_integer(matching_clients),
    do: parse_page(filters["page"]) * @per_page < matching_clients

  defp has_next_page?(_filters, _matching_clients), do: false

  defp page_filters(filters, delta) do
    page = max(parse_page(filters["page"]) + delta, 1)
    Map.put(filters, "page", Integer.to_string(page))
  end

  defp normalize_query(q) when is_binary(q), do: q
  defp normalize_query(_q), do: ""

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

  defp client_create_path(filters),
    do: Lockspire.mount_path() <> "/admin/clients/new?" <> URI.encode_query(filters)

  defp client_show_path(client_id), do: Lockspire.mount_path() <> "/admin/clients/" <> client_id

  defp first_use_empty?(filters, 0) do
    filters["q"] in [nil, ""] and filters["status"] == "all" and
      filters["provenance"] == "all" and filters["page"] == "1"
  end

  defp first_use_empty?(_filters, _total_clients), do: false

  defp safe_create_params(params) do
    Map.take(params, [
      "name",
      "client_type",
      "token_endpoint_auth_method",
      "redirect_uris",
      "allowed_scopes"
    ])
  end

  defp client_count_label(1), do: "1 matching app"
  defp client_count_label(count), do: "#{count} matching apps"

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
end
