# Host-owned Lockspire seam
# Lockspire generates this file once, but your app owns the ongoing logic, UX, claims, and policy here.
# If you customize this file, keep those edits and reconcile future changes manually.

defmodule GeneratedHostAppWeb.LockspireConsentLive do
  @moduledoc """
  Host-owned presentation for a Lockspire consent interaction.

  Keep this module aligned with your application's layout, components, copy,
  and authentication hooks. Lockspire owns the context validity and the final
  decision endpoint; this LiveView only renders safe context facts.
  """

  use Phoenix.LiveView

  alias Lockspire.Web.ConsentContext

  @impl true
  def mount(%{"interaction_id" => interaction_id}, _session, socket) do
    socket = assign(socket, loading?: true, submitting?: false, decision: nil, error: nil)
    host_assigns = socket.assigns
    connect_info = socket.private[:connect_info]

    if connected?(socket) do
      {:ok,
       start_async(socket, :load_consent_context, fn ->
         ConsentContext.load(
           %Phoenix.LiveView.Socket{
             assigns: host_assigns,
             private: %{connect_info: connect_info}
           },
           interaction_id
         )
       end)}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_async(:load_consent_context, {:ok, {:ok, context}}, socket) do
    {:noreply,
     assign(
       socket,
       Map.merge(context, %{loading?: false, submitting?: false, decision: nil, error: nil})
     )}
  end

  def handle_async(:load_consent_context, {:ok, {:redirect, redirect_uri}}, socket) do
    {:noreply, redirect(socket, external: redirect_uri)}
  end

  def handle_async(:load_consent_context, {:ok, {:error, reason}}, socket) do
    {:noreply, assign_error(socket, reason)}
  end

  def handle_async(:load_consent_context, {:ok, _unexpected_result}, socket) do
    {:noreply, assign_error(socket, :unavailable)}
  end

  def handle_async(:load_consent_context, {:exit, _reason}, socket) do
    {:noreply, assign_error(socket, :unavailable)}
  end

  @impl true
  def handle_event("submit", %{"decision" => decision}, socket)
      when decision in ["approve", "deny"] do
    {:noreply, assign(socket, submitting?: true, decision: decision)}
  end

  @impl true
  def render(%{loading?: true} = assigns) do
    ~H"""
    <section class="host-consent-shell">
      <div role="status">
        <h1>Authorize access</h1>
        <p>Loading authorization request…</p>
      </div>
    </section>
    """
  end

  def render(%{error: error} = assigns) when not is_nil(error) do
    ~H"""
    <section class="host-consent-shell">
      <div role="alert">
        <h1>Authorize access</h1>
        <p>{@error}</p>
      </div>
    </section>
    """
  end

  def render(assigns) do
    ~H"""
    <section class="host-consent-shell">
      <header>
        <h1>{@page_title}</h1>
        <p>
          <strong>{@client_name || "Application details are unavailable"}</strong>
          wants access to your account.
        </p>
      </header>

      <%= if @requested_scopes == [] do %>
        <p>This application did not request any additional permissions.</p>
      <% else %>
        <section>
          <h2>Requested permissions</h2>
          <ul>
            <%= for scope <- @requested_scopes do %>
              <li>{scope}</li>
            <% end %>
          </ul>
        </section>
      <% end %>

      <%= if @authorization_detail_types != [] do %>
        <section>
          <h2>Requested access types</h2>
          <ul>
            <%= for type <- @authorization_detail_types do %>
              <li>{type}</li>
            <% end %>
          </ul>
        </section>
      <% end %>

      <form
        id="approve-consent"
        action={@finalize_path}
        method="post"
        phx-submit="submit"
        phx-trigger-action={@submitting? and @decision == "approve"}
      >
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
        <input type="hidden" name="decision" value="approve" />
        <label>
          <input type="checkbox" name="remember" value="true" checked={@remember?} />
          Remember this consent for future matching requests
        </label>
        <button type="submit" disabled={@submitting?} phx-disable-with="Approving access…">
          Approve access
        </button>
      </form>

      <form
        id="deny-consent"
        action={@finalize_path}
        method="post"
        phx-submit="submit"
        phx-trigger-action={@submitting? and @decision == "deny"}
      >
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
        <input type="hidden" name="decision" value="deny" />
        <button type="submit" disabled={@submitting?} phx-disable-with="Denying access…">
          Deny access
        </button>
      </form>
    </section>
    """
  end

  defp error_message(:expired),
    do:
      "This authorization request is no longer available. Return to the application and start again."

  defp error_message(:subject_mismatch),
    do:
      "This authorization request is no longer available. Return to the application and start again."

  defp error_message(_reason),
    do: "We could not load this authorization request. Return to the application and try again."

  defp assign_error(socket, reason) do
    assign(socket,
      loading?: false,
      error: error_message(reason),
      submitting?: false,
      decision: nil
    )
  end
end
