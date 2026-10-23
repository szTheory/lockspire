# Host-owned Lockspire seam
# Lockspire generates this file once, but your app owns the ongoing logic, UX, claims, and policy here.
# If you customize this file, keep those edits and reconcile future changes manually.

defmodule GeneratedHostAppWeb.OperatorAuthorization do
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
