defmodule CleanRoomProviderWeb.OperatorAuthorization do
  @moduledoc false

  import Plug.Conn

  def init(options), do: options

  def call(conn, _options) do
    conn
    |> send_resp(:forbidden, "operator authorization required")
    |> halt()
  end
end
