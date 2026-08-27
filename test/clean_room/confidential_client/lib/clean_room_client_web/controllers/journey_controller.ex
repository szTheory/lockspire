defmodule CleanRoomClientWeb.JourneyController do
  use Phoenix.Controller, formats: [:json]

  def status(conn, _params), do: json(conn, %{complete: false, dpop_session: nil})
end
