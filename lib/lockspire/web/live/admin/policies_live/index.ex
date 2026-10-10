defmodule Lockspire.Web.Live.Admin.PoliciesLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Admin.InitialAccessTokens
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
        title="Issuer policy settings"
        body="Choose the setting you need to review: PAR, security profile, DPoP, or Dynamic Client Registration. Each page changes its own issuer policy."
      />

      <div class="lockspire-admin-dashboard-grid">
        <.policy_card
          route={:par}
          title="PAR"
          value={policy_value(@policy, :par_policy)}
          detail={summary_detail(@summary.par, :par)}
          href={admin_path("/policies/par")}
        />
        <.policy_card
          route={:security_profile}
          title="Security profile"
          value={policy_value(@policy, :security_profile)}
          detail={summary_detail(@summary.security, :security)}
          href={admin_path("/policies/security-profile")}
        />
        <.policy_card
          route={:dpop}
          title="DPoP"
          value={policy_value(@policy, :dpop_policy)}
          detail={summary_detail(@summary.dpop, :dpop)}
          href={admin_path("/policies/dpop")}
        />
        <.policy_card
          route={:dcr}
          title="Dynamic Client Registration"
          value={policy_value(@policy, :registration_policy)}
          detail={summary_detail(@summary.dcr, :dcr)}
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
      <p class="lockspire-admin-kicker">Current issuer setting</p>
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
      _result -> nil
    end
  end

  defp load_summary do
    clients = read_list(fn -> Admin.list_clients() end)
    iats = read_list(fn -> InitialAccessTokens.list_iats() end)

    %{
      par:
        client_counts(clients, fn clients ->
          %{
            required: Enum.count(clients, &(&1.par_policy == :required)),
            optional: Enum.count(clients, &(&1.par_policy == :optional))
          }
        end),
      security:
        client_counts(clients, fn clients ->
          %{
            fapi: Enum.count(clients, &(&1.security_profile == :fapi_2_0_security)),
            message_signing:
              Enum.count(clients, &(&1.security_profile == :fapi_2_0_message_signing))
          }
        end),
      dpop:
        client_counts(clients, fn clients ->
          %{
            dpop: Enum.count(clients, &(&1.dpop_policy == :dpop)),
            bearer: Enum.count(clients, &(&1.dpop_policy == :bearer))
          }
        end),
      dcr: %{
        self_registered:
          client_counts(clients, fn clients ->
            Enum.count(clients, &(&1.provenance == :self_registered))
          end),
        active_iats: token_counts(iats)
      }
    }
  end

  defp result_list({:ok, list}) when is_list(list), do: list
  defp result_list(_result), do: nil

  defp read_list(read) do
    read.() |> result_list()
  rescue
    _error -> nil
  end

  defp client_counts(clients, counter) when is_function(counter, 1) and is_list(clients),
    do: counter.(clients)

  defp client_counts(_clients, _counter), do: nil

  defp token_counts(tokens) when is_list(tokens),
    do: Enum.count(tokens, &(iat_status(&1) == :active))

  defp token_counts(_tokens), do: nil

  defp policy_value(%ServerPolicy{} = policy, field), do: Map.fetch!(policy, field)
  defp policy_value(nil, _field), do: "Unavailable"

  defp summary_detail(%{required: required, optional: optional}, :par)
       when is_integer(required) and is_integer(optional),
       do: "#{required} clients require PAR; #{optional} mark it optional."

  defp summary_detail(%{fapi: fapi, message_signing: signing}, :security)
       when is_integer(fapi) and is_integer(signing),
       do: "#{fapi} clients require FAPI; #{signing} require message signing."

  defp summary_detail(%{dpop: dpop, bearer: bearer}, :dpop)
       when is_integer(dpop) and is_integer(bearer),
       do: "#{dpop} clients require DPoP; #{bearer} force bearer."

  defp summary_detail(%{self_registered: registered, active_iats: iats}, :dcr) do
    [
      if(is_integer(registered), do: "#{registered} self-registered clients"),
      if(is_integer(iats), do: "#{iats} active Initial Access Tokens")
    ]
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> "Client and Initial Access Token counts are unavailable."
      values -> Enum.join(values, "; ") <> "."
    end
  end

  defp summary_detail(_summary, _route), do: "Client counts are unavailable."

  defp iat_status(token) do
    InitialAccessTokens.lifecycle_status(token)
  end

  defp policy_review_label(:par), do: "Review PAR policy"
  defp policy_review_label(:security_profile), do: "Review security profile"
  defp policy_review_label(:dpop), do: "Review DPoP policy"
  defp policy_review_label(:dcr), do: "Review DCR policy"

  defp policy_review_detail(:par),
    do: "Review issuer PAR defaults and client exceptions."

  defp policy_review_detail(:security_profile),
    do: "Review inherited security profile settings and readiness."

  defp policy_review_detail(:dpop),
    do: "Review the DPoP default and client exceptions."

  defp policy_review_detail(:dcr),
    do: "Review future registration gates, metadata allowlists, and DCR lifetimes."

  defp admin_path(path), do: Lockspire.mount_path() <> "/admin" <> path
end
