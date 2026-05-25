defmodule Lockspire.Web.ProtectedResourceChallenge do
  @moduledoc false

  import Plug.Conn

  alias Lockspire.Protocol.DPoP
  alias Lockspire.Storage.Ecto.Repository

  @dpop_reason_codes [
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
    :missing_jti,
    :missing_dpop_nonce,
    :invalid_dpop_nonce
  ]

  def put_dpop_challenge(conn, error, opts \\ []) do
    realm = Keyword.get(opts, :realm, "Lockspire")
    profile = Keyword.get(opts, :security_profile, current_security_profile())

    conn
    |> put_resp_header("www-authenticate", www_authenticate_value(error, realm, profile))
    |> maybe_put_dpop_nonce(error)
  end

  def dpop_reason_code?(reason_code), do: reason_code in @dpop_reason_codes

  def www_authenticate_value(%{error: "use_dpop_nonce"} = error, realm, profile) do
    algorithms = Enum.join(DPoP.signing_alg_values_supported(profile), " ")

    description =
      Map.get(error, :error_description, "Resource server requires nonce in DPoP proof")

    ~s(DPoP realm="#{realm}", error="use_dpop_nonce", error_description="#{description}", algs="#{algorithms}")
  end

  def www_authenticate_value(%{challenge: :dpop, error: error} = challenge, realm, profile) do
    algorithms = Enum.join(DPoP.signing_alg_values_supported(profile), " ")

    description =
      Map.get(challenge, :error_description, "The access token is invalid or expired")

    ~s(DPoP realm="#{realm}", error="#{error}", error_description="#{description}", algs="#{algorithms}")
  end

  def www_authenticate_value(%{reason_code: reason_code}, realm, profile)
      when reason_code in @dpop_reason_codes do
    algorithms = Enum.join(DPoP.signing_alg_values_supported(profile), " ")
    ~s(DPoP realm="#{realm}", error="invalid_token", algs="#{algorithms}")
  end

  defp maybe_put_dpop_nonce(conn, %{dpop_nonce: nonce}) when is_binary(nonce) and nonce != "" do
    conn
    |> put_resp_header("dpop-nonce", nonce)
    |> expose_header("DPoP-Nonce")
    |> expose_header("WWW-Authenticate")
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

  defp current_security_profile do
    case Repository.get_server_policy() do
      {:ok, policy} -> policy.security_profile
      _ -> :none
    end
  end
end
