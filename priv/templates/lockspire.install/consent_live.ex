defmodule <%= @consent_live_module %> do
  use Phoenix.LiveView

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     assign(socket,
       interaction_id: params["interaction_id"],
       client_name: params["client_name"] || "Third-party application",
       requested_scopes: List.wrap(params["requested_scopes"] || []),
       page_title: "Authorize Access"
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="host-consent-shell">
      <header>
        <p>Brand, copy, and product framing stay in the host app.</p>
        <h1><%%= @page_title %></h1>
        <p>
          <strong><%%= @client_name %></strong>
          is requesting access for interaction
          <code><%%= @interaction_id %></code>.
        </p>
      </header>

      <ul>
        <%%= for scope <- @requested_scopes do %>
          <li><%%= scope %></li>
        <%% end %>
      </ul>

      <form action={finalize_path(@interaction_id)} method="post">
        <input type="hidden" name="decision" value="approve" />
        <label>
          <input type="checkbox" name="remember" value="true" checked />
          Remember this consent for future matching requests
        </label>
        <button type="submit">Approve access</button>
      </form>

      <form action={finalize_path(@interaction_id)} method="post">
        <input type="hidden" name="decision" value="deny" />
        <button type="submit">Deny access</button>
      </form>
    </section>
    """
  end

  defp finalize_path(interaction_id) do
    "<%= @mount_path %>/interactions/#{interaction_id}/complete"
  end
end
