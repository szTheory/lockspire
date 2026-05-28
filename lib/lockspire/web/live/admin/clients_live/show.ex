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
      <AdminComponents.section_card
        title={@client.name || @client.client_id}
        subtitle="Immutable security posture stays fixed. Safe edits are targeted workflows."
      >
        <p>Client ID: <code>{@client.client_id}</code></p>
        <p>Type: <code>{@client.client_type}</code></p>
        <p>Token auth: <code>{@client.token_endpoint_auth_method}</code></p>
        <p>PKCE required: <code>{to_string(@client.pkce_required)}</code></p>
        <p>Global security profile: <code>{security_profile_label(@effective_security_profile.global_profile)}</code></p>
        <p>Client security override: <code>{security_profile_label(@client.security_profile)}</code></p>
        <p>Effective security profile: <strong>{security_verdict_for(@effective_security_profile)}</strong></p>
        <section :if={show_strict_message_signing_panel?(@effective_security_profile)} class="lockspire-admin-help">
          <h3>Strict message-signing posture</h3>
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
        </section>
        <div
          :if={mixed_mode_override?(@effective_security_profile)}
          class="lockspire-admin-warning"
          role="alert"
        >
          <strong>Warning:</strong> This client overrides the global FAPI 2.0 Security Profile
          to None. FAPI 2.0 boundary checks (PAR, DPoP) will NOT be enforced for this client.
          This is an intentional mixed-mode bypass. Confirm the client genuinely needs standard
          OIDC.
        </div>
        <p>Global PAR policy: <code>{par_policy_label(@effective_par_policy.global_policy)}</code></p>
        <p>Client PAR override: <code>{par_policy_label(@client.par_policy)}</code></p>
        <p>Effective PAR requirement: <strong>{verdict_for(@effective_par_policy)}</strong></p>
        <p>Global access token format: <code>{@global_access_token_format}</code></p>
        <p>Client access token override: <code>{access_token_format_override_label(@client.access_token_format)}</code></p>
        <p>Effective access token format: <strong>{@effective_access_token_format}</strong></p>
        <p>Current secret: redacted</p>
        <p>Last secret rotation: {format_datetime(@client.last_secret_rotated_at)}</p>
        <AdminComponents.status_badge status={status_for(@client)} />

        <section :if={client_secret_jwt_client?(@client)}>
          <h3>Shared JWT client secret posture</h3>
          <p>
            Stored auth method: <code>client_secret_jwt</code>
          </p>
          <p>
            Stored signing algorithm: <code>{value_or_not_configured(@client.token_endpoint_auth_signing_alg)}</code>
          </p>
          <p>
            This slice is limited to the shared direct-client verifier surfaces. Lockspire
            keeps <code>HS256</code> read-only here and never exposes secret-derived verifier
            material.
          </p>
        </section>

        <section :if={private_key_jwt_client?(@client)}>
          <h3>Client assertion keys</h3>
          <p>
            Remote JWKS URI configured:
            <code>{value_or_not_configured(@client.jwks_uri)}</code>
          </p>
          <p>
            Inline JWKS configured:
            <code>{boolean_label(not is_nil(@client.jwks))}</code>
          </p>
          <p>
            Issuer-supported assertion algorithms:
            <code>{supported_assertion_algorithms(@private_key_jwt_truth)}</code>
          </p>
          <p>
            This client uses <code>private_key_jwt</code>. Key material stays read-only in
            Phase 59; later verification and remote-fetch behavior are owned by Lockspire,
            not by ad hoc admin actions.
          </p>
        </section>

        <section
          :if={show_remote_jwks_summary?(@client, @remote_jwks_summary)}
          class="lockspire-admin-help"
        >
          <h3>Remote JWKS</h3>
          <p>
            <strong>Status:</strong> <code>{@remote_jwks_summary.status}</code>
          </p>
          <p>
            <strong>Summary:</strong> {@remote_jwks_summary.headline}
          </p>
          <p>{@remote_jwks_summary.detail}</p>
          <p>
            <strong>Next step:</strong> {@remote_jwks_summary.next_step}
          </p>
          <p>
            <strong>Ownership:</strong> {@remote_jwks_summary.ownership}
          </p>
          <p :if={@remote_jwks_summary.incident}>
            Incident class:
            <code>{@remote_jwks_summary.incident.class}</code>
          </p>
          <p :if={@remote_jwks_summary.command_hint}>
            Support command:
            <code>{@remote_jwks_summary.command_hint}</code>
          </p>
        </section>

        <h3>Redirect URIs</h3>
        <ul>
          <%= for redirect_uri <- @client.redirect_uris do %>
            <li>{redirect_uri}</li>
          <% end %>
        </ul>

        <h3>Post-logout redirect URIs</h3>
        <ul>
          <%= for uri <- @client.post_logout_redirect_uris do %>
            <li>{uri}</li>
          <% end %>
        </ul>

        <h3>Logout propagation</h3>
        <p>Back-channel logout URI: <code>{value_or_not_configured(@client.backchannel_logout_uri)}</code></p>
        <p>
          Back-channel session required:
          <code>{boolean_label(@client.backchannel_logout_session_required)}</code>
        </p>
        <p>Front-channel logout URI: <code>{value_or_not_configured(@client.frontchannel_logout_uri)}</code></p>
        <p>
          Front-channel session required:
          <code>{boolean_label(@client.frontchannel_logout_session_required)}</code>
        </p>
        <p>These logout propagation URIs stay separate from post-logout redirect URIs.</p>
        <p>
          Back-channel delivery stays durable through the protocol-owned
          <code>/end_session/complete</code> flow.
        </p>
        <p>Front-channel logout remains best effort browser cleanup. It does not prove remote success.</p>

        <h3>Allowed scopes</h3>
        <ul>
          <%= for scope <- @client.allowed_scopes do %>
            <li>{scope}</li>
          <% end %>
        </ul>

        <div class="lockspire-admin-actions">
          <.link patch={show_path(@client.client_id, :edit)}>Edit metadata</.link>
          <.link patch={show_path(@client.client_id, :logout_propagation)}>
            Edit logout propagation
          </.link>
          <.link patch={show_path(@client.client_id, :security_profile)}>Edit security profile</.link>
          <.link patch={show_path(@client.client_id, :par_policy)}>Edit PAR policy</.link>
          <.link patch={show_path(@client.client_id, :redirects)}>Edit redirect URIs</.link>
          <.link patch={show_path(@client.client_id, :logout_uris)}>
            Edit post-logout redirect URIs
          </.link>
          <.link :if={@client.client_type == :confidential} patch={show_path(@client.client_id, :rotate_secret)}>
            Rotate secret
          </.link>
          <button phx-click="toggle_client" type="button">
            {if @client.active, do: "Disable client", else: "Enable client"}
          </button>
        </div>
      </AdminComponents.section_card>

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
          effective_access_token_format: resolve_effective_access_token_format(server_policy, client)
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

  defp access_token_format_string(nil), do: "jwt"
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
