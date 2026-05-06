defmodule Lockspire.Web.BCAuthorizeController do
  @moduledoc """
  Thin `/bc-authorize` delivery adapter for CIBA request intake.
  """

  use Phoenix.Controller, formats: [:json]

  alias Lockspire.Protocol.BackchannelAuthentication
  alias Lockspire.Protocol.BackchannelAuthentication.Error
  alias Lockspire.Protocol.BackchannelAuthentication.Success
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.CibaAuthorizationJSON

  def create(conn, params) do
    authorization = List.first(get_req_header(conn, "authorization"))

    case BackchannelAuthentication.authorize(%{
           params: params,
           authorization: authorization,
           opts: [
             client_store: Repository,
             ciba_authorization_store: Repository
           ]
         }) do
      {:ok, %Success{} = success} ->
        conn
        |> put_cache_headers()
        |> put_status(:ok)
        |> json(CibaAuthorizationJSON.success_response(success))

      {:error, %Error{} = error} ->
        conn
        |> put_cache_headers()
        |> maybe_put_www_authenticate(error)
        |> put_status(error.status)
        |> json(CibaAuthorizationJSON.error_response(error))
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
      ~s(Basic realm="Lockspire CIBA Backchannel Authentication Endpoint")
    )
  end

  defp maybe_put_www_authenticate(conn, _error), do: conn
end
