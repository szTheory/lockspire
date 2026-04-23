defmodule Lockspire.Web.TokenController do
  @moduledoc """
  Thin `/token` delivery adapter for authorization code exchange.
  """

  use Phoenix.Controller, formats: [:json]

  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Protocol.TokenExchange.Error
  alias Lockspire.Protocol.TokenExchange.Success
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.TokenJSON

  def create(conn, params) do
    authorization = List.first(get_req_header(conn, "authorization"))

    case TokenExchange.exchange_authorization_code(%{
           params: params,
           authorization: authorization,
           opts: [client_store: Repository, token_store: Repository]
         }) do
      {:ok, %Success{} = success} ->
        conn
        |> put_cache_headers()
        |> put_status(:ok)
        |> json(TokenJSON.access_token_response(success))

      {:error, %Error{} = error} ->
        conn
        |> put_cache_headers()
        |> maybe_put_www_authenticate(error)
        |> put_status(error.status)
        |> json(TokenJSON.error_response(error))
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
