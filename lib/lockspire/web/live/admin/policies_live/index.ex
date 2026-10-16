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
       page_title: "Security settings",
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
      <AdminComponents.policy_nav current={:index} />
      <AdminComponents.page_hero body="Defaults apply when an app has no separate setting. Stronger security requirements can add restrictions." />

      <div class="lockspire-admin-policy-list">
        <.policy_card
          title="Authorization requests"
          value={policy_value(@policy, :par_policy)}
          detail={summary_detail(@summary.par, :par)}
          href={admin_path("/policies/par")}
        />
        <.policy_card
          title="Default security settings"
          value={policy_value(@policy, :security_profile)}
          detail={summary_detail(@summary.security, :security)}
          href={admin_path("/policies/security-profile")}
        />
        <.policy_card
          title="Token proof"
          value={policy_value(@policy, :dpop_policy)}
          detail={summary_detail(@summary.dpop, :dpop)}
          href={admin_path("/policies/dpop")}
        />
        <.policy_card
          title="App self-registration"
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

  defp policy_card(assigns) do
    ~H"""
    <section class="lockspire-admin-policy-list__row">
      <div class="lockspire-admin-policy-list__main">
        <h2><a href={@href}>{@title}</a></h2>
        <p>{@detail}</p>
      </div>
      <dl class="lockspire-admin-policy-list__default">
        <dt>Default for apps</dt>
        <dd>{@value}</dd>
      </dl>
    </section>
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

  defp policy_value(%ServerPolicy{} = policy, field),
    do: policy_value_label(field, Map.fetch!(policy, field))

  defp policy_value(nil, _field), do: "Unavailable"

  defp policy_value_label(:par_policy, :optional), do: "Optional PAR"
  defp policy_value_label(:par_policy, :required), do: "PAR required"
  defp policy_value_label(:security_profile, :none), do: "Standard OAuth and OpenID Connect"
  defp policy_value_label(:security_profile, :fapi_2_0_security), do: "FAPI 2.0 Security Profile"

  defp policy_value_label(:security_profile, :fapi_2_0_message_signing),
    do: "FAPI 2.0 Message Signing"

  defp policy_value_label(:dpop_policy, :bearer), do: "Bearer tokens"
  defp policy_value_label(:dpop_policy, :dpop), do: "Key-bound tokens required (DPoP)"
  defp policy_value_label(:registration_policy, :disabled), do: "Self-registration off"

  defp policy_value_label(:registration_policy, :initial_access_token),
    do: "App setup token required"

  defp policy_value_label(:registration_policy, :open), do: "Open registration"

  defp summary_detail(%{required: required, optional: optional}, :par)
       when is_integer(required) and is_integer(optional),
       do:
         "With PAR, an app sends its sign-in request details to Lockspire directly before redirecting the browser. #{counted(required, "app", "apps")} #{verb(required, "requires", "require")} PAR; #{counted(optional, "app", "apps")} #{verb(optional, "chooses", "choose")} it."

  defp summary_detail(%{fapi: fapi, message_signing: signing}, :security)
       when is_integer(fapi) and is_integer(signing),
       do:
         "#{counted(fapi, "app", "apps")} #{verb(fapi, "chooses", "choose")} stronger security checks; #{counted(signing, "app", "apps")} #{verb(signing, "requires", "require")} signed responses."

  defp summary_detail(%{dpop: dpop, bearer: bearer}, :dpop)
       when is_integer(dpop) and is_integer(bearer),
       do:
         "#{counted(dpop, "app", "apps")} #{verb(dpop, "chooses", "choose")} key-bound tokens; #{counted(bearer, "app", "apps")} #{verb(bearer, "chooses", "choose")} bearer tokens."

  defp summary_detail(%{self_registered: registered, active_iats: iats}, :dcr) do
    case {registered, iats} do
      {registered, iats} when is_integer(registered) and is_integer(iats) ->
        "#{counted(registered, "app", "apps")} #{verb(registered, "registered itself", "registered themselves")} through the API; #{counted(iats, "active setup token", "active setup tokens")} #{verb(iats, "is", "are")} stored."

      {nil, iats} when is_integer(iats) ->
        "The app registration count is unavailable; #{counted(iats, "active setup token", "active setup tokens")} #{verb(iats, "is", "are")} stored."

      {registered, nil} when is_integer(registered) ->
        "#{counted(registered, "app", "apps")} #{verb(registered, "registered itself", "registered themselves")} through the API; active setup-token count unavailable."

      {nil, nil} ->
        "App registration and setup-token counts could not be loaded."
    end
  end

  defp summary_detail(_summary, _route), do: "App settings could not be loaded."

  defp counted(1, singular, _plural), do: "1 #{singular}"
  defp counted(count, _singular, plural), do: "#{count} #{plural}"

  defp verb(1, singular, _plural), do: singular
  defp verb(_count, _singular, plural), do: plural

  defp iat_status(token) do
    InitialAccessTokens.lifecycle_status(token)
  end

  defp admin_path(path), do: Lockspire.mount_path() <> "/admin" <> path
end
