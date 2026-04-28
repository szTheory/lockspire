defmodule Lockspire.Web.Live.Admin.ClientsLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.ParPolicy
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.Admin.ClientsLive.FormComponent
  alias Lockspire.Web.Live.Admin.ClientsLive.RotateSecretComponent
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(params, _session, socket) do
    client_id = if is_map(params), do: Map.get(params, "client_id"), else: nil

    {:ok,
     socket
     |> assign(
       page_title: "Client detail",
       current_section: :clients,
       client_id: client_id,
       client: nil,
       effective_par_policy: nil,
       form_errors: [],
       rotation_errors: [],
       revealed_secret: nil,
       revealed_rat: nil
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
        "edit" ->
          Admin.update_client(
            socket.assigns.client_id,
            edit_attrs(params) |> Map.put(:actor, %{type: :operator, id: "admin-ui"})
          )

        "redirects" ->
          Admin.update_client(
            socket.assigns.client_id,
            redirect_attrs(params) |> Map.put(:actor, %{type: :operator, id: "admin-ui"})
          )

        "par_policy" ->
          Admin.update_client(socket.assigns.client_id, %{
            par_policy: params["par_policy"],
            actor: %{type: :operator, id: "admin-ui"}
          })
      end

    case result do
      {:ok, %Client{} = client} ->
        {:noreply,
         assign(socket,
           client: client,
           effective_par_policy: resolve_effective_par_policy(client),
           form_errors: []
         )}

      {:error, errors} when is_list(errors) ->
        {:noreply, assign(socket, form_errors: errors)}

      {:error, _reason} ->
        {:noreply,
         assign(socket, form_errors: [%{field: :base, reason: :request_failed, detail: nil}])}
    end
  end

  def handle_event("rotate_secret", %{"rotate" => %{"confirm" => "true"}}, socket) do
    case Admin.rotate_client_secret(socket.assigns.client_id, %{
           actor: %{type: :operator, id: "admin-ui"}
         }) do
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

  def handle_event("rotate_rat", %{"rotate" => %{"confirm" => "true"}}, socket) do
    case Lockspire.Protocol.RegistrationManagement.rotate_registration_access_token(
           socket.assigns.client
         ) do
      {:ok, plaintext, updated_client} ->
        {:noreply,
         assign(socket, client: updated_client, revealed_rat: plaintext, rotation_errors: [])}

      {:error, errors} when is_list(errors) ->
        {:noreply, assign(socket, rotation_errors: errors)}

      {:error, _reason} ->
        {:noreply,
         assign(socket, rotation_errors: [%{field: :base, reason: :request_failed, detail: nil}])}
    end
  end

  def handle_event("rotate_rat", _params, socket) do
    {:noreply,
     assign(socket,
       rotation_errors: [%{field: :confirm, reason: :required, detail: "confirmation required"}]
     )}
  end

  def handle_event("acknowledge_rat", _params, socket) do
    {:noreply, assign(socket, revealed_rat: nil)}
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
        <p>Global PAR policy: <code>{par_policy_label(@effective_par_policy.global_policy)}</code></p>
        <p>Client PAR override: <code>{par_policy_label(@client.par_policy)}</code></p>
        <p>Effective PAR requirement: <strong>{verdict_for(@effective_par_policy)}</strong></p>
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
          <.link patch={show_path(@client.client_id, :edit)}>Edit metadata</.link>
          <.link patch={show_path(@client.client_id, :par_policy)}>Edit PAR policy</.link>
          <.link patch={show_path(@client.client_id, :redirects)}>Edit redirect URIs</.link>
          <.link :if={@client.client_type == :confidential} patch={show_path(@client.client_id, :rotate_secret)}>
            Rotate secret
          </.link>
          <button phx-click="toggle_client" type="button">
            {if @client.active, do: "Disable client", else: "Enable client"}
          </button>
        </div>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        :if={@action in [:edit, :redirects, :par_policy]}
        title="Safe edit workflow"
        subtitle="Only the allowed shape for this workflow is editable."
      >
        <FormComponent.client_form
          mode={@action}
          client={@client}
          effective_par_policy={@effective_par_policy}
          errors={@form_errors}
        />
      </AdminComponents.section_card>

      <AdminComponents.section_card
        :if={@client.provenance == :self_registered}
        title="Self-registered client (DCR)"
        subtitle="This client was dynamically registered by a third party."
      >
        <p>Registration Client URI: <code>{@client.registration_client_uri || "N/A"}</code></p>
        <div class="lockspire-admin-actions">
          <.link patch={show_path(@client.client_id, :rotate_registration_access_token)}>
            Rotate Registration Access Token (RAT)
          </.link>
        </div>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        :if={@action == :rotate_registration_access_token}
        title="Rotate Registration Access Token (RAT)"
        subtitle="Rotation is explicit and reveals the new RAT once."
      >
        <section class="lockspire-admin-form-shell">
          <header>
            <p>Lockspire reveals the new RAT once. It is redacted immediately after this state.</p>
          </header>

          <ul :if={@rotation_errors != []} class="lockspire-admin-errors">
            <%= for error <- @rotation_errors do %>
              <li>{inspect(error)}</li>
            <% end %>
          </ul>

          <div :if={@revealed_rat} class="lockspire-admin-secret-reveal">
            <h3>New Registration Access Token</h3>
            <code>{@revealed_rat}</code>
            <p>Copy it now. Lockspire does not store or re-show plaintext tokens.</p>
            <button type="button" phx-click="acknowledge_rat">I have copied the token</button>
          </div>

          <form :if={is_nil(@revealed_rat)} phx-submit="rotate_rat">
            <label>
              <input type="checkbox" name="rotate[confirm]" value="true" />
              I understand the previous RAT stops being the current credential after rotation.
            </label>

            <button type="submit">Rotate RAT</button>
          </form>
        </section>
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

  defp load_client(socket, nil) do
    assign(socket, client: nil, effective_par_policy: nil)
  end

  defp load_client(socket, client_id) do
    case Admin.get_client(client_id) do
      {:ok, %Client{} = client} ->
        assign(socket,
          client_id: client_id,
          client: client,
          effective_par_policy: resolve_effective_par_policy(client)
        )

      {:error, _reason} ->
        assign(socket, client_id: client_id, client: nil, effective_par_policy: nil)
    end
  end

  defp apply_toggle(socket, active) do
    result =
      if active do
        Admin.enable_client(socket.assigns.client_id, %{actor: %{type: :operator, id: "admin-ui"}})
      else
        Admin.disable_client(socket.assigns.client_id, %{
          actor: %{type: :operator, id: "admin-ui"}
        })
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
      dpop_policy: params["dpop_policy"],
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

  defp normalize_action(action)
       when action in [
              :show,
              :edit,
              :redirects,
              :rotate_secret,
              :par_policy,
              :rotate_registration_access_token
            ],
       do: action

  defp normalize_action(_action), do: :show

  defp show_path(client_id, :show), do: Lockspire.mount_path() <> "/admin/clients/" <> client_id
  defp show_path(client_id, :edit), do: show_path(client_id, :show) <> "/edit"
  defp show_path(client_id, :par_policy), do: show_path(client_id, :show) <> "/par-policy"
  defp show_path(client_id, :redirects), do: show_path(client_id, :show) <> "/redirects"
  defp show_path(client_id, :rotate_secret), do: show_path(client_id, :show) <> "/rotate-secret"

  defp show_path(client_id, :rotate_registration_access_token),
    do: show_path(client_id, :show) <> "/rotate-registration-access-token"

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

  defp resolve_effective_par_policy(%Client{} = client) do
    server_policy =
      case Admin.get_server_policy() do
        {:ok, %ServerPolicy{} = policy} -> policy
        {:error, _reason} -> %ServerPolicy{}
      end

    ParPolicy.resolve_effective_policy(server_policy, client)
  end

  defp par_policy_label(policy) when policy in [:inherit, :required, :optional] do
    Atom.to_string(policy)
  end

  defp verdict_for(%{par_required?: true}), do: "Required"
  defp verdict_for(%{par_required?: false}), do: "Not required"

  defp format_datetime(nil), do: "Never"
  defp format_datetime(%DateTime{} = value), do: DateTime.to_iso8601(value)
end
