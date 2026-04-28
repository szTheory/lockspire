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
  def handle_event("save_policy", %{"policy" => %{"dpop_policy" => mode}}, socket) do
    case AdminServerPolicy.put_dpop_policy(mode) do
      {:ok, %ServerPolicy{} = policy} ->
        {:noreply,
         socket
         |> assign(policy: policy, form_errors: [])
         |> put_flash(:info, "Global DPoP policy updated")}

      {:error, errors} when is_list(errors) ->
        {:noreply, assign(socket, form_errors: errors)}

      {:error, _reason} ->
        {:noreply,
         assign(socket,
           form_errors: [%{field: :dpop_policy, reason: :request_failed, detail: nil}]
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
      <AdminComponents.section_card
        title="Global DPoP policy"
        subtitle={"Current mode is #{@policy.dpop_policy}. This governs all clients that inherit their policy."}
      >
        <AdminComponents.error_list :if={@form_errors != []} errors={@form_errors} />

        <form phx-submit="save_policy">
          <div class="lockspire-admin-field">
            <label for="dpop_policy">Enforcement mode</label>
            <select id="dpop_policy" name="policy[dpop_policy]">
              <option value="bearer" selected={@policy.dpop_policy == :bearer}>Bearer</option>
              <option value="dpop" selected={@policy.dpop_policy == :dpop}>DPoP</option>
            </select>
            <p class="lockspire-admin-help">
              <strong>Bearer:</strong> Inheriting clients can use bearer access tokens on Lockspire-owned surfaces.
              <br />
              <strong>DPoP:</strong> Inheriting clients MUST use DPoP-bound access tokens on Lockspire-owned surfaces.
            </p>
          </div>

          <button class="lockspire-admin-btn-primary" type="submit">Save global DPoP policy</button>
        </form>
      </AdminComponents.section_card>

      <AdminComponents.section_card
        title="Client override summary"
        subtitle="Exceptions to the global DPoP policy across all registered clients."
      >
        <div class="lockspire-admin-summary-grid">
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

        <p :if={@summary.bearer == 0 and @summary.dpop == 0} class="lockspire-admin-empty-notice">
          No client DPoP overrides yet. All clients currently inherit the global DPoP policy.
        </p>
      </AdminComponents.section_card>
    </AdminLayoutLive.shell>
    """
  end

  defp load_policy(socket) do
    case Admin.get_server_policy() do
      {:ok, %ServerPolicy{} = policy} -> assign(socket, policy: policy)
      {:error, _reason} -> assign(socket, policy: %ServerPolicy{dpop_policy: :bearer})
    end
  end

  defp load_summary(socket) do
    {:ok, clients} = Admin.list_clients()

    summary =
      Enum.reduce(clients, %{inherit: 0, bearer: 0, dpop: 0}, fn %Client{dpop_policy: mode}, acc ->
        Map.update!(acc, mode, &(&1 + 1))
      end)

    assign(socket, summary: summary)
  end
end
