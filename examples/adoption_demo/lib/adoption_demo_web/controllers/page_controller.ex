defmodule AdoptionDemoWeb.PageController do
  use AdoptionDemoWeb, :controller

  alias AdoptionDemoWeb.HTML

  def home(conn, _params) do
    body = """
    <section class="panel">
      <h1>Embedded OAuth/OIDC provider inside a SaaS app</h1>
      <p>
        This demo is a small billing SaaS that uses Lockspire as its embedded provider.
        The host app owns account login, tenant claims, operator access, and product routes.
      </p>
    </section>

    <section class="grid">
      <article class="panel">
        <h2>Users</h2>
        <p><code>alice</code> and <code>bob</code> are tenant users. <code>ops</code> can reach the operator UI.</p>
        <a href="/login">Choose demo account</a>
      </article>
      <article class="panel">
        <h2>OAuth client</h2>
        <p>Use the seeded public client to run auth-code + PKCE against <code>/lockspire</code>.</p>
        <a href="/developer/apps">View client details</a>
      </article>
      <article class="panel">
        <h2>Protected API</h2>
        <p><code>/api/billing/summary</code> requires a Lockspire-issued access token with <code>read:billing</code>.</p>
      </article>
    </section>
    """

    html(conn, HTML.page(conn, "Dashboard", body))
  end
end
