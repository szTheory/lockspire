defmodule Lockspire.Protocol.Jarm do
  @moduledoc """
  Core JARM (JWT Secured Authorization Response Mode) signer utility.
  """

  alias Lockspire.Config

  @type signing_error :: :invalid_signing_key | :invalid_algorithm | term()

  @doc """
  Signs the given authorization response parameters into a JWS.
  """
  @spec sign(map(), map()) :: {:ok, String.t()} | {:error, signing_error()}
  def sign(response_params, context) do
    client = Map.fetch!(context, :client)
    issuer = Map.fetch!(context, :issuer)
    key_store = Map.get(context, :key_store, Config.repo!())

    alg_atom = client.authorization_signed_response_alg || :RS256
    alg = to_string(alg_atom)
    
    if alg == "none" do
      {:error, :invalid_algorithm}
    else
      with {:ok, signing_key} <- fetch_key(key_store, alg, client.security_profile),
           {:ok, jwk_map} <- decode_private_jwk(signing_key.private_jwk_encrypted),
           claims <- build_claims(response_params, issuer, client.client_id),
           {_, compact} <-
             JOSE.JWT.sign(
               JOSE.JWK.from_map(jwk_map),
               %{"alg" => signing_key.alg, "kid" => signing_key.kid, "typ" => "JWT"},
               claims
             )
             |> JOSE.JWS.compact() do
        {:ok, compact}
      else
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp fetch_key(key_store, alg, security_profile) do
    case key_store.fetch_active_signing_key(alg: alg, security_profile: security_profile) do
      {:ok, nil} -> {:error, :invalid_signing_key}
      {:ok, key} -> {:ok, key}
      {:error, reason} -> {:error, reason}
      nil -> {:error, :invalid_signing_key}
    end
  end

  defp build_claims(params, issuer, client_id) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    exp = now + 600

    base_claims = %{
      "iss" => issuer,
      "aud" => client_id,
      "exp" => exp
    }

    string_params =
      for {k, v} <- params, into: %{} do
        {to_string(k), v}
      end

    Map.merge(string_params, base_claims)
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
