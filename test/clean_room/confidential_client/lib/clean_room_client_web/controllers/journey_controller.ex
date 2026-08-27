defmodule CleanRoomClientWeb.JourneyController do
  use Phoenix.Controller, formats: [:json]
  import Plug.Conn

  def status(conn, _params) do
    json(conn, get_session(conn, :journey_receipt) || %{complete: false})
  end
end
