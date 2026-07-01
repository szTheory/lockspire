defmodule Lockspire.Web.Live.Admin.PoliciesLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Security",
       current_section: :policies,
       policy: load_policy(),
       summary: load_summary()
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, policy: load_policy(), summary: load_summary())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.policy_nav />

      <AdminComponents.page_hero
        eyebrow="Configure"
        title="Policy posture"
        body="Choose the issuer-level policy route that owns the setting you need to review. Each policy remains its own explicit operator action surface."
      />

      <div class="lockspire-admin-dashboard-grid">
        <.policy_card
          route={:par}
          title="PAR"
          value={@policy.par_policy}
          detail={"#{@summary.par.required} clients require PAR; #{@summary.par.optional} mark it optional."}
          href={admin_path("/policies/par")}
        />
        <.policy_card
          route={:security_profile}
          title="Security profile"
          value={@policy.security_profile}
          detail={"#{@summary.security.fapi} clients require FAPI; #{@summary.security.message_signing} require message signing."}
          href={admin_path("/policies/security-profile")}
        />
        <.policy_card
          route={:dpop}
          title="DPoP"
          value={@policy.dpop_policy}
          detail={"#{@summary.dpop.dpop} clients require DPoP; #{@summary.dpop.bearer} force bearer."}
          href={admin_path("/policies/dpop")}
        />
        <.policy_card
          route={:dcr}
          title="Dynamic Client Registration"
          value={@policy.registration_policy}
          detail={"#{@summary.dcr.self_registered} self-registered clients and #{@summary.dcr.active_iats} active IATs."}
          href={admin_path("/policies/dcr")}
        />
      </div>
    </AdminLayoutLive.shell>
    """
  end

  attr(:title, :string, required: true)
  attr(:value, :any, required: true)
  attr(:detail, :string, required: true)
  attr(:href, :string, required: true)
  attr(:route, :atom, required: true)

  defp policy_card(assigns) do
    ~H"""
    <AdminComponents.section_card title={@title} subtitle={@detail}>
      <p class="lockspire-admin-kicker">Current setting</p>
      <p class="lockspire-admin-display-value">{@value}</p>
      <p class="lockspire-admin-help">{policy_review_detail(@route)}</p>
      <AdminComponents.action_bar>
        <AdminComponents.admin_button href={@href}>{policy_review_label(@route)}</AdminComponents.admin_button>
      </AdminComponents.action_bar>
    </AdminComponents.section_card>
    """
  end

  defp load_policy do
    case Admin.get_server_policy() do
      {:ok, %ServerPolicy{} = policy} -> policy
      _result -> %ServerPolicy{}
    end
  end

  defp load_summary do
    clients = ok_list(Admin.list_clients())
    iats = ok_list(Lockspire.Admin.InitialAccessTokens.list_iats())

    %{
      par: %{
        required: Enum.count(clients, &(&1.par_policy == :required)),
        optional: Enum.count(clients, &(&1.par_policy == :optional))
      },
      security: %{
        fapi: Enum.count(clients, &(&1.security_profile == :fapi_2_0_security)),
        message_signing: Enum.count(clients, &(&1.security_profile == :fapi_2_0_message_signing))
      },
      dpop: %{
        dpop: Enum.count(clients, &(&1.dpop_policy == :dpop)),
        bearer: Enum.count(clients, &(&1.dpop_policy == :bearer))
      },
      dcr: %{
        self_registered: Enum.count(clients, &(&1.provenance == :self_registered)),
        active_iats: Enum.count(iats, &(iat_status(&1) == :active))
      }
    }
  end

  defp ok_list({:ok, list}) when is_list(list), do: list
  defp ok_list(_result), do: []

  defp iat_status(token) do
    cond do
      token.revoked_at != nil ->
        :revoked

      token.used_at != nil ->
        :used

      token.expires_at != nil and DateTime.compare(token.expires_at, DateTime.utc_now()) == :lt ->
        :expired

      true ->
        :active
    end
  end

  defp policy_review_label(:par), do: "Review PAR policy"
  defp policy_review_label(:security_profile), do: "Review security profile"
  defp policy_review_label(:dpop), do: "Review DPoP policy"
  defp policy_review_label(:dcr), do: "Review DCR policy"

  defp policy_review_detail(:par),
    do: "Review issuer PAR defaults and client override pressure."

  defp policy_review_detail(:security_profile),
    do: "Review inherited security profile posture and strict readiness."

  defp policy_review_detail(:dpop),
    do: "Review sender-constrained token defaults and client exceptions."

  defp policy_review_detail(:dcr),
    do: "Review future registration gates, metadata allowlists, and DCR lifetimes."

  defp admin_path(path), do: Lockspire.mount_path() <> "/admin" <> path
end
