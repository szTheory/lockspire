defmodule Lockspire.Web.UserinfoController do
  @moduledoc """
  Thin `/userinfo` delivery adapter over protocol-owned bearer validation.
  """

  use Phoenix.Controller, formats: [:json]

  alias Lockspire.Protocol.Userinfo
  alias Lockspire.Protocol.Userinfo.Error
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.UserinfoJSON

  def show(conn, _params) do
    authorization = List.first(get_req_header(conn, "authorization"))

    case Userinfo.fetch_claims(%{authorization: authorization, opts: [token_store: Repository]}) do
      {:ok, claims} ->
        conn
        |> put_cache_headers()
        |> put_status(:ok)
        |> json(UserinfoJSON.response(claims))

      {:error, %Error{} = error} ->
        conn
        |> put_cache_headers()
        |> put_www_authenticate(error)
        |> put_status(error.status)
        |> json(UserinfoJSON.error_response(error))
    end
  end

  defp put_cache_headers(conn) do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> put_resp_header("pragma", "no-cache")
  end

  defp put_www_authenticate(conn, %Error{status: 401, error: "invalid_token"}) do
    put_resp_header(
      conn,
      "www-authenticate",
      ~s(Bearer realm="Lockspire Userinfo", error="invalid_token")
    )
  end

  defp put_www_authenticate(conn, _error), do: conn
end
