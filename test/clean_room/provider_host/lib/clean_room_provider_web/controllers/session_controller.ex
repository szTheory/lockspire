defmodule CleanRoomProviderWeb.SessionController do
  use Phoenix.Controller, formats: [:html]
  import Plug.Conn

  def new(conn, params) do
    interaction_id = Map.get(params, "interaction_id", "")
    csrf = Plug.CSRFProtection.get_csrf_token()

    send_resp(
      conn,
      200,
      "<form method=\"post\" action=\"/login\"><input name=\"_csrf_token\" value=\"#{escape(csrf)}\"><input name=\"return_to\" value=\"/lockspire/authorize\"><input name=\"interaction_id\" value=\"#{escape(interaction_id)}\"><button>Sign in</button></form>"
    )
  end

  def create(conn, params) do
    conn
    |> put_session("account_id", Map.get(params, "account_id", "clean-room-user"))
    |> redirect(to: resume(params))
  end

  defp resume(%{"interaction_id" => id}) when is_binary(id) and id != "",
    do: "/lockspire/interactions/#{URI.encode(id, &URI.char_unreserved?/1)}"

  defp resume(_params), do: "/lockspire/authorize"

  defp escape(value) when is_binary(value),
    do: value |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
end
