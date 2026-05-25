defmodule Lockspire.Web.TokenController do
  @moduledoc """
  Thin `/token` delivery adapter for OAuth token exchange.
  """

  use Phoenix.Controller, formats: [:json]

  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Protocol.TokenExchange.Error
  alias Lockspire.Protocol.TokenExchange.Success
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.TokenJSON

  def create(conn, params) do
    authorization = List.first(get_req_header(conn, "authorization"))

    case TokenExchange.exchange(%{
           params: params,
           authorization: authorization,
           dpop: List.first(get_req_header(conn, "dpop")),
           method: conn.method,
           opts:
             [client_store: Repository, token_store: Repository]
             |> Keyword.put(:server_policy_store, Repository)
             |> Keyword.put(:dpop_replay_store, Repository)
             |> Keyword.put(:device_authorization_store, Repository)
             |> Keyword.put(:ciba_authorization_store, Repository)
             |> Keyword.put(:interaction_store, Repository)
             |> Keyword.put(:key_store, Repository)
             |> Keyword.put(:secret_key_base, conn.secret_key_base)
             |> Keyword.put(:mtls_cert, conn.private[:lockspire_mtls_cert])
         }) do
      {:ok, %Success{} = success} ->
        conn
        |> put_cache_headers()
        |> put_status(:ok)
        |> json(TokenJSON.access_token_response(success))

      {:error, %Error{} = error} ->
        conn
        |> put_cache_headers()
        |> maybe_put_dpop_nonce(error)
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

  defp maybe_put_dpop_nonce(conn, %Error{dpop_nonce: nonce})
       when is_binary(nonce) and nonce != "" do
    conn
    |> put_resp_header("dpop-nonce", nonce)
    |> expose_header("DPoP-Nonce")
  end

  defp maybe_put_dpop_nonce(conn, _error), do: conn

  defp expose_header(conn, header_name) do
    update_resp_header(conn, "access-control-expose-headers", header_name, fn existing ->
      [existing, header_name]
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()
      |> Enum.join(", ")
    end)
  end
end
