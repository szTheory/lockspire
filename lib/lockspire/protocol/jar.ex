defmodule Lockspire.Protocol.Jar do
  @moduledoc """
  JWT Secured Authorization Request (JAR) foundation.

  Provides unverified decoding and signature verification of RFC 9101 request objects.
  """

  alias Lockspire.Domain.Client

  defstruct [:claims, :header]

  @type t :: %__MODULE__{
          claims: map(),
          header: map()
        }

  # Algorithms explicitly permitted for JAR request objects.
  # "none" is never permitted — it would allow unsigned requests to bypass auth.
  @allowed_algorithms ~w(RS256 RS384 RS512 PS256 PS384 PS512 ES256 ES384 ES512 EdDSA)

  @doc """
  Decodes a JWT string without signature verification.
  """
  @spec decode(String.t()) :: {:ok, t()} | {:error, :invalid_jwt}
  def decode(jwt) when is_binary(jwt) do
    try do
      # JOSE.JWT.peek_payload and peek_protected raise ArgumentError if malformed
      payload_struct = JOSE.JWT.peek_payload(jwt)
      protected_struct = JOSE.JWT.peek_protected(jwt)

      # to_map returns {modules_map, fields_map}
      {_modules, claims} = JOSE.JWT.to_map(payload_struct)
      {_modules, header} = JOSE.JWS.to_map(protected_struct)

      {:ok, %__MODULE__{claims: claims, header: header}}
    rescue
      _ -> {:error, :invalid_jwt}
    end
  end

  def decode(_), do: {:error, :invalid_jwt}

  @doc """
  Verifies the signature of a JAR request object using the client's registered public keys.

  Returns `{:ok, %Jar{}}` if the JWT signature is valid and the signing key matches a
  key registered for the client.

  Returns `{:error, reason}` where reason is one of:
  - `:invalid_signature` — the JWT signature does not verify against the client's keys
  - `:no_matching_key` — no key could be loaded from the client's JWKS
  - `:invalid_client_keys` — the client's `jwks` field is missing, not a map, or cannot
    be parsed as a JWK or JWK Set by JOSE

  Security: `alg=none` is never accepted. Only algorithms in the explicit allow-list are
  permitted, mitigating T-21-03 (Spoofing) and T-21-04 (Tampering).
  """
  @spec verify_signature(String.t(), Client.t()) ::
          {:ok, t()} | {:error, :invalid_signature | :no_matching_key | :invalid_client_keys}
  def verify_signature(jwt, %Client{jwks: jwks}) when is_binary(jwt) and is_map(jwks) do
    case load_jwk(jwks) do
      {:ok, public_jwk} ->
        verify_with_jwk(jwt, public_jwk)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def verify_signature(_jwt, %Client{jwks: _}), do: {:error, :invalid_client_keys}
  def verify_signature(_jwt, _client), do: {:error, :invalid_client_keys}

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp load_jwk(jwks) when is_map(jwks) do
    try do
      jwk = JOSE.JWK.from_map(jwks)
      {:ok, jwk}
    rescue
      _ -> {:error, :invalid_client_keys}
    catch
      _, _ -> {:error, :invalid_client_keys}
    end
  end

  defp verify_with_jwk(jwt, public_jwk) do
    try do
      case JOSE.JWT.verify_strict(public_jwk, @allowed_algorithms, jwt) do
        {true, %JOSE.JWT{} = jwt_struct, %JOSE.JWS{} = jws_struct} ->
          {_modules, claims} = JOSE.JWT.to_map(jwt_struct)
          {_modules, header} = JOSE.JWS.to_map(jws_struct)
          {:ok, %__MODULE__{claims: claims, header: header}}

        {false, _jwt_struct, _jws_struct} ->
          {:error, :invalid_signature}
      end
    rescue
      _ -> {:error, :invalid_signature}
    catch
      _, _ -> {:error, :invalid_signature}
    end
  end
end
