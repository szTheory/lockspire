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
    account_id = Map.get(params, "account_id", "clean-room-user")
    auth_time = host_auth_time(account_id)

    conn
    |> put_session("account_id", account_id)
    |> put_session("current_auth_time_unix", auth_time)
    |> redirect(to: resume(params))
  end

  defp host_auth_time("clean-room-selected-stale") do
    fixture_auth_time(
      "CLEAN_ROOM_SELECTED_STALE_AUTH_TIME_FILE",
      "selected-stale-auth-time-unix.txt"
    )
  end

  defp host_auth_time("clean-room-selected-fresh") do
    fixture_auth_time(
      "CLEAN_ROOM_SELECTED_FRESH_AUTH_TIME_FILE",
      "selected-fresh-auth-time-unix.txt"
    )
  end

  defp host_auth_time(_account_id), do: System.system_time(:second)

  defp fixture_auth_time(environment_name, filename) do
    root = System.get_env("CLEAN_ROOM_SELECTED_AUTH_TIME_ROOT")
    configured = System.get_env(environment_name)

    unless is_binary(root) and Path.type(root) == :absolute and
             configured == Path.join(root, filename) and
             File.regular?(Path.join(root, ".lockspire-clean-room-owner")) do
      raise "invalid clean-room selected authentication-time fixture path"
    end

    with {:ok, %{type: :regular}} <- File.lstat(configured),
         {:ok, contents} <- File.read(configured),
         value when is_binary(value) <- String.trim(contents),
         true <- Regex.match?(~r/\A\d{1,12}\z/, value),
         {unix, ""} <- Integer.parse(value) do
      unix
    else
      _other -> raise "invalid clean-room selected authentication-time fixture value"
    end
  end

  defp resume(%{"interaction_id" => id}) when is_binary(id) and id != "",
    do: "/lockspire/interactions/#{URI.encode(id, &URI.char_unreserved?/1)}"

  defp resume(_params), do: "/lockspire/authorize"

  defp escape(value) when is_binary(value),
    do: value |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
end
