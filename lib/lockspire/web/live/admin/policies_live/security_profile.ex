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
  def handle_event("save_policy", %{"policy" => %{"security_profile" => profile}}, socket) do
    case Admin.put_security_profile(profile) do
      {:ok, %ServerPolicy{} = policy} ->
        {:noreply,
         socket
         |> assign(policy: policy, form_errors: [])
         |> load_strict_readiness()
         |> put_flash(:info, "Global security profile updated")}

      {:error, errors} when is_list(errors) ->
        {:noreply, assign(socket, form_errors: errors)}

      {:error, _reason} ->
        {:noreply,
         assign(socket,
           form_errors: [%{field: :security_profile, reason: :request_failed, detail: nil}]
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.page_hero
        eyebrow="Configure"
        title="Global security profile"
        body="Review the issuer security profile default, strict readiness, inherited-client impact, and the next safe policy save before changing enforcement."
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
              <strong>None (Standard OIDC):</strong> Baseline OIDC/OAuth 2.0 security.
              <br />
              <strong>FAPI 2.0 Security Profile:</strong> Strict enforcement of FAPI 2.0 requirements (mandatory PAR, DPoP, S256 PKCE). Rejects non-compliant requests.
              <br />
              <strong>FAPI 2.0 Message Signing:</strong> Everything in the FAPI 2.0 Security Profile, plus explicit JARM on `/authorize` and JWT-only introspection negotiation on `/introspect`.
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
        subtitle="Strict message-signing readiness for the stricter JARM and JWT introspection tier."
      >
        <p>
          <strong>Status:</strong> {strict_readiness_status(@policy.security_profile, @strict_readiness)}
        </p>
        <p>
          <strong>Operator truth:</strong> {strict_readiness_summary(@policy.security_profile, @strict_readiness)}
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
        <div class="lockspire-admin-summary-grid">
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
          :if={@summary.fapi_2_0_message_signing == 0 and @summary.fapi_2_0_security == 0 and @summary.none == 0}
          class="lockspire-admin-empty-notice"
        >
          No client security profile overrides yet. All clients currently inherit the global security profile.
        </p>
      </AdminComponents.section_card>
    </AdminLayoutLive.shell>
    """
  end

  defp security_profile_label(:none), do: "None (Standard OIDC)"
  defp security_profile_label(:fapi_2_0_security), do: "FAPI 2.0 Security Profile"
  defp security_profile_label(:fapi_2_0_message_signing), do: "FAPI 2.0 Message Signing"

  defp load_policy(socket) do
    case Admin.get_server_policy() do
      {:ok, %ServerPolicy{} = policy} -> assign(socket, policy: policy)
      {:error, _reason} -> assign(socket, policy: %ServerPolicy{security_profile: :none})
    end
  end

  defp load_summary(socket) do
    {:ok, clients} = Admin.list_clients()

    summary =
      Enum.reduce(
        clients,
        %{inherit: 0, fapi_2_0_message_signing: 0, fapi_2_0_security: 0, none: 0},
        fn %Client{
             security_profile: mode
           },
           acc ->
          Map.update!(acc, mode, &(&1 + 1))
        end
      )

    assign(socket, summary: summary)
  end

  defp load_strict_readiness(socket) do
    assign(socket, strict_readiness: strict_readiness())
  end

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

  defp strict_readiness_status(:fapi_2_0_message_signing, %{ready?: true}), do: "Ready"
  defp strict_readiness_status(:fapi_2_0_message_signing, _readiness), do: "Blocked"
  defp strict_readiness_status(_profile, %{ready?: true}), do: "Ready if enabled"
  defp strict_readiness_status(_profile, _readiness), do: "Not ready yet"

  defp strict_readiness_summary(:fapi_2_0_message_signing, %{ready?: true}) do
    "Strict message signing is active. `/authorize` requires explicit JARM and `/introspect` requires JWT negotiation."
  end

  defp strict_readiness_summary(:fapi_2_0_message_signing, _readiness) do
    "Strict message signing is selected, but issuer prerequisites are still missing."
  end

  defp strict_readiness_summary(_profile, %{ready?: true}) do
    "Issuer prerequisites are already in place. Operators can enable the stricter profile without extra key work."
  end

  defp strict_readiness_summary(_profile, _readiness) do
    "Issuer prerequisites are not complete yet. Fix the items below before enabling the stricter profile."
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
        detail: "Shows issuer signing-key readiness for the FAPI 2.0 Message Signing profile."
      },
      %{
        label: "Clients that inherit",
        value: inherited_clients_value(summary.inherit),
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

  defp strict_readiness_tone(:fapi_2_0_message_signing, %{ready?: true}), do: :success
  defp strict_readiness_tone(:fapi_2_0_message_signing, _readiness), do: :danger
  defp strict_readiness_tone(_profile, %{ready?: true}), do: :success
  defp strict_readiness_tone(_profile, _readiness), do: :warning

  defp inherited_clients_value(1), do: "1 client"
  defp inherited_clients_value(count), do: "#{count} clients"

  defp policy_scope_copy(:security_profile) do
    "This save changes the global issuer security profile default for future requests from inheriting clients. Existing client overrides stay on their client policy routes."
  end
end
