defmodule GeneratedHostAppWeb.SessionController do
  use Phoenix.Controller, formats: [:html]

  import Plug.Conn

  def new(conn, params) do
    return_to = Map.get(params, "return_to", "/lockspire/authorize")
    interaction_id = Map.get(params, "interaction_id")
    login = Map.get(params, "login", "generated-host-user")
    auth_time_seconds_ago = Map.get(params, "auth_time_seconds_ago", "30")

    html = """
    <html>
      <body>
        <h1>Generated host login</h1>
        <form method="post" action="/login">
          <input type="hidden" name="_csrf_token" value="#{html_escape(Plug.CSRFProtection.get_csrf_token())}" />
          <input type="hidden" name="return_to" value="#{html_escape(return_to)}" />
          <input type="hidden" name="interaction_id" value="#{html_escape(interaction_id || "")}" />
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
    interaction_id = normalize_optional_param(params["interaction_id"])

    conn =
      conn
      |> put_session("current_account_id", login)
      |> put_session("current_account_email", "#{login}@example.test")
      |> put_session("current_account_name", "Generated Host User")
      |> maybe_put_auth_time(params["auth_time_seconds_ago"])

    redirect(conn, to: resume_path(return_to, interaction_id))
  end

  defp safe_return_to(nil), do: "/lockspire/authorize"
  defp safe_return_to(""), do: "/lockspire/authorize"
  defp safe_return_to("/" <> _ = path), do: path
  defp safe_return_to(_), do: "/lockspire/authorize"

  defp resume_path(return_to, nil), do: safe_return_to(return_to)

  defp resume_path(_return_to, interaction_id) do
    "/lockspire/interactions/#{interaction_id}"
  end

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

  defp normalize_optional_param(nil), do: nil
  defp normalize_optional_param(""), do: nil
  defp normalize_optional_param(value), do: to_string(value)

  defp html_escape(value) do
    value
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end
end
