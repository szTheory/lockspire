defmodule GeneratedHostAppWeb.Plugs.RequireOperator do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{assigns: %{current_scope: %{user: %{operator?: true}}}} = conn, _opts),
    do: conn

  def call(conn, _opts) do
    conn
    |> send_resp(:forbidden, "operator authorization required")
    |> halt()
  end
end
