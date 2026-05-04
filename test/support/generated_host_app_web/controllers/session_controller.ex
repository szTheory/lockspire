defmodule GeneratedHostAppWeb.SessionController do
  use Phoenix.Controller, formats: [:html]

  import Plug.Conn

  def new(conn, params) do
    return_to = Map.get(params, "return_to", "/lockspire/authorize")
    login = Map.get(params, "login", "generated-host-user")
    auth_time_seconds_ago = Map.get(params, "auth_time_seconds_ago", "30")

    html = """
    <html>
      <body>
        <h1>Generated host login</h1>
        <form method="post" action="/login">
          <input type="hidden" name="return_to" value="#{html_escape(return_to)}" />
          <label>Login <input type="text" name="login" value="#{html_escape(login)}" /></label>
          <label>Password <input type="password" name="password" value="phase37-password" /></label>
          <label>
            auth_time seconds ago
            <input type="text" name="auth_time_seconds_ago" value="#{html_escape(auth_time_seconds_ago)}" />
          </label>
          <button type="submit" class="login-submit">Sign in</button>
        </form>
      </body>
    </html>
    """

    send_resp(conn, 200, html)
  end

  def create(conn, params) do
    login =
      params
      |> Map.get("login", "generated-host-user")
      |> normalize_login()

    return_to = Map.get(params, "return_to", "/lockspire/authorize")

    conn =
      conn
      |> put_session("current_account_id", login)
      |> maybe_put_auth_time(params["auth_time_seconds_ago"])

    redirect(conn, to: safe_return_to(return_to))
  end

  defp safe_return_to(nil), do: "/lockspire/authorize"
  defp safe_return_to(""), do: "/lockspire/authorize"
  defp safe_return_to("/" <> _ = path), do: path
  defp safe_return_to(_), do: "/lockspire/authorize"

  defp maybe_put_auth_time(conn, nil), do: conn
  defp maybe_put_auth_time(conn, ""), do: delete_session(conn, "current_auth_time_unix")

  defp maybe_put_auth_time(conn, value) do
    case Integer.parse(to_string(value)) do
      {seconds_ago, ""} when seconds_ago >= 0 ->
        put_session(
          conn,
          "current_auth_time_unix",
          DateTime.utc_now() |> DateTime.add(-seconds_ago, :second) |> DateTime.to_unix()
        )

      _other ->
        delete_session(conn, "current_auth_time_unix")
    end
  end

  defp normalize_login(""), do: "generated-host-user"
  defp normalize_login(value), do: to_string(value)

  defp html_escape(value) do
    value
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end
end
