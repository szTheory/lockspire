defmodule CleanRoomClientWeb.JourneyController do
  use Phoenix.Controller, formats: [:json]
  import Plug.Conn

  def status(conn, _params) do
    json(conn, get_session(conn, :journey_receipt) || %{complete: false})
  end

  def callback_attempts(conn, _params) do
    json(conn, %{token_exchange_attempts: get_session(conn, :token_exchange_attempts, 0)})
  end
end
