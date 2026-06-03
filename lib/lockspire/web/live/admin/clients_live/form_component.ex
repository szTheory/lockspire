defmodule Lockspire.Web.Live.Admin.ClientsLive.FormComponent do
  @moduledoc false

  use Phoenix.Component

  alias Lockspire.Domain.Client

  attr(:mode, :atom, required: true)
  attr(:client, Client, default: nil)
  attr(:effective_par_policy, :map, default: nil)
  attr(:effective_security_profile, :map, default: nil)
  attr(:strict_readiness, :map, default: nil)
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
        <p class="lockspire-admin-help">{subtitle_for(@mode)}</p>
      </header>

      <.error_list errors={@errors} />

      <form phx-submit="save_client" style="display: flex; flex-direction: column; gap: var(--ls-space-5);">
        <input type="hidden" name="client[mode]" value={Atom.to_string(@mode)} />

        <div :if={@mode == :new} style="display: flex; flex-direction: column; gap: var(--ls-space-4);">
          <div class="lockspire-admin-field">
            <label for="client_name">Name</label>
            <input id="client_name" name="client[name]" type="text" value={@defaults.name} />
          </div>

          <div class="lockspire-admin-field">
            <label for="client_type">Client type</label>
            <select id="client_type" name="client[client_type]">
              <option value="confidential" selected={@defaults.client_type == "confidential"}>
                Confidential
              </option>
              <option value="public" selected={@defaults.client_type == "public"}>Public</option>
            </select>
          </div>

          <div class="lockspire-admin-field">
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
              <option
                value="client_secret_jwt"
                selected={@defaults.token_endpoint_auth_method == "client_secret_jwt"}
              >
                client_secret_jwt
              </option>
              <option value="none" selected={@defaults.token_endpoint_auth_method == "none"}>
                none
              </option>
            </select>
            <p class="lockspire-admin-help">
              <code>client_secret_jwt</code> is the narrow direct-client slice. Lockspire stores
              it with read-only <code>HS256</code> truth and does not expose a generic signing
              algorithm editor here.
            </p>
          </div>
        </div>

        <div :if={@mode in [:new, :edit]} style="display: flex; flex-direction: column; gap: var(--ls-space-4);">
          <div :if={@mode == :edit} class="lockspire-admin-field">
            <label for="client_name">Name</label>
            <input
              id="client_name"
              name="client[name]"
              type="text"
              value={@defaults.name}
            />
          </div>

          <div class="lockspire-admin-field">
            <label for="client_allowed_scopes">Allowed scopes</label>
            <input
              id="client_allowed_scopes"
              name="client[allowed_scopes]"
              type="text"
              value={@defaults.allowed_scopes}
            />
          </div>

          <div :if={@mode == :edit} class="lockspire-admin-field">
            <label for="client_dpop_policy">Client DPoP override</label>
            <select id="client_dpop_policy" name="client[dpop_policy]">
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
          </div>

          <div :if={@mode == :edit} class="lockspire-admin-field">
            <label for="client_access_token_format">Access token format override</label>
            <select
              id="client_access_token_format"
              name="client[access_token_format]"
            >
              <option value="inherit" selected={@defaults.access_token_format == "inherit"}>
                Inherit from server default
              </option>
              <option value="jwt" selected={@defaults.access_token_format == "jwt"}>
                JWT (RFC 9068 at+jwt)
              </option>
              <option value="opaque" selected={@defaults.access_token_format == "opaque"}>
                Opaque (Lockspire-stored)
              </option>
            </select>
            <div class="lockspire-admin-help">
              <p>
                JWT (at+jwt) is the default and is what host Phoenix API routes verify. Opaque tokens
                are Lockspire-stored and back /userinfo and /introspect — they are not interchangeable.
                Leave this set to inherit unless a specific client needs opaque.
              </p>
              <p>
                <a href="docs/protect-phoenix-api-routes.md">Learn when to choose JWT vs opaque</a>
              </p>
            </div>
          </div>

          <div :if={@mode == :edit} class="lockspire-admin-field">
            <label for="client_contacts">Contacts</label>
            <input
              id="client_contacts"
              name="client[contacts]"
              type="text"
              value={@defaults.contacts}
            />
          </div>

          <div :if={@mode == :edit} class="lockspire-admin-field">
            <label for="client_logo_uri">Logo URI</label>
            <input
              id="client_logo_uri"
              name="client[logo_uri]"
              type="text"
              value={@defaults.logo_uri}
            />
          </div>

          <div :if={@mode == :edit} class="lockspire-admin-field">
            <label for="client_tos_uri">Terms of service URI</label>
            <input
              id="client_tos_uri"
              name="client[tos_uri]"
              type="text"
              value={@defaults.tos_uri}
            />
          </div>

          <div :if={@mode == :edit} class="lockspire-admin-field">
            <label for="client_policy_uri">Policy URI</label>
            <input
              id="client_policy_uri"
              name="client[policy_uri]"
              type="text"
              value={@defaults.policy_uri}
            />
          </div>
        </div>

        <div :if={@mode in [:new, :redirects]} class="lockspire-admin-field">
          <label for="client_redirect_uris">Redirect URIs</label>
          <textarea id="client_redirect_uris" name="client[redirect_uris]" rows="4"><%= @defaults.redirect_uris %></textarea>
        </div>

        <div :if={@mode in [:new, :logout_uris]} class="lockspire-admin-field">
          <label for="client_post_logout_redirect_uris">Post-Logout Redirect URIs</label>
          <textarea id="client_post_logout_redirect_uris" name="client[post_logout_redirect_uris]" rows="4"><%= @defaults.post_logout_redirect_uris %></textarea>
        </div>

        <div :if={@mode == :par_policy} class="lockspire-admin-field">
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

        <div :if={@mode == :security_profile} style="display: flex; flex-direction: column; gap: var(--ls-space-4);">
          <div class="lockspire-admin-field">
            <label for="client_security_profile">Client security profile override</label>
            <select id="client_security_profile" name="client[security_profile]">
              <option value="inherit" selected={@defaults.security_profile == "inherit"}>
                Inherit from global policy
              </option>
              <option
                value="fapi_2_0_message_signing"
                selected={@defaults.security_profile == "fapi_2_0_message_signing"}
              >
                FAPI 2.0 Message Signing
              </option>
              <option
                value="fapi_2_0_security"
                selected={@defaults.security_profile == "fapi_2_0_security"}
              >
                FAPI 2.0 Security Profile
              </option>
              <option value="none" selected={@defaults.security_profile == "none"}>
                None (Standard OIDC)
              </option>
            </select>
          </div>

          <div class="lockspire-admin-field">
            <label for="client_authorization_signed_response_alg">
              Authorization response signing algorithm
            </label>
            <select
              id="client_authorization_signed_response_alg"
              name="client[authorization_signed_response_alg]"
            >
              <option value="" selected={is_nil(@defaults.authorization_signed_response_alg)}>
                Use legacy default / not set
              </option>
              <option
                value="ES256"
                selected={@defaults.authorization_signed_response_alg == "ES256"}
              >
                ES256
              </option>
              <option
                value="PS256"
                selected={@defaults.authorization_signed_response_alg == "PS256"}
              >
                PS256
              </option>
              <option
                value="RS256"
                selected={@defaults.authorization_signed_response_alg == "RS256"}
              >
                RS256
              </option>
              <option
                value="EdDSA"
                selected={@defaults.authorization_signed_response_alg == "EdDSA"}
              >
                EdDSA
              </option>
            </select>
          </div>

          <div :if={@effective_security_profile} class="lockspire-admin-help">
            <p>
              <strong>Global policy:</strong> {@effective_security_profile.global_profile}
            </p>
            <p>
              <strong>Effective profile:</strong> {effective_profile_label(
                @effective_security_profile
              )}
            </p>
            <p>
              <strong>Strict readiness:</strong> {strict_readiness_label(
                @effective_security_profile,
                @strict_readiness
              )}
            </p>
            <p :if={@effective_security_profile.fapi_2_0_message_signing?}>
              This stricter tier requires explicit JARM on `/authorize` and JWT negotiation on
              `/introspect`.
            </p>
            <p :if={mixed_mode_override?(@effective_security_profile)}>
              This client is using the mixed-mode escape hatch under a stricter global profile.
            </p>
            <ul :if={@strict_readiness && @strict_readiness.remediation != [] && @effective_security_profile.fapi_2_0_message_signing?} class="lockspire-admin-errors">
              <%= for item <- @strict_readiness.remediation do %>
                <li>{item}</li>
              <% end %>
            </ul>
          </div>
        </div>

        <div :if={@mode == :security_profile} class="lockspire-admin-help">
          <p>
            <strong>None (Standard OIDC):</strong> compatibility-first OIDC behavior.
          </p>
          <p>
            <strong>FAPI 2.0 Security Profile:</strong> PAR, DPoP, and FAPI baseline enforcement.
          </p>
          <p>
            <strong>FAPI 2.0 Message Signing:</strong> baseline FAPI enforcement plus explicit JARM
            and JWT-only introspection negotiation.
          </p>
        </div>

        <div :if={@mode == :logout_propagation} style="display: flex; flex-direction: column; gap: var(--ls-space-4);">
          <div class="lockspire-admin-field">
            <label for="client_backchannel_logout_uri">Back-channel logout URI</label>
            <input
              id="client_backchannel_logout_uri"
              name="client[backchannel_logout_uri]"
              type="text"
              value={@defaults.backchannel_logout_uri}
            />
          </div>

          <div class="lockspire-admin-field" style="flex-direction: row; align-items: center; gap: var(--ls-space-2);">
            <input
              id="client_backchannel_logout_session_required"
              name="client[backchannel_logout_session_required]"
              type="checkbox"
              value="true"
              checked={@defaults.backchannel_logout_session_required}
            />
            <label for="client_backchannel_logout_session_required" style="font-weight: normal;">
              Include `sid` in back-channel logout tokens
            </label>
          </div>

          <div class="lockspire-admin-field">
            <label for="client_frontchannel_logout_uri">Front-channel logout URI</label>
            <input
              id="client_frontchannel_logout_uri"
              name="client[frontchannel_logout_uri]"
              type="text"
              value={@defaults.frontchannel_logout_uri}
            />
          </div>

          <div class="lockspire-admin-field" style="flex-direction: row; align-items: center; gap: var(--ls-space-2);">
            <input
              id="client_frontchannel_logout_session_required"
              name="client[frontchannel_logout_session_required]"
              type="checkbox"
              value="true"
              checked={@defaults.frontchannel_logout_session_required}
            />
            <label for="client_frontchannel_logout_session_required" style="font-weight: normal;">
              Include `sid` in front-channel iframe requests
            </label>
          </div>

          <div class="lockspire-admin-help">
            <p><strong>Separate concern:</strong> these URIs control RP logout propagation, not post-logout redirects.</p>
            <p><strong>Protocol fork point:</strong> after the host clears its own browser session, <code>/end_session/complete</code> persists propagation intent and enqueues durable back-channel delivery.</p>
            <p><strong>Truth model:</strong> front-channel logout stays best effort because browsers can block cross-site cleanup.</p>
          </div>
        </div>

        <div class="lockspire-admin-actions">
          <button class="lockspire-admin-btn-primary" type="submit">{@button_label}</button>
        </div>
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

  defp mixed_mode_override?(%{
         global_profile: :fapi_2_0_message_signing,
         effective_profile: :none,
         client_profile: :none
       }),
       do: true

  defp mixed_mode_override?(%{
         global_profile: :fapi_2_0_security,
         effective_profile: :none,
         client_profile: :none
       }),
       do: true

  defp mixed_mode_override?(_resolved), do: false

  defp strict_readiness_label(%{fapi_2_0_message_signing?: true}, %{ready?: true}), do: "Ready"
  defp strict_readiness_label(%{fapi_2_0_message_signing?: true}, _readiness), do: "Blocked"

  defp strict_readiness_label(resolved, %{ready?: true}) when is_map(resolved),
    do: "Ready if enabled"

  defp strict_readiness_label(_resolved, _readiness), do: "Not ready yet"

  defp effective_profile_label(%{effective_profile: :fapi_2_0_message_signing}),
    do: "FAPI 2.0 Message Signing"

  defp effective_profile_label(%{effective_profile: :fapi_2_0_security}),
    do: "FAPI 2.0 Security Profile"

  defp effective_profile_label(_resolved), do: "None (Standard OIDC)"

  defp defaults_for(:new, _client) do
    %{
      name: nil,
      client_type: "confidential",
      token_endpoint_auth_method: "client_secret_basic",
      redirect_uris: nil,
      post_logout_redirect_uris: nil,
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

  defp defaults_for(:logout_uris, %Client{} = client) do
    %{
      post_logout_redirect_uris: Enum.join(client.post_logout_redirect_uris, "\n")
    }
  end

  defp defaults_for(:edit, %Client{} = client) do
    %{
      allowed_scopes: Enum.join(client.allowed_scopes, ", "),
      dpop_policy: Atom.to_string(client.dpop_policy),
      access_token_format: format_default_for_select(client.access_token_format),
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

  defp defaults_for(:security_profile, %Client{} = client) do
    %{
      security_profile: Atom.to_string(client.security_profile),
      authorization_signed_response_alg:
        client.authorization_signed_response_alg &&
          Atom.to_string(client.authorization_signed_response_alg)
    }
  end

  defp defaults_for(:logout_propagation, %Client{} = client) do
    %{
      backchannel_logout_uri: client.backchannel_logout_uri,
      backchannel_logout_session_required: client.backchannel_logout_session_required,
      frontchannel_logout_uri: client.frontchannel_logout_uri,
      frontchannel_logout_session_required: client.frontchannel_logout_session_required
    }
  end

  # `nil` means inherit (no `:inherit` sentinel is stored), so the inherit option
  # must pre-select for a nil override. Unlike `dpop_policy`, which stores a real atom.
  defp format_default_for_select(nil), do: "inherit"
  defp format_default_for_select(format), do: Atom.to_string(format)

  defp title_for(:new), do: "Register client"
  defp title_for(:edit), do: "Update safe metadata"
  defp title_for(:logout_propagation), do: "Update logout propagation"
  defp title_for(:redirects), do: "Update redirect URIs"
  defp title_for(:logout_uris), do: "Update post-logout redirect URIs"
  defp title_for(:par_policy), do: "Update PAR policy"
  defp title_for(:security_profile), do: "Update security profile"

  defp subtitle_for(:new), do: "Create a client using the canonical secure registration path."

  defp subtitle_for(:edit),
    do: "Change only the operator-safe metadata Lockspire allows in place."

  defp subtitle_for(:logout_propagation),
    do: "Configure back-channel and front-channel logout separately from post-logout redirects."

  defp subtitle_for(:redirects), do: "Redirect URIs stay explicit and exact-match validated."

  defp subtitle_for(:logout_uris),
    do: "Post-logout redirect URIs stay explicit and exact-match validated."

  defp subtitle_for(:par_policy),
    do: "Override the global PAR requirement for this specific client."

  defp subtitle_for(:security_profile),
    do: "Override the global security profile requirement for this specific client."

  defp button_for(:new), do: "Create client"
  defp button_for(:edit), do: "Save metadata"
  defp button_for(:logout_propagation), do: "Save logout propagation"
  defp button_for(:redirects), do: "Save redirect URIs"
  defp button_for(:logout_uris), do: "Save post-logout redirect URIs"
  defp button_for(:par_policy), do: "Save PAR policy"
  defp button_for(:security_profile), do: "Save security profile"

  defp format_error(%{field: field, reason: reason, detail: detail}) do
    "#{field} #{reason} #{inspect(detail)}"
  end
end
