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
       filters: %{"q" => "", "status" => "all", "provenance" => "all", "page" => "1"},
       form_errors: [],
       created_result: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filters = normalize_filters(params)
    clients = load_clients(filters)

    {:noreply,
     assign(socket,
       filters: filters,
       clients: paginate(clients, filters),
       total_clients: length(clients)
     )}
  end

  @impl true
  def handle_event("save_client", %{"client" => client_params}, socket) do
    case Admin.create_client(create_attrs(client_params)) do
      {:ok, result} ->
        filters = socket.assigns.filters

        {:noreply,
         socket
         |> assign(
           created_result: result,
           form_errors: [],
           clients: paginate(load_clients(filters), filters),
           total_clients: length(load_clients(filters))
         )}

      {:error, errors} ->
        {:noreply, assign(socket, form_errors: errors, created_result: nil)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.section_card
        title="Client inventory"
        subtitle="Clients are the default operator entrypoint. Search and filters stay URL-driven."
      >
        <form method="get" action={clients_index_path()} class="lockspire-admin-form-shell">
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
              <option value="self_registered" selected={@filters["provenance"] == "self_registered"}>Self-Registered</option>
            </select>
          </div>

          <AdminComponents.action_bar>
            <AdminComponents.admin_button variant={:secondary} type="submit">Apply</AdminComponents.admin_button>
          </AdminComponents.action_bar>
        </form>

        <p class="lockspire-admin-help">Total matching clients: {@total_clients}</p>

        <%= if @clients == [] do %>
          <AdminComponents.empty_state
            title="No clients match this view"
            body="Adjust the search or status filter, or register a new client."
          />
        <% else %>
          <AdminComponents.resource_list>
            <%= for client <- @clients do %>
              <AdminComponents.resource_item
                href={client_show_path(client.client_id)}
                title={client.name || client.client_id}
                subtitle={client.client_id}
              >
                <:meta>
                  <AdminComponents.status_badge status={status_for(client)} />
                  <AdminComponents.status_badge status={client.provenance} />
                </:meta>
              </AdminComponents.resource_item>
            <% end %>
          </AdminComponents.resource_list>
        <% end %>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="Register client"
        subtitle="Registration reuses the canonical Lockspire client API and reveals plaintext only once."
      >
        <FormComponent.client_form mode={:new} errors={@form_errors} />

        <div :if={@created_result} class="lockspire-admin-secret-reveal">
          <h3>Client created</h3>
          <p>Client ID: <code>{@created_result.client.client_id}</code></p>
          <p :if={@created_result.client_secret}>
            Client secret: <code>{@created_result.client_secret}</code>
          </p>
          <p :if={!@created_result.client_secret}>This public client does not use a client secret.</p>
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
      {:ok, clients} -> clients
      {:error, _reason} -> []
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

  defp clients_index_path, do: Lockspire.mount_path() <> "/admin/clients"
  defp client_show_path(client_id), do: Lockspire.mount_path() <> "/admin/clients/" <> client_id

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
