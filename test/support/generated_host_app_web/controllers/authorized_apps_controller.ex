defmodule GeneratedHostAppWeb.AuthorizedAppsController do
  use Phoenix.Controller, formats: [:html]

  def index(conn, _params) do
    send_resp(conn, 200, "Authorized apps")
  end

  def delete(conn, _params) do
    send_resp(conn, 204, "")
  end
end
