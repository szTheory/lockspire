defmodule Lockspire.Web.IntrospectionController do
  @moduledoc """
  Thin `/introspect` delivery adapter over protocol-owned opaque token classification.
  """

  use Phoenix.Controller, formats: [:json]

  alias Lockspire.Protocol.Introspection
  alias Lockspire.Protocol.Introspection.Error
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.IntrospectionJSON

  def create(conn, params) do
    authorization = List.first(get_req_header(conn, "authorization"))

    case Introspection.introspect(%{
           params: params,
           authorization: authorization,
           opts: [client_store: Repository, token_store: Repository, consent_store: Repository]
         }) do
      {:ok, response} ->
        conn
        |> put_cache_headers()
        |> put_status(:ok)
        |> json(IntrospectionJSON.response(response))

      {:error, %Error{} = error} ->
        conn
        |> put_cache_headers()
        |> maybe_put_www_authenticate(error)
        |> put_status(error.status)
        |> json(IntrospectionJSON.error_response(error))
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
