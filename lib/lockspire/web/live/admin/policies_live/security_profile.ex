defmodule Lockspire.Web.Live.Admin.PoliciesLive.SecurityProfile do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
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
       summary: %{inherit: 0, fapi_2_0_security: 0, none: 0},
       form_errors: []
     )
     |> load_policy()
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
      <AdminComponents.policy_nav />

      <AdminComponents.section_card
        title="Global security profile"
        subtitle={"Current profile is #{security_profile_label(@policy.security_profile)}. This governs all clients that inherit their profile."}
      >
        <AdminComponents.error_list :if={@form_errors != []} errors={@form_errors} />

        <form phx-submit="save_policy">
          <div class="lockspire-admin-field">
            <label for="security_profile">Active profile</label>
            <select id="security_profile" name="policy[security_profile]">
              <option value="none" selected={@policy.security_profile == :none}>None (Standard OIDC)</option>
              <option value="fapi_2_0_security" selected={@policy.security_profile == :fapi_2_0_security}>FAPI 2.0 Security Profile</option>
            </select>
            <p class="lockspire-admin-help">
              <strong>None (Standard OIDC):</strong> Baseline OIDC/OAuth 2.0 security.
              <br />
              <strong>FAPI 2.0 Security Profile:</strong> Strict enforcement of FAPI 2.0 requirements (mandatory PAR, DPoP, S256 PKCE). Rejects non-compliant requests.
            </p>
          </div>

          <button class="lockspire-admin-btn-primary" type="submit">Save global security profile</button>
        </form>
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

        <p :if={@summary.fapi_2_0_security == 0 and @summary.none == 0} class="lockspire-admin-empty-notice">
          No client security profile overrides yet. All clients currently inherit the global security profile.
        </p>
      </AdminComponents.section_card>
    </AdminLayoutLive.shell>
    """
  end

  defp security_profile_label(:none), do: "None (Standard OIDC)"
  defp security_profile_label(:fapi_2_0_security), do: "FAPI 2.0 Security Profile"

  defp load_policy(socket) do
    case Admin.get_server_policy() do
      {:ok, %ServerPolicy{} = policy} -> assign(socket, policy: policy)
      {:error, _reason} -> assign(socket, policy: %ServerPolicy{security_profile: :none})
    end
  end

  defp load_summary(socket) do
    {:ok, clients} = Admin.list_clients()

    summary =
      Enum.reduce(clients, %{inherit: 0, fapi_2_0_security: 0, none: 0}, fn %Client{
                                                                              security_profile:
                                                                                mode
                                                                            },
                                                                            acc ->
        Map.update!(acc, mode, &(&1 + 1))
      end)

    assign(socket, summary: summary)
  end
end
