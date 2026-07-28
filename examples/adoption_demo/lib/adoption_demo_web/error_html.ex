defmodule AdoptionDemoWeb.ErrorHTML do
  @moduledoc """
  Billingo-styled error pages.

  Without this module Phoenix falls back to a default error view that has no
  `404` template, so a mistyped demo URL raised `ArgumentError (no "404" html
  template)` and returned a raw crash page. Billingo owns its own not-found and
  failure copy the same way it owns every other customer-facing surface.
  """

  alias AdoptionDemo.Accounts
  alias AdoptionDemoWeb.HTML

  def render("404.html", assigns) do
    render_page(assigns, "Page not found", "warn", "404", """
    <div>
      <p class="kicker">Billingo</p>
      <h1>We couldn't find that page.</h1>
      <p>The link may be out of date, or the address may have a typo. Your account and your connected apps are unaffected.</p>
    </div>
    """, """
    <div class="task-actions">
      <a class="button" href="/">Back to dashboard</a>
      <a class="button secondary" href="/developer/apps">Developer console</a>
      <a class="button ghost" href="/authorized-apps">Authorized apps</a>
    </div>
    #{requested_path_note(assigns)}
    """)
  end

  def render("500.html", assigns) do
    render_page(assigns, "Something went wrong", "bad", "500", """
    <div>
      <p class="kicker">Billingo</p>
      <h1>Something went wrong on our end.</h1>
      <p>This request failed inside Billingo. Nothing about your authorized apps or consent records changed.</p>
    </div>
    """, """
    <div class="task-actions">
      <a class="button" href="/">Back to dashboard</a>
    </div>
    """)
  end

  def render(template, assigns) do
    message = Phoenix.Controller.status_message_from_template(template)
    status = String.replace_trailing(template, ".html", "")

    render_page(assigns, message, "neutral", status, """
    <div>
      <p class="kicker">Billingo</p>
      <h1>#{HTML.escape(message)}</h1>
      <p>Billingo could not complete that request.</p>
    </div>
    """, """
    <div class="task-actions">
      <a class="button" href="/">Back to dashboard</a>
    </div>
    """)
  end

  defp render_page(assigns, title, pill_kind, pill_label, heading, actions) do
    body = """
    <section class="task-stage">
      <article class="panel task-card">
        <header class="task-header split-header">
          #{heading}
          <span class="status-pill #{pill_kind}">#{HTML.escape(pill_label)}</span>
        </header>
        #{actions}
        <div class="task-note">
          <p>Billingo owns this page. Lockspire only answers OAuth/OIDC protocol routes under <code>/lockspire</code>.</p>
        </div>
      </article>
    </section>
    """

    assigns
    |> conn_from_assigns()
    |> HTML.page(title, body)
    |> Phoenix.HTML.raw()
  end

  defp requested_path_note(assigns) do
    case conn_from_assigns(assigns) do
      %Plug.Conn{request_path: path} when is_binary(path) and path != "" ->
        ~s(<p class="fine-print">Requested address: <code>#{HTML.escape(path)}</code></p>)

      _other ->
        ""
    end
  end

  # Unmatched routes raise inside the router, before the browser pipeline runs,
  # so `:current_account` is never assigned. Read the session directly to keep a
  # signed-in customer looking signed in on the error page.
  defp conn_from_assigns(assigns) do
    case assigns[:conn] do
      %Plug.Conn{assigns: %{current_account: _}} = conn -> conn
      %Plug.Conn{} = conn -> Plug.Conn.assign(conn, :current_account, session_account(conn))
      _other -> %Plug.Conn{}
    end
  end

  defp session_account(conn) do
    conn
    |> Plug.Conn.fetch_session()
    |> Plug.Conn.get_session("demo_login")
    |> case do
      login when is_binary(login) -> Accounts.get(login)
      _other -> nil
    end
  rescue
    _error -> nil
  end
end
