defmodule AdoptionDemoWeb.ConsentController do
  use AdoptionDemoWeb, :controller

  alias AdoptionDemoWeb.HTML
  alias Lockspire.Storage.Ecto.Repository

  def show(conn, %{"interaction_id" => interaction_id}) do
    with {:ok, interaction} <- Repository.fetch_interaction(interaction_id),
         false <- is_nil(interaction),
         {:ok, client} <- Repository.fetch_client_by_id(interaction.client_id),
         false <- is_nil(client) do
      render_consent(conn, interaction, client)
    else
      _other ->
        conn
        |> put_status(:not_found)
        |> html(HTML.page(conn, "Consent not found", "<h1>Consent not found</h1>"))
    end
  end

  defp render_consent(conn, interaction, client) do
    scopes =
      interaction.scopes_requested
      |> Enum.map(&"<li>#{HTML.escape(&1)}</li>")
      |> Enum.join("\n")

    body = """
    <section class="panel">
      <p class="muted">Host-owned consent review</p>
      <h1>Authorize access</h1>
      <p>
        <strong>#{HTML.escape(client.name || client.client_id)}</strong>
        wants access for <code>#{HTML.escape(interaction.account_id)}</code>.
      </p>
      <ul>
        #{scopes}
      </ul>
      <form action="/lockspire/interactions/#{HTML.escape(interaction.interaction_id)}/complete" method="post">
        <input type="hidden" name="_csrf_token" value="#{Plug.CSRFProtection.get_csrf_token()}" />
        <input type="hidden" name="decision" value="approve" />
        <label>
          <input type="checkbox" name="remember" value="true" checked />
          Remember this consent for future matching requests
        </label>
        <button class="primary" type="submit">Approve access</button>
      </form>
      <form action="/lockspire/interactions/#{HTML.escape(interaction.interaction_id)}/complete" method="post">
        <input type="hidden" name="_csrf_token" value="#{Plug.CSRFProtection.get_csrf_token()}" />
        <input type="hidden" name="decision" value="deny" />
        <button type="submit">Deny access</button>
      </form>
    </section>
    """

    html(conn, HTML.page(conn, "Authorize access", body))
  end
end
