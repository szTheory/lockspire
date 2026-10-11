defmodule Lockspire.Web.Live.Admin.PoliciesLive.Dpop do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Admin.ServerPolicy, as: AdminServerPolicy
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "DPoP policy",
       current_section: :policies,
       policy: nil,
       summary: %{inherit: 0, bearer: 0, dpop: 0},
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
  def handle_event("reload_policy", _params, socket) do
    {:noreply, socket |> load_policy() |> load_summary()}
  end

  @impl true
  def handle_event(
        "save_policy",
        %{"policy" => %{"dpop_policy" => mode}},
        %{assigns: %{policy: %ServerPolicy{}}} = socket
      ) do
    case AdminServerPolicy.put_dpop_policy(mode) do
      {:ok, %ServerPolicy{} = policy} ->
        {:noreply,
         socket
         |> assign(policy: policy, form_errors: [])
         |> put_flash(:info, "Global DPoP policy saved")}

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
      <AdminComponents.alert :if={is_nil(@policy)} variant={:danger} title="Could not load global DPoP policy">
        <p>The issuer DPoP setting could not be loaded, so its current value is unknown. Settings and save controls stay hidden until the stored policy can be confirmed.</p>
        <AdminComponents.action_bar>
          <AdminComponents.admin_button type="button" variant={:secondary} phx-click="reload_policy">
            Reload policy
          </AdminComponents.admin_button>
        </AdminComponents.action_bar>
      </AdminComponents.alert>

      <div :if={@policy}>
      <AdminComponents.page_hero
        eyebrow="Configure"
        title="Global DPoP policy"
        body="DPoP (Demonstrating Proof of Possession) binds access tokens to the public key used in a DPoP proof. Choose whether clients that inherit issuer policy may use bearer access tokens or must use DPoP-bound access tokens. Client-specific choices stay on each client policy route."
      >
        <:summary>
          <AdminComponents.decision_summary>
            <:item
              :for={item <- dpop_decision_summary_items(%{policy: @policy, summary: @summary})}
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
        title="Global DPoP policy"
        subtitle={"Current choice is #{dpop_policy_label(@policy.dpop_policy)}. #{policy_scope_copy(:dpop)}"}
      >
        <AdminComponents.error_list :if={@form_errors != []} errors={@form_errors} />

        <form class="lockspire-admin-form-stack" phx-submit="save_policy">
          <div class="lockspire-admin-field">
            <label for="dpop_policy">Access token requirement</label>
            <select id="dpop_policy" name="policy[dpop_policy]">
              <option value="bearer" selected={@policy.dpop_policy == :bearer}>Bearer access tokens allowed</option>
              <option value="dpop" selected={@policy.dpop_policy == :dpop}>DPoP-bound access tokens required</option>
            </select>
            <p class="lockspire-admin-help">
              <strong>Bearer access tokens allowed:</strong> Clients that inherit this setting may use bearer access tokens.
              <br />
              <strong>DPoP-bound access tokens required:</strong> Clients that inherit this setting must provide a valid DPoP proof when requesting tokens. Issued access tokens are bound to the proof key.
            </p>
          </div>

          <AdminComponents.action_bar>
            <AdminComponents.admin_button type="submit" variant={:primary}>
              Save global DPoP policy
            </AdminComponents.admin_button>
          </AdminComponents.action_bar>
        </form>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="Client override summary"
        subtitle="Counts by client choice: inherit the issuer setting, allow bearer access tokens, or require DPoP."
      >
        <div :if={@summary} class="lockspire-admin-summary-grid">
          <div class="lockspire-admin-summary-stat">
            <span class="lockspire-admin-summary-value">{@summary.inherit}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.inherit == 1, do: "client inherits", else: "clients inherit"}
            </span>
          </div>
          <div class="lockspire-admin-summary-stat">
            <span class="lockspire-admin-summary-value">{@summary.bearer}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.bearer == 1, do: "client uses bearer", else: "clients use bearer"}
            </span>
          </div>
          <div class="lockspire-admin-summary-stat">
            <span class="lockspire-admin-summary-value">{@summary.dpop}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.dpop == 1, do: "client requires DPoP", else: "clients require DPoP"}
            </span>
          </div>
        </div>

        <p :if={not is_nil(@summary) and @summary.bearer == 0 and @summary.dpop == 0} class="lockspire-admin-empty-notice">
          No client-specific DPoP choices are stored. Registered clients inherit the issuer setting.
        </p>
        <p :if={is_nil(@summary)} class="lockspire-admin-empty-notice">
          Client override counts are unavailable.
        </p>
      </AdminComponents.section_card>
      </div>
    </AdminLayoutLive.shell>
    """
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
          Enum.reduce(clients, %{inherit: 0, bearer: 0, dpop: 0}, fn %Client{dpop_policy: mode},
                                                                     acc ->
            Map.update!(acc, mode, &(&1 + 1))
          end)

        assign(socket, summary: summary)

      _result ->
        assign(socket, summary: nil)
    end
  end

  defp dpop_decision_summary_items(%{policy: %ServerPolicy{} = policy, summary: summary}) do
    [
      %{
        label: "Issuer DPoP choice",
        value: dpop_policy_label(policy.dpop_policy),
        tone: dpop_policy_tone(policy.dpop_policy),
        detail: "Clients without a DPoP choice of their own use this issuer setting."
      },
      %{
        label: "Clients that inherit",
        value: inherited_clients_value(summary),
        tone: :info,
        detail:
          "These clients use the global issuer DPoP default; client overrides stay on client policy routes."
      },
      %{
        label: "Next safe action",
        value: "Save global DPoP policy",
        tone: :info,
        detail: policy_scope_copy(:dpop)
      }
    ]
  end

  defp dpop_policy_label(:dpop), do: "DPoP required"
  defp dpop_policy_label(:bearer), do: "Bearer allowed"
  defp dpop_policy_label(value), do: value |> to_string() |> String.replace("_", " ")

  defp policy_errors(errors) do
    if Enum.any?(errors, fn
         %{reason: :invalid_dpop_policy} -> true
         _error -> false
       end) do
      [
        %{
          field: "Access token requirement",
          message:
            "Choose whether clients that inherit issuer policy may use bearer access tokens or require DPoP."
        }
      ]
    else
      [save_uncertain_error()]
    end
  end

  defp save_uncertain_error do
    %{
      field: "Access token requirement",
      message:
        "The DPoP policy change could not be confirmed. Reload the policy to check its current value."
    }
  end

  defp dpop_policy_tone(:dpop), do: :warning
  defp dpop_policy_tone(:bearer), do: :success
  defp dpop_policy_tone(_value), do: :info

  defp inherited_clients_value(%{inherit: 1}), do: "1 client"
  defp inherited_clients_value(%{inherit: count}), do: "#{count} clients"
  defp inherited_clients_value(_summary), do: "Unavailable"

  defp policy_scope_copy(:dpop) do
    "The issuer uses this setting for clients without a DPoP choice of their own. A client-specific choice takes precedence on that client's policy route."
  end
end
