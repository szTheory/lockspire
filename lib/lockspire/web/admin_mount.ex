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

  def on_mount({:mount_path, router}, _params, _session, socket) do
    {path, host} = request_context(socket)
    assert_mount_alignment!(effective_path!(router, "GET", path, host), :live_view)
    {:cont, socket}
  end

  defp request_context(%{private: %{connect_info: %Plug.Conn{} = conn}}) do
    {conn.request_path, conn.host}
  end

  defp request_context(%{host_uri: uri}) do
    {uri.path, uri.host}
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
