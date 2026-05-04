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

    case Userinfo.fetch_claims(%{
           authorization: authorization,
           dpop: List.first(get_req_header(conn, "dpop")),
           method: conn.method,
           opts: [
             token_store: Repository,
             dpop_replay_store: Repository,
             server_policy_store: Repository
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

  defp put_www_authenticate(conn, %Error{status: 401, error: "invalid_token"} = error) do
    put_resp_header(conn, "www-authenticate", www_authenticate_value(error))
  end

  defp put_www_authenticate(conn, _error), do: conn

  defp www_authenticate_value(%Error{reason_code: reason_code})
       when reason_code in [
              :invalid_dpop_authorization_scheme,
              :missing_dpop_proof,
              :invalid_jwt,
              :invalid_dpop_proof,
              :missing_dpop_ath,
              :invalid_dpop_ath,
              :dpop_binding_mismatch,
              :invalid_access_token_binding,
              :dpop_proof_replayed,
              :invalid_signature,
              :invalid_typ,
              :missing_jwk,
              :invalid_jwk,
              :invalid_claims_options,
              :missing_htm,
              :invalid_htm,
              :missing_htu,
              :invalid_htu,
              :missing_iat,
              :invalid_iat,
              :stale_iat,
              :future_iat,
              :missing_jti
            ] do
    profile =
      case Lockspire.Storage.Ecto.Repository.get_server_policy() do
        {:ok, policy} -> policy.security_profile
        _ -> :none
      end

    algorithms = Enum.join(Lockspire.Protocol.DPoP.signing_alg_values_supported(profile), " ")
    ~s(DPoP realm="Lockspire Userinfo", error="invalid_token", algs="#{algorithms}")
  end

  defp www_authenticate_value(_error),
    do: ~s(Bearer realm="Lockspire Userinfo", error="invalid_token")
end
