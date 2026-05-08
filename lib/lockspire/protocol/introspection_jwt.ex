defmodule Lockspire.Protocol.IntrospectionJwt do
  @moduledoc """
  Signs RFC 9701 JWT token introspection responses from protocol-owned success context.
  """

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.SecurityProfile

  @type signing_key :: %{
          kid: String.t(),
          alg: String.t(),
          private_jwk_encrypted: binary()
        }

  @spec sign(map()) :: {:ok, String.t()} | {:error, atom()}
  def sign(
        %{
          issuer: issuer,
          issued_at: %DateTime{} = issued_at,
          success: %{
            payload: payload,
            caller: %Client{client_id: caller_client_id},
            security_profile: security_profile
          }
        } = params
      )
      when is_binary(issuer) and is_map(payload) and is_binary(caller_client_id) do
    key_store = Map.get(params, :key_store, Config.repo!())
    effective_security_profile = effective_security_profile(security_profile)
    alg = Map.get(params, :alg, default_alg(effective_security_profile))

    with {:ok, signing_key} <- fetch_key(key_store, alg, effective_security_profile),
         :ok <- ensure_allowed_alg(signing_key.alg, effective_security_profile),
         {:ok, jwk_map} <- decode_private_jwk(signing_key.private_jwk_encrypted),
         claims <- build_claims(issuer, caller_client_id, issued_at, payload),
         protected_header <- protected_header(signing_key),
         {:ok, compact} <- sign_compact_jwt(jwk_map, protected_header, claims) do
      {:ok, compact}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def sign(_params), do: {:error, :invalid_signing_key}

  defp fetch_key(key_store, alg, security_profile) do
    case key_store.fetch_active_signing_key(alg: alg, security_profile: security_profile) do
      {:ok, nil} -> {:error, :invalid_signing_key}
      {:ok, key} -> {:ok, key}
      {:error, reason} -> {:error, reason}
      nil -> {:error, :invalid_signing_key}
    end
  end

  defp ensure_allowed_alg(alg, security_profile) do
    if alg in SecurityProfile.allowed_signing_algorithms(security_profile) do
      :ok
    else
      {:error, :unsupported_signing_algorithm}
    end
  end

  defp build_claims(issuer, caller_client_id, issued_at, payload) do
    %{
      "iss" => issuer,
      "aud" => caller_client_id,
      "iat" => DateTime.to_unix(issued_at),
      "token_introspection" => stringify_keys(payload)
    }
  end

  defp protected_header(%{alg: alg, kid: kid}) do
    %{"alg" => alg, "kid" => kid, "typ" => "token-introspection+jwt"}
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)
  end

  defp stringify_keys(list) when is_list(list), do: Enum.map(list, &stringify_keys/1)
  defp stringify_keys(value), do: value

  defp effective_security_profile(%SecurityProfile.Resolved{effective_profile: profile}),
    do: profile

  defp effective_security_profile(profile) when is_atom(profile), do: profile
  defp effective_security_profile(_profile), do: :none

  defp default_alg(security_profile) do
    security_profile
    |> SecurityProfile.allowed_signing_algorithms()
    |> List.first()
    |> Kernel.||("RS256")
  end

  defp sign_compact_jwt(jwk_map, protected_header, claims) do
    {:ok,
     JOSE.JWK.from_map(jwk_map)
     |> JOSE.JWT.sign(protected_header, claims)
     |> JOSE.JWS.compact()
     |> elem(1)}
  rescue
    ErlangError -> {:error, :unsupported_signing_algorithm}
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
