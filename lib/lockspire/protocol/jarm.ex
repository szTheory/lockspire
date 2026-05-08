defmodule Lockspire.Protocol.Jarm do
  @moduledoc """
  Core JARM (JWT Secured Authorization Response Mode) encoder.
  """

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.Jarm.ClientKeyResolver

  @type signing_error :: :invalid_signing_key | :invalid_algorithm | term()
  @type encoding_error ::
          signing_error()
          | :invalid_jarm_client_metadata
          | :jarm_encryption_key_fetch_failed
          | :jarm_encryption_key_unavailable
          | :unsupported_jarm_encryption_alg
          | :unsupported_jarm_encryption_enc

  @doc """
  Encodes the given authorization response as signed-only JARM or nested encrypted JARM.
  """
  @spec encode(map(), map()) :: {:ok, String.t()} | {:error, encoding_error()}
  def encode(response_params, context) do
    client = Map.fetch!(context, :client)

    with {:ok, signed_jwt} <- sign(response_params, context),
         {:ok, output} <- maybe_encrypt(signed_jwt, client, context) do
      {:ok, output}
    end
  end

  @doc """
  Signs the given authorization response parameters into a JWS.
  """
  @spec sign(map(), map()) :: {:ok, String.t()} | {:error, signing_error()}
  def sign(response_params, context) do
    client = Map.fetch!(context, :client)
    issuer = Map.fetch!(context, :issuer)
    key_store = Map.get(context, :key_store, Config.repo!())

    alg = signing_alg(client)

    if alg == "none" do
      {:error, :invalid_algorithm}
    else
      with {:ok, signing_key} <- fetch_key(key_store, alg, client.security_profile),
           {:ok, jwk_map} <- decode_private_jwk(signing_key.private_jwk_encrypted),
           claims <- build_claims(response_params, issuer, client.client_id),
           protected_header <- %{"alg" => signing_key.alg, "kid" => signing_key.kid, "typ" => "JWT"},
           {_, compact} <-
             JOSE.JWT.sign(JOSE.JWK.from_map(jwk_map), protected_header, claims)
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

  defp maybe_encrypt(signed_jwt, %Client{} = client, context) do
    if encrypted_response_requested?(client) do
      if is_nil(client.authorization_signed_response_alg) do
        {:error, :invalid_jarm_client_metadata}
      else
        encrypt_nested(signed_jwt, client, context)
      end
    else
      {:ok, signed_jwt}
    end
  end

  defp encrypt_nested(signed_jwt, %Client{} = client, context) do
    alg = encryption_alg(client)
    enc = encryption_enc(client)

    with {:ok, recipient_jwk, _source} <-
           ClientKeyResolver.resolve(
             client,
             %{alg: alg, enc: enc},
             client_key_resolver_opts(context)
           ),
         protected_header <- encryption_header(recipient_jwk, alg, enc),
         {_, compact} <-
           JOSE.JWE.block_encrypt(recipient_jwk, signed_jwt, protected_header)
           |> JOSE.JWE.compact() do
      {:ok, compact}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp encrypted_response_requested?(%Client{} = client) do
    not is_nil(client.authorization_encrypted_response_alg) or
      not is_nil(client.authorization_encrypted_response_enc)
  end

  defp encryption_header(recipient_jwk, alg, enc) do
    %{"alg" => alg, "enc" => enc, "cty" => "JWT"}
    |> maybe_put_kid(recipient_jwk)
  end

  defp maybe_put_kid(header, recipient_jwk) do
    {_kty, jwk_map} = JOSE.JWK.to_public_map(recipient_jwk)

    case Map.get(jwk_map, "kid") do
      kid when is_binary(kid) and kid != "" -> Map.put(header, "kid", kid)
      _other -> header
    end
  end

  defp signing_alg(%Client{} = client) do
    client.authorization_signed_response_alg
    |> normalize_alg()
    |> Kernel.||("RS256")
  end

  defp encryption_alg(%Client{} = client),
    do: normalize_alg(client.authorization_encrypted_response_alg)

  defp encryption_enc(%Client{} = client),
    do: normalize_alg(client.authorization_encrypted_response_enc)

  defp normalize_alg(nil), do: nil
  defp normalize_alg(value) when is_binary(value), do: value

  defp normalize_alg(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", "-")
  end

  defp client_key_resolver_opts(context) do
    []
    |> Keyword.put(:jwks_fetcher, Map.get(context, :jwks_fetcher, Config.jwks_fetcher()))
    |> Keyword.put(:jwks_fetcher_opts, Map.get(context, :jwks_fetcher_opts, []))
  end
end
