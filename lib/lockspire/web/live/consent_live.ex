defmodule Lockspire.Web.ConsentLive do
  @moduledoc """
  Reference consent surface rendered from durable interaction state.
  """

  use Phoenix.LiveView

  alias Lockspire.Web.ConsentContext

  @impl true
  def mount(%{"interaction_id" => interaction_id}, _session, socket) do
    case ConsentContext.load(socket, interaction_id) do
      {:ok, assigns} ->
        {:ok, assign(socket, assigns)}

      {:redirect, redirect_uri} ->
        {:ok, redirect(socket, external: redirect_uri)}

      {:error, reason} ->
        {:ok,
         assign(socket,
           page_title: "Authorization Error",
           error: error_message(reason)
         )}
    end
  end

  @impl true
  def render(%{error: _error} = assigns) do
    ~H"""
    <section class="lockspire-consent-error">
      <h1>Authorization request rejected</h1>
      <p>{@error}</p>
    </section>
    """
  end

  def render(assigns) do
    ~H"""
    <section class="lockspire-consent-shell">
      <header>
        <p class="eyebrow">Host-owned consent review</p>
        <h1>{@page_title}</h1>
        <p>
          <strong>{@client_name}</strong>
          wants access to these scopes.
        </p>
      </header>

      <ul>
        <%= for scope <- @requested_scopes do %>
          <li>{scope}</li>
        <% end %>
      </ul>

      <%= if @authorization_detail_types != [] do %>
        <section class="lockspire-consent-rar">
          <h2>Requested access types</h2>
          <ul>
            <%= for type <- @authorization_detail_types do %>
              <li>{type}</li>
            <% end %>
          </ul>
        </section>
      <% end %>

      <p>
        Brand, copy, and product framing stay in the host app. Lockspire remains the authority
        for interaction validity and the final redirect.
      </p>

      <form action={@finalize_path} method="post">
        <input type="hidden" name="decision" value="approve" />
        <label>
          <input type="checkbox" name="remember" value="true" checked={@remember?} />
          Remember this consent for future matching requests
        </label>
        <button type="submit" class="approve-submit">Approve access</button>
      </form>

      <form action={@finalize_path} method="post">
        <input type="hidden" name="decision" value="deny" />
        <button type="submit" class="deny-submit">Deny access</button>
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
end
