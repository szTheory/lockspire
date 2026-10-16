defmodule Lockspire.Web.Live.Admin.ClientsLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Admin.Clients, as: AdminClients
  alias Lockspire.Admin.ServerPolicy, as: AdminServerPolicy
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.MessageSigningProfile
  alias Lockspire.Protocol.DpopPolicy
  alias Lockspire.Protocol.ParPolicy
  alias Lockspire.Protocol.SecurityProfile
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.Admin.ClientsLive.FormComponent
  alias Lockspire.Web.Live.Admin.ClientsLive.Index
  alias Lockspire.Web.Live.Admin.ClientsLive.RotateSecretComponent
  alias Lockspire.Web.Live.AdminLayoutLive

  @saveable_modes [
    :edit,
    :redirects,
    :logout_uris,
    :par_policy,
    :security_profile,
    :logout_propagation
  ]

  @impl true
  def mount(params, _session, socket) do
    client_id = if is_map(params), do: Map.get(params, "client_id"), else: nil

    {:ok,
     socket
     |> assign(
       page_title: "App details",
       task_title: "App details",
       task_body:
         "Review this app's identity, effective policy, credentials, and registered endpoints.",
       current_section: :clients,
       client_id: client_id,
       return_filters: Index.normalize_filters(if is_map(params), do: params, else: %{}),
       form_mode: nil,
       client: nil,
       client_load_state: :loading,
       form_params: nil,
       save_notice: nil,
       save_notice_pending: false,
       effective_par_policy: nil,
       effective_dpop_policy: nil,
       effective_security_profile: nil,
       policy_load_state: :unavailable,
       strict_readiness: default_readiness(),
       private_key_jwt_truth: nil,
       remote_jwks_summary: nil,
       global_access_token_format: nil,
       effective_access_token_format: nil,
       form_errors: [],
       rotation_errors: [],
       revealed_secret: nil,
       revealed_rat: nil,
       lifecycle_errors: []
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    action = normalize_action(socket.assigns.live_action || :show)
    form_mode = resolve_form_mode(action, params)
    {task_title, task_body} = client_task_copy(action, form_mode)

    {:noreply,
     socket
     |> assign(
       action: action,
       form_mode: form_mode,
       page_title: task_title,
       task_title: task_title,
       task_body: task_body,
       form_params: nil,
       save_notice:
         if(socket.assigns.save_notice_pending and is_nil(form_mode),
           do: socket.assigns.save_notice,
           else: nil
         ),
       save_notice_pending: false,
       form_errors: [],
       rotation_errors: [],
       lifecycle_errors: [],
       revealed_secret: nil,
       revealed_rat: nil
     )
     |> load_client(Map.get(params, "client_id", socket.assigns.client_id))}
  end

  @impl true
  def handle_event(
        "preview_client_policy",
        %{"client" => params},
        %{assigns: %{form_mode: mode}} = socket
      )
      when mode in [:edit, :par_policy, :security_profile] do
    {:noreply, assign(socket, form_params: safe_form_params(params, mode))}
  end

  @impl true
  def handle_event(
        "save_client",
        %{"client" => params},
        %{assigns: %{form_mode: mode}} = socket
      )
      when mode in @saveable_modes do
    result =
      Admin.update_client(
        socket.assigns.client_id,
        save_client_attrs(mode, params, socket.assigns.client)
      )

    case result do
      {:ok, %Client{} = client} ->
        updated_socket =
          assign(socket,
            client: client,
            client_load_state: :loaded,
            strict_readiness: strict_readiness(),
            remote_jwks_summary: AdminClients.remote_jwks_summary(client),
            form_errors: [],
            form_params: nil,
            save_notice: "App changes saved.",
            save_notice_pending: mode == :edit
          )
          |> assign(policy_view_assigns(client))

        if mode == :edit do
          {:noreply, push_patch(updated_socket, to: show_path(client.client_id, :show))}
        else
          {:noreply, updated_socket}
        end

      {:error, errors} when is_list(errors) ->
        {:noreply,
         assign(socket,
           form_errors: errors,
           form_params: safe_form_params(params, mode),
           save_notice: nil
         )}

      {:error, _reason} ->
        {:noreply,
         assign(socket,
           form_errors: [%{field: :base, reason: :request_failed, detail: nil}],
           form_params: safe_form_params(params, mode),
           save_notice: nil
         )}
    end
  end

  def handle_event("save_client", _params, socket), do: {:noreply, socket}

  def handle_event(
        "rotate_secret",
        %{"rotate" => %{"confirm" => "true"}},
        %{assigns: %{action: :rotate_secret, revealed_secret: nil}} = socket
      ) do
    case Admin.rotate_client_secret(socket.assigns.client_id, %{
           actor: %{type: :operator, id: "admin-ui"}
         }) do
      {:ok, %{client: client, client_secret: secret}} ->
        {:noreply,
         assign(socket,
           client: client,
           revealed_secret: secret,
           revealed_rat: nil,
           rotation_errors: []
         )}

      {:error, _reason} ->
        {:noreply,
         assign(socket,
           revealed_secret: nil,
           revealed_rat: nil,
           rotation_errors: [client_secret_rotation_error()]
         )}
    end
  end

  def handle_event(
        "rotate_secret",
        _params,
        %{assigns: %{action: :rotate_secret, revealed_secret: nil}} = socket
      ) do
    {:noreply,
     assign(socket,
       rotation_errors: [%{field: :confirm, reason: :required, detail: "confirmation required"}]
     )}
  end

  def handle_event(
        "rotate_rat",
        %{"rotate" => %{"confirm" => "true"}},
        %{
          assigns: %{
            action: :rotate_registration_access_token,
            client: %Client{provenance: :self_registered},
            revealed_rat: nil
          }
        } = socket
      ) do
    case Lockspire.Protocol.RegistrationManagement.rotate_registration_access_token(
           socket.assigns.client
         ) do
      {:ok, plaintext, updated_client} ->
        {:noreply,
         assign(socket,
           client: updated_client,
           revealed_secret: nil,
           revealed_rat: plaintext,
           rotation_errors: []
         )}

      {:error, _reason} ->
        {:noreply,
         assign(socket,
           revealed_secret: nil,
           revealed_rat: nil,
           rotation_errors: [registration_token_rotation_error()]
         )}
    end
  end

  def handle_event(
        "rotate_rat",
        _params,
        %{
          assigns: %{
            action: :rotate_registration_access_token,
            client: %Client{provenance: :self_registered},
            revealed_rat: nil
          }
        } = socket
      ) do
    {:noreply,
     assign(socket,
       rotation_errors: [%{field: :confirm, reason: :required, detail: "confirmation required"}]
     )}
  end

  def handle_event("rotate_secret", _params, socket), do: {:noreply, socket}
  def handle_event("rotate_rat", _params, socket), do: {:noreply, socket}

  def handle_event("acknowledge_secret", _params, socket) do
    {:noreply, assign(socket, revealed_secret: nil)}
  end

  def handle_event("acknowledge_rat", _params, socket) do
    {:noreply, assign(socket, revealed_rat: nil)}
  end

  def handle_event(
        "toggle_client",
        %{"toggle" => %{"confirm" => "true"}},
        %{assigns: %{client: %Client{active: true}}} = socket
      ) do
    {:noreply, apply_toggle(socket, false)}
  end

  def handle_event("toggle_client", %{"toggle" => %{"confirm" => "true"}}, socket) do
    {:noreply, apply_toggle(socket, true)}
  end

  def handle_event("toggle_client", _params, socket) do
    {:noreply,
     assign(socket,
       lifecycle_errors: [
         %{field: :confirm, reason: :required, detail: "confirm this lifecycle change"}
       ]
     )}
  end

  @impl true
  def render(%{client: nil, client_load_state: :error} = assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.alert variant={:danger} title="Could not load app">
        <p>This app couldn't be loaded. Reload the page or go back to the app list.</p>
        <div class="lockspire-admin-client-inventory__recovery">
          <.link
            class="lockspire-admin-btn lockspire-admin-btn-secondary"
            href={show_path(@client_id, :show)}
          >
            Reload this view
          </.link>
          <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={client_index_path(@return_filters)}>
            Back to apps
          </.link>
        </div>
      </AdminComponents.alert>
      </AdminLayoutLive.shell>
    """
  end

  @impl true
  def render(%{client: nil} = assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.empty_state
        title="App not found"
        body="No app has this Client ID. Return to the app list and choose a current app."
      >
        <:actions>
          <.link
            class="lockspire-admin-btn lockspire-admin-btn-secondary"
            href={client_index_path(@return_filters)}
          >
            Back to apps
          </.link>
        </:actions>
      </AdminComponents.empty_state>
    </AdminLayoutLive.shell>
    """
  end

  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.alert :if={@save_notice} variant={:success} title={@save_notice}>
        The saved app settings are shown below.
      </AdminComponents.alert>

      <AdminComponents.entity_header
        :if={@action != :show}
        data-client-task-context
        title={@client.name || @client.client_id}
        subtitle={@task_body}
        identifier={@client.client_id}
      >
        <:actions>
          <.link
            class="lockspire-admin-btn lockspire-admin-btn-secondary"
            patch={show_path(@client.client_id, :show)}
          >
            Back to app
          </.link>
        </:actions>
      </AdminComponents.entity_header>

      <div :if={@action == :show} class="lockspire-admin-client-workspace">
        <AdminComponents.entity_header
          title={@client.name || @client.client_id}
          subtitle={@task_body}
          identifier={@client.client_id}
        >
          <:status>
            <AdminComponents.status_badge status={status_for(@client)} />
            <AdminComponents.status_badge status={@client.provenance} />
          </:status>
          <:actions>
            <AdminComponents.action_group>
              <:primary>
                <.link
                  class="lockspire-admin-btn lockspire-admin-btn-primary"
                  patch={show_path(@client.client_id, :edit)}
                >
                  Edit app details
                </.link>
              </:primary>
              <:secondary>
                <.link
                  class="lockspire-admin-btn lockspire-admin-btn-secondary"
                  href={client_index_path(@return_filters)}
                >
                  Back to apps
                </.link>
              </:secondary>
            </AdminComponents.action_group>
          </:actions>
        </AdminComponents.entity_header>

        <AdminComponents.pane
          title="Identity and current status"
          subtitle="Client ID, app type, and whether the app is active."
        >
          <AdminComponents.description_list>
            <:item label="Client ID">
              <AdminComponents.long_value value={@client.client_id} kind={:id} />
            </:item>
            <:item label="App type">{client_type_label(@client.client_type)}</:item>
            <:item label="How the app authenticates">
              {token_auth_method_label(@client.token_endpoint_auth_method)}
            </:item>
            <:item label="Code exchange protection (PKCE)">
              {if @client.pkce_required, do: "Required", else: "Not required"}
            </:item>
            <:item label="Created">
              <AdminComponents.long_value value={format_datetime(@client.created_at)} kind={:timestamp} />
            </:item>
          </AdminComponents.description_list>
        </AdminComponents.pane>

        <AdminComponents.pane
          title="Security settings"
          subtitle="The default applies unless this app has its own setting. The values below show what this app uses."
        >
          <AdminComponents.alert
            :if={@policy_load_state == :unavailable}
            variant={:warning}
            title="Provider settings are unavailable"
          >
            <p>
              This app's saved settings are shown, but provider defaults and the resulting behavior could not be loaded.
            </p>
          </AdminComponents.alert>
          <AdminComponents.description_list>
            <:item label="Security requirements">
              <strong>{security_verdict_for(@effective_security_profile)}</strong>
              <p class="lockspire-admin-help">
                Default: {security_global_profile_label(@effective_security_profile)} · This app: {security_profile_label(@client.security_profile)}
              </p>
            </:item>
            <:item label="Authorization requests">
              <strong>{verdict_for(@effective_par_policy)}</strong>
              <p class="lockspire-admin-help">
                Default: {par_global_policy_label(@effective_par_policy)} · This app: {par_policy_label(@client.par_policy)}
              </p>
            </:item>
            <:item label="Access token format">
              <strong>{policy_value_label(@effective_access_token_format)}</strong>
              <p class="lockspire-admin-help">
                Default: {policy_value_label(@global_access_token_format)} · This app: {access_token_format_override_label(@client.access_token_format)}
              </p>
            </:item>
            <:item label="Token proof">
              <strong>{dpop_policy_label(effective_dpop_policy(@effective_dpop_policy))}</strong>
              <p class="lockspire-admin-help">
                Default: {dpop_policy_label(global_dpop_policy(@effective_dpop_policy))} · This app: {dpop_policy_label(@client.dpop_policy)}
              </p>
            </:item>
          </AdminComponents.description_list>

          <AdminComponents.alert
            :if={show_strict_message_signing_panel?(@effective_security_profile)}
            variant={if mixed_mode_override?(@effective_security_profile), do: :warning, else: :info}
            title="FAPI 2.0 message-signing rules"
          >
            <p>
              <strong>App requirements:</strong> {strict_posture_label(@effective_security_profile)}
            </p>
            <p>
              <strong>Provider readiness:</strong> {strict_readiness_label(@effective_security_profile, @strict_readiness)}
            </p>
            <p :if={@effective_security_profile.fapi_2_0_message_signing?}>
              `/authorize` requires an explicit JWT response mode and `/introspect` requires
              `Accept: application/token-introspection+jwt`.
            </p>
            <p :if={mixed_mode_override?(@effective_security_profile)}>
              This app has an explicit exception to the provider's message-signing requirement.
              The provider's stricter setting does not apply to this app.
            </p>
            <ul
              :if={
                @strict_readiness.remediation != [] and
                  (@effective_security_profile.fapi_2_0_message_signing? or
                     @strict_readiness.status == :unavailable)
              }
              class="lockspire-admin-errors"
            >
              <%= for item <- @strict_readiness.remediation do %>
                <li>{item}</li>
              <% end %>
            </ul>
          </AdminComponents.alert>

          <AdminComponents.alert
            :if={mixed_mode_override?(@effective_security_profile)}
            variant={:warning}
            role="alert"
            title="Provider security defaults do not apply to this app"
          >
            <p>
              This app is excluded from FAPI 2.0 checks, including Pushed Authorization Requests
              and DPoP. Review this exception before relying on the provider's security defaults.
            </p>
          </AdminComponents.alert>

          <AdminComponents.action_group>
            <:secondary>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :par_policy)}>Edit authorization request rules</.link>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :security_profile)}>Edit security profile</.link>
            </:secondary>
          </AdminComponents.action_group>
        </AdminComponents.pane>

        <AdminComponents.pane
          title="Secret and signing keys"
          subtitle="Check this app's secret and the keys it signs requests with. Secret values stay hidden."
        >
          <AdminComponents.description_list>
            <:item label="Current secret">
              <AdminComponents.long_value value="redacted" kind={:token} redacted />
            </:item>
            <:item label="Last secret rotation">
              <AdminComponents.long_value
                value={format_datetime(@client.last_secret_rotated_at)}
                kind={:timestamp}
              />
            </:item>
          </AdminComponents.description_list>

          <div :if={client_secret_jwt_client?(@client)} class="lockspire-admin-detail-section">
            <h3>Signed app requests with a shared secret</h3>
            <p>
              Authentication method: <code>client_secret_jwt</code>
            </p>
            <p>
              Stored signing algorithm: <code>{value_or_not_configured(@client.token_endpoint_auth_signing_alg)}</code>
            </p>
            <p class="lockspire-admin-help">
              Lockspire verifies HS256-signed app requests with this secret. The secret itself
              is never shown here.
            </p>
          </div>

          <div :if={private_key_jwt_client?(@client)} class="lockspire-admin-detail-section">
            <h3>App signing keys</h3>
            <p>
              Remote JWKS URI configured:
              <AdminComponents.long_value
                value={value_or_not_configured(@client.jwks_uri)}
                kind={:url}
              />
            </p>
            <p>
              Inline JWKS configured:
              {boolean_label(not is_nil(@client.jwks))}
            </p>
            <p>
              Accepted signing algorithms:
              <code>{supported_assertion_algorithms(@private_key_jwt_truth)}</code>
            </p>
            <p class="lockspire-admin-help">
              Lockspire checks this app's signed requests against its public keys. Private keys
              stay with the app and are never shown here.
            </p>
          </div>

          <div
            :if={show_remote_jwks_summary?(@client, @remote_jwks_summary)}
            class="lockspire-admin-detail-section lockspire-admin-detail-section-muted"
          >
            <h3>Remote JWKS</h3>
            <AdminComponents.description_list>
              <:item label="Status"><code>{@remote_jwks_summary.status}</code></:item>
              <:item label="Summary"><span>{@remote_jwks_summary.headline}</span></:item>
              <:item label="Details"><span>{@remote_jwks_summary.detail}</span></:item>
              <:item label="Next step"><span>{@remote_jwks_summary.next_step}</span></:item>
              <:item label="Ownership"><span>{@remote_jwks_summary.ownership}</span></:item>
              <:item :if={@remote_jwks_summary.incident} label="Incident class">
                <code>{@remote_jwks_summary.incident.class}</code>
              </:item>
              <:item :if={@remote_jwks_summary.command_hint} label="Support command">
                <code>{@remote_jwks_summary.command_hint}</code>
              </:item>
            </AdminComponents.description_list>
          </div>

          <AdminComponents.action_group>
            <:secondary>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" :if={@client.client_type == :confidential} patch={show_path(@client.client_id, :rotate_secret)}>
                Rotate client secret
              </.link>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" :if={@client.provenance == :self_registered} patch={show_path(@client.client_id, :rotate_registration_access_token)}>
                Rotate app management token
              </.link>
            </:secondary>
          </AdminComponents.action_group>
        </AdminComponents.pane>

        <AdminComponents.pane
          title="Sign-in and sign-out URLs"
          subtitle="Review where users return and where this app receives sign-out notifications."
        >
          <AdminComponents.description_list>
            <:item label="Sign-in return URLs">
              <ul class="lockspire-admin-value-list">
                <%= for redirect_uri <- @client.redirect_uris do %>
                  <li><AdminComponents.long_value value={redirect_uri} kind={:url} /></li>
                <% end %>
              </ul>
            </:item>
            <:item label="Sign-out return URLs">
              <p class="lockspire-admin-help">
                Where users may return after signing out.
              </p>
              <ul class="lockspire-admin-value-list">
                <%= for uri <- @client.post_logout_redirect_uris do %>
                  <li><AdminComponents.long_value value={uri} kind={:url} /></li>
                <% end %>
              </ul>
            </:item>
            <:item label="Server sign-out notification URL">
              <p class="lockspire-admin-help">Lockspire sends this app a sign-out notification from the server.</p>
              <AdminComponents.long_value
                value={value_or_not_configured(@client.backchannel_logout_uri)}
                kind={:url}
              />
            </:item>
            <:item label="Include session in server notification">
              {boolean_label(@client.backchannel_logout_session_required)}
            </:item>
            <:item label="Browser sign-out notification URL">
              <p class="lockspire-admin-help">Lockspire notifies this app in the user's browser. Delivery is best effort.</p>
              <AdminComponents.long_value
                value={value_or_not_configured(@client.frontchannel_logout_uri)}
                kind={:url}
              />
            </:item>
            <:item label="Include session in browser notification">
              {boolean_label(@client.frontchannel_logout_session_required)}
            </:item>
          </AdminComponents.description_list>
          <div class="lockspire-admin-help lockspire-admin-help-block">
            <p>
              Server notifications can be retried. Browser notifications are best effort and cannot
              confirm that the app cleared its session.
            </p>
          </div>
          <AdminComponents.action_group>
            <:secondary>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :redirects)}>Edit sign-in return URLs</.link>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :logout_uris)}>
                Edit sign-out return URLs
              </.link>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :logout_propagation)}>
                Edit sign-out notifications
              </.link>
            </:secondary>
          </AdminComponents.action_group>
        </AdminComponents.pane>

        <AdminComponents.pane
          title="Registration details"
          subtitle="Review how this app was added and which permissions it can request."
        >
          <AdminComponents.description_list>
            <:item :if={@client.provenance == :self_registered} label="Registration URL">
              <AdminComponents.long_value
                value={@client.registration_client_uri || "N/A"}
                kind={:url}
              />
            </:item>
            <:item :if={@client.provenance == :self_registered} label="App management token">
              <AdminComponents.long_value value="redacted" kind={:token} redacted />
            </:item>
            <:item label="Allowed permissions">
              <AdminComponents.badge_group>
                <%= for scope <- @client.allowed_scopes do %>
                  <span class="lockspire-admin-badge lockspire-admin-badge-disabled">{scope}</span>
                <% end %>
              </AdminComponents.badge_group>
            </:item>
          </AdminComponents.description_list>
          <p :if={@client.provenance == :self_registered} class="lockspire-admin-help">
            This app was registered through the API. It can update its details using the registration URL and token.
          </p>
          <AdminComponents.action_group>
            <:secondary>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={Lockspire.mount_path() <> "/admin/dcr"}>Review API registration</.link>
            </:secondary>
          </AdminComponents.action_group>
        </AdminComponents.pane>

        <AdminComponents.pane
          title="Related records"
          subtitle="Use this Client ID to find the app's tokens, consent grants, and sign-out notices."
        >
          <AdminComponents.description_list>
            <:item label="Client ID">
              <AdminComponents.long_value value={@client.client_id} kind={:id} />
            </:item>
            <:item label="Finding related records">
              <span>
                These links open the full inventories. Match records there by this Client ID.
              </span>
            </:item>
          </AdminComponents.description_list>
          <AdminComponents.action_group>
            <:secondary>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={Lockspire.mount_path() <> "/admin/tokens"}>Review tokens</.link>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={Lockspire.mount_path() <> "/admin/consents"}>Review consent grants</.link>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={Lockspire.mount_path() <> "/admin/logouts"}>Review sign-out notices</.link>
            </:secondary>
          </AdminComponents.action_group>
        </AdminComponents.pane>

        <AdminComponents.pane
          title="Disable or enable app"
          subtitle="Disabling blocks future OAuth/OIDC requests; enabling lets configured use resume."
        >
          <AdminComponents.lifecycle_row
            title={if @client.active, do: "Disable app", else: "Enable app"}
            timestamp={@client.disabled_at}
            actor={@client.disabled_by}
            consequence={
              if @client.active,
                do: "Disabling this app stops it from signing users in or getting tokens until you enable it again.",
                else: "Enabling this app lets it sign users in and get tokens again."
            }
          >
          </AdminComponents.lifecycle_row>

          <AdminComponents.confirmation_panel
            title={if @client.active, do: "Confirm disabling app", else: "Confirm enabling app"}
            variant={if @client.active, do: :danger, else: :warning}
            errors={@lifecycle_errors}
          >
            <:body>
              <form class="lockspire-admin-form-stack" phx-submit="toggle_client">
                <label class="lockspire-admin-checkbox-field">
                  <input type="checkbox" name="toggle[confirm]" value="true" />
                  <span>
                    <%= if @client.active do %>
                      Disable
                      <AdminComponents.long_value value={@client.client_id} kind={:id} />
                      so this app can't sign users in or get tokens until you enable it again.
                    <% else %>
                      Enable
                      <AdminComponents.long_value value={@client.client_id} kind={:id} />
                      so configured OAuth/OIDC use can resume.
                    <% end %>
                  </span>
                </label>
                <AdminComponents.action_bar>
                  <AdminComponents.admin_button
                    type="submit"
                    variant={if @client.active, do: :danger, else: :secondary}
                  >
                    {if @client.active, do: "Disable app", else: "Enable app"}
                  </AdminComponents.admin_button>
                </AdminComponents.action_bar>
              </form>
            </:body>
          </AdminComponents.confirmation_panel>
        </AdminComponents.pane>
      </div>

      <AdminComponents.section_card
        :if={not is_nil(@form_mode)}
        title="App settings"
        subtitle="Change the values for this task; other app settings stay as they are."
      >
        <FormComponent.client_form
          mode={@form_mode}
          client={@client}
          effective_par_policy={@effective_par_policy}
          effective_dpop_policy={@effective_dpop_policy}
          effective_security_profile={@effective_security_profile}
          global_access_token_format={@global_access_token_format}
          policy_load_state={@policy_load_state}
          strict_readiness={@strict_readiness}
          errors={@form_errors}
          params={@form_params}
          show_heading={false}
        />
      </AdminComponents.section_card>

      <AdminComponents.section_card
        :if={@action == :rotate_registration_access_token}
        title="Rotate app management token"
        subtitle="This token lets the app update its registration. The current token stops working after rotation."
      >
        <section class="lockspire-admin-form-shell">
          <header>
            <p>
              Use this token to update the app's registration at this URL. The current token stops
              working when you create a new one.
            </p>
            <p>
              <strong>Registration URL:</strong>
              <AdminComponents.long_value
                value={value_or_not_configured(@client.registration_client_uri)}
                kind={:url}
              />
            </p>
          </header>

          <AdminComponents.error_list errors={@rotation_errors} />

          <div :if={@revealed_rat}>
            <AdminComponents.copy_once_secret_panel
              title="New app management token"
              body="Copy this token now. It is shown once, and Lockspire stores only a hash."
              label="App management token"
              value={@revealed_rat}
            />
            <AdminComponents.action_bar>
              <AdminComponents.admin_button phx-click="acknowledge_rat">
                I have copied the token
              </AdminComponents.admin_button>
            </AdminComponents.action_bar>
          </div>

          <form :if={is_nil(@revealed_rat)} phx-submit="rotate_rat">
            <label class="lockspire-admin-checkbox-field">
              <input type="checkbox" name="rotate[confirm]" value="true" />
              <span>I understand the current token stops working after rotation.</span>
            </label>

            <AdminComponents.action_bar>
              <AdminComponents.admin_button
                type="submit"
                variant={:danger}
                phx-disable-with="Rotating app management token…"
              >
                Rotate app management token
              </AdminComponents.admin_button>
            </AdminComponents.action_bar>
          </form>
        </section>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        :if={@action == :rotate_secret}
        title="Rotate client secret"
        subtitle="Update the app with the new secret before it requests tokens. Copy it when shown; Lockspire stores only a hash, so it cannot show the secret again."
      >
        <RotateSecretComponent.rotation_panel
          show_heading={false}
          errors={@rotation_errors}
          revealed_secret={@revealed_secret}
        />
      </AdminComponents.section_card>
    </AdminLayoutLive.shell>
    """
  end

  defp load_client(socket, nil) do
    assign(socket,
      client: nil,
      client_load_state: :not_found,
      effective_par_policy: nil,
      effective_dpop_policy: nil,
      effective_security_profile: nil,
      policy_load_state: :unavailable,
      strict_readiness: default_readiness(),
      private_key_jwt_truth: nil,
      remote_jwks_summary: nil,
      global_access_token_format: nil,
      effective_access_token_format: nil
    )
  end

  defp load_client(socket, client_id) do
    case Admin.get_client(client_id) do
      {:ok, %Client{} = client} ->
        assign(socket,
          client_id: client_id,
          client: client,
          client_load_state: :loaded,
          strict_readiness: strict_readiness(),
          remote_jwks_summary: AdminClients.remote_jwks_summary(client)
        )
        |> assign(policy_view_assigns(client))

      {:error, :not_found} ->
        assign(socket,
          client_id: client_id,
          client: nil,
          client_load_state: :not_found,
          effective_par_policy: nil,
          effective_dpop_policy: nil,
          effective_security_profile: nil,
          policy_load_state: :unavailable,
          strict_readiness: default_readiness(),
          private_key_jwt_truth: nil,
          remote_jwks_summary: nil,
          global_access_token_format: nil,
          effective_access_token_format: nil
        )

      {:error, _reason} ->
        assign(socket,
          client_id: client_id,
          client: nil,
          client_load_state: :error,
          effective_par_policy: nil,
          effective_dpop_policy: nil,
          effective_security_profile: nil,
          policy_load_state: :unavailable,
          strict_readiness: default_readiness(),
          private_key_jwt_truth: nil,
          remote_jwks_summary: nil,
          global_access_token_format: nil,
          effective_access_token_format: nil
        )
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
      {:ok, %Client{} = client} ->
        assign(socket,
          client: client,
          remote_jwks_summary: AdminClients.remote_jwks_summary(client),
          lifecycle_errors: []
        )

      {:error, _reason} ->
        assign(socket,
          lifecycle_errors: [
            %{
              field: :base,
              reason: :request_failed,
              detail: nil,
              message: "The app was not changed. Reload the page and try again."
            }
          ]
        )
    end
  end

  defp edit_attrs(params, %Client{} = client) do
    %{
      name: Map.get(params, "name", client.name),
      allowed_scopes:
        if(Map.has_key?(params, "allowed_scopes"),
          do: split_csv(params["allowed_scopes"]),
          else: client.allowed_scopes
        ),
      dpop_policy: Map.get(params, "dpop_policy", client.dpop_policy),
      access_token_format: Map.get(params, "access_token_format", client.access_token_format),
      contacts:
        if(Map.has_key?(params, "contacts"),
          do: split_csv(params["contacts"]),
          else: client.contacts
        ),
      logo_uri: Map.get(params, "logo_uri", client.logo_uri),
      tos_uri: Map.get(params, "tos_uri", client.tos_uri),
      policy_uri: Map.get(params, "policy_uri", client.policy_uri)
    }
  end

  defp redirect_attrs(params, %Client{} = client, :redirects) do
    %{
      redirect_uris: split_lines(params["redirect_uris"]),
      post_logout_redirect_uris: client.post_logout_redirect_uris
    }
  end

  defp redirect_attrs(params, %Client{} = client, :logout_uris) do
    %{
      redirect_uris: client.redirect_uris,
      post_logout_redirect_uris: split_lines(params["post_logout_redirect_uris"])
    }
  end

  defp logout_propagation_attrs(params) do
    %{
      backchannel_logout_uri: params["backchannel_logout_uri"],
      backchannel_logout_session_required: params["backchannel_logout_session_required"],
      frontchannel_logout_uri: params["frontchannel_logout_uri"],
      frontchannel_logout_session_required: params["frontchannel_logout_session_required"]
    }
  end

  defp normalize_action(action)
       when action in [
              :show,
              :edit,
              :redirects,
              :logout_uris,
              :rotate_secret,
              :par_policy,
              :security_profile,
              :rotate_registration_access_token
            ],
       do: action

  defp normalize_action(_action), do: :show

  defp resolve_form_mode(:edit, %{"workflow" => "logout-propagation"}), do: :logout_propagation

  defp resolve_form_mode(action, _params)
       when action in [:edit, :redirects, :logout_uris, :par_policy, :security_profile],
       do: action

  defp resolve_form_mode(_action, _params), do: nil

  defp client_task_copy(:show, _form_mode) do
    {"App details", "Review this app's settings, credentials, and sign-in destinations."}
  end

  defp client_task_copy(:edit, :logout_propagation) do
    {"Update sign-out notifications",
     "Choose where this app receives sign-out notifications. Server delivery can be retried; browser delivery is best effort."}
  end

  defp client_task_copy(:edit, :edit) do
    {"Edit app settings", "Update this app's name, permissions, details, and token settings."}
  end

  defp client_task_copy(:redirects, :redirects) do
    {"Update sign-in return URLs", "Set the exact URLs where users return after signing in."}
  end

  defp client_task_copy(:logout_uris, :logout_uris) do
    {"Update sign-out return URLs",
     "Set the exact URLs where users may return after signing out."}
  end

  defp client_task_copy(:par_policy, :par_policy) do
    {"Set authorization request rules",
     "Choose whether this app must use Pushed Authorization Requests (PAR) or follow the provider default."}
  end

  defp client_task_copy(:security_profile, :security_profile) do
    {"Update app security requirements",
     "Choose this app's FAPI and OIDC requirements or use the provider default."}
  end

  defp client_task_copy(:rotate_registration_access_token, _form_mode) do
    {"Rotate app management token",
     "Replace the token this app uses to update or delete its registration. The new token is shown once, right after you confirm."}
  end

  defp client_task_copy(:rotate_secret, _form_mode) do
    {"Rotate client secret",
     "Replace this app's client secret. The new secret is shown once, right after you confirm."}
  end

  defp show_path(client_id, :show),
    do:
      Lockspire.mount_path() <>
        "/admin/clients/" <> URI.encode(client_id, &URI.char_unreserved?/1)

  defp show_path(client_id, :edit), do: show_path(client_id, :show) <> "/edit"

  defp show_path(client_id, :logout_propagation),
    do: show_path(client_id, :edit) <> "?workflow=logout-propagation"

  defp show_path(client_id, :security_profile),
    do: show_path(client_id, :show) <> "/security-profile"

  defp show_path(client_id, :par_policy), do: show_path(client_id, :show) <> "/par-policy"
  defp show_path(client_id, :redirects), do: show_path(client_id, :show) <> "/redirects"
  defp show_path(client_id, :logout_uris), do: show_path(client_id, :show) <> "/logout-uris"
  defp show_path(client_id, :rotate_secret), do: show_path(client_id, :show) <> "/rotate-secret"

  defp show_path(client_id, :rotate_registration_access_token),
    do: show_path(client_id, :show) <> "/rotate-registration-access-token"

  defp client_index_path(filters), do: Index.index_path(filters)

  defp safe_form_params(params, mode) when is_map(params) do
    Map.take(params, form_param_keys(mode))
  end

  defp form_param_keys(:edit),
    do:
      ~w(name allowed_scopes dpop_policy access_token_format contacts logo_uri tos_uri policy_uri)

  defp form_param_keys(:redirects), do: ~w(redirect_uris)
  defp form_param_keys(:logout_uris), do: ~w(post_logout_redirect_uris)

  defp form_param_keys(:logout_propagation),
    do:
      ~w(backchannel_logout_uri backchannel_logout_session_required frontchannel_logout_uri frontchannel_logout_session_required)

  defp form_param_keys(:par_policy), do: ~w(par_policy)

  defp form_param_keys(:security_profile),
    do: ~w(security_profile authorization_signed_response_alg)

  defp form_param_keys(_mode), do: []

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

  defp policy_view_assigns(%Client{} = client) do
    case Admin.get_server_policy() do
      {:ok, %ServerPolicy{} = policy} ->
        {:ok, effective_dpop_policy} = DpopPolicy.resolve_effective_policy(policy, client)

        %{
          policy_load_state: :loaded,
          effective_par_policy: ParPolicy.resolve_effective_policy(policy, client),
          effective_dpop_policy: effective_dpop_policy,
          effective_security_profile: SecurityProfile.resolve_effective_profile(policy, client),
          strict_readiness: strict_readiness(),
          private_key_jwt_truth: AdminServerPolicy.private_key_jwt_registration_truth(policy),
          global_access_token_format: global_access_token_format(policy),
          effective_access_token_format: resolve_effective_access_token_format(policy, client)
        }

      {:error, _reason} ->
        %{
          policy_load_state: :unavailable,
          effective_par_policy: nil,
          effective_dpop_policy: nil,
          effective_security_profile: nil,
          private_key_jwt_truth: nil,
          global_access_token_format: nil,
          effective_access_token_format: nil
        }
    end
  end

  defp global_access_token_format(%ServerPolicy{access_token_format: format}),
    do: access_token_format_string(format)

  # Same per-client -> server-default -> :jwt precedence the signer uses. A `nil`
  # client override means inherit, so the server default (or :jwt) wins.
  defp resolve_effective_access_token_format(%ServerPolicy{} = policy, %Client{
         access_token_format: nil
       }),
       do: global_access_token_format(policy)

  defp resolve_effective_access_token_format(%ServerPolicy{}, %Client{access_token_format: format}),
       do: access_token_format_string(format)

  defp access_token_format_string(format), do: Atom.to_string(format)

  # `nil` means the app uses the provider setting (no `:inherit` sentinel is stored).
  defp access_token_format_override_label(nil), do: "Use provider default"
  defp access_token_format_override_label(format), do: policy_value_label(format)

  defp par_policy_label(:inherit), do: "Use provider default"
  defp par_policy_label(:required), do: "Required"
  defp par_policy_label(:optional), do: "Optional"

  defp par_policy_label(nil), do: "Unavailable"
  defp par_policy_label(_policy), do: "Unavailable"

  defp par_global_policy_label(nil), do: "Unavailable"
  defp par_global_policy_label(%{global_policy: policy}), do: par_policy_label(policy)

  defp dpop_policy_label(:inherit), do: "Use provider default"
  defp dpop_policy_label(:bearer), do: "Bearer tokens allowed"
  defp dpop_policy_label(:dpop), do: "DPoP proof required"

  defp dpop_policy_label(nil), do: "Unavailable"
  defp dpop_policy_label(_policy), do: "Unavailable"
  defp global_dpop_policy(nil), do: nil
  defp global_dpop_policy(%{global_policy: policy}), do: policy
  defp effective_dpop_policy(nil), do: nil
  defp effective_dpop_policy(%{effective_policy: policy}), do: policy

  defp security_global_profile_label(nil), do: "Unavailable"

  defp security_global_profile_label(%{global_profile: profile}),
    do: security_profile_label(profile)

  defp security_profile_label(:inherit), do: "Use provider default"
  defp security_profile_label(:fapi_2_0_message_signing), do: "FAPI 2.0 Message Signing"
  defp security_profile_label(:fapi_2_0_security), do: "FAPI 2.0 Security"
  defp security_profile_label(:none), do: "Standard OAuth and OpenID Connect"

  defp security_profile_label(nil), do: "Unavailable"
  defp security_profile_label(_profile), do: "Unavailable"

  defp policy_value_label(nil), do: "Unavailable"
  defp policy_value_label(:jwt), do: "JWT"
  defp policy_value_label(:opaque), do: "Opaque token"
  defp policy_value_label("jwt"), do: "JWT"
  defp policy_value_label("opaque"), do: "Opaque token"
  defp policy_value_label(value) when is_binary(value), do: value
  defp policy_value_label(_value), do: "Unavailable"

  defp verdict_for(%{par_required?: true}), do: "Required"
  defp verdict_for(%{par_required?: false}), do: "Not required"
  defp verdict_for(nil), do: "Unavailable"

  defp security_verdict_for(%{effective_profile: :fapi_2_0_message_signing}),
    do: "FAPI 2.0 Message Signing"

  defp security_verdict_for(%{effective_profile: :fapi_2_0_security}),
    do: "FAPI 2.0 Security Profile"

  defp security_verdict_for(%{effective_profile: :none}), do: "Standard OAuth and OpenID Connect"
  defp security_verdict_for(nil), do: "Unavailable"

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

  defp show_strict_message_signing_panel?(%{fapi_2_0_message_signing?: true}), do: true
  defp show_strict_message_signing_panel?(resolved), do: mixed_mode_override?(resolved)

  defp strict_posture_label(%{fapi_2_0_message_signing?: true}),
    do: "Required for this app"

  defp strict_posture_label(resolved) when is_map(resolved),
    do: "Provider requirement overridden"

  defp strict_readiness_label(_resolved, %{status: :unavailable}),
    do: "Could not check provider requirements"

  defp strict_readiness_label(%{fapi_2_0_message_signing?: true}, %{ready?: true}), do: "Ready"
  defp strict_readiness_label(%{fapi_2_0_message_signing?: true}, _readiness), do: "Blocked"

  defp strict_readiness_label(_resolved, %{ready?: true}),
    do: "Provider is ready, but this app is excluded"

  defp strict_readiness_label(_resolved, _readiness), do: "Provider requirements still need setup"

  defp private_key_jwt_client?(%Client{token_endpoint_auth_method: :private_key_jwt}), do: true
  defp private_key_jwt_client?(_client), do: false

  defp client_type_label(:confidential), do: "Server-side app"
  defp client_type_label(:public), do: "Browser or mobile app"
  defp client_type_label(_type), do: "Unknown"

  defp token_auth_method_label(:client_secret_basic), do: "Client secret in the request header"
  defp token_auth_method_label(:client_secret_post), do: "Client secret in the request body"
  defp token_auth_method_label(:client_secret_jwt), do: "Signed client assertion (JWT)"
  defp token_auth_method_label(:private_key_jwt), do: "Signed client assertion with app key"
  defp token_auth_method_label(:none), do: "No client secret"
  defp token_auth_method_label(_method), do: "Unknown"

  defp show_remote_jwks_summary?(%Client{jwks_uri: jwks_uri}, %{applicable?: true})
       when is_binary(jwks_uri) and jwks_uri != "",
       do: true

  defp show_remote_jwks_summary?(_client, _summary), do: false

  defp client_secret_jwt_client?(%Client{token_endpoint_auth_method: :client_secret_jwt}),
    do: true

  defp client_secret_jwt_client?(_client), do: false

  defp supported_assertion_algorithms(nil), do: "Not available"

  defp supported_assertion_algorithms(%{supported_assertion_signing_algorithms: algorithms}) do
    Enum.join(algorithms, ", ")
  end

  defp client_secret_rotation_error do
    %{
      field: :base,
      reason: :request_failed,
      detail: nil,
      message:
        "Rotation was not confirmed. No new client secret is shown. Check the client before retrying."
    }
  end

  defp registration_token_rotation_error do
    %{
      field: :base,
      reason: :request_failed,
      detail: nil,
      message:
        "Rotation was not confirmed. No new app management token was created. Review this app before retrying."
    }
  end

  defp format_datetime(nil), do: "Never"
  defp format_datetime(%DateTime{} = value), do: DateTime.to_iso8601(value)

  defp boolean_label(true), do: "Yes"
  defp boolean_label(false), do: "No"

  defp value_or_not_configured(nil), do: "Not configured"
  defp value_or_not_configured(value), do: value

  defp strict_readiness do
    case MessageSigningProfile.readiness() do
      readiness when is_map(readiness) ->
        Map.put(readiness, :status, :available)

      {:error, _reason} ->
        %{
          default_readiness()
          | status: :unavailable,
            remediation: ["Unable to load strict message-signing readiness."]
        }
    end
  end

  defp default_readiness do
    %{
      ready?: false,
      status: :unavailable,
      profile: :fapi_2_0_message_signing,
      prerequisite_reasons: [],
      remediation: []
    }
  end

  defp save_client_attrs(:edit, params, client) do
    edit_attrs(params, client) |> Map.put(:actor, %{type: :operator, id: "admin-ui"})
  end

  defp save_client_attrs(:redirects, params, client) do
    redirect_attrs(params, client, :redirects)
    |> Map.put(:actor, %{type: :operator, id: "admin-ui"})
  end

  defp save_client_attrs(:logout_uris, params, client) do
    redirect_attrs(params, client, :logout_uris)
    |> Map.put(:actor, %{type: :operator, id: "admin-ui"})
  end

  defp save_client_attrs(:par_policy, params, _client) do
    %{par_policy: params["par_policy"], actor: %{type: :operator, id: "admin-ui"}}
  end

  defp save_client_attrs(:security_profile, params, _client) do
    %{
      security_profile: params["security_profile"],
      authorization_signed_response_alg: params["authorization_signed_response_alg"],
      actor: %{type: :operator, id: "admin-ui"}
    }
  end

  defp save_client_attrs(:logout_propagation, params, _client) do
    logout_propagation_attrs(params) |> Map.put(:actor, %{type: :operator, id: "admin-ui"})
  end
end
