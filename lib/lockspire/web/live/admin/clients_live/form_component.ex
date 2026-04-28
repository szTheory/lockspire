defmodule Lockspire.Web.Live.Admin.ClientsLive.FormComponent do
  @moduledoc false

  use Phoenix.Component

  alias Lockspire.Domain.Client

  attr(:mode, :atom, required: true)
  attr(:client, Client, default: nil)
  attr(:effective_par_policy, :map, default: nil)
  attr(:errors, :list, default: [])

  def client_form(assigns) do
    assigns =
      assigns
      |> assign(:title, title_for(assigns.mode))
      |> assign(:button_label, button_for(assigns.mode))
      |> assign(:defaults, defaults_for(assigns.mode, assigns.client))

    ~H"""
    <section class="lockspire-admin-form-shell">
      <header>
        <h2>{@title}</h2>
        <p>{subtitle_for(@mode)}</p>
      </header>

      <.error_list errors={@errors} />

      <form phx-submit="save_client">
        <input type="hidden" name="client[mode]" value={Atom.to_string(@mode)} />

        <div :if={@mode == :new}>
          <label for="client_name">Name</label>
          <input id="client_name" name="client[name]" type="text" value={@defaults.name} />

          <label for="client_type">Client type</label>
          <select id="client_type" name="client[client_type]">
            <option value="confidential" selected={@defaults.client_type == "confidential"}>
              Confidential
            </option>
            <option value="public" selected={@defaults.client_type == "public"}>Public</option>
          </select>

          <label for="client_auth_method">Token endpoint auth method</label>
          <select id="client_auth_method" name="client[token_endpoint_auth_method]">
            <option
              value="client_secret_basic"
              selected={@defaults.token_endpoint_auth_method == "client_secret_basic"}
            >
              client_secret_basic
            </option>
            <option
              value="client_secret_post"
              selected={@defaults.token_endpoint_auth_method == "client_secret_post"}
            >
              client_secret_post
            </option>
            <option value="none" selected={@defaults.token_endpoint_auth_method == "none"}>
              none
            </option>
          </select>
        </div>

        <div :if={@mode in [:new, :edit]}>
          <label for="client_allowed_scopes">Allowed scopes</label>
          <input
            id="client_allowed_scopes"
            name="client[allowed_scopes]"
            type="text"
            value={@defaults.allowed_scopes}
          />

          <label :if={@mode == :edit} for="client_dpop_policy">Client DPoP override</label>
          <select :if={@mode == :edit} id="client_dpop_policy" name="client[dpop_policy]">
            <option value="inherit" selected={@defaults.dpop_policy == "inherit"}>
              Inherit from global policy
            </option>
            <option value="bearer" selected={@defaults.dpop_policy == "bearer"}>
              Use bearer access tokens
            </option>
            <option value="dpop" selected={@defaults.dpop_policy == "dpop"}>
              Require DPoP-bound access tokens
            </option>
          </select>

          <label :if={@mode == :edit} for="client_contacts">Contacts</label>
          <input
            :if={@mode == :edit}
            id="client_contacts"
            name="client[contacts]"
            type="text"
            value={@defaults.contacts}
          />

          <label :if={@mode == :edit} for="client_logo_uri">Logo URI</label>
          <input
            :if={@mode == :edit}
            id="client_logo_uri"
            name="client[logo_uri]"
            type="text"
            value={@defaults.logo_uri}
          />

          <label :if={@mode == :edit} for="client_tos_uri">Terms of service URI</label>
          <input
            :if={@mode == :edit}
            id="client_tos_uri"
            name="client[tos_uri]"
            type="text"
            value={@defaults.tos_uri}
          />

          <label :if={@mode == :edit} for="client_policy_uri">Policy URI</label>
          <input
            :if={@mode == :edit}
            id="client_policy_uri"
            name="client[policy_uri]"
            type="text"
            value={@defaults.policy_uri}
          />
        </div>

        <div :if={@mode in [:new, :redirects]}>
          <label for="client_redirect_uris">Redirect URIs</label>
          <textarea id="client_redirect_uris" name="client[redirect_uris]" rows="4"><%= @defaults.redirect_uris %></textarea>
        </div>

        <div :if={@mode == :par_policy}>
          <label for="client_par_policy">Client PAR override</label>
          <select id="client_par_policy" name="client[par_policy]">
            <option value="inherit" selected={@defaults.par_policy == "inherit"}>
              Inherit from global policy
            </option>
            <option value="required" selected={@defaults.par_policy == "required"}>
              Require PAR for this client
            </option>
            <option value="optional" selected={@defaults.par_policy == "optional"}>
              Mark PAR optional for this client
            </option>
          </select>

          <div :if={@effective_par_policy} class="lockspire-admin-help">
            <p>
              <strong>Global policy:</strong> {@effective_par_policy.global_policy}
            </p>
            <p>
              <strong>Effective requirement:</strong> {if @effective_par_policy.par_required?,
                do: "Required",
                else: "Not required"}
            </p>
          </div>
        </div>

        <button type="submit">{@button_label}</button>
      </form>
    </section>
    """
  end

  attr(:errors, :list, required: true)

  def error_list(assigns) do
    ~H"""
    <ul :if={@errors != []} class="lockspire-admin-errors">
      <%= for error <- @errors do %>
        <li>{format_error(error)}</li>
      <% end %>
    </ul>
    """
  end

  defp defaults_for(:new, _client) do
    %{
      name: nil,
      client_type: "confidential",
      token_endpoint_auth_method: "client_secret_basic",
      redirect_uris: nil,
      allowed_scopes: nil,
      contacts: nil,
      logo_uri: nil,
      tos_uri: nil,
      policy_uri: nil
    }
  end

  defp defaults_for(:redirects, %Client{} = client) do
    %{
      redirect_uris: Enum.join(client.redirect_uris, "\n")
    }
  end

  defp defaults_for(:edit, %Client{} = client) do
    %{
      allowed_scopes: Enum.join(client.allowed_scopes, ", "),
      dpop_policy: Atom.to_string(client.dpop_policy),
      contacts: Enum.join(client.contacts, ", "),
      logo_uri: client.logo_uri,
      tos_uri: client.tos_uri,
      policy_uri: client.policy_uri,
      name: client.name
    }
  end

  defp defaults_for(:par_policy, %Client{} = client) do
    %{
      par_policy: Atom.to_string(client.par_policy)
    }
  end

  defp title_for(:new), do: "Register client"
  defp title_for(:edit), do: "Update safe metadata"
  defp title_for(:redirects), do: "Update redirect URIs"
  defp title_for(:par_policy), do: "Update PAR policy"

  defp subtitle_for(:new), do: "Create a client using the canonical secure registration path."

  defp subtitle_for(:edit),
    do: "Change only the operator-safe metadata Lockspire allows in place."

  defp subtitle_for(:redirects), do: "Redirect URIs stay explicit and exact-match validated."

  defp subtitle_for(:par_policy),
    do: "Override the global PAR requirement for this specific client."

  defp button_for(:new), do: "Create client"
  defp button_for(:edit), do: "Save metadata"
  defp button_for(:redirects), do: "Save redirect URIs"
  defp button_for(:par_policy), do: "Save PAR policy"

  defp format_error(%{field: field, reason: reason, detail: detail}) do
    "#{field} #{reason} #{inspect(detail)}"
  end
end
