defmodule Lockspire.Web.Live.Admin.ClientsLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Admin.Clients, as: AdminClients
  alias Lockspire.Admin.ServerPolicy, as: AdminServerPolicy
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.MessageSigningProfile
  alias Lockspire.Protocol.ParPolicy
  alias Lockspire.Protocol.SecurityProfile
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
       form_mode: nil,
       client: nil,
       effective_par_policy: nil,
       effective_security_profile: nil,
       strict_readiness: default_readiness(),
       private_key_jwt_truth: nil,
       remote_jwks_summary: nil,
       global_access_token_format: nil,
       effective_access_token_format: nil,
       form_errors: [],
       rotation_errors: [],
       revealed_secret: nil,
       revealed_rat: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    action = normalize_action(socket.assigns.live_action || :show)
    form_mode = resolve_form_mode(action, params)

    {:noreply,
     socket
     |> assign(action: action, form_mode: form_mode, form_errors: [], rotation_errors: [])
     |> load_client(Map.get(params, "client_id", socket.assigns.client_id))}
  end

  @impl true
  def handle_event("save_client", %{"client" => params}, socket) do
    result =
      Admin.update_client(
        socket.assigns.client_id,
        save_client_attrs(params, socket.assigns.client)
      )

    case result do
      {:ok, %Client{} = client} ->
        server_policy = server_policy()

        {:noreply,
         assign(socket,
           client: client,
           effective_par_policy: resolve_effective_par_policy(client),
           effective_security_profile: resolve_effective_security_profile(client),
           strict_readiness: strict_readiness(),
           remote_jwks_summary: AdminClients.remote_jwks_summary(client),
           global_access_token_format: global_access_token_format(server_policy),
           effective_access_token_format:
             resolve_effective_access_token_format(server_policy, client),
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
      <AdminComponents.page_hero
        eyebrow="Configure"
        title="Review client configuration"
        body="Review identity, effective posture, credentials, endpoints, DCR context, and lifecycle actions for this client."
      />

      <div class="lockspire-admin-client-workspace">
        <AdminComponents.entity_header
          eyebrow="Client workspace"
          title={@client.name || @client.client_id}
          subtitle="Identity, posture, credentials, endpoints, DCR context, support pivots, and lifecycle actions for this client."
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
                  class="lockspire-admin-btn lockspire-admin-btn-secondary"
                  patch={show_path(@client.client_id, :edit)}
                >
                  Edit client metadata
                </.link>
              </:primary>
            </AdminComponents.action_group>
          </:actions>
        </AdminComponents.entity_header>

        <AdminComponents.pane
          title="Identity and current status"
          subtitle="Stable identity, client class, and current availability."
        >
          <:status>
            <AdminComponents.status_badge status={status_for(@client)} />
          </:status>
          <AdminComponents.description_list>
            <:item label="Client ID">
              <AdminComponents.long_value value={@client.client_id} kind={:id} />
            </:item>
            <:item label="Type"><code>{@client.client_type}</code></:item>
            <:item label="Token auth"><code>{@client.token_endpoint_auth_method}</code></:item>
            <:item label="PKCE required"><code>{to_string(@client.pkce_required)}</code></:item>
            <:item label="Created">
              <AdminComponents.long_value value={format_datetime(@client.created_at)} kind={:timestamp} />
            </:item>
          </AdminComponents.description_list>
        </AdminComponents.pane>

        <AdminComponents.pane
          title="Effective posture"
          subtitle="Issuer defaults and client overrides shown together."
        >
          <:status>
            <AdminComponents.status_cluster>
              <span>Security: {security_verdict_for(@effective_security_profile)}</span>
              <span>PAR: {verdict_for(@effective_par_policy)}</span>
              <span>Access tokens: {@effective_access_token_format}</span>
            </AdminComponents.status_cluster>
          </:status>
          <AdminComponents.description_list>
            <:item label="Global security profile">
              <code>{security_profile_label(@effective_security_profile.global_profile)}</code>
            </:item>
            <:item label="Client security override">
              <code>{security_profile_label(@client.security_profile)}</code>
            </:item>
            <:item label="Effective security profile">
              <strong>{security_verdict_for(@effective_security_profile)}</strong>
            </:item>
            <:item label="Global PAR policy">
              <code>{par_policy_label(@effective_par_policy.global_policy)}</code>
            </:item>
            <:item label="Client PAR override">
              <code>{par_policy_label(@client.par_policy)}</code>
            </:item>
            <:item label="Effective PAR requirement">
              <strong>{verdict_for(@effective_par_policy)}</strong>
            </:item>
            <:item label="Global access token format">
              <code>{@global_access_token_format}</code>
            </:item>
            <:item label="Client access token override">
              <code>{access_token_format_override_label(@client.access_token_format)}</code>
            </:item>
            <:item label="Effective access token format">
              <strong>{@effective_access_token_format}</strong>
            </:item>
          </AdminComponents.description_list>

          <AdminComponents.alert
            :if={show_strict_message_signing_panel?(@effective_security_profile)}
            variant={if mixed_mode_override?(@effective_security_profile), do: :warning, else: :info}
            title="Strict message-signing posture"
          >
            <p>
              <strong>Effective posture:</strong> {strict_posture_label(@effective_security_profile)}
            </p>
            <p>
              <strong>Issuer readiness:</strong> {strict_readiness_label(@effective_security_profile, @strict_readiness)}
            </p>
            <p :if={@effective_security_profile.fapi_2_0_message_signing?}>
              `/authorize` requires an explicit JWT response mode and `/introspect` requires
              `Accept: application/token-introspection+jwt`.
            </p>
            <p :if={mixed_mode_override?(@effective_security_profile)}>
              This client is using the explicit mixed-mode escape hatch. Strict message-signing
              enforcement does not apply to this client even though the issuer is stricter.
            </p>
            <ul :if={@strict_readiness.remediation != [] and @effective_security_profile.fapi_2_0_message_signing?} class="lockspire-admin-errors">
              <%= for item <- @strict_readiness.remediation do %>
                <li>{item}</li>
              <% end %>
            </ul>
          </AdminComponents.alert>

          <AdminComponents.alert
            :if={mixed_mode_override?(@effective_security_profile)}
            variant={:warning}
            role="alert"
            title="Warning: mixed-mode bypass"
          >
            <p>
              This client overrides the global FAPI 2.0 Security Profile to None. FAPI 2.0
              boundary checks (PAR, DPoP) will NOT be enforced for this client.
            </p>
            This is an intentional mixed-mode bypass. Confirm the client genuinely needs standard
            OIDC.
          </AdminComponents.alert>

          <AdminComponents.action_group>
            <:primary>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :par_policy)}>Edit PAR policy</.link>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :security_profile)}>Edit security profile</.link>
            </:primary>
          </AdminComponents.action_group>
        </AdminComponents.pane>

        <AdminComponents.pane
          title="Credentials and assertion keys"
          subtitle="Credential rotation and assertion-key posture without exposing raw credential material."
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
            <h3>Shared JWT client secret posture</h3>
            <p>
              Stored auth method: <code>client_secret_jwt</code>
            </p>
            <p>
              Stored signing algorithm: <code>{value_or_not_configured(@client.token_endpoint_auth_signing_alg)}</code>
            </p>
            <p class="lockspire-admin-help">
              This slice is limited to the shared direct-client assertion surfaces. Lockspire
              keeps <code>HS256</code> read-only here and never exposes secret-derived values.
            </p>
          </div>

          <div :if={private_key_jwt_client?(@client)} class="lockspire-admin-detail-section">
            <h3>Client assertion keys</h3>
            <p>
              Remote JWKS URI configured:
              <AdminComponents.long_value
                value={value_or_not_configured(@client.jwks_uri)}
                kind={:url}
              />
            </p>
            <p>
              Inline JWKS configured:
              <code>{boolean_label(not is_nil(@client.jwks))}</code>
            </p>
            <p>
              Issuer-supported assertion algorithms:
              <code>{supported_assertion_algorithms(@private_key_jwt_truth)}</code>
            </p>
            <p class="lockspire-admin-help">
              This client uses <code>private_key_jwt</code>. Key material stays read-only in
              Phase 59; later verification and remote-fetch behavior are owned by Lockspire,
              not by ad hoc admin actions.
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
            <:primary>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" :if={@client.client_type == :confidential} patch={show_path(@client.client_id, :rotate_secret)}>
                Rotate client secret
              </.link>
            </:primary>
            <:secondary>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" :if={@client.provenance == :self_registered} patch={show_path(@client.client_id, :rotate_registration_access_token)}>
                Rotate registration access token
              </.link>
            </:secondary>
          </AdminComponents.action_group>
        </AdminComponents.pane>

        <AdminComponents.pane
          title="Endpoints and logout"
          subtitle="Browser destinations are separate from RP cleanup endpoints."
        >
          <AdminComponents.description_list>
            <:item label="Redirect URIs">
              <ul class="lockspire-admin-value-list">
                <%= for redirect_uri <- @client.redirect_uris do %>
                  <li><AdminComponents.long_value value={redirect_uri} kind={:url} /></li>
                <% end %>
              </ul>
            </:item>
            <:item label="Post-logout redirect URIs">
              <p class="lockspire-admin-help">
                Post-logout redirect URIs are browser destinations after RP-initiated logout.
              </p>
              <ul class="lockspire-admin-value-list">
                <%= for uri <- @client.post_logout_redirect_uris do %>
                  <li><AdminComponents.long_value value={uri} kind={:url} /></li>
                <% end %>
              </ul>
            </:item>
            <:item label="Back-channel logout URI">
              <AdminComponents.long_value
                value={value_or_not_configured(@client.backchannel_logout_uri)}
                kind={:url}
              />
            </:item>
            <:item label="Back-channel session required">
              <code>{boolean_label(@client.backchannel_logout_session_required)}</code>
            </:item>
            <:item label="Front-channel logout URI">
              <AdminComponents.long_value
                value={value_or_not_configured(@client.frontchannel_logout_uri)}
                kind={:url}
              />
            </:item>
            <:item label="Front-channel session required">
              <code>{boolean_label(@client.frontchannel_logout_session_required)}</code>
            </:item>
          </AdminComponents.description_list>
          <div class="lockspire-admin-help lockspire-admin-help-block">
            <p>Logout propagation URIs are RP cleanup endpoints.</p>
            <p>These logout propagation endpoints stay separate from browser destinations.</p>
            <p>
              Back-channel delivery stays durable through the protocol-owned
              <code>/end_session/complete</code>
              flow.
            </p>
            <p>Front-channel logout remains best effort browser cleanup. It does not prove remote success.</p>
          </div>
          <AdminComponents.action_group>
            <:primary>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :redirects)}>Edit redirect URIs</.link>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :logout_uris)}>
                Edit post-logout redirect URIs
              </.link>
            </:primary>
            <:secondary>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :logout_propagation)}>
                Edit logout propagation URIs
              </.link>
            </:secondary>
          </AdminComponents.action_group>
        </AdminComponents.pane>

        <AdminComponents.pane
          title="DCR and RAT context"
          subtitle="DCR onboarding, self-registered provenance, allowed scopes, and RAT handling."
        >
          <:status>
            <AdminComponents.status_badge status={@client.provenance} />
          </:status>
          <AdminComponents.description_list>
            <:item label="Provenance">
              <code>{@client.provenance}</code>
            </:item>
            <:item :if={@client.provenance == :self_registered} label="Registration Client URI">
              <AdminComponents.long_value
                value={@client.registration_client_uri || "N/A"}
                kind={:url}
              />
            </:item>
            <:item label="Allowed scopes">
              <AdminComponents.badge_group>
                <%= for scope <- @client.allowed_scopes do %>
                  <span class="lockspire-admin-badge lockspire-admin-badge-disabled">{scope}</span>
                <% end %>
              </AdminComponents.badge_group>
            </:item>
          </AdminComponents.description_list>
          <p :if={@client.provenance == :self_registered} class="lockspire-admin-help">
            Self-registered client (DCR). Registration access token rotation is grouped with credential actions above.
          </p>
          <AdminComponents.action_group>
            <:secondary>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={Lockspire.mount_path() <> "/admin/dcr"}>Review DCR onboarding</.link>
            </:secondary>
          </AdminComponents.action_group>
        </AdminComponents.pane>

        <AdminComponents.pane
          title="Support pivots"
          subtitle="Use stable identifiers to review adjacent support and operate surfaces without inventing new filters."
        >
          <AdminComponents.description_list>
            <:item label="Client pivot">
              <AdminComponents.long_value value={@client.client_id} kind={:id} />
            </:item>
            <:item label="Review context">
              <span>
                Use this client ID when reviewing token, consent, and logout delivery surfaces.
                No client-specific support mutation is introduced here.
              </span>
            </:item>
          </AdminComponents.description_list>
          <AdminComponents.action_group>
            <:secondary>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={Lockspire.mount_path() <> "/admin/tokens"}>Review tokens</.link>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={Lockspire.mount_path() <> "/admin/consents"}>Review consent grants</.link>
              <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={Lockspire.mount_path() <> "/admin/logouts"}>Review logout deliveries</.link>
            </:secondary>
          </AdminComponents.action_group>
        </AdminComponents.pane>

        <AdminComponents.pane
          title="Lifecycle and destructive actions"
          subtitle="Client availability changes are explicit and keep the existing toggle event."
        >
          <:status>
            <AdminComponents.status_badge status={status_for(@client)} />
          </:status>
          <AdminComponents.lifecycle_row
            title={if @client.active, do: "Disable client", else: "Enable client"}
            state={status_for(@client)}
            timestamp={@client.disabled_at}
            actor={@client.disabled_by}
            consequence={
              if @client.active,
                do: "Disabling this client blocks future OAuth/OIDC use until it is enabled again.",
                else: "Enabling this client allows configured OAuth/OIDC use to resume."
            }
          >
            <:actions>
              <AdminComponents.action_group>
                <:destructive>
                  <button :if={@client.active} class="lockspire-admin-btn lockspire-admin-btn-danger" phx-click="toggle_client" type="button">
                    Disable client
                  </button>
                </:destructive>
                <:secondary>
                  <button :if={!@client.active} class="lockspire-admin-btn lockspire-admin-btn-secondary" phx-click="toggle_client" type="button">
                    Enable client
                  </button>
                </:secondary>
              </AdminComponents.action_group>
            </:actions>
          </AdminComponents.lifecycle_row>
        </AdminComponents.pane>
      </div>

      <AdminComponents.section_card
        :if={not is_nil(@form_mode)}
        title="Safe edit workflow"
        subtitle="Only the allowed shape for this workflow is editable."
      >
        <FormComponent.client_form
          mode={@form_mode}
          client={@client}
          effective_par_policy={@effective_par_policy}
          effective_security_profile={@effective_security_profile}
          strict_readiness={@strict_readiness}
          errors={@form_errors}
        />
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

          <AdminComponents.error_list errors={@rotation_errors} />

          <div :if={@revealed_rat}>
            <AdminComponents.copy_once_secret_panel
              title="New Registration Access Token"
              body="Copy it now. Lockspire does not store or re-show plaintext tokens."
              label="Registration access token"
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
              <span>I understand the previous RAT stops being the current credential after rotation.</span>
            </label>

            <AdminComponents.action_bar>
              <AdminComponents.admin_button type="submit" variant={:danger}>
                Rotate registration access token
              </AdminComponents.admin_button>
            </AdminComponents.action_bar>
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
    assign(socket,
      client: nil,
      effective_par_policy: nil,
      effective_security_profile: nil,
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
        server_policy = server_policy()

        assign(socket,
          client_id: client_id,
          client: client,
          effective_par_policy: resolve_effective_par_policy(client),
          effective_security_profile: resolve_effective_security_profile(client),
          strict_readiness: strict_readiness(),
          private_key_jwt_truth:
            AdminServerPolicy.private_key_jwt_registration_truth(server_policy),
          remote_jwks_summary: AdminClients.remote_jwks_summary(client),
          global_access_token_format: global_access_token_format(server_policy),
          effective_access_token_format:
            resolve_effective_access_token_format(server_policy, client)
        )

      {:error, _reason} ->
        assign(socket,
          client_id: client_id,
          client: nil,
          effective_par_policy: nil,
          effective_security_profile: nil,
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
          remote_jwks_summary: AdminClients.remote_jwks_summary(client)
        )

      {:error, _reason} ->
        socket
    end
  end

  defp edit_attrs(params, %Client{} = client) do
    %{
      name: Map.get(params, "name", client.name),
      allowed_scopes: split_csv(params["allowed_scopes"]),
      dpop_policy: params["dpop_policy"],
      access_token_format: params["access_token_format"],
      contacts: split_csv(params["contacts"]),
      logo_uri: params["logo_uri"],
      tos_uri: params["tos_uri"],
      policy_uri: params["policy_uri"]
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

  defp show_path(client_id, :show), do: Lockspire.mount_path() <> "/admin/clients/" <> client_id
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
    ParPolicy.resolve_effective_policy(server_policy(), client)
  end

  defp resolve_effective_security_profile(%Client{} = client) do
    SecurityProfile.resolve_effective_profile(server_policy(), client)
  end

  defp server_policy do
    case Admin.get_server_policy() do
      {:ok, %ServerPolicy{} = policy} -> policy
      {:error, _reason} -> %ServerPolicy{}
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

  # `nil` means inherit (no `:inherit` sentinel is stored), rendered as the word "inherit".
  defp access_token_format_override_label(nil), do: "inherit"
  defp access_token_format_override_label(format), do: Atom.to_string(format)

  defp par_policy_label(policy) when policy in [:inherit, :required, :optional] do
    Atom.to_string(policy)
  end

  defp security_profile_label(profile)
       when profile in [:inherit, :fapi_2_0_message_signing, :fapi_2_0_security, :none] do
    Atom.to_string(profile)
  end

  defp verdict_for(%{par_required?: true}), do: "Required"
  defp verdict_for(%{par_required?: false}), do: "Not required"

  defp security_verdict_for(%{effective_profile: :fapi_2_0_message_signing}),
    do: "FAPI 2.0 Message Signing"

  defp security_verdict_for(%{effective_profile: :fapi_2_0_security}),
    do: "FAPI 2.0 Security Profile"

  defp security_verdict_for(%{effective_profile: :none}), do: "None (Standard OIDC)"

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
    do: "Strict message signing enforced"

  defp strict_posture_label(resolved) when is_map(resolved),
    do: "Mixed-mode escape hatch"

  defp strict_readiness_label(%{fapi_2_0_message_signing?: true}, %{ready?: true}), do: "Ready"
  defp strict_readiness_label(%{fapi_2_0_message_signing?: true}, _readiness), do: "Blocked"

  defp strict_readiness_label(_resolved, %{ready?: true}),
    do: "Issuer is ready, but this client opted out"

  defp strict_readiness_label(_resolved, _readiness), do: "Issuer prerequisites still missing"

  defp private_key_jwt_client?(%Client{token_endpoint_auth_method: :private_key_jwt}), do: true
  defp private_key_jwt_client?(_client), do: false

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

  defp format_datetime(nil), do: "Never"
  defp format_datetime(%DateTime{} = value), do: DateTime.to_iso8601(value)

  defp boolean_label(true), do: "true"
  defp boolean_label(false), do: "false"

  defp value_or_not_configured(nil), do: "Not configured"
  defp value_or_not_configured(value), do: value

  defp strict_readiness do
    case MessageSigningProfile.readiness() do
      readiness when is_map(readiness) ->
        readiness

      {:error, _reason} ->
        %{default_readiness() | remediation: ["Unable to load strict message-signing readiness."]}
    end
  end

  defp default_readiness do
    %{
      ready?: false,
      profile: :fapi_2_0_message_signing,
      prerequisite_reasons: [],
      remediation: []
    }
  end

  defp save_client_attrs(%{"mode" => "edit"} = params, client) do
    edit_attrs(params, client) |> Map.put(:actor, %{type: :operator, id: "admin-ui"})
  end

  defp save_client_attrs(%{"mode" => "redirects"} = params, client) do
    redirect_attrs(params, client, :redirects)
    |> Map.put(:actor, %{type: :operator, id: "admin-ui"})
  end

  defp save_client_attrs(%{"mode" => "logout_uris"} = params, client) do
    redirect_attrs(params, client, :logout_uris)
    |> Map.put(:actor, %{type: :operator, id: "admin-ui"})
  end

  defp save_client_attrs(%{"mode" => "par_policy"} = params, _client) do
    %{par_policy: params["par_policy"], actor: %{type: :operator, id: "admin-ui"}}
  end

  defp save_client_attrs(%{"mode" => "security_profile"} = params, _client) do
    %{
      security_profile: params["security_profile"],
      authorization_signed_response_alg: params["authorization_signed_response_alg"],
      actor: %{type: :operator, id: "admin-ui"}
    }
  end

  defp save_client_attrs(%{"mode" => "logout_propagation"} = params, _client) do
    logout_propagation_attrs(params) |> Map.put(:actor, %{type: :operator, id: "admin-ui"})
  end
end
