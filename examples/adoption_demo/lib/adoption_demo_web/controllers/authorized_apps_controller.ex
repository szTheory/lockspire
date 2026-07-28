defmodule AdoptionDemoWeb.AuthorizedAppsController do
  use AdoptionDemoWeb, :controller

  alias AdoptionDemoWeb.HTML

  def index(conn, _params) do
    account = conn.assigns[:current_account]
    dashboard_scope_meanings = HTML.scope_meaning_list("openid email profile read:billing")

    body =
      if account do
        """
        <section class="task-stage wide">
          <article class="panel task-card">
            <header class="task-header split-header">
              <div>
                <p class="kicker">Customer account</p>
                <h1>Apps connected to your Billingo data.</h1>
                <p>Review software that can use Billingo on your behalf. Billingo owns this settings surface; Lockspire stores the consent record behind it.</p>
              </div>
              <span class="status-pill neutral">user:#{HTML.escape(account.id)}</span>
            </header>

            <section class="app-list" aria-label="Connected apps">
              <article class="app-row">
                <div>
                  <h2>Billingo Dashboard</h2>
                  <p>Can read billing summaries and profile details for this workspace.</p>
                  <p class="kicker">What this app can do</p>
                  #{dashboard_scope_meanings}
                  <dl class="data-list">
                    <div class="data-row"><dt>Stored by Lockspire</dt><dd>Remembered consent for matching client, user, and scope requests.</dd></div>
                  </dl>
                </div>
                <div class="app-meta">
                  <span class="status-pill good">Active</span>
                </div>
              </article>

              <article class="app-row">
                <div>
                  <h2>Northstar Payables Portal</h2>
                  <p>Partner integration shown in Lockspire's operator UI for registration and logout propagation proof.</p>
                  <p class="fine-print">Customer-facing revoke UX belongs here; operator support lives in Lockspire admin.</p>
                </div>
                <div class="app-meta">
                  <span class="status-pill neutral">Example</span>
                </div>
              </article>
            </section>
          </article>
        </section>
        """
      else
        """
        <section class="task-stage">
          <article class="panel task-card">
            <header class="task-header">
              <p class="kicker">Customer account</p>
              <h1>Review apps connected to Billingo.</h1>
              <p>Sign in as a demo customer to see the host-owned authorized-apps surface.</p>
            </header>
            <div class="task-actions">
              <a class="button" href="/login?return_to=/authorized-apps">Sign in</a>
              <a class="button secondary" href="/developer/apps">View developer app</a>
            </div>
            <div class="task-note">
              <p>Billingo presents the customer-facing connected-apps list; Lockspire keeps the consent records behind it.</p>
            </div>
          </article>
        </section>
        """
      end

    html(conn, HTML.page(conn, "Authorized apps", body))
  end

  def delete(conn, _params) do
    conn
    |> put_status(:no_content)
    |> text("")
  end
end
