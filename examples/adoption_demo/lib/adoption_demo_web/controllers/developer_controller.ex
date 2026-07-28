defmodule AdoptionDemoWeb.DeveloperController do
  use AdoptionDemoWeb, :controller

  alias AdoptionDemoWeb.HTML

  def index(conn, _params) do
    verifier = "demo-pkce-verifier"
    challenge = code_challenge(verifier)
    demo_base_url = Application.fetch_env!(:adoption_demo, :demo_base_url)
    oauth_callback_url = demo_base_url <> "/oauth/callback"
    requested_scope = "openid email profile read:billing"
    scope_meanings = HTML.scope_meaning_list(requested_scope)

    authorize_url =
      "/lockspire/authorize?" <>
        URI.encode_query(%{
          "client_id" => "billingo-dashboard-public",
          "response_type" => "code",
          "redirect_uri" => oauth_callback_url,
          "scope" => requested_scope,
          "state" => "demo-state",
          "nonce" => "demo-nonce",
          "prompt" => "consent",
          "code_challenge" => challenge,
          "code_challenge_method" => "S256"
        })

    body = """
    <section class="record-layout">
      <article class="panel record-main">
        <header class="record-header">
          <p class="kicker">Developer console</p>
          <h1>Billingo Dashboard SPA</h1>
          <p>Public browser client for Billingo dashboards. Billingo owns partner-facing setup; Lockspire validates the OAuth/OIDC request after launch.</p>
          <div class="record-actions">
            <a class="button" href="#{authorize_url}">Start OAuth authorization</a>
            <a class="button secondary" href="/lockspire/admin/clients">Review in Lockspire admin</a>
          </div>
        </header>

        <section class="record-section">
          <p class="kicker">OAuth request preview</p>
          <dl class="data-list">
            <div class="data-row"><dt>Software client</dt><dd><code>billingo-dashboard-public</code></dd></div>
            <div class="data-row"><dt>Redirect URI</dt><dd><code>#{oauth_callback_url}</code></dd></div>
            <div class="data-row"><dt>Requested access</dt><dd>#{scope_meanings}</dd></div>
            <div class="data-row"><dt>PKCE proof</dt><dd><code>S256</code> challenge protects the short-lived authorization code.</dd></div>
            <div class="data-row"><dt>Smoke verifier</dt><dd><code>#{verifier}</code></dd></div>
            <div class="data-row"><dt>Provider</dt><dd><code>/lockspire</code> inside Billingo</dd></div>
          </dl>
        </section>
      </article>

      <aside class="panel record-side">
        <span class="status-pill good">PKCE required</span>
        <h2>Browser OAuth handoff</h2>
        <ol class="handoff-steps">
          <li class="handoff-step">
            <span class="step-index">1</span>
            <p><strong>Start request.</strong> Billingo sends the browser to <code>/lockspire/authorize</code>.</p>
          </li>
          <li class="handoff-step">
            <span class="step-index">2</span>
            <p><strong>Human decision.</strong> Billingo handles login and consent copy.</p>
          </li>
          <li class="handoff-step">
            <span class="step-index">3</span>
            <p><strong>Protocol result.</strong> Lockspire returns an authorization code to Billingo's callback.</p>
          </li>
        </ol>
        <p class="fine-print">Operator policy and protocol state remain visible in <code>/lockspire/admin</code>.</p>
      </aside>
    </section>
    """

    html(conn, HTML.page(conn, "Developer apps", body))
  end

  defp code_challenge(verifier) do
    :sha256
    |> :crypto.hash(verifier)
    |> Base.url_encode64(padding: false)
  end
end
