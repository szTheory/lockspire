defmodule Lockspire.Web.DeviceAuthorizationController do
  @moduledoc """
  Thin `/device/code` delivery adapter for device authorization request intake.
  """

  use Phoenix.Controller, formats: [:json]

  alias Lockspire.Protocol.DeviceAuthorization
  alias Lockspire.Protocol.DeviceAuthorization.Error
  alias Lockspire.Protocol.DeviceAuthorization.Success
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.DeviceAuthorizationJSON

  def create(conn, params) do
    authorization = List.first(get_req_header(conn, "authorization"))

    case DeviceAuthorization.authorize(%{
           params: params,
           authorization: authorization,
           opts: [client_store: Repository, device_code_store: Repository]
         }) do
      {:ok, %Success{} = success} ->
        conn
        |> put_cache_headers()
        |> put_status(:ok)
        |> json(DeviceAuthorizationJSON.success_response(success))

      {:error, %Error{} = error} ->
        conn
        |> put_cache_headers()
        |> maybe_put_www_authenticate(error)
        |> put_status(error.status)
        |> json(DeviceAuthorizationJSON.error_response(error))
    end
  end

  defp put_cache_headers(conn) do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> put_resp_header("pragma", "no-cache")
  end

  defp maybe_put_www_authenticate(conn, %Error{error: "invalid_client"}) do
    put_resp_header(
      conn,
      "www-authenticate",
      ~s(Basic realm="Lockspire Device Authorization Endpoint")
    )
  end

  defp maybe_put_www_authenticate(conn, _error), do: conn
end
