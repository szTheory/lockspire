defmodule <%= @web_module %>.OperatorAuthorization do
  @moduledoc """
  Host-owned authorization for Lockspire's admin LiveViews.

  This generated implementation denies all access until the host replaces it with
  its own current staff identity and authorization policy.
  """

  @behaviour Plug

  import Plug.Conn, only: [halt: 1, send_resp: 3]
  import Phoenix.LiveView, only: [redirect: 2]

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    conn
    |> send_resp(:forbidden, "Admin access is not configured.")
    |> halt()
  end

  @doc false
  def on_mount(_name, _params, _session, socket) do
    {:halt, redirect(socket, to: "/")}
  end
end
