defmodule Lockspire.Web.Live.Admin.ClientsLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Domain.Client
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.Admin.ClientsLive.FormComponent
  alias Lockspire.Web.Live.Admin.ClientsLive.RotateSecretComponent
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(%{"client_id" => client_id}, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Client detail",
       current_section: :clients,
       client_id: client_id,
       client: nil,
       form_errors: [],
       rotation_errors: [],
       revealed_secret: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    action = normalize_action(socket.assigns.live_action || :show)

    {:noreply,
     socket
     |> assign(action: action, form_errors: [], rotation_errors: [])
     |> load_client(Map.get(params, "client_id", socket.assigns.client_id))}
  end

  @impl true
  def handle_event("save_client", %{"client" => params}, socket) do
    result =
      case params["mode"] do
        "edit" -> Admin.update_client(socket.assigns.client_id, edit_attrs(params))
        "redirects" -> Admin.update_client(socket.assigns.client_id, redirect_attrs(params))
      end

    case result do
      {:ok, %Client{} = client} ->
        {:noreply, assign(socket, client: client, form_errors: [])}

      {:error, errors} when is_list(errors) ->
        {:noreply, assign(socket, form_errors: errors)}

      {:error, _reason} ->
        {:noreply,
         assign(socket, form_errors: [%{field: :base, reason: :request_failed, detail: nil}])}
    end
  end

  def handle_event("rotate_secret", %{"rotate" => %{"confirm" => "true"}}, socket) do
    case Admin.rotate_client_secret(socket.assigns.client_id) do
      {:ok, %{client: client, client_secret: secret}} ->
        {:noreply, assign(socket, client: client, revealed_secret: secret, rotation_errors: [])}

      {:error, errors} when is_list(errors) ->
        {:noreply, assign(socket, rotation_errors: errors)}

      {:error, _reason} ->
        {:noreply,
         assign(socket, rotation_errors: [%{field: :base, reason: :request_failed, detail: nil}])}
    end
  end

  def handle_event("rotate_secret", _params, socket) do
    {:noreply,
     assign(socket,
       rotation_errors: [%{field: :confirm, reason: :required, detail: "confirmation required"}]
     )}
  end

  def handle_event(
        "toggle_client",
        _params,
        %{assigns: %{client: %Client{active: true}}} = socket
      ) do
    {:noreply, apply_toggle(socket, false)}
  end

  def handle_event("toggle_client", _params, socket) do
    {:noreply, apply_toggle(socket, true)}
  end

  @impl true
  def render(%{client: nil} = assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.empty_state
        title="Client not found"
        body="Lockspire could not load that client from durable storage."
      />
    </AdminLayoutLive.shell>
    """
  end

  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.section_card
        title={@client.name || @client.client_id}
        subtitle="Immutable security posture stays fixed. Safe edits are targeted workflows."
      >
        <p>Client ID: <code>{@client.client_id}</code></p>
        <p>Type: <code>{@client.client_type}</code></p>
        <p>Token auth: <code>{@client.token_endpoint_auth_method}</code></p>
        <p>PKCE required: <code>{to_string(@client.pkce_required)}</code></p>
        <p>Current secret: redacted</p>
        <p>Last secret rotation: {format_datetime(@client.last_secret_rotated_at)}</p>
        <AdminComponents.status_badge status={status_for(@client)} />

        <h3>Redirect URIs</h3>
        <ul>
          <%= for redirect_uri <- @client.redirect_uris do %>
            <li>{redirect_uri}</li>
          <% end %>
        </ul>

        <h3>Allowed scopes</h3>
        <ul>
          <%= for scope <- @client.allowed_scopes do %>
            <li>{scope}</li>
          <% end %>
        </ul>

        <div class="lockspire-admin-actions">
          <a href={show_path(@client.client_id, :edit)}>Edit metadata</a>
          <a href={show_path(@client.client_id, :redirects)}>Edit redirect URIs</a>
          <a :if={@client.client_type == :confidential} href={show_path(@client.client_id, :rotate_secret)}>
            Rotate secret
          </a>
          <button phx-click="toggle_client" type="button">
            {if @client.active, do: "Disable client", else: "Enable client"}
          </button>
        </div>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        :if={@action in [:edit, :redirects]}
        title="Safe edit workflow"
        subtitle="Only the allowed shape for this workflow is editable."
      >
        <FormComponent.client_form mode={@action} client={@client} errors={@form_errors} />
      </AdminComponents.section_card>

      <AdminComponents.section_card
        :if={@action == :rotate_secret}
        title="Secret rotation"
        subtitle="Rotation is explicit and reveals the new secret once."
      >
        <RotateSecretComponent.rotation_panel
          errors={@rotation_errors}
          revealed_secret={@revealed_secret}
        />
      </AdminComponents.section_card>
    </AdminLayoutLive.shell>
    """
  end

  defp load_client(socket, client_id) do
    case Admin.get_client(client_id) do
      {:ok, %Client{} = client} ->
        assign(socket, client_id: client_id, client: client)

      {:error, _reason} ->
        assign(socket, client_id: client_id, client: nil)
    end
  end

  defp apply_toggle(socket, active) do
    result =
      if active do
        Admin.enable_client(socket.assigns.client_id)
      else
        Admin.disable_client(socket.assigns.client_id)
      end

    case result do
      {:ok, %Client{} = client} -> assign(socket, client: client)
      {:error, _reason} -> socket
    end
  end

  defp edit_attrs(params) do
    %{
      name: params["name"],
      allowed_scopes: split_csv(params["allowed_scopes"]),
      contacts: split_csv(params["contacts"]),
      logo_uri: params["logo_uri"],
      tos_uri: params["tos_uri"],
      policy_uri: params["policy_uri"]
    }
  end

  defp redirect_attrs(params) do
    %{
      redirect_uris: split_lines(params["redirect_uris"])
    }
  end

  defp normalize_action(action) when action in [:show, :edit, :redirects, :rotate_secret],
    do: action

  defp normalize_action(_action), do: :show

  defp show_path(client_id, :show), do: Lockspire.mount_path() <> "/admin/clients/" <> client_id
  defp show_path(client_id, :edit), do: show_path(client_id, :show) <> "/edit"
  defp show_path(client_id, :redirects), do: show_path(client_id, :show) <> "/redirects"
  defp show_path(client_id, :rotate_secret), do: show_path(client_id, :show) <> "/rotate-secret"

  defp split_csv(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
  end

  defp split_csv(_value), do: []

  defp split_lines(value) when is_binary(value) do
    value
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim/1)
  end

  defp split_lines(_value), do: []

  defp status_for(%Client{active: true}), do: :active
  defp status_for(%Client{}), do: :disabled

  defp format_datetime(nil), do: "Never"
  defp format_datetime(%DateTime{} = value), do: DateTime.to_iso8601(value)
end
