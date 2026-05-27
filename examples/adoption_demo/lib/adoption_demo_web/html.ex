defmodule AdoptionDemoWeb.HTML do
  @moduledoc false

  def page(conn, title, body) do
    account = conn.assigns[:current_account]
    csrf = Plug.CSRFProtection.get_csrf_token()

    """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>#{escape(title)} - Acme Ledger</title>
        <style>
          body { margin: 0; font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; color: #17202a; background: #f7f8fa; }
          header, main { max-width: 980px; margin: 0 auto; padding: 24px; }
          nav { display: flex; gap: 14px; align-items: center; flex-wrap: wrap; margin-top: 12px; }
          a { color: #0b5cad; text-decoration: none; }
          a:hover { text-decoration: underline; }
          .panel { background: #fff; border: 1px solid #d8dde6; border-radius: 8px; padding: 18px; margin: 16px 0; }
          .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(230px, 1fr)); gap: 16px; }
          code, pre { background: #eef2f7; border-radius: 4px; padding: 2px 5px; }
          label { display: block; margin: 10px 0 4px; font-weight: 600; }
          input, select { font: inherit; padding: 8px; min-width: 260px; }
          button { font: inherit; padding: 8px 12px; border-radius: 6px; border: 1px solid #778ca3; background: #fff; cursor: pointer; }
          button.primary { background: #155eef; border-color: #155eef; color: #fff; }
          .muted { color: #5d6d7e; }
          .danger { color: #a51d2d; }
        </style>
      </head>
      <body>
        <header>
          <strong>Acme Ledger</strong>
          <span class="muted">Lockspire adoption demo</span>
          <nav>
            <a href="/">Dashboard</a>
            <a href="/developer/apps">Developer apps</a>
            <a href="/authorized-apps">Authorized apps</a>
            <a href="/verify">Device verification</a>
            <a href="/lockspire/.well-known/openid-configuration">Discovery</a>
            <a href="/lockspire/admin">Operator admin</a>
          </nav>
          <p class="muted">Signed in as: #{account_label(account)}</p>
          <form action="/logout" method="post">
            <input type="hidden" name="_csrf_token" value="#{csrf}" />
            <button type="submit">Sign out</button>
          </form>
        </header>
        <main>
          #{body}
        </main>
      </body>
    </html>
    """
  end

  def escape(value) do
    value
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  def account_label(nil), do: "anonymous"

  def account_label(account) do
    "#{escape(account.name)} (#{escape(account.email)})"
  end
end
