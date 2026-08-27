defmodule CleanRoomProviderWeb.SessionController do
  use Phoenix.Controller, formats: [:html]
  import Plug.Conn

  def new(conn, params) do
    return_to = Map.get(params, "return_to", "/lockspire/authorize")
    interaction_id = Map.get(params, "interaction_id", "")
    csrf = Plug.CSRFProtection.get_csrf_token()

    send_resp(conn, 200, "<form method=\"post\" action=\"/login\"><input name=\"_csrf_token\" value=\"#{csrf}\"><input name=\"return_to\" value=\"#{return_to}\"><input name=\"interaction_id\" value=\"#{interaction_id}\"><button>Sign in</button></form>")
  end

  def create(conn, params) do
    conn
    |> put_session("account_id", "clean-room-user")
    |> redirect(to: resume(params))
  end

  defp resume(%{"interaction_id" => id}) when is_binary(id) and id != "", do: "/lockspire/interactions/#{id}"
  defp resume(%{"return_to" => "/" <> _ = path}), do: path
  defp resume(_params), do: "/lockspire/authorize"
end
