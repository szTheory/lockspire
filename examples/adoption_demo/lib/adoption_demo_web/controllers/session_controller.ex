defmodule AdoptionDemoWeb.SessionController do
  use AdoptionDemoWeb, :controller

  alias AdoptionDemoWeb.HTML

  def new(conn, params) do
    return_to = safe_return_to(params["return_to"])
    interaction_id = params["interaction_id"] || ""
    oauth_request? = interaction_id != ""

    {description, status_label} =
      if oauth_request? do
        {
          "Lockspire paused an OAuth request here because Billingo owns sign-in. Choose a Billingo account, then Lockspire receives the resolved subject.",
          "OAuth handoff"
        }
      else
        {
          "Use a seeded account to continue. Billingo owns login; Lockspire receives the resolved subject only when an OAuth flow needs it.",
          "Host-owned"
        }
      end

    account_options =
      AdoptionDemo.Accounts.all()
      |> Enum.map(fn account ->
        ~s(<option value="#{HTML.escape(account.login)}">#{HTML.escape(account.name)} - #{HTML.escape(account.email)}</option>)
      end)
      |> Enum.join("\n")

    body = """
    <section class="task-stage">
      <article class="panel task-card">
        <header class="task-header split-header">
          <div>
            <p class="kicker">Demo login</p>
            <h1>Choose a Billingo account.</h1>
            <p>#{description}</p>
          </div>
          <span class="status-pill neutral">#{status_label}</span>
        </header>

        <form class="task-form" action="/login" method="post">
          <input type="hidden" name="_csrf_token" value="#{Plug.CSRFProtection.get_csrf_token()}" />
          <input type="hidden" name="return_to" value="#{HTML.escape(return_to)}" />
          <input type="hidden" name="interaction_id" value="#{HTML.escape(interaction_id)}" />
          <div>
            <label for="login">Account</label>
            <select id="login" name="login">#{account_options}</select>
          </div>
          <button class="primary" type="submit">Sign in</button>
        </form>

        <div class="task-note">
          <p class="kicker">Seeded roles</p>
          <dl class="data-list">
            <div class="data-row"><dt>alice</dt><dd>Billingo user</dd></div>
            <div class="data-row"><dt>bob</dt><dd>Customer user</dd></div>
            <div class="data-row"><dt>ops</dt><dd>Operator with Lockspire admin access</dd></div>
          </dl>
        </div>
      </article>
    </section>
    """

    html(conn, HTML.page(conn, "Login", body))
  end

  def create(conn, params) do
    login = params["login"] || "alice"
    return_to = safe_return_to(params["return_to"])
    interaction_id = normalize_optional(params["interaction_id"])

    conn
    |> put_session("demo_login", login)
    |> redirect(to: resume_path(return_to, interaction_id))
  end

  def delete(conn, _params) do
    conn
    |> delete_session("demo_login")
    |> redirect(to: "/")
  end

  defp resume_path(_return_to, interaction_id) when is_binary(interaction_id) do
    "/lockspire/interactions/#{interaction_id}"
  end

  defp resume_path(return_to, nil), do: return_to

  defp safe_return_to(nil), do: "/"
  defp safe_return_to(""), do: "/"
  defp safe_return_to("/" <> _ = path), do: path
  defp safe_return_to(_other), do: "/"

  defp normalize_optional(nil), do: nil
  defp normalize_optional(""), do: nil
  defp normalize_optional(value), do: value
end
