defmodule Lockspire.Web.Live.Admin.PoliciesLive.SecurityProfile do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.MessageSigningProfile
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Security profile",
       current_section: :policies,
       policy: nil,
       summary: %{inherit: 0, fapi_2_0_message_signing: 0, fapi_2_0_security: 0, none: 0},
       strict_readiness: default_readiness(),
       form_errors: []
     )
     |> load_policy()
     |> load_strict_readiness()
     |> load_summary()}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("reload_policy", _params, socket) do
    {:noreply, socket |> load_policy() |> load_strict_readiness() |> load_summary()}
  end

  @impl true
  def handle_event(
        "save_policy",
        %{"policy" => %{"security_profile" => profile}},
        %{assigns: %{policy: %ServerPolicy{}}} = socket
      ) do
    case Admin.put_security_profile(profile) do
      {:ok, %ServerPolicy{} = policy} ->
        {:noreply,
         socket
         |> assign(policy: policy, form_errors: [])
         |> load_strict_readiness()
         |> put_flash(:info, "Global security profile saved")}

      {:error, errors} when is_list(errors) ->
        {:noreply, assign(socket, form_errors: policy_errors(errors))}

      {:error, _reason} ->
        {:noreply,
         assign(socket,
           form_errors: [save_uncertain_error()]
         )}
    end
  end

  def handle_event("save_policy", _params, socket) do
    {:noreply,
     assign(socket,
       form_errors: [save_uncertain_error()]
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.alert :if={is_nil(@policy)} variant={:danger} title="Could not load global security profile">
        <p>The issuer security profile could not be loaded, so its current value is unknown. Settings and save controls stay hidden until the stored profile can be confirmed.</p>
        <AdminComponents.action_bar>
          <AdminComponents.admin_button type="button" variant={:secondary} phx-click="reload_policy">
            Reload policy
          </AdminComponents.admin_button>
        </AdminComponents.action_bar>
      </AdminComponents.alert>

      <div :if={@policy}>
      <AdminComponents.page_hero
        eyebrow="Configure"
        title="Global security profile"
        body="Choose the issuer security profile for clients that inherit policy. The check below reports signing-key prerequisites for FAPI 2.0 Message Signing; it does not confirm external verifier readiness. Client-specific choices remain separate."
      >
        <:summary>
          <AdminComponents.decision_summary>
            <:item
              :for={
                item <-
                  security_profile_decision_summary_items(%{
                    policy: @policy,
                    summary: @summary,
                    strict_readiness: @strict_readiness
                  })
              }
              label={item.label}
              value={item.value}
              tone={item.tone}
              detail={item.detail}
            >
            </:item>
          </AdminComponents.decision_summary>
        </:summary>
      </AdminComponents.page_hero>

      <AdminComponents.policy_nav />

      <AdminComponents.section_card
        title="Global security profile"
        subtitle={"Current profile is #{security_profile_label(@policy.security_profile)}. #{policy_scope_copy(:security_profile)}"}
      >
        <AdminComponents.error_list :if={@form_errors != []} errors={@form_errors} />

        <form class="lockspire-admin-form-stack" phx-submit="save_policy">
          <div class="lockspire-admin-field">
            <label for="security_profile">Active profile</label>
            <select id="security_profile" name="policy[security_profile]">
              <option value="none" selected={@policy.security_profile == :none}>None (Standard OIDC)</option>
              <option value="fapi_2_0_security" selected={@policy.security_profile == :fapi_2_0_security}>FAPI 2.0 Security Profile</option>
              <option value="fapi_2_0_message_signing" selected={@policy.security_profile == :fapi_2_0_message_signing}>
                FAPI 2.0 Message Signing
              </option>
            </select>
            <p class="lockspire-admin-help">
              <strong>None (Standard OIDC):</strong> Baseline OAuth 2.0 and OIDC behavior.
              <br />
              <strong>FAPI 2.0 Security Profile:</strong> Requires PAR, DPoP-bound access tokens, and S256 PKCE. Requests that do not meet these requirements are rejected.
              <br />
              <strong>FAPI 2.0 Message Signing:</strong> Includes the FAPI 2.0 Security Profile requirements. It also requires JARM on `/authorize` and a JWT introspection response selected with `Accept: application/token-introspection+jwt` on `/introspect`.
            </p>
          </div>

          <AdminComponents.action_bar>
            <AdminComponents.admin_button type="submit" variant={:primary}>
              Save global security profile
            </AdminComponents.admin_button>
          </AdminComponents.action_bar>
        </form>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="Strict readiness"
        subtitle="Signing-key prerequisites for FAPI 2.0 Message Signing."
      >
        <p>
          <strong>Status:</strong> {strict_readiness_status(@policy.security_profile, @strict_readiness)}
        </p>
        <p>
          <strong>Readiness details:</strong> {strict_readiness_summary(@policy.security_profile, @strict_readiness)}
        </p>

        <ul :if={@strict_readiness.remediation != []} class="lockspire-admin-errors">
          <%= for item <- @strict_readiness.remediation do %>
            <li>{item}</li>
          <% end %>
        </ul>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="Client override summary"
        subtitle="Exceptions to the global security profile across all registered clients."
      >
        <div :if={@summary} class="lockspire-admin-summary-grid">
          <div class="lockspire-admin-summary-stat">
            <span class="lockspire-admin-summary-value">{@summary.inherit}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.inherit == 1, do: "client inherits", else: "clients inherit"}
            </span>
          </div>
          <div class="lockspire-admin-summary-stat">
            <span class="lockspire-admin-summary-value">{@summary.fapi_2_0_message_signing}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.fapi_2_0_message_signing == 1,
                do: "client requires strict message signing",
                else: "clients require strict message signing"}
            </span>
          </div>
          <div class="lockspire-admin-summary-stat">
            <span class="lockspire-admin-summary-value">{@summary.fapi_2_0_security}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.fapi_2_0_security == 1, do: "client requires FAPI 2.0", else: "clients require FAPI 2.0"}
            </span>
          </div>
          <div class="lockspire-admin-summary-stat">
            <span class="lockspire-admin-summary-value">{@summary.none}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.none == 1, do: "client forces None", else: "clients force None"}
            </span>
          </div>
        </div>

        <p
          :if={@summary && @summary.fapi_2_0_message_signing == 0 and @summary.fapi_2_0_security == 0 and @summary.none == 0}
          class="lockspire-admin-empty-notice"
        >
          No client security profile overrides yet. All clients currently inherit the global security profile.
        </p>
        <p :if={is_nil(@summary)} class="lockspire-admin-empty-notice">
          Client override counts are unavailable. Reload this page to try again.
        </p>
      </AdminComponents.section_card>
      </div>
    </AdminLayoutLive.shell>
    """
  end

  defp security_profile_label(:none), do: "None (Standard OIDC)"
  defp security_profile_label(:fapi_2_0_security), do: "FAPI 2.0 Security Profile"
  defp security_profile_label(:fapi_2_0_message_signing), do: "FAPI 2.0 Message Signing"

  defp policy_errors(errors) do
    case Enum.find(errors, fn
           %{reason: reason}
           when reason in [
                  :invalid_security_profile,
                  :missing_compliant_active_key,
                  :missing_compliant_publishable_key
                ] ->
             true

           _error ->
             false
         end) do
      %{reason: :invalid_security_profile} ->
        [
          %{
            field: "Active profile",
            message:
              "Choose None (Standard OIDC), FAPI 2.0 Security Profile, or FAPI 2.0 Message Signing."
          }
        ]

      %{reason: reason, detail: profile}
      when reason in [:missing_compliant_active_key, :missing_compliant_publishable_key] and
             profile in [:fapi_2_0_security, :fapi_2_0_message_signing] ->
        [key_prerequisite_error(reason, profile)]

      _error ->
        [save_uncertain_error()]
    end
  end

  defp save_uncertain_error do
    %{
      field: "Active profile",
      message:
        "The security profile change could not be confirmed. Reload the policy to check its current value."
    }
  end

  defp key_prerequisite_error(:missing_compliant_active_key, profile) do
    %{
      field: "Active profile",
      message:
        "Activate an ES256 or PS256 issuer signing key before enabling #{security_profile_label(profile)}."
    }
  end

  defp key_prerequisite_error(:missing_compliant_publishable_key, profile) do
    %{
      field: "Active profile",
      message:
        "Publish an ES256 or PS256 issuer signing key before enabling #{security_profile_label(profile)}."
    }
  end

  defp load_policy(socket) do
    case Admin.get_server_policy() do
      {:ok, %ServerPolicy{} = policy} -> assign(socket, policy: policy)
      _result -> assign(socket, policy: nil)
    end
  end

  defp load_summary(socket) do
    case Admin.list_clients() do
      {:ok, clients} ->
        summary =
          Enum.reduce(
            clients,
            %{inherit: 0, fapi_2_0_message_signing: 0, fapi_2_0_security: 0, none: 0},
            fn %Client{security_profile: mode}, acc ->
              Map.update!(acc, mode, &(&1 + 1))
            end
          )

        assign(socket, summary: summary)

      _result ->
        assign(socket, summary: nil)
    end
  end

  defp load_strict_readiness(socket) do
    assign(socket, strict_readiness: strict_readiness())
  end

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

  defp strict_readiness_status(_profile, %{status: :unavailable}), do: "Unavailable"

  defp strict_readiness_status(:fapi_2_0_message_signing, %{ready?: true}),
    do: "Active; key prerequisites met"

  defp strict_readiness_status(:fapi_2_0_message_signing, _readiness),
    do: "Selected; key prerequisites missing"

  defp strict_readiness_status(_profile, %{ready?: true}), do: "Key prerequisites met"
  defp strict_readiness_status(_profile, _readiness), do: "Key prerequisites missing"

  defp strict_readiness_summary(_profile, %{status: :unavailable}) do
    "The signing-key check could not be completed. Readiness is unknown."
  end

  defp strict_readiness_summary(:fapi_2_0_message_signing, %{ready?: true}) do
    "FAPI 2.0 Message Signing is active. `/authorize` requires JARM, and `/introspect` requires `Accept: application/token-introspection+jwt`."
  end

  defp strict_readiness_summary(:fapi_2_0_message_signing, _readiness) do
    "FAPI 2.0 Message Signing is selected, but the signing-key prerequisite shown below is missing."
  end

  defp strict_readiness_summary(_profile, %{ready?: true}) do
    "An ES256 or PS256 issuer signing key is active and publishable. This check covers signing-key prerequisites only."
  end

  defp strict_readiness_summary(_profile, _readiness) do
    "The key check below identifies what is missing before FAPI 2.0 Message Signing can be enabled."
  end

  defp security_profile_decision_summary_items(%{
         policy: %ServerPolicy{} = policy,
         summary: summary,
         strict_readiness: readiness
       }) do
    [
      %{
        label: "Global security profile",
        value: security_profile_label(policy.security_profile),
        tone: security_profile_tone(policy.security_profile),
        detail:
          "This is the global issuer security profile default for clients that inherit security policy."
      },
      %{
        label: "Strict readiness",
        value: strict_readiness_status(policy.security_profile, readiness),
        tone: strict_readiness_tone(policy.security_profile, readiness),
        detail: "Checks only whether a compliant issuer signing key is active and publishable."
      },
      %{
        label: "Clients that inherit",
        value: inherited_clients_value(summary),
        tone: :info,
        detail:
          "These clients use the global issuer security profile default; client overrides stay on client policy routes."
      },
      %{
        label: "Next safe action",
        value: "Save global security profile",
        tone: :info,
        detail: policy_scope_copy(:security_profile)
      }
    ]
  end

  defp security_profile_tone(:none), do: :neutral
  defp security_profile_tone(:fapi_2_0_security), do: :warning
  defp security_profile_tone(:fapi_2_0_message_signing), do: :warning
  defp security_profile_tone(_profile), do: :info

  defp strict_readiness_tone(_profile, %{status: :unavailable}), do: :warning
  defp strict_readiness_tone(:fapi_2_0_message_signing, %{ready?: true}), do: :success
  defp strict_readiness_tone(:fapi_2_0_message_signing, _readiness), do: :danger
  defp strict_readiness_tone(_profile, %{ready?: true}), do: :success
  defp strict_readiness_tone(_profile, _readiness), do: :warning

  defp inherited_clients_value(%{inherit: 1}), do: "1 client"
  defp inherited_clients_value(%{inherit: count}), do: "#{count} clients"
  defp inherited_clients_value(_summary), do: "Unavailable"

  defp policy_scope_copy(:security_profile) do
    "The issuer uses this profile for clients without a security-profile choice of their own. A client-specific choice takes precedence on that client's policy route."
  end
end
