defmodule AdoptionDemoWeb.AuthorizedAppsController do
  use AdoptionDemoWeb, :controller

  alias AdoptionDemoWeb.HTML

  def index(conn, _params) do
    account = conn.assigns[:current_account]

    body =
      if account do
        """
        <section class="panel">
          <h1>Authorized apps</h1>
          <p>This is the host-owned account surface where a SaaS app would show remembered consents.</p>
          <p>Signed-in subject: <code>user:#{HTML.escape(account.id)}</code></p>
        </section>
        """
      else
        """
        <section class="panel">
          <h1>Authorized apps</h1>
          <p>Sign in before viewing authorized apps.</p>
          <a href="/login?return_to=/authorized-apps">Sign in</a>
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
