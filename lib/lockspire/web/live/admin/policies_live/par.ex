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
       page_title: "PAR policy",
       current_section: :policies,
       policy: nil,
       summary: %{inherit: 0, required: 0, optional: 0},
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
  def handle_event("save_policy", %{"policy" => %{"par_policy" => mode}}, socket) do
    case Admin.put_server_policy(mode) do
      {:ok, %ServerPolicy{} = policy} ->
        {:noreply,
         socket
         |> assign(policy: policy, form_errors: [])
         |> put_flash(:info, "Global PAR policy updated")}

      {:error, errors} when is_list(errors) ->
        {:noreply, assign(socket, form_errors: errors)}

      {:error, _reason} ->
        {:noreply,
         assign(socket,
           form_errors: [%{field: :par_policy, reason: :request_failed, detail: nil}]
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.policy_nav />

      <AdminComponents.section_card
        title="Global PAR policy"
        subtitle={"Current mode is #{@policy.par_policy}. This governs all clients that inherit their policy."}
      >
        <AdminComponents.error_list :if={@form_errors != []} errors={@form_errors} />

        <form class="lockspire-admin-form-stack" phx-submit="save_policy">
          <div class="lockspire-admin-field">
            <label for="par_policy">Enforcement mode</label>
            <select id="par_policy" name="policy[par_policy]">
              <option value="optional" selected={@policy.par_policy == :optional}>Optional</option>
              <option value="required" selected={@policy.par_policy == :required}>Required</option>
            </select>
            <p class="lockspire-admin-help">
              <strong>Optional:</strong> Clients can use PAR but direct <code>/authorize</code> is still allowed.
              <br />
              <strong>Required:</strong> Inheriting clients MUST use PAR; direct <code>/authorize</code> will be rejected.
            </p>
          </div>

          <AdminComponents.action_bar>
            <AdminComponents.admin_button type="submit" variant={:primary}>
              Save global PAR policy
            </AdminComponents.admin_button>
          </AdminComponents.action_bar>
        </form>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="Client override summary"
        subtitle="Exceptions to the global policy across all registered clients."
      >
        <div class="lockspire-admin-summary-grid">
          <div class="lockspire-admin-summary-stat">
            <span class="lockspire-admin-summary-value">{@summary.inherit}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.inherit == 1, do: "client inherits", else: "clients inherit"}
            </span>
          </div>
          <div class="lockspire-admin-summary-stat">
            <span class="lockspire-admin-summary-value">{@summary.required}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.required == 1, do: "client requires PAR", else: "clients require PAR"}
            </span>
          </div>
          <div class="lockspire-admin-summary-stat">
            <span class="lockspire-admin-summary-value">{@summary.optional}</span>
            <span class="lockspire-admin-summary-label">
              {if @summary.optional == 1, do: "client marks PAR optional", else: "clients mark PAR optional"}
            </span>
          </div>
        </div>

        <p :if={@summary.required == 0 and @summary.optional == 0} class="lockspire-admin-empty-notice">
          No client PAR overrides yet. All clients currently inherit the global PAR policy.
        </p>
      </AdminComponents.section_card>
    </AdminLayoutLive.shell>
    """
  end

  defp load_policy(socket) do
    case Admin.get_server_policy() do
      {:ok, %ServerPolicy{} = policy} -> assign(socket, policy: policy)
      {:error, _reason} -> assign(socket, policy: %ServerPolicy{par_policy: :optional})
    end
  end

  defp load_summary(socket) do
    {:ok, clients} = Admin.list_clients()

    summary =
      Enum.reduce(clients, %{inherit: 0, required: 0, optional: 0}, fn %Client{par_policy: mode},
                                                                       acc ->
        Map.update!(acc, mode, &(&1 + 1))
      end)

    assign(socket, summary: summary)
  end
end
