defmodule Lockspire.Web.PushedAuthorizationRequestController do
  @moduledoc """
  Thin `/par` delivery adapter for pushed authorization request intake.
  """

  use Phoenix.Controller, formats: [:json]

  alias Lockspire.Protocol.PushedAuthorizationRequest
  alias Lockspire.Protocol.PushedAuthorizationRequest.Error
  alias Lockspire.Protocol.PushedAuthorizationRequest.Success
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.PushedAuthorizationRequestJSON

  def create(conn, params) do
    authorization = List.first(get_req_header(conn, "authorization"))

    case PushedAuthorizationRequest.push(%{
           params: params,
           authorization: authorization,
           opts: [client_store: Repository, pushed_authorization_request_store: Repository]
         }) do
      {:ok, %Success{} = success} ->
        conn
        |> put_cache_headers()
        |> put_status(:created)
        |> json(PushedAuthorizationRequestJSON.success_response(success))

      {:error, %Error{} = error} ->
        conn
        |> put_cache_headers()
        |> maybe_put_www_authenticate(error)
        |> put_status(error.status)
        |> json(PushedAuthorizationRequestJSON.error_response(error))
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
      ~s(Basic realm="Lockspire Pushed Authorization Request Endpoint")
    )
  end

  defp maybe_put_www_authenticate(conn, _error), do: conn
end
