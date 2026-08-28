defmodule Lockspire.Protocol.Jar do
  @moduledoc """
  JWT Secured Authorization Request (JAR) foundation.

  Provides unverified decoding, signature verification, and security claims
  validation of RFC 9101 request objects.
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.PrivateJwk
  alias Lockspire.Protocol.RequestObject.Claims

  defstruct [:claims, :header]

  @type t :: %__MODULE__{
          claims: map(),
          header: map()
        }

  @type validate_claims_reason ::
          :invalid_claims_options
          | :missing_issuer
          | :invalid_issuer
          | :missing_audience
          | :invalid_audience
          | :missing_expiration
          | :invalid_expiration
          | :expired_token
          | :expiration_too_far
          | :invalid_not_before
          | :invalid_issued_at

  @doc """
  Decrypts a nested JWE request object to return the inner JWS string.
  If the input is not a JWE (e.g. it is a 3-part JWS), it returns `{:ok, jwt}` immediately.
  """
  @spec decrypt(String.t(), [Lockspire.Domain.SigningKey.t()]) ::
          {:ok, String.t()} | {:error, :decryption_failed}
  def decrypt(jwt, decryption_keys) when is_binary(jwt) do
    if length(String.split(jwt, ".")) == 5 do
      Enum.reduce_while(decryption_keys, {:error, :decryption_failed}, fn key, _acc ->
        try do
          with {:ok, jwk_map} <- PrivateJwk.decode(key.private_jwk_encrypted),
               jwk <- JOSE.JWK.from_map(jwk_map),
               {plain_text, %JOSE.JWE{}} <- JOSE.JWK.block_decrypt(jwt, jwk) do
            {:halt, {:ok, plain_text}}
          else
            _ -> {:cont, {:error, :decryption_failed}}
          end
        rescue
          _ -> {:cont, {:error, :decryption_failed}}
        catch
          _, _ -> {:cont, {:error, :decryption_failed}}
        end
      end)
    else
      {:ok, jwt}
    end
  end

  @doc """
  Decodes a JWT string without signature verification.
  """
  @spec decode(String.t()) :: {:ok, t()} | {:error, :invalid_jwt}
  def decode(jwt) when is_binary(jwt) do
    # JOSE.JWT.peek_payload and peek_protected raise ArgumentError if malformed.
    payload_struct = JOSE.JWT.peek_payload(jwt)
    protected_struct = JOSE.JWT.peek_protected(jwt)

    # to_map returns {modules_map, fields_map}.
    {_modules, claims} = JOSE.JWT.to_map(payload_struct)
    {_modules, header} = JOSE.JWS.to_map(protected_struct)

    {:ok, %__MODULE__{claims: claims, header: header}}
  rescue
    _ -> {:error, :invalid_jwt}
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
  - `:invalid_typ` — the JWT protected header has a `typ` value other than
    `oauth-authz-req+jwt` or `jwt` (case-insensitive). RFC 9101 §10.8 cross-JWT-confusion
    mitigation.

  Security: `alg=none` is never accepted. Only algorithms in the explicit allow-list are
  permitted, preventing unsigned spoofing and algorithm-confusion tampering.
  """
  @spec verify_signature(String.t(), Client.t(), [String.t()]) ::
          {:ok, t()}
          | {:error, :invalid_signature | :no_matching_key | :invalid_client_keys | :invalid_typ}
  def verify_signature(jwt, %Client{jwks: jwks}, allowed_algorithms)
      when is_binary(jwt) and is_map(jwks) and is_list(allowed_algorithms) do
    case extract_public_keys(jwks) do
      {:ok, []} ->
        {:error, :no_matching_key}

      {:ok, public_keys} ->
        verify_against_keys(jwt, public_keys, allowed_algorithms)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def verify_signature(_jwt, %Client{jwks: _}, _allowed), do: {:error, :invalid_client_keys}
  def verify_signature(_jwt, _client, _allowed), do: {:error, :invalid_client_keys}

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  # Normalise client.jwks into a flat list of individual JOSE.JWK structs.
  # Supports both a single JWK map (RFC 7517) and a JWK Set with a "keys" array.
  defp extract_public_keys(%{"keys" => keys} = _jwks_set) when is_list(keys) do
    parsed =
      Enum.reduce_while(keys, {:ok, []}, fn key_map, {:ok, acc} ->
        case parse_single_jwk(key_map) do
          {:ok, jwk} -> {:cont, {:ok, [jwk | acc]}}
          {:error, _} -> {:halt, {:error, :invalid_client_keys}}
        end
      end)

    case parsed do
      {:ok, list} -> {:ok, Enum.reverse(list)}
      error -> error
    end
  end

  defp extract_public_keys(jwk_map) when is_map(jwk_map) do
    case parse_single_jwk(jwk_map) do
      {:ok, jwk} -> {:ok, [jwk]}
      {:error, _} -> {:error, :invalid_client_keys}
    end
  end

  defp parse_single_jwk(key_map) when is_map(key_map) do
    {:ok, JOSE.JWK.from_map(key_map)}
  rescue
    _ -> {:error, :invalid_client_keys}
  catch
    _, _ -> {:error, :invalid_client_keys}
  end

  defp parse_single_jwk(_), do: {:error, :invalid_client_keys}

  # Attempt verification against each candidate public key.
  # Returns {:ok, %Jar{}} on the first successful verification.
  # Returns {:error, :invalid_signature} if all keys fail.
  # Returns {:error, :invalid_typ} immediately if the typ header is rejected — this is a
  # definitive rejection, not a "try next key" situation.
  defp verify_against_keys(jwt, public_keys, allowed_algorithms) do
    Enum.reduce_while(public_keys, {:error, :invalid_signature}, fn jwk, _acc ->
      case verify_with_single_jwk(jwt, jwk, allowed_algorithms) do
        {:ok, _} = ok -> {:halt, ok}
        {:error, :invalid_typ} = err -> {:halt, err}
        {:error, :invalid_signature} -> {:cont, {:error, :invalid_signature}}
      end
    end)
  end

  defp verify_with_single_jwk(jwt, public_jwk, allowed_algorithms) do
    case JOSE.JWT.verify_strict(public_jwk, allowed_algorithms, jwt) do
      {true, %JOSE.JWT{} = jwt_struct, %JOSE.JWS{} = jws_struct} ->
        {_modules, claims} = JOSE.JWT.to_map(jwt_struct)
        {_modules, header} = JOSE.JWS.to_map(jws_struct)

        case check_typ(header) do
          :ok -> {:ok, %__MODULE__{claims: claims, header: header}}
          {:error, _} = err -> err
        end

      {false, _jwt_struct, _jws_struct} ->
        {:error, :invalid_signature}
    end
  rescue
    _ -> {:error, :invalid_signature}
  catch
    _, _ -> {:error, :invalid_signature}
  end

  # Permissive: absent typ allowed (RFC 9101 §10.8 SHOULD, not MUST).
  # Recognized values (case-insensitive): "oauth-authz-req+jwt" (canonical), "jwt" (legacy).
  # Rejecting every other value as :invalid_typ closes JWT-type confusion at the
  # HTTP boundary (RFC 9101 §10.8).
  defp check_typ(%{"typ" => typ}) when is_binary(typ) do
    if String.downcase(typ) in ["oauth-authz-req+jwt", "jwt"],
      do: :ok,
      else: {:error, :invalid_typ}
  end

  defp check_typ(_), do: :ok

  @doc """
  Validates RFC 9101 security claims on a decoded JAR request object.

  Required options:
  - `:expected_client_id` (binary) — the `iss` claim MUST equal this value.
  - `:expected_audience` (binary) — the `aud` claim MUST contain this value.

  Optional options:
  - `:now` — a `DateTime.t()` representing the current time for `exp`/`nbf`/`iat`
    checks. Defaults to `DateTime.utc_now/0`.
  - `:leeway` (non-negative integer, seconds) — clock skew tolerance applied to
    time-based checks. Defaults to `0`.
  - `:max_age` (positive integer, seconds) — caps the time between `now` and `exp`.
    When set, returns `{:error, :expiration_too_far}` if `exp - now > max_age + leeway`.
    When nil/absent, no ceiling is applied.

  Returns `:ok` on success, or `{:error, reason}` where `reason` is one of:

  - `:invalid_claims_options` — required options missing or malformed.
  - `:missing_issuer` / `:invalid_issuer` — `iss` claim missing or mismatched.
  - `:missing_audience` / `:invalid_audience` — `aud` claim missing or mismatched.
  - `:missing_expiration` / `:invalid_expiration` / `:expired_token` —
    `exp` claim missing, malformed, or in the past.
  - `:expiration_too_far` — `exp` is farther in the future than `:max_age + leeway`
    permits (RFC 9101 replay-window mitigation).
  - `:invalid_not_before` — `nbf` is present but in the future.
  - `:invalid_issued_at` — `iat` is present but in the future.

  Security: binds requests to a specific client via `iss` and prevents
  cross-issuer disclosure by ensuring requests
  are intended for this AS via `aud`.
  """
  @spec validate_claims(t(), keyword()) :: :ok | {:error, validate_claims_reason()}
  def validate_claims(%__MODULE__{claims: claims}, opts) when is_map(claims) and is_list(opts) do
    Claims.validate(claims, opts)
  end

  def validate_claims(%__MODULE__{}, _opts), do: {:error, :invalid_claims_options}
end
