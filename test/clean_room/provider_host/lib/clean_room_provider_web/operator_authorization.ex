defmodule CleanRoomProviderWeb.OperatorAuthorization do
  @moduledoc false

  @behaviour Plug

  import Plug.Conn
  import Phoenix.LiveView, only: [redirect: 2]

  @impl Plug
  def init(options), do: options

  @impl Plug
  def call(conn, _options) do
    conn
    |> send_resp(:forbidden, "operator authorization required")
    |> halt()
  end

  def on_mount(_name, _params, _session, socket) do
    {:halt, redirect(socket, to: "/")}
  end
end
