defmodule Lockspire.Protocol.IdToken do
  @moduledoc """
  Builds and signs minimal OIDC ID tokens with Lockspire-owned protocol claims.
  """

  alias Lockspire.Host.Claims
  alias Lockspire.Protocol.SecurityProfile

  @id_token_ttl 3600

  @type signing_key :: %{
          kid: String.t(),
          alg: String.t(),
          private_jwk_encrypted: binary()
        }

  @spec sign(map()) :: {:ok, String.t()} | {:error, atom()}
  def sign(%{
        client_id: client_id,
        issuer: issuer,
        host_claims: %Claims{} = host_claims,
        interaction_nonce: nonce,
        access_token: access_token,
        issued_at: %DateTime{} = issued_at,
        signing_key: %{kid: kid, alg: alg, private_jwk_encrypted: private_jwk}
      } = params)
      when is_binary(client_id) and is_binary(issuer) and is_binary(access_token) do
    security_profile = Map.get(params, :security_profile, :none)
    allowed_algs = SecurityProfile.allowed_signing_algorithms(security_profile)

    with :ok <- ensure_allowed_alg(alg, allowed_algs),
         {:ok, auth_time} <- validate_auth_time(Map.get(params, :auth_time)),
         sid <- Map.get(params, :sid),
         {:ok, jwk_map} <- decode_private_jwk(private_jwk),
         claims <-
           build_claims(
             host_claims,
             issuer,
             client_id,
             nonce,
             access_token,
             issued_at,
             auth_time,
             sid
           ),
         {_, compact} <-
           JOSE.JWT.sign(
             JOSE.JWK.from_map(jwk_map),
             %{"alg" => alg, "kid" => kid, "typ" => "JWT"},
             claims
           )
           |> JOSE.JWS.compact() do
      {:ok, compact}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def sign(_params), do: {:error, :invalid_signing_key}

  defp ensure_allowed_alg(alg, allowed_algs) do
    if alg in allowed_algs do
      :ok
    else
      {:error, :unsupported_signing_algorithm}
    end
  end

  defp build_claims(%Claims{} = host_claims, issuer, client_id, nonce, access_token, issued_at, auth_time, sid) do
    protocol_claims = %{
      "iss" => issuer,
      "aud" => client_id,
      "iat" => DateTime.to_unix(issued_at),
      "exp" => DateTime.add(issued_at, @id_token_ttl, :second) |> DateTime.to_unix(),
      "nonce" => nonce,
      "at_hash" => at_hash(access_token),
      "auth_time" => encode_auth_time(auth_time),
      "sid" => sid
    }

    Claims.build_id_token_claims(host_claims, protocol_claims)
  end

  defp validate_auth_time(nil), do: {:ok, nil}
  defp validate_auth_time(%DateTime{} = auth_time), do: {:ok, auth_time}
  defp validate_auth_time(_auth_time), do: {:error, :invalid_auth_time}

  defp encode_auth_time(nil), do: nil
  defp encode_auth_time(%DateTime{} = auth_time), do: DateTime.to_unix(auth_time)

  defp at_hash(access_token) do
    <<left::binary-size(16), _rest::binary>> = :crypto.hash(:sha256, access_token)
    Base.url_encode64(left, padding: false)
  end

  defp decode_private_jwk(binary) when is_binary(binary) do
    case decode_json_jwk(binary) do
      %{} = jwk -> {:ok, jwk}
      nil -> decode_erlang_jwk(binary)
    end
  end

  defp decode_private_jwk(_binary), do: {:error, :invalid_signing_key}

  defp decode_json_jwk(binary) do
    case Jason.decode(binary) do
      {:ok, %{} = jwk} -> jwk
      _other -> nil
    end
  end

  defp decode_erlang_jwk(binary) do
    try do
      case :erlang.binary_to_term(binary) do
        %{} = jwk -> {:ok, jwk}
        _other -> {:error, :invalid_signing_key}
      end
    rescue
      _ -> {:error, :invalid_signing_key}
    end
  end
end
