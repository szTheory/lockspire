defmodule AdoptionDemoWeb.PageController do
  use AdoptionDemoWeb, :controller

  alias AdoptionDemoWeb.HTML

  def home(conn, _params) do
    body = """
    <section class="hero">
      <div class="hero-copy">
        <p class="kicker">Billingo workspace</p>
        <h1>Revenue operations, with Lockspire embedded.</h1>
        <p>
          Billingo already signs users in. Lockspire lets other software use
          that trusted Billingo identity safely, through the OAuth/OIDC provider
          mounted at <code>/lockspire</code>.
        </p>
        <div class="hero-actions">
          <a class="button" href="/developer/apps">Review developer app</a>
          <a class="button secondary" href="/authorized-apps">Authorized apps</a>
          <a class="button ghost" href="/lockspire/admin">Open Lockspire admin</a>
        </div>
      </div>
      <aside class="visual-card" aria-label="Billingo revenue summary">
        <p class="kicker">Live billing sample</p>
        <div class="ledger-row"><span>July usage invoices</span><strong>$128,400</strong></div>
        <div class="ledger-row"><span>Open usage disputes</span><strong>3</strong></div>
        <div class="ledger-row"><span>Partner integrations</span><strong>5</strong></div>
        <div class="total-line">
          <p class="muted">Protected API</p>
          <strong>/api/billing/summary</strong>
          <p class="fine-print">Requires a Lockspire-issued access token with <code>read:billing</code>.</p>
        </div>
      </aside>
    </section>

    <section class="grid">
      <article class="card highlight">
        <p class="metric">1</p>
        <p class="metric-label">Billingo proves user</p>
        <p><code>alice</code> and <code>bob</code> are Billingo users. <code>ops</code> is the host-owned operator account.</p>
        <a href="/login">Choose account</a>
      </article>
      <article class="card">
        <p class="metric">2</p>
        <p class="metric-label">Lockspire issues artifacts</p>
        <p>Authorization code + PKCE turns Billingo's signed-in subject into standards-based tokens.</p>
        <a href="/developer/apps">Start OAuth proof</a>
      </article>
      <article class="card">
        <p class="metric">3</p>
        <p class="metric-label">Billingo API enforces policy</p>
        <p>The access token needs <code>read:billing</code>; Billingo still checks tenant and product rules.</p>
        <a href="/lockspire/.well-known/openid-configuration">View discovery</a>
      </article>
    </section>

    <section class="panel integration-map">
      <div class="section-heading">
        <p class="kicker">Embedded provider boundary</p>
        <h2>Billingo runs product decisions; Lockspire runs protocol artifacts.</h2>
      </div>
      <div class="boundary-list">
        <div class="boundary-item">
          <strong>Billingo</strong>
          <p>Accounts, login, consent words, developer UX, billing APIs, and product authorization.</p>
        </div>
        <div class="boundary-item">
          <strong>Lockspire</strong>
          <p>Clients, authorization codes, consent records, tokens, keys, discovery, and operator workflows.</p>
        </div>
      </div>
    </section>
    """

    html(conn, HTML.page(conn, "Dashboard", body))
  end
end
