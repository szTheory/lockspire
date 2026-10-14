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
       page_title: "Token proof settings",
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
         |> put_flash(:info, "Token proof settings saved")}

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
      <AdminComponents.alert :if={is_nil(@policy)} variant={:danger} title="Could not load token proof settings">
        <p>Lockspire could not confirm the saved default. Reload this page before changing it.</p>
        <AdminComponents.action_bar>
          <AdminComponents.admin_button type="button" variant={:secondary} phx-click="reload_policy">
            Reload settings
          </AdminComponents.admin_button>
        </AdminComponents.action_bar>
      </AdminComponents.alert>

      <div :if={@policy}>
      <AdminComponents.policy_nav current={:dpop} />

      <AdminComponents.section_card
        title="Default for apps"
      >
        <form class="lockspire-admin-form-stack" phx-submit="save_policy">
          <AdminComponents.radio_group id="dpop_policy" name="policy[dpop_policy]"
            label="Access token proof" value={@policy.dpop_policy} errors={@form_errors}
            help="DPoP ties an access token to an app's public key. Apps using this default may use bearer tokens or must prove they hold the key, depending on the choice above. Apps may have their own setting.">
            <:option value="bearer" label="Bearer access tokens allowed" />
            <:option value="dpop" label="DPoP-bound access tokens required" />
          </AdminComponents.radio_group>

          <AdminComponents.action_bar>
            <AdminComponents.admin_button type="submit" variant={:primary}>
              Save token proof settings
            </AdminComponents.admin_button>
          </AdminComponents.action_bar>
        </form>
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
            <span class="lockspire-admin-summary-value">{@summary.bearer}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.bearer == 1, do: "app uses bearer tokens", else: "apps use bearer tokens"}
            </span>
          </div>
          <div class="lockspire-admin-summary-stat">
            <span class="lockspire-admin-summary-value">{@summary.dpop}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.dpop == 1, do: "app requires DPoP", else: "apps require DPoP"}
            </span>
          </div>
        </div>

        <p :if={not is_nil(@summary) and @summary.bearer == 0 and @summary.dpop == 0} class="lockspire-admin-empty-notice">
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

  defp policy_errors(errors) do
    if Enum.any?(errors, fn
         %{reason: :invalid_dpop_policy} -> true
         _error -> false
       end) do
      [
        %{
          field: "Access token proof",
          message:
            "Choose whether apps using the provider default may use bearer tokens or must prove key possession with DPoP."
        }
      ]
    else
      [save_uncertain_error()]
    end
  end

  defp save_uncertain_error do
    %{
      field: "Access token proof",
      message:
        "Token proof settings could not be confirmed. Reload this page to check the saved value."
    }
  end
end
