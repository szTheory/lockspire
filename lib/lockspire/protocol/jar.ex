defmodule Lockspire.Protocol.Jar do
  @moduledoc """
  JWT Secured Authorization Request (JAR) foundation.

  Provides unverified decoding, signature verification, and security claims
  validation of RFC 9101 request objects.
  """

  alias Lockspire.Domain.Client

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
          | :invalid_not_before
          | :invalid_issued_at

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
    case extract_public_keys(jwks) do
      {:ok, []} ->
        {:error, :no_matching_key}

      {:ok, public_keys} ->
        verify_against_keys(jwt, public_keys)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def verify_signature(_jwt, %Client{jwks: _}), do: {:error, :invalid_client_keys}
  def verify_signature(_jwt, _client), do: {:error, :invalid_client_keys}

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
    try do
      jwk = JOSE.JWK.from_map(key_map)
      {:ok, jwk}
    rescue
      _ -> {:error, :invalid_client_keys}
    catch
      _, _ -> {:error, :invalid_client_keys}
    end
  end

  defp parse_single_jwk(_), do: {:error, :invalid_client_keys}

  # Attempt verification against each candidate public key.
  # Returns {:ok, %Jar{}} on the first successful verification.
  # Returns {:error, :invalid_signature} if all keys fail.
  defp verify_against_keys(jwt, public_keys) do
    Enum.reduce_while(public_keys, {:error, :invalid_signature}, fn jwk, _acc ->
      case verify_with_single_jwk(jwt, jwk) do
        {:ok, _} = ok -> {:halt, ok}
        {:error, :invalid_signature} -> {:cont, {:error, :invalid_signature}}
      end
    end)
  end

  defp verify_with_single_jwk(jwt, public_jwk) do
    try do
      case JOSE.JWT.verify_strict(public_jwk, @allowed_algorithms, jwt) do
        {true, %JOSE.JWT{} = jwt_struct, %JOSE.JWS{} = jws_struct} ->
          {_modules, claims} = JOSE.JWT.to_map(jwt_struct)
          {_modules, header} = JOSE.JWS.to_map(jws_struct)
          {:ok, %__MODULE__{claims: claims, header: header}}

        {false, _jwt_struct, _jws_struct} ->
          {:error, :invalid_signature}

        {:error, _} ->
          {:error, :invalid_signature}
      end
    rescue
      _ -> {:error, :invalid_signature}
    catch
      _, _ -> {:error, :invalid_signature}
    end
  end

  @doc """
  Validates RFC 9101 security claims on a decoded JAR request object.

  Required options:
  - `:expected_client_id` (binary) — the `iss` claim MUST equal this value.
  - `:expected_audience` (binary) — the `aud` claim MUST contain this value.

  Optional options:
  - `:now` — a `DateTime.t/0` representing the current time for `exp`/`nbf`/`iat`
    checks. Defaults to `DateTime.utc_now/0`.
  - `:leeway` (non-negative integer, seconds) — clock skew tolerance applied to
    time-based checks. Defaults to `0`.

  Returns `:ok` on success, or `{:error, reason}` where `reason` is one of:

  - `:invalid_claims_options` — required options missing or malformed.
  - `:missing_issuer` / `:invalid_issuer` — `iss` claim missing or mismatched.
  - `:missing_audience` / `:invalid_audience` — `aud` claim missing or mismatched.
  - `:missing_expiration` / `:invalid_expiration` / `:expired_token` —
    `exp` claim missing, malformed, or in the past.
  - `:invalid_not_before` — `nbf` is present but in the future.
  - `:invalid_issued_at` — `iat` is present but in the future.

  Security: Mitigates T-21-05 (Repudiation) by binding requests to a specific
  client via `iss`, and T-21-06 (Information Disclosure) by ensuring requests
  are intended for this AS via `aud`.
  """
  @spec validate_claims(t(), keyword()) :: :ok | {:error, validate_claims_reason()}
  def validate_claims(%__MODULE__{claims: claims}, opts) when is_map(claims) and is_list(opts) do
    with {:ok, expected_client_id, expected_audience, now, leeway} <- parse_opts(opts),
         :ok <- check_issuer(claims, expected_client_id),
         :ok <- check_audience(claims, expected_audience),
         :ok <- check_expiration(claims, now, leeway),
         :ok <- check_not_before(claims, now, leeway),
         :ok <- check_issued_at(claims, now, leeway) do
      :ok
    end
  end

  def validate_claims(%__MODULE__{}, _opts), do: {:error, :invalid_claims_options}

  # ---------------------------------------------------------------------------
  # validate_claims helpers
  # ---------------------------------------------------------------------------

  defp parse_opts(opts) do
    expected_client_id = Keyword.get(opts, :expected_client_id)
    expected_audience = Keyword.get(opts, :expected_audience)
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
    leeway = Keyword.get(opts, :leeway, 0)

    cond do
      not is_binary(expected_client_id) or expected_client_id == "" ->
        {:error, :invalid_claims_options}

      not is_binary(expected_audience) or expected_audience == "" ->
        {:error, :invalid_claims_options}

      not match?(%DateTime{}, now) ->
        {:error, :invalid_claims_options}

      not (is_integer(leeway) and leeway >= 0) ->
        {:error, :invalid_claims_options}

      true ->
        {:ok, expected_client_id, expected_audience, now, leeway}
    end
  end

  defp check_issuer(claims, expected_client_id) do
    case Map.get(claims, "iss") do
      nil ->
        {:error, :missing_issuer}

      iss when is_binary(iss) ->
        if iss == expected_client_id, do: :ok, else: {:error, :invalid_issuer}

      _ ->
        {:error, :invalid_issuer}
    end
  end

  defp check_audience(claims, expected_audience) do
    case Map.get(claims, "aud") do
      nil ->
        {:error, :missing_audience}

      aud when is_binary(aud) ->
        if aud == expected_audience, do: :ok, else: {:error, :invalid_audience}

      aud when is_list(aud) ->
        if Enum.any?(aud, fn entry -> entry == expected_audience end) do
          :ok
        else
          {:error, :invalid_audience}
        end

      _ ->
        {:error, :invalid_audience}
    end
  end

  defp check_expiration(claims, now, leeway) do
    case Map.get(claims, "exp") do
      nil ->
        {:error, :missing_expiration}

      exp when is_integer(exp) ->
        now_unix = DateTime.to_unix(now)

        if exp + leeway > now_unix do
          :ok
        else
          {:error, :expired_token}
        end

      _ ->
        {:error, :invalid_expiration}
    end
  end

  defp check_not_before(claims, now, leeway) do
    case Map.get(claims, "nbf") do
      nil ->
        :ok

      nbf when is_integer(nbf) ->
        now_unix = DateTime.to_unix(now)

        if nbf - leeway <= now_unix do
          :ok
        else
          {:error, :invalid_not_before}
        end

      _ ->
        {:error, :invalid_not_before}
    end
  end

  defp check_issued_at(claims, now, leeway) do
    case Map.get(claims, "iat") do
      nil ->
        :ok

      iat when is_integer(iat) ->
        now_unix = DateTime.to_unix(now)

        if iat - leeway <= now_unix do
          :ok
        else
          {:error, :invalid_issued_at}
        end

      _ ->
        {:error, :invalid_issued_at}
    end
  end
end
