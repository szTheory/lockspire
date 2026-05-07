defmodule Lockspire.Protocol.Jarm do
  @moduledoc """
  Builds and signs JWT Secured Authorization Response Mode (JARM) responses.
  """

  alias Lockspire.Protocol.SecurityProfile

  @jarm_ttl 600

  @type signing_key :: %{
          kid: String.t(),
          alg: String.t(),
          private_jwk_encrypted: binary()
        }

  @spec sign(map(), map()) :: {:ok, String.t()} | {:error, atom()}
  def sign(
        params,
        %{
          client_id: client_id,
          issuer: issuer,
          signing_key: %{kid: kid, alg: alg, private_jwk_encrypted: private_jwk}
        } = context
      )
      when is_map(params) and is_binary(client_id) and is_binary(issuer) do
    security_profile = Map.get(context, :security_profile, :none)
    allowed_algs = SecurityProfile.allowed_signing_algorithms(security_profile)

    with :ok <- ensure_allowed_alg(alg, allowed_algs),
         {:ok, jwk_map} <- decode_private_jwk(private_jwk),
         claims <- build_claims(params, issuer, client_id),
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

  def sign(_params, _context), do: {:error, :invalid_signing_key}

  defp ensure_allowed_alg(alg, allowed_algs) do
    if alg in allowed_algs do
      :ok
    else
      {:error, :unsupported_signing_algorithm}
    end
  end

  defp build_claims(params, issuer, client_id) do
    now = DateTime.utc_now() |> DateTime.to_unix()

    base_claims = %{
      "iss" => issuer,
      "aud" => client_id,
      "exp" => now + @jarm_ttl
    }

    Map.merge(params, base_claims)
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
    case Plug.Crypto.non_executable_binary_to_term(binary, [:safe]) do
      %{} = jwk -> {:ok, jwk}
      _other -> {:error, :invalid_signing_key}
    end
  rescue
    _ -> {:error, :invalid_signing_key}
  end
end
