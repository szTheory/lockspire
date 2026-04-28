defmodule GeneratedHostAppWeb.SessionController do
  use Phoenix.Controller, formats: [:html]

  def new(conn, _params) do
    send_resp(conn, 200, "Generated host login")
  end
end
