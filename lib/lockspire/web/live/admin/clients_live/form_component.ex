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
  attr(:show_heading, :boolean, default: true)

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
      <header :if={@show_heading}>
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
        phx-change={if change_event(@mode), do: Phoenix.LiveView.JS.push(change_event(@mode), page_loading: true)}
        phx-submit={Phoenix.LiveView.JS.push("save_client", page_loading: true)}
      >
        <input type="hidden" name="client[mode]" value={Atom.to_string(@mode)} />

        <div :if={@mode == :new} class="lockspire-admin-fieldset">
          <AdminComponents.form_field
            id="client_name"
            label="App name"
            errors={field_errors(@display_errors, :name)}
          >
            <input
              id="client_name"
              name="client[name]"
              type="text"
              value={@defaults.name}
              aria-invalid={if field_errors(@display_errors, :name) != [], do: "true", else: "false"}
              aria-describedby={
                if field_errors(@display_errors, :name) != [], do: "client_name-error"
              }
            />
          </AdminComponents.form_field>

          <AdminComponents.radio_group
            id="client_type" name="client[client_type]" label="Client type"
            value={@defaults.client_type} errors={field_errors(@display_errors, :client_type)}
          >
            <:option value="confidential" label="Server-side app" help="Can keep a client secret secure." />
            <:option value="public" label="Browser or mobile app" help="Cannot keep a client secret secure. Uses PKCE." />
          </AdminComponents.radio_group>

          <AdminComponents.radio_group
            id="client_auth_method" name="client[token_endpoint_auth_method]" label="How the app authenticates"
            value={@defaults.token_endpoint_auth_method}
            errors={field_errors(@display_errors, :token_endpoint_auth_method)}
          >
            <:option value="client_secret_basic" label="Client secret in the request header" />
            <:option value="client_secret_post" label="Client secret in the request body" />
            <:option value="client_secret_jwt" label="Signed client assertion (JWT)" help="Uses the client secret to sign assertions with HS256." />
            <:option value="none" label="No client secret" />
          </AdminComponents.radio_group>
        </div>

        <div :if={@mode in [:new, :edit]} class="lockspire-admin-fieldset">
          <h3 :if={@mode == :edit}>App name and access</h3>
          <AdminComponents.form_field
            :if={@mode == :edit}
            id="client_name"
            label="App name"
            errors={field_errors(@display_errors, :name)}
          >
            <input
              id="client_name"
              name="client[name]"
              type="text"
              value={@defaults.name}
              aria-invalid={if field_errors(@display_errors, :name) != [], do: "true", else: "false"}
              aria-describedby={if field_errors(@display_errors, :name) != [], do: "client_name-error"}
            />

          </AdminComponents.form_field>

          <AdminComponents.form_field
            id="client_allowed_scopes"
            label="Allowed permissions (OAuth scopes)"
            help="Permissions this app may request."
            errors={field_errors(@display_errors, :allowed_scopes)}
          >
            <AdminComponents.multi_value_control
              id="client_allowed_scopes"
              name="client[allowed_scopes]"
              value={@defaults.allowed_scopes}
              required={@mode == :new}
              suggestions={["openid", "profile", "email", "phone", "address", "offline_access"]}
              errors={field_errors(@display_errors, :allowed_scopes)}
            />
          </AdminComponents.form_field>

          <h3 :if={@mode == :edit}>Effective security defaults</h3>
          <AdminComponents.radio_group
            :if={@mode == :edit} id="client_dpop_policy" name="client[dpop_policy]"
            label="Access token proof" value={@defaults.dpop_policy}
            errors={field_errors(@display_errors, :dpop_policy)}
          >
            <:option value="inherit" label="Use provider default" />
            <:option value="bearer" label="Bearer access tokens" />
            <:option value="dpop" label="Tokens tied to a key (DPoP)" />
            <div class="lockspire-admin-help">
              <p><strong>Provider default:</strong> {dpop_default_label(@effective_dpop_policy, @policy_load_state)}</p>
              <p><strong>Result if saved:</strong> {dpop_effective_preview(@effective_dpop_policy, @defaults.dpop_policy, @policy_load_state)}</p>
            </div>
          </AdminComponents.radio_group>

          <AdminComponents.radio_group
            :if={@mode == :edit} id="client_access_token_format" name="client[access_token_format]"
            label="Access token format" value={@defaults.access_token_format}
            help="JWTs let APIs verify tokens locally. Opaque tokens are checked with Lockspire."
            errors={field_errors(@display_errors, :access_token_format)}
          >
            <:option value="inherit" label="Use provider default" />
            <:option value="jwt" label="JWT" />
            <:option value="opaque" label="Opaque token" />
            <div class="lockspire-admin-help">
              <p><strong>Provider default:</strong> {access_token_format_label(@global_access_token_format, @policy_load_state)}</p>
              <p><strong>Result if saved:</strong> {access_token_format_preview(@global_access_token_format, @defaults.access_token_format, @policy_load_state)}</p>
            </div>
          </AdminComponents.radio_group>

          <AdminComponents.form_field
            :if={@mode == :edit}
            id="client_contacts"
            label="Contacts"
            errors={field_errors(@display_errors, :contacts)}
          >
            <AdminComponents.multi_value_control
              id="client_contacts"
              name="client[contacts]"
              value={@defaults.contacts}
              help={false}
              errors={field_errors(@display_errors, :contacts)}
            />
          </AdminComponents.form_field>

          <AdminComponents.form_field
            :if={@mode == :edit}
            id="client_logo_uri"
            label="Logo URL"
            errors={field_errors(@display_errors, :logo_uri)}
          >
            <input
              id="client_logo_uri"
              name="client[logo_uri]"
              type="text"
              value={@defaults.logo_uri}
              aria-invalid={if field_errors(@display_errors, :logo_uri) != [], do: "true", else: "false"}
              aria-describedby={if field_errors(@display_errors, :logo_uri) != [], do: "client_logo_uri-error"}
            />
          </AdminComponents.form_field>

          <AdminComponents.form_field
            :if={@mode == :edit}
            id="client_tos_uri"
            label="Terms of service URL"
            errors={field_errors(@display_errors, :tos_uri)}
          >
            <input
              id="client_tos_uri"
              name="client[tos_uri]"
              type="text"
              value={@defaults.tos_uri}
              aria-invalid={if field_errors(@display_errors, :tos_uri) != [], do: "true", else: "false"}
              aria-describedby={if field_errors(@display_errors, :tos_uri) != [], do: "client_tos_uri-error"}
            />
          </AdminComponents.form_field>

          <AdminComponents.form_field
            :if={@mode == :edit}
            id="client_policy_uri"
            label="Privacy policy URL"
            errors={field_errors(@display_errors, :policy_uri)}
          >
            <input
              id="client_policy_uri"
              name="client[policy_uri]"
              type="text"
              value={@defaults.policy_uri}
              aria-invalid={if field_errors(@display_errors, :policy_uri) != [], do: "true", else: "false"}
              aria-describedby={if field_errors(@display_errors, :policy_uri) != [], do: "client_policy_uri-error"}
            />
          </AdminComponents.form_field>
        </div>

        <AdminComponents.form_field
          :if={@mode in [:new, :redirects]}
          id="client_redirect_uris"
          label="Sign-in return URLs"
          help="Enter one exact URL per line. Lockspire sends users back to one of these URLs after sign-in."
          required={@mode == :new}
          errors={field_errors(@display_errors, :redirect_uris)}
        >
          <textarea
            id="client_redirect_uris"
            name="client[redirect_uris]"
            rows="4"
            required={@mode == :new}
            aria-invalid={if field_errors(@display_errors, :redirect_uris) != [], do: "true", else: "false"}
            aria-describedby={field_description("client_redirect_uris", field_errors(@display_errors, :redirect_uris))}
          ><%= @defaults.redirect_uris %></textarea>
        </AdminComponents.form_field>

        <AdminComponents.form_field
          :if={@mode == :logout_uris}
          id="client_post_logout_redirect_uris"
          label="Sign-out return URLs"
          help="Enter one exact URL per line where users may return after signing out."
          errors={field_errors(@display_errors, :post_logout_redirect_uris)}
        >
          <textarea
            id="client_post_logout_redirect_uris"
            name="client[post_logout_redirect_uris]"
            rows="4"
            aria-invalid={if field_errors(@display_errors, :post_logout_redirect_uris) != [], do: "true", else: "false"}
            aria-describedby={field_description("client_post_logout_redirect_uris", field_errors(@display_errors, :post_logout_redirect_uris))}
          ><%= @defaults.post_logout_redirect_uris %></textarea>
        </AdminComponents.form_field>

        <AdminComponents.radio_group
          :if={@mode == :par_policy} id="client_par_policy" name="client[par_policy]"
          label="Authorization request rule" value={@defaults.par_policy}
          errors={field_errors(@display_errors, :par_policy)}
        >
          <:option value="inherit" label="Use provider default" />
          <:option value="required" label="Require PAR for this app" />
          <:option value="optional" label="Make PAR optional for this app" />
          <div class="lockspire-admin-help">
            <p><strong>Provider default:</strong> {par_default_label(@effective_par_policy, @policy_load_state)}</p>
            <p><strong>Result if saved:</strong> {par_effective_preview(@effective_par_policy, @defaults.par_policy, @policy_load_state)}</p>
          </div>
        </AdminComponents.radio_group>

        <div :if={@mode == :security_profile} class="lockspire-admin-fieldset">
          <AdminComponents.radio_group
            id="client_security_profile" name="client[security_profile]" label="App security requirements"
            value={@defaults.security_profile} errors={field_errors(@display_errors, :security_profile)}
          >
            <:option value="inherit" label="Use provider default" />
            <:option value="fapi_2_0_message_signing" label="FAPI 2.0 Message Signing" />
            <:option value="fapi_2_0_security" label="FAPI 2.0 Security Profile" />
            <:option value="none" label="Standard OAuth and OpenID Connect" />
            <div class="lockspire-admin-help">
              <p><strong>Provider default:</strong> {security_default_label(@effective_security_profile, @policy_load_state)}</p>
              <p><strong>Result if saved:</strong> {security_effective_preview(@effective_security_profile, @defaults.security_profile, @policy_load_state)}</p>
            </div>
          </AdminComponents.radio_group>

          <AdminComponents.form_field
            id="client_authorization_signed_response_alg"
            label="Authorization response signing algorithm"
            errors={field_errors(@display_errors, :authorization_signed_response_alg)}
          >
            <AdminComponents.select_control
              id="client_authorization_signed_response_alg"
              name="client[authorization_signed_response_alg]"
              aria-invalid={if field_errors(@display_errors, :authorization_signed_response_alg) != [], do: "true", else: "false"}
              aria-describedby={
                if field_errors(@display_errors, :authorization_signed_response_alg) != [],
                  do: "client_authorization_signed_response_alg-error"
              }
            >
              <option value="" selected={is_nil(@defaults.authorization_signed_response_alg)}>
                Not set (use default)
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
            </AdminComponents.select_control>
          </AdminComponents.form_field>

          <div :if={@effective_security_profile} class="lockspire-admin-help">
            <p>
              <strong>Provider default:</strong>
              {security_profile_name(@effective_security_profile.global_profile)}
            </p>
            <p>
              <strong>This app currently uses:</strong> {effective_profile_label(
                @effective_security_profile
              )}
            </p>
            <p>
              <strong>Signing key ready for message signing:</strong> {strict_readiness_label(
                @effective_security_profile,
                @strict_readiness
              )}
            </p>
            <p :if={@effective_security_profile.fapi_2_0_message_signing?}>
              Message signing requires signed authorization responses (JARM) and signed
              introspection responses (JWT).
            </p>
            <p :if={mixed_mode_override?(@effective_security_profile)}>
              This app opts out of the stricter provider default and uses standard OIDC.
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
            <strong>None (Standard OIDC):</strong> Standard OAuth and OIDC protections.
          </p>
          <p>
            <strong>FAPI 2.0 Security Profile:</strong> Requires PAR, key-bound access tokens (DPoP), and S256 PKCE.
          </p>
          <p>
            <strong>FAPI 2.0 Message Signing:</strong> Includes those requirements and signed
            authorization and introspection responses.
          </p>
        </div>

        <div :if={@mode == :logout_propagation} class="lockspire-admin-fieldset">
          <div class="lockspire-admin-field">
            <label for="client_backchannel_logout_uri">Server sign-out notification URL</label>
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
              Include a session ID in the server notification
            </label>
          </div>

          <div class="lockspire-admin-field">
            <label for="client_frontchannel_logout_uri">Browser sign-out notification URL</label>
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
              Include a session ID in the browser notification
            </label>
          </div>

          <div class="lockspire-admin-help">
            <p>These URLs tell Lockspire where this app receives sign-out notifications.</p>
            <p>Server notifications are stored and retried. Browser notifications may be blocked and cannot confirm that this app cleared its session.</p>
          </div>
        </div>

        <AdminComponents.action_bar>
          <AdminComponents.admin_button
            type="submit"
            variant={:primary}
            phx-disable-with={
              cond do
                @mode == :new -> "Creating app…"
                @mode == :edit -> "Saving app changes…"
                @mode == :par_policy -> "Saving authorization request rules…"
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
            Back to app details
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

  defp field_description(id, errors) do
    if errors == [], do: "#{id}-help", else: "#{id}-help #{id}-error"
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
    do: "Add at least one sign-in return URL."

  defp error_message(:redirect_uris, :invalid_redirect_uri, _detail),
    do: "Enter a valid URL for users to return to after sign-in."

  defp error_message(:post_logout_redirect_uris, :invalid_redirect_uri, _detail),
    do: "Enter a valid URL for users to return to after signing out."

  defp error_message(:allowed_scopes, :invalid_scope, :empty),
    do: "Add at least one permission (OAuth scope)."

  defp error_message(:allowed_scopes, :invalid_scope, _detail),
    do: "Use valid permission names."

  defp error_message(:token_endpoint_auth_method, :invalid_token_endpoint_auth_method, _detail),
    do: "Choose a supported sign-in method for this app."

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
    do: "Authorization request setting was not saved. Review your choice and try again."

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

  defp dpop_effective_preview(_policy, _choice, state) when state != :loaded,
    do: "Unavailable until provider settings load"

  defp dpop_effective_preview(%{global_policy: global}, "inherit", :loaded),
    do: dpop_default_label(%{global_policy: global}, :loaded)

  defp dpop_effective_preview(_policy, "bearer", :loaded), do: "Bearer access tokens"
  defp dpop_effective_preview(_policy, "dpop", :loaded), do: "DPoP-bound access tokens"

  defp dpop_effective_preview(_policy, _choice, :loaded),
    do: "Unavailable until the selection is valid"

  defp access_token_format_label("jwt", :loaded), do: "JWT (RFC 9068 at+jwt)"
  defp access_token_format_label("opaque", :loaded), do: "Opaque (Lockspire-stored)"
  defp access_token_format_label(_format, _state), do: "Unavailable"

  defp access_token_format_preview(_global, _choice, state) when state != :loaded,
    do: "Unavailable until provider settings load"

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

  defp par_effective_preview(_policy, _choice, state) when state != :loaded,
    do: "Unavailable until provider settings load"

  defp par_effective_preview(%{global_policy: global}, "inherit", :loaded),
    do: par_default_label(%{global_policy: global}, :loaded)

  defp par_effective_preview(_policy, "required", :loaded), do: "Required"
  defp par_effective_preview(_policy, "optional", :loaded), do: "Optional"

  defp par_effective_preview(_policy, _choice, :loaded),
    do: "Unavailable until the selection is valid"

  defp security_default_label(%{global_profile: profile}, :loaded),
    do: security_profile_name(profile)

  defp security_default_label(_profile, _state), do: "Unavailable"

  defp security_effective_preview(_profile, _choice, state) when state != :loaded,
    do: "Unavailable until provider settings load"

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

  defp title_for(:new), do: "New app"
  defp title_for(:edit), do: "Edit client settings"
  defp title_for(:logout_propagation), do: "Update sign-out notifications"
  defp title_for(:redirects), do: "Update sign-in return URLs"
  defp title_for(:logout_uris), do: "Update sign-out return URLs"
  defp title_for(:par_policy), do: "Set authorization request rules"
  defp title_for(:security_profile), do: "Update client security profile"

  defp subtitle_for(:new),
    do: "Add an app that will use Lockspire."

  defp subtitle_for(:edit),
    do: "Update this app's name, access, and sign-in settings."

  defp subtitle_for(:logout_propagation),
    do:
      "Choose where this app receives sign-out notifications. Server delivery can be retried; browser delivery is best effort."

  defp subtitle_for(:redirects),
    do: "Set the exact URLs where users return after signing in."

  defp subtitle_for(:logout_uris),
    do: "Set the exact URLs where users may return after signing out."

  defp subtitle_for(:par_policy),
    do:
      "Choose whether this app must use Pushed Authorization Requests (PAR) or follow the provider default."

  defp subtitle_for(:security_profile),
    do: "Choose this app's FAPI and OIDC requirements or use the provider default."

  defp button_for(:new), do: "Add app"
  defp button_for(:edit), do: "Save app changes"
  defp button_for(:logout_propagation), do: "Save notification settings"
  defp button_for(:redirects), do: "Save return URLs"
  defp button_for(:logout_uris), do: "Save return URLs"
  defp button_for(:par_policy), do: "Save authorization request rules"
  defp button_for(:security_profile), do: "Save security profile"
end
