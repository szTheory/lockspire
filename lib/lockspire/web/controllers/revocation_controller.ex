defmodule Lockspire.Web.RevocationController do
  @moduledoc """
  Thin `/revoke` delivery adapter for client-bound lifecycle token revocation.
  """

  use Phoenix.Controller, formats: [:json]

  alias Lockspire.Protocol.Revocation
  alias Lockspire.Protocol.Revocation.Error
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.RevocationJSON

  def create(conn, params) do
    authorization = List.first(get_req_header(conn, "authorization"))

    case Revocation.revoke(%{
           params: params,
           authorization: authorization,
           opts:
             [client_store: Repository, token_store: Repository]
             |> Keyword.put(:mtls_cert, conn.private[:lockspire_mtls_cert])
         }) do
      :ok ->
        conn
        |> put_cache_headers()
        |> put_status(:ok)
        |> json(RevocationJSON.success())

      {:error, %Error{} = error} ->
        conn
        |> put_cache_headers()
        |> maybe_put_www_authenticate(error)
        |> put_status(error.status)
        |> json(RevocationJSON.error_response(error))
    end
  end

  defp put_cache_headers(conn) do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> put_resp_header("pragma", "no-cache")
  end

  defp maybe_put_www_authenticate(conn, %Error{error: "invalid_client"}) do
    put_resp_header(conn, "www-authenticate", ~s(Basic realm="Lockspire Token Endpoint"))
  end

  defp maybe_put_www_authenticate(conn, _error), do: conn
end
