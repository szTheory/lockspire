defmodule Lockspire.Web.Live.Admin.PoliciesLive.Par do
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
       page_title: "Authorization request settings",
       current_section: :policies,
       policy: nil,
       summary: %{inherit: 0, required: 0, optional: 0},
       form_errors: [],
       save_notice: nil
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
        %{"policy" => %{"par_policy" => mode}},
        %{assigns: %{policy: %ServerPolicy{}}} = socket
      ) do
    case Admin.put_server_policy(mode) do
      {:ok, %ServerPolicy{} = policy} ->
        {:noreply,
         socket
         |> assign(
           policy: policy,
           form_errors: [],
           save_notice: "Request policy saved. Apps with their own setting are unchanged."
         )
         |> put_flash(:info, "Request policy saved")}

      {:error, errors} when is_list(errors) ->
        {:noreply, assign(socket, form_errors: policy_errors(errors), save_notice: nil)}

      {:error, _reason} ->
        {:noreply,
         assign(socket,
           form_errors: [save_uncertain_error()],
           save_notice: nil
         )}
    end
  end

  def handle_event("save_policy", _params, socket) do
    {:noreply,
     assign(socket,
       form_errors: [save_uncertain_error()],
       save_notice: nil
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.alert :if={is_nil(@policy)} variant={:danger} title="Could not load request settings">
        <p>Lockspire could not confirm the saved default. Reload this page before changing it.</p>
        <AdminComponents.action_bar>
          <AdminComponents.admin_button type="button" variant={:secondary} phx-click="reload_policy">
            Reload settings
          </AdminComponents.admin_button>
        </AdminComponents.action_bar>
      </AdminComponents.alert>

      <div :if={@policy}>
      <AdminComponents.policy_nav current={:par} />

      <AdminComponents.section_card
        title="Default for apps"
      >
        <p :if={@save_notice} role="status" class="lockspire-admin-alert lockspire-admin-alert-info">
          {@save_notice}
        </p>

        <form class="lockspire-admin-form-stack" phx-submit="save_policy">
          <AdminComponents.radio_group id="par_policy" name="policy[par_policy]"
            label="When apps must use PAR" value={@policy.par_policy} errors={@form_errors}
            help="PAR lets an app send its authorization request to Lockspire before redirecting the user. Optional allows direct requests. Required rejects them for apps using this default. Apps may have their own setting.">
            <:option value="optional" label="Optional" />
            <:option value="required" label="Required" />
          </AdminComponents.radio_group>

          <AdminComponents.action_bar>
            <AdminComponents.admin_button type="submit" variant={:primary}>
              Save request settings
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
            <span class="lockspire-admin-summary-value">{@summary.required}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.required == 1, do: "app requires PAR", else: "apps require PAR"}
            </span>
          </div>
          <div class="lockspire-admin-summary-stat">
            <span class="lockspire-admin-summary-value">{@summary.optional}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.optional == 1, do: "app allows direct requests", else: "apps allow direct requests"}
            </span>
          </div>
        </div>

        <p :if={not is_nil(@summary) and @summary.required == 0 and @summary.optional == 0} class="lockspire-admin-empty-notice">
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
          Enum.reduce(clients, %{inherit: 0, required: 0, optional: 0}, fn %Client{
                                                                             par_policy: mode
                                                                           },
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
         %{reason: :invalid_par_policy} -> true
         _error -> false
       end) do
      [%{field: :par_policy, message: "Enforcement mode: choose Optional or Required."}]
    else
      [save_uncertain_error()]
    end
  end

  defp save_uncertain_error do
    %{
      field: :par_policy,
      message:
        "The request settings could not be confirmed. Reload this page to check the saved value."
    }
  end
end
