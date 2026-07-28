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
    account_id = HTML.escape(interaction.account_id)
    client_label = HTML.escape(client.name || client.client_id)
    interaction_id = HTML.escape(interaction.interaction_id)
    csrf_token = Plug.CSRFProtection.get_csrf_token()
    scope_meanings = HTML.scope_meaning_list(interaction.scopes_requested)

    body = """
    <section class="consent-stage">
      <article class="panel consent-card" aria-labelledby="consent-card-title">
        <header class="consent-card-header">
          <div class="consent-heading">
            <p class="kicker">Host-owned consent review</p>
            <h1 id="consent-card-title">Authorize access to Billingo?</h1>
            <p>
              <strong>#{client_label}</strong>
              wants access for <code>#{account_id}</code>.
              Billingo owns this consent copy and layout; Lockspire records the protocol decision.
            </p>
          </div>
          <span class="status-pill warn">Consent required</span>
        </header>

        <div class="consent-grid">
          <section class="consent-summary" aria-label="Request details">
            <div class="consent-detail-row"><span>Requesting app</span><strong>#{client_label}</strong></div>
            <div class="consent-detail-row"><span>Decision owner</span><strong>Billingo user</strong></div>
            <div class="consent-detail-row"><span>Data host</span><strong>Billingo</strong></div>
            <div class="consent-detail-row"><span>Protocol owner</span><strong>Lockspire OAuth/OIDC</strong></div>

            <div class="scope-block">
              <p class="kicker">Requested access</p>
              #{scope_meanings}
            </div>
          </section>

          <section class="consent-decision" aria-label="Approve or deny access">
            <p class="kicker">Decision</p>
            <h2>Approve access</h2>
            <p>Approving returns a short-lived authorization code to Billingo's callback. Your Billingo password is never shared.</p>

            <form class="approve-form" action="/lockspire/interactions/#{interaction_id}/complete" method="post">
              <input type="hidden" name="_csrf_token" value="#{csrf_token}" />
              <input type="hidden" name="decision" value="approve" />
              <label class="remember-consent">
                <input type="checkbox" name="remember" value="true" checked />
                <span>
                  <strong>Remember this consent</strong>
                  <small>Billingo asks Lockspire to reuse this approval for future matching client, user, and scope requests.</small>
                </span>
              </label>
              <button class="primary" type="submit">Approve access</button>
            </form>

            <form class="deny-form" action="/lockspire/interactions/#{interaction_id}/complete" method="post">
              <input type="hidden" name="_csrf_token" value="#{csrf_token}" />
              <input type="hidden" name="decision" value="deny" />
              <button class="danger" type="submit">Deny access</button>
            </form>
          </section>
        </div>
      </article>
    </section>
    """

    html(conn, HTML.page(conn, "Authorize access", body))
  end
end
