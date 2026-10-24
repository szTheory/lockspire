defmodule Lockspire.Web.AdminMount do
  @moduledoc false
  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, opts) do
    router = Keyword.fetch!(opts, :router)

    assert_mount_alignment!(
      effective_path!(router, conn.method, conn.request_path, conn.host),
      :http
    )

    conn
  end

  def on_mount({:mount_path, _router}, _params, _session, socket) do
    # The original page request was checked by call/2 before LiveView rendered
    # its signed static token. A connected LiveView socket only exposes the
    # websocket URI, not that page path, so mount alignment belongs at HTTP entry.
    {:cont, socket}
  end

  defp effective_path!(router, method, path, host) do
    case Lockspire.Web.AdminRoutes.effective_admin_path(router, method, path, host) do
      effective_path when is_binary(effective_path) ->
        effective_path

      _missing ->
        raise ArgumentError,
              "Lockspire admin mount alignment could not identify the compiled route"
    end
  end

  defp assert_mount_alignment!(compiled_path, entry) do
    runtime_path = runtime_admin_path!()

    if compiled_path != runtime_path do
      raise ArgumentError,
            "Lockspire admin route path #{inspect(compiled_path)} does not match " <>
              "configured :lockspire, :mount_path admin path #{inspect(runtime_path)} at #{entry} entry"
    end
  end

  defp runtime_admin_path! do
    Lockspire.Config.normalize_mount_path!(Lockspire.mount_path()) <> "/admin"
  end
end
