defmodule Lockspire.Web.UserinfoController do
  @moduledoc """
  Thin `/userinfo` delivery adapter over protocol-owned bearer validation.
  """

  use Phoenix.Controller, formats: [:json]

  alias Lockspire.Protocol.Userinfo
  alias Lockspire.Protocol.Userinfo.Error
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.ProtectedResourceChallenge
  alias Lockspire.Web.UserinfoJSON

  def show(conn, _params) do
    authorization = List.first(get_req_header(conn, "authorization"))

    case Userinfo.fetch_claims(%{
           authorization: authorization,
           dpop: List.first(get_req_header(conn, "dpop")),
           method: conn.method,
           opts: [
             token_store: Repository,
             dpop_replay_store: Repository,
             server_policy_store: Repository,
             secret_key_base: conn.secret_key_base,
             mtls_cert: conn.private[:lockspire_mtls_cert]
           ]
         }) do
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

  defp put_www_authenticate(conn, %Error{status: 401, error: "use_dpop_nonce"} = error) do
    ProtectedResourceChallenge.put_dpop_challenge(conn, error, realm: "Lockspire Userinfo")
  end

  defp put_www_authenticate(
         conn,
         %Error{status: 401, error: "invalid_token", reason_code: reason_code} = error
       ) do
    if ProtectedResourceChallenge.dpop_reason_code?(reason_code) do
      ProtectedResourceChallenge.put_dpop_challenge(conn, error, realm: "Lockspire Userinfo")
    else
      put_resp_header(
        conn,
        "www-authenticate",
        ~s(Bearer realm="Lockspire Userinfo", error="invalid_token")
      )
    end
  end

  defp put_www_authenticate(conn, %Error{status: 401}),
    do:
      put_resp_header(
        conn,
        "www-authenticate",
        ~s(Bearer realm="Lockspire Userinfo", error="invalid_token")
      )

  defp put_www_authenticate(conn, _error), do: conn
end
