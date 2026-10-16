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
       page_title: "Default security settings",
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
         |> put_flash(:info, "Default security settings saved")}

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
      <AdminComponents.alert :if={is_nil(@policy)} variant={:danger} title="Could not load security settings">
        <p>Lockspire could not confirm the saved default. Reload this page before changing it.</p>
        <AdminComponents.action_bar>
          <AdminComponents.admin_button type="button" variant={:secondary} phx-click="reload_policy">
            Reload settings
          </AdminComponents.admin_button>
        </AdminComponents.action_bar>
      </AdminComponents.alert>

      <div :if={@policy}>
      <AdminComponents.policy_nav current={:security_profile} />

      <AdminComponents.section_card
        title="Default for apps"
      >
        <form class="lockspire-admin-form-stack" phx-submit="save_policy">
          <AdminComponents.radio_group id="security_profile" name="policy[security_profile]"
            label="Security requirements" value={@policy.security_profile} errors={@form_errors}
            help="Apps may have their own setting.">
            <:option value="none" label="Standard OAuth and OpenID Connect" />
            <:option value="fapi_2_0_security" label="FAPI 2.0 Security Profile" />
            <:option value="fapi_2_0_message_signing" label="FAPI 2.0 Message Signing" />
            <details class="lockspire-admin-help-disclosure">
              <summary>Compare security requirements</summary>
              <div>
                <p><strong>Standard OAuth and OpenID Connect:</strong> Lockspire's default protections, including S256 PKCE and exact sign-in return URL matching, without the extra FAPI 2.0 requirements.</p>
                <p><strong>FAPI 2.0 Security Profile:</strong> Requires PAR, key-bound access tokens (DPoP), and S256 PKCE. Requests that miss a requirement are rejected.</p>
                <p><strong>FAPI 2.0 Message Signing:</strong> Includes those requirements and signed authorization and introspection responses.</p>
              </div>
            </details>
          </AdminComponents.radio_group>

          <AdminComponents.action_bar>
            <AdminComponents.admin_button type="submit" variant={:primary}>
              Save security settings
            </AdminComponents.admin_button>
          </AdminComponents.action_bar>
        </form>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="Signing key check"
        subtitle="Checks Lockspire's signing key only; it does not test how apps handle these requirements."
      >
        <p>
          <strong>Status:</strong> {strict_readiness_status(@policy.security_profile, @strict_readiness)}
        </p>
        <p>
          <strong>What we checked:</strong> {strict_readiness_summary(@policy.security_profile, @strict_readiness)}
        </p>

        <ul :if={@strict_readiness.remediation != []} class="lockspire-admin-errors">
          <%= for item <- @strict_readiness.remediation do %>
            <li>{item}</li>
          <% end %>
        </ul>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="App settings"
      >
        <div :if={@summary} class="lockspire-admin-summary-grid">
          <div class="lockspire-admin-summary-stat">
            <span class="lockspire-admin-summary-value">{@summary.inherit}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.inherit == 1, do: "app uses provider default", else: "apps use provider default"}
            </span>
          </div>
          <div class="lockspire-admin-summary-stat">
            <span class="lockspire-admin-summary-value">{@summary.fapi_2_0_message_signing}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.fapi_2_0_message_signing == 1,
                do: "app requires signed responses",
                else: "apps require signed responses"}
            </span>
          </div>
          <div class="lockspire-admin-summary-stat">
            <span class="lockspire-admin-summary-value">{@summary.fapi_2_0_security}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.fapi_2_0_security == 1, do: "app requires FAPI 2.0", else: "apps require FAPI 2.0"}
            </span>
          </div>
          <div class="lockspire-admin-summary-stat">
            <span class="lockspire-admin-summary-value">{@summary.none}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.none == 1, do: "app uses standard OIDC", else: "apps use standard OIDC"}
            </span>
          </div>
        </div>

        <p
          :if={not is_nil(@summary) and @summary.fapi_2_0_message_signing == 0 and @summary.fapi_2_0_security == 0 and @summary.none == 0}
          class="lockspire-admin-empty-notice"
        >
          All apps use the provider default.
        </p>
        <p :if={is_nil(@summary)} class="lockspire-admin-empty-notice">
          App settings are unavailable.
        </p>
      </AdminComponents.section_card>
      </div>
    </AdminLayoutLive.shell>
    """
  end

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
              "Choose Standard OAuth and OpenID Connect, FAPI 2.0 Security Profile, or FAPI 2.0 Message Signing."
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
        "Security settings could not be confirmed. Reload this page to check the saved value."
    }
  end

  defp key_prerequisite_error(:missing_compliant_active_key, profile) do
    %{
      field: "Active profile",
      message:
        "Activate an ES256 or PS256 Lockspire signing key before choosing #{security_profile_label(profile)}."
    }
  end

  defp key_prerequisite_error(:missing_compliant_publishable_key, profile) do
    %{
      field: "Active profile",
      message:
        "Publish an ES256 or PS256 Lockspire signing key before choosing #{security_profile_label(profile)}."
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
            remediation: ["Could not check the signing key. Reload this page to try again."]
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

  defp strict_readiness_status(:fapi_2_0_message_signing, %{ready?: true}), do: "Ready"

  defp strict_readiness_status(:fapi_2_0_message_signing, _readiness),
    do: "Needs signing key"

  defp strict_readiness_status(_profile, %{ready?: true}), do: "Signing key ready"
  defp strict_readiness_status(_profile, _readiness), do: "Signing key not ready"

  defp strict_readiness_summary(_profile, %{status: :unavailable}) do
    "The signing-key check could not be completed. Its result is unknown."
  end

  defp strict_readiness_summary(:fapi_2_0_message_signing, %{ready?: true}) do
    "An active, published signing key is ready. The profile also requires signed authorization and introspection responses."
  end

  defp strict_readiness_summary(:fapi_2_0_message_signing, _readiness) do
    "This profile is selected, but the required signing key is missing."
  end

  defp strict_readiness_summary(_profile, %{ready?: true}) do
    "An ES256 or PS256 Lockspire signing key is active and published. This check covers the key only."
  end

  defp strict_readiness_summary(_profile, _readiness) do
    "Activate and publish an ES256 or PS256 Lockspire signing key before choosing this profile."
  end
end
