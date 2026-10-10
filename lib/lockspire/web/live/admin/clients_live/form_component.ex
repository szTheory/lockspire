defmodule Lockspire.Web.Live.Admin.ClientsLive.FormComponent do
  @moduledoc false

  use Phoenix.Component

  alias Lockspire.Domain.Client
  alias Lockspire.Web.Components.AdminComponents

  attr(:mode, :atom, required: true)
  attr(:client, Client, default: nil)
  attr(:effective_par_policy, :map, default: nil)
  attr(:effective_dpop_policy, :map, default: nil)
  attr(:effective_security_profile, :map, default: nil)
  attr(:global_access_token_format, :string, default: nil)
  attr(:policy_load_state, :atom, default: :loaded)
  attr(:strict_readiness, :map, default: nil)
  attr(:errors, :list, default: [])
  attr(:params, :map, default: nil)

  def client_form(assigns) do
    assigns =
      assigns
      |> assign(:title, title_for(assigns.mode))
      |> assign(:button_label, button_for(assigns.mode))
      |> assign(:form_id, form_id(assigns.mode))
      |> assign(:display_errors, display_errors(assigns.errors))
      |> assign(
        :defaults,
        submitted_defaults(defaults_for(assigns.mode, assigns.client), assigns.params)
      )
      |> assign(:error_title, error_title(assigns.mode, display_errors(assigns.errors)))

    ~H"""
    <section class="lockspire-admin-form-shell">
      <header>
        <h2>{@title}</h2>
        <p class="lockspire-admin-help">{subtitle_for(@mode)}</p>
      </header>

      <AdminComponents.error_summary
        :if={@display_errors != []}
        title={@error_title}
        errors={@display_errors}
      />

      <form
        id={@form_id}
        class="lockspire-admin-form-stack"
        phx-change={change_event(@mode)}
        phx-submit="save_client"
      >
        <input type="hidden" name="client[mode]" value={Atom.to_string(@mode)} />

        <div :if={@mode == :new} class="lockspire-admin-fieldset">
          <AdminComponents.form_field
            id="client_name"
            label="Client name"
            errors={field_errors(@display_errors, :name)}
          >
            <input
              id="client_name"
              name="client[name]"
              type="text"
              value={@defaults.name}
              aria-invalid={field_errors(@display_errors, :name) != []}
              aria-describedby={
                if field_errors(@display_errors, :name) != [], do: "client_name-error"
              }
            />
          </AdminComponents.form_field>

          <AdminComponents.form_field
            id="client_type"
            label="Client type"
            errors={field_errors(@display_errors, :client_type)}
          >
            <select
              id="client_type"
              name="client[client_type]"
              aria-invalid={field_errors(@display_errors, :client_type) != []}
              aria-describedby={
                if field_errors(@display_errors, :client_type) != [], do: "client_type-error"
              }
            >
              <option value="confidential" selected={@defaults.client_type == "confidential"}>
                Confidential
              </option>
              <option value="public" selected={@defaults.client_type == "public"}>Public</option>
            </select>
          </AdminComponents.form_field>

          <AdminComponents.form_field
            id="client_auth_method"
            label="Token endpoint authentication"
            errors={field_errors(@display_errors, :token_endpoint_auth_method)}
          >
            <select
              id="client_auth_method"
              name="client[token_endpoint_auth_method]"
              aria-invalid={field_errors(@display_errors, :token_endpoint_auth_method) != []}
              aria-describedby={
                if field_errors(@display_errors, :token_endpoint_auth_method) != [],
                  do: "client_auth_method-error"
              }
            >
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
              <code>client_secret_jwt</code> uses <code>HS256</code> on Lockspire's supported
              direct-client endpoints.
            </p>
          </AdminComponents.form_field>
        </div>

        <div :if={@mode in [:new, :edit]} class="lockspire-admin-fieldset">
          <h3 :if={@mode == :edit}>Client identity and access</h3>
          <AdminComponents.form_field
            :if={@mode == :edit}
            id="client_name"
            label="Client name"
            errors={field_errors(@errors, :name)}
          >
            <input
              id="client_name"
              name="client[name]"
              type="text"
              value={@defaults.name}
              aria-invalid={field_errors(@errors, :name) != []}
              aria-describedby={if field_errors(@errors, :name) != [], do: "client_name-error"}
            />

          </AdminComponents.form_field>

          <AdminComponents.form_field
            id="client_allowed_scopes"
            label="Allowed scopes"
            help="Separate OAuth scope names with commas. Only these scopes may be requested for this client."
            errors={field_errors(@display_errors, :allowed_scopes)}
          >
            <input
              id="client_allowed_scopes"
              name="client[allowed_scopes]"
              type="text"
              value={@defaults.allowed_scopes}
              required={@mode == :new}
              aria-invalid={field_errors(@display_errors, :allowed_scopes) != []}
              aria-describedby={
                if field_errors(@display_errors, :allowed_scopes) != [],
                  do: "client_allowed_scopes-error"
              }
            />
          </AdminComponents.form_field>

          <h3 :if={@mode == :edit}>Effective security defaults</h3>
          <AdminComponents.form_field
            :if={@mode == :edit}
            id="client_dpop_policy"
            label="Client DPoP override"
            errors={field_errors(@errors, :dpop_policy)}
          >
            <select
              id="client_dpop_policy"
              name="client[dpop_policy]"
              aria-invalid={field_errors(@errors, :dpop_policy) != []}
              aria-describedby={if field_errors(@errors, :dpop_policy) != [], do: "client_dpop_policy-error"}
            >
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
            <div class="lockspire-admin-help">
              <p><strong>Issuer default:</strong> {dpop_default_label(@effective_dpop_policy, @policy_load_state)}</p>
              <p><strong>Selected client override:</strong> {dpop_choice_label(@defaults.dpop_policy)}</p>
              <p>
                <strong>Effective behavior if saved:</strong>
                {dpop_effective_preview(@effective_dpop_policy, @defaults.dpop_policy, @policy_load_state)}
              </p>
            </div>
          </AdminComponents.form_field>

          <AdminComponents.form_field
            :if={@mode == :edit}
            id="client_access_token_format"
            label="Access token format override"
            errors={field_errors(@errors, :access_token_format)}
          >
            <select
              id="client_access_token_format"
              name="client[access_token_format]"
              aria-invalid={field_errors(@errors, :access_token_format) != []}
              aria-describedby={
                if field_errors(@errors, :access_token_format) != [],
                  do: "client_access_token_format-error"
              }
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
              <p><strong>Issuer default:</strong> {access_token_format_label(@global_access_token_format, @policy_load_state)}</p>
              <p><strong>Selected client override:</strong> {access_token_format_choice_label(@defaults.access_token_format)}</p>
              <p>
                <strong>Effective behavior if saved:</strong>
                {access_token_format_preview(@global_access_token_format, @defaults.access_token_format, @policy_load_state)}
              </p>
            </div>
          </AdminComponents.form_field>

          <AdminComponents.form_field
            :if={@mode == :edit}
            id="client_contacts"
            label="Contacts"
            errors={field_errors(@errors, :contacts)}
          >
            <input
              id="client_contacts"
              name="client[contacts]"
              type="text"
              value={@defaults.contacts}
              aria-invalid={field_errors(@errors, :contacts) != []}
              aria-describedby={if field_errors(@errors, :contacts) != [], do: "client_contacts-error"}
            />
          </AdminComponents.form_field>

          <AdminComponents.form_field
            :if={@mode == :edit}
            id="client_logo_uri"
            label="Logo URI"
            errors={field_errors(@errors, :logo_uri)}
          >
            <input
              id="client_logo_uri"
              name="client[logo_uri]"
              type="text"
              value={@defaults.logo_uri}
              aria-invalid={field_errors(@errors, :logo_uri) != []}
              aria-describedby={if field_errors(@errors, :logo_uri) != [], do: "client_logo_uri-error"}
            />
          </AdminComponents.form_field>

          <AdminComponents.form_field
            :if={@mode == :edit}
            id="client_tos_uri"
            label="Terms of service URI"
            errors={field_errors(@errors, :tos_uri)}
          >
            <input
              id="client_tos_uri"
              name="client[tos_uri]"
              type="text"
              value={@defaults.tos_uri}
              aria-invalid={field_errors(@errors, :tos_uri) != []}
              aria-describedby={if field_errors(@errors, :tos_uri) != [], do: "client_tos_uri-error"}
            />
          </AdminComponents.form_field>

          <AdminComponents.form_field
            :if={@mode == :edit}
            id="client_policy_uri"
            label="Policy URI"
            errors={field_errors(@errors, :policy_uri)}
          >
            <input
              id="client_policy_uri"
              name="client[policy_uri]"
              type="text"
              value={@defaults.policy_uri}
              aria-invalid={field_errors(@errors, :policy_uri) != []}
              aria-describedby={if field_errors(@errors, :policy_uri) != [], do: "client_policy_uri-error"}
            />
          </AdminComponents.form_field>
        </div>

        <AdminComponents.form_field
          :if={@mode in [:new, :redirects]}
          id="client_redirect_uris"
          label="Redirect URIs"
          help="Enter one callback URI per line. Each must exactly match the URI sent in an authorization request."
          required={@mode == :new}
          errors={field_errors(@display_errors, :redirect_uris)}
        >
          <textarea
            id="client_redirect_uris"
            name="client[redirect_uris]"
            rows="4"
            required={@mode == :new}
            aria-invalid={field_errors(@display_errors, :redirect_uris) != []}
            aria-describedby={
              if field_errors(@display_errors, :redirect_uris) != [],
                do: "client_redirect_uris-error"
            }
          ><%= @defaults.redirect_uris %></textarea>
        </AdminComponents.form_field>

        <AdminComponents.form_field
          :if={@mode == :logout_uris}
          id="client_post_logout_redirect_uris"
          label="Post-logout redirect URIs"
          help="Enter one browser destination per line after RP-initiated logout. These do not receive logout notifications."
          errors={field_errors(@display_errors, :post_logout_redirect_uris)}
        >
          <textarea
            id="client_post_logout_redirect_uris"
            name="client[post_logout_redirect_uris]"
            rows="4"
            aria-invalid={field_errors(@display_errors, :post_logout_redirect_uris) != []}
            aria-describedby={
              if field_errors(@display_errors, :post_logout_redirect_uris) != [],
                do: "client_post_logout_redirect_uris-error"
            }
          ><%= @defaults.post_logout_redirect_uris %></textarea>
        </AdminComponents.form_field>

        <AdminComponents.form_field
          :if={@mode == :par_policy}
          id="client_par_policy"
          label="Client PAR override"
          errors={field_errors(@display_errors, :par_policy)}
        >
          <select
            id="client_par_policy"
            name="client[par_policy]"
            aria-invalid={field_errors(@display_errors, :par_policy) != []}
            aria-describedby={
              if field_errors(@display_errors, :par_policy) != [],
                do: "client_par_policy-error"
            }
          >
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

          <div class="lockspire-admin-help">
            <p><strong>Issuer default:</strong> {par_default_label(@effective_par_policy, @policy_load_state)}</p>
            <p><strong>Selected client override:</strong> {par_choice_label(@defaults.par_policy)}</p>
            <p>
              <strong>Effective behavior if saved:</strong>
              {par_effective_preview(@effective_par_policy, @defaults.par_policy, @policy_load_state)}
            </p>
          </div>
        </AdminComponents.form_field>

        <div :if={@mode == :security_profile} class="lockspire-admin-fieldset">
          <AdminComponents.form_field
            id="client_security_profile"
            label="Client security profile override"
            errors={field_errors(@display_errors, :security_profile)}
          >
            <select
              id="client_security_profile"
              name="client[security_profile]"
              aria-invalid={field_errors(@display_errors, :security_profile) != []}
              aria-describedby={
                if field_errors(@display_errors, :security_profile) != [],
                  do: "client_security_profile-error"
              }
            >
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
            <div class="lockspire-admin-help">
              <p>
                <strong>Issuer default:</strong>
                {security_default_label(@effective_security_profile, @policy_load_state)}
              </p>
              <p><strong>Selected client override:</strong> {security_choice_label(@defaults.security_profile)}</p>
              <p>
                <strong>Effective behavior if saved:</strong>
                {security_effective_preview(@effective_security_profile, @defaults.security_profile, @policy_load_state)}
              </p>
            </div>
          </AdminComponents.form_field>

          <AdminComponents.form_field
            id="client_authorization_signed_response_alg"
            label="Authorization response signing algorithm"
            errors={field_errors(@display_errors, :authorization_signed_response_alg)}
          >
            <select
              id="client_authorization_signed_response_alg"
              name="client[authorization_signed_response_alg]"
              aria-invalid={field_errors(@display_errors, :authorization_signed_response_alg) != []}
              aria-describedby={
                if field_errors(@display_errors, :authorization_signed_response_alg) != [],
                  do: "client_authorization_signed_response_alg-error"
              }
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
          </AdminComponents.form_field>

          <div :if={@effective_security_profile} class="lockspire-admin-help">
            <p>
              <strong>Currently saved global policy:</strong>
              {@effective_security_profile.global_profile}
            </p>
            <p>
              <strong>Currently saved effective profile:</strong> {effective_profile_label(
                @effective_security_profile
              )}
            </p>
            <p>
              <strong>Current strict readiness:</strong> {strict_readiness_label(
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

        <div :if={@mode == :logout_propagation} class="lockspire-admin-fieldset">
          <div class="lockspire-admin-field">
            <label for="client_backchannel_logout_uri">Back-channel logout URI</label>
            <input
              id="client_backchannel_logout_uri"
              name="client[backchannel_logout_uri]"
              type="text"
              value={@defaults.backchannel_logout_uri}
            />
          </div>

          <div class="lockspire-admin-checkbox-field">
            <input
              id="client_backchannel_logout_session_required"
              name="client[backchannel_logout_session_required]"
              type="checkbox"
              value="true"
              checked={@defaults.backchannel_logout_session_required}
            />
            <label for="client_backchannel_logout_session_required">
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

          <div class="lockspire-admin-checkbox-field">
            <input
              id="client_frontchannel_logout_session_required"
              name="client[frontchannel_logout_session_required]"
              type="checkbox"
              value="true"
              checked={@defaults.frontchannel_logout_session_required}
            />
            <label for="client_frontchannel_logout_session_required">
              Include `sid` in front-channel iframe requests
            </label>
          </div>

          <div class="lockspire-admin-help">
            <p>These endpoints receive logout notifications. They are separate from post-logout browser destinations.</p>
            <p>After the host clears its browser session, <code>/end_session/complete</code> records propagation intent and enqueues durable back-channel delivery.</p>
            <p>Front-channel logout is best effort because the browser may block cross-site cleanup.</p>
          </div>
        </div>

        <AdminComponents.action_bar>
          <AdminComponents.admin_button
            type="submit"
            variant={:primary}
            phx-disable-with={
              cond do
                @mode == :new -> "Creating client…"
                @mode == :edit -> "Saving client changes…"
                @mode == :par_policy -> "Saving PAR policy…"
                @mode == :security_profile -> "Saving security profile…"
                true -> nil
              end
            }
          >
            {@button_label}
          </AdminComponents.admin_button>
          <.link
            :if={@mode == :edit and @client}
            class="lockspire-admin-btn lockspire-admin-btn-secondary"
            href={client_detail_path(@client)}
          >
            Return to client details
          </.link>
        </AdminComponents.action_bar>
      </form>
    </section>
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

  defp submitted_defaults(defaults, params) when is_map(params) do
    Map.new(defaults, fn {key, default} ->
      {key, Map.get(params, Atom.to_string(key), default)}
    end)
  end

  defp submitted_defaults(defaults, _params), do: defaults

  defp field_errors(errors, field) do
    Enum.filter(errors, &(is_map(&1) and Map.get(&1, :field) == field))
  end

  defp display_errors(errors) do
    Enum.map(errors, fn
      %{field: field, reason: reason} = error ->
        Map.put(error, :message, error_message(field, reason, Map.get(error, :detail)))

      _error ->
        %{field: :base, message: "The client could not be saved. Try again."}
    end)
  end

  defp error_message(:redirect_uris, :invalid_redirect_uri, :empty),
    do: "Add at least one redirect URI."

  defp error_message(:redirect_uris, :invalid_redirect_uri, _detail),
    do:
      "Enter a valid callback URI that exactly matches the value sent in an authorization request."

  defp error_message(:post_logout_redirect_uris, :invalid_redirect_uri, _detail),
    do:
      "Enter a valid post-logout redirect URI that exactly matches the browser destination sent during logout."

  defp error_message(:allowed_scopes, :invalid_scope, :empty),
    do: "Enter at least one allowed scope."

  defp error_message(:allowed_scopes, :invalid_scope, _detail),
    do: "Enter valid OAuth scope names separated by commas."

  defp error_message(:token_endpoint_auth_method, :invalid_token_endpoint_auth_method, _detail),
    do: "Choose an authentication method supported by the current security policy."

  defp error_message(:token_endpoint_auth_method, _reason, _detail),
    do: "Choose a supported token endpoint authentication method."

  defp error_message(:client_type, _reason, _detail), do: "Choose public or confidential."

  defp error_message(:base, _reason, _detail),
    do: "The client could not be saved. Your information is still here; try again."

  defp error_message(_field, _reason, _detail),
    do: "Review this value and try again."

  defp error_title(:new, errors) do
    if Enum.any?(errors, &(Map.get(&1, :field) == :base)) do
      "Client was not created. Your information is still here; try again."
    else
      "Client was not created. Review the marked fields and try again."
    end
  end

  defp error_title(:edit, errors) do
    if Enum.any?(errors, &(Map.get(&1, :field) == :base)) do
      "Client changes were not saved. Your information is still here; try again."
    else
      "Client changes were not saved. Review the marked fields and try again."
    end
  end

  defp error_title(:par_policy, _errors),
    do: "Client PAR override was not saved. Review the selected value and try again."

  defp error_title(:security_profile, _errors),
    do: "Client security profile was not saved. Review the selected value and try again."

  defp error_title(_mode, _errors), do: "Review the highlighted fields."

  defp change_event(:new), do: "validate_client"

  defp change_event(mode) when mode in [:edit, :par_policy, :security_profile],
    do: "preview_client_policy"

  defp change_event(_mode), do: nil

  defp dpop_default_label(%{global_policy: :bearer}, :loaded), do: "Bearer access tokens"
  defp dpop_default_label(%{global_policy: :dpop}, :loaded), do: "DPoP-bound access tokens"
  defp dpop_default_label(_policy, _state), do: "Unavailable"

  defp dpop_choice_label("inherit"), do: "Inherit from issuer"
  defp dpop_choice_label("bearer"), do: "Use bearer access tokens"
  defp dpop_choice_label("dpop"), do: "Require DPoP-bound access tokens"
  defp dpop_choice_label(_value), do: "Review the selected value"

  defp dpop_effective_preview(_policy, _choice, state) when state != :loaded,
    do: "Unavailable until issuer policy loads"

  defp dpop_effective_preview(%{global_policy: global}, "inherit", :loaded),
    do: dpop_default_label(%{global_policy: global}, :loaded)

  defp dpop_effective_preview(_policy, "bearer", :loaded), do: "Bearer access tokens"
  defp dpop_effective_preview(_policy, "dpop", :loaded), do: "DPoP-bound access tokens"

  defp dpop_effective_preview(_policy, _choice, :loaded),
    do: "Unavailable until the selection is valid"

  defp access_token_format_label("jwt", :loaded), do: "JWT (RFC 9068 at+jwt)"
  defp access_token_format_label("opaque", :loaded), do: "Opaque (Lockspire-stored)"
  defp access_token_format_label(_format, _state), do: "Unavailable"

  defp access_token_format_choice_label("inherit"), do: "Inherit from issuer"
  defp access_token_format_choice_label("jwt"), do: "JWT (RFC 9068 at+jwt)"
  defp access_token_format_choice_label("opaque"), do: "Opaque (Lockspire-stored)"
  defp access_token_format_choice_label(_value), do: "Review the selected value"

  defp access_token_format_preview(_global, _choice, state) when state != :loaded,
    do: "Unavailable until issuer policy loads"

  defp access_token_format_preview(global, "inherit", :loaded),
    do: access_token_format_label(global, :loaded)

  defp access_token_format_preview(_global, "jwt", :loaded),
    do: "JWT (RFC 9068 at+jwt)"

  defp access_token_format_preview(_global, "opaque", :loaded),
    do: "Opaque (Lockspire-stored)"

  defp access_token_format_preview(_global, _choice, :loaded),
    do: "Unavailable until the selection is valid"

  defp par_default_label(%{global_policy: :required}, :loaded), do: "Required"
  defp par_default_label(%{global_policy: :optional}, :loaded), do: "Optional"
  defp par_default_label(_policy, _state), do: "Unavailable"

  defp par_choice_label("inherit"), do: "Inherit from issuer"
  defp par_choice_label("required"), do: "Require PAR for this client"
  defp par_choice_label("optional"), do: "Allow requests without PAR for this client"
  defp par_choice_label(_value), do: "Review the selected value"

  defp par_effective_preview(_policy, _choice, state) when state != :loaded,
    do: "Unavailable until issuer policy loads"

  defp par_effective_preview(%{global_policy: global}, "inherit", :loaded),
    do: par_default_label(%{global_policy: global}, :loaded)

  defp par_effective_preview(_policy, "required", :loaded), do: "Required"
  defp par_effective_preview(_policy, "optional", :loaded), do: "Optional"

  defp par_effective_preview(_policy, _choice, :loaded),
    do: "Unavailable until the selection is valid"

  defp security_default_label(%{global_profile: profile}, :loaded),
    do: security_profile_name(profile)

  defp security_default_label(_profile, _state), do: "Unavailable"

  defp security_choice_label("inherit"), do: "Inherit from issuer"
  defp security_choice_label("fapi_2_0_message_signing"), do: "FAPI 2.0 Message Signing"
  defp security_choice_label("fapi_2_0_security"), do: "FAPI 2.0 Security Profile"
  defp security_choice_label("none"), do: "None (Standard OIDC)"
  defp security_choice_label(_value), do: "Review the selected value"

  defp security_effective_preview(_profile, _choice, state) when state != :loaded,
    do: "Unavailable until issuer policy loads"

  defp security_effective_preview(%{global_profile: global}, "inherit", :loaded),
    do: security_profile_name(global)

  defp security_effective_preview(_profile, "fapi_2_0_message_signing", :loaded),
    do: "FAPI 2.0 Message Signing"

  defp security_effective_preview(_profile, "fapi_2_0_security", :loaded),
    do: "FAPI 2.0 Security Profile"

  defp security_effective_preview(_profile, "none", :loaded), do: "None (Standard OIDC)"

  defp security_effective_preview(_profile, _choice, :loaded),
    do: "Unavailable until the selection is valid"

  defp security_profile_name(:fapi_2_0_message_signing), do: "FAPI 2.0 Message Signing"
  defp security_profile_name(:fapi_2_0_security), do: "FAPI 2.0 Security Profile"
  defp security_profile_name(:none), do: "None (Standard OIDC)"
  defp security_profile_name(_profile), do: "Unavailable"

  defp form_id(:new), do: "client-create-form"
  defp form_id(:edit), do: "client-edit-form"
  defp form_id(:redirects), do: "client-redirect-uris-form"
  defp form_id(:logout_uris), do: "client-post-logout-redirect-uris-form"
  defp form_id(:logout_propagation), do: "client-logout-propagation-form"
  defp form_id(:par_policy), do: "client-par-policy-form"
  defp form_id(:security_profile), do: "client-security-profile-form"

  defp client_detail_path(%Client{client_id: client_id}),
    do: Lockspire.mount_path() <> "/admin/clients/" <> client_id

  # `nil` means inherit (no `:inherit` sentinel is stored), so the inherit option
  # must pre-select for a nil override. Unlike `dpop_policy`, which stores a real atom.
  defp format_default_for_select(nil), do: "inherit"
  defp format_default_for_select(format), do: Atom.to_string(format)

  defp title_for(:new), do: "Create client"
  defp title_for(:edit), do: "Edit client settings"
  defp title_for(:logout_propagation), do: "Update logout propagation settings"
  defp title_for(:redirects), do: "Update redirect URIs"
  defp title_for(:logout_uris), do: "Update post-logout redirect URIs"
  defp title_for(:par_policy), do: "Set client PAR policy"
  defp title_for(:security_profile), do: "Update client security profile"

  defp subtitle_for(:new),
    do:
      "Enter this client's name, token endpoint authentication method, callback URI, and allowed scopes."

  defp subtitle_for(:edit),
    do: "Update this client's name, scopes, descriptive details, and token policies."

  defp subtitle_for(:logout_propagation),
    do:
      "Set this client's logout notification endpoints. Back-channel delivery is durable; front-channel browser cleanup is best effort."

  defp subtitle_for(:redirects),
    do:
      "Set callback URIs for authorization responses. Lockspire matches each registered URI exactly."

  defp subtitle_for(:logout_uris),
    do:
      "Set browser destinations allowed after RP-initiated logout. These are separate from logout propagation endpoints."

  defp subtitle_for(:par_policy),
    do:
      "Choose whether this client requires Pushed Authorization Requests (PAR), may omit them, or inherits the issuer default."

  defp subtitle_for(:security_profile),
    do: "Choose this client's FAPI/OIDC requirements or inherit the issuer's security profile."

  defp button_for(:new), do: "Create client"
  defp button_for(:edit), do: "Save client changes"
  defp button_for(:logout_propagation), do: "Save logout propagation settings"
  defp button_for(:redirects), do: "Save redirect URIs"
  defp button_for(:logout_uris), do: "Save post-logout redirect URIs"
  defp button_for(:par_policy), do: "Save PAR policy"
  defp button_for(:security_profile), do: "Save security profile"
end
