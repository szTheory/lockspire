# credo:disable-for-this-file
defmodule Lockspire.Protocol.DPoP do
  @moduledoc """
  DPoP proof decoding, verification, and proof-key thumbprint helpers.

  This module owns the protocol-sensitive JOSE work for DPoP proofs so later
  token and protected-resource flows can depend on one validator.
  """

  alias Lockspire.Protocol.SecurityProfile

  defstruct [:claims, :header, :public_jwk, :jkt]

  @type t :: %__MODULE__{
          claims: map(),
          header: map(),
          public_jwk: JOSE.JWK.t() | nil,
          jkt: String.t() | nil
        }

  @type validate_reason ::
          :invalid_jwt
          | :invalid_signature
          | :invalid_typ
          | :missing_jwk
          | :invalid_jwk
          | :invalid_claims_options
          | :missing_htm
          | :invalid_htm
          | :missing_htu
          | :invalid_htu
          | :missing_iat
          | :invalid_iat
          | :stale_iat
          | :future_iat
          | :missing_jti
          | :unsupported_signing_algorithm

  @required_typ "dpop+jwt"

  # Exported as `def signing_alg_values_supported/0` for later discovery/challenge reuse.
  @spec signing_alg_values_supported() :: [String.t()]
  def signing_alg_values_supported(), do: SecurityProfile.allowed_signing_algorithms(:none)

  @spec signing_alg_values_supported(SecurityProfile.Resolved.t() | :fapi_2_0_security | :none) ::
          [String.t()]
  def signing_alg_values_supported(%SecurityProfile.Resolved{effective_profile: profile}),
    do: SecurityProfile.allowed_signing_algorithms(profile)

  def signing_alg_values_supported(profile) when is_atom(profile),
    do: SecurityProfile.allowed_signing_algorithms(profile)

  # Exported as `def access_token_ath/1` so ath hashing stays canonical across surfaces.
  @spec access_token_ath(String.t()) :: String.t()
  def access_token_ath(access_token) when is_binary(access_token) do
    access_token
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.url_encode64(padding: false)
  end

  @spec decode(String.t()) :: {:ok, t()} | {:error, :invalid_jwt}
  def decode(jwt) when is_binary(jwt) do
    try do
      payload_struct = JOSE.JWT.peek_payload(jwt)
      protected_struct = JOSE.JWT.peek_protected(jwt)
      {_modules, claims} = JOSE.JWT.to_map(payload_struct)
      {_modules, header} = JOSE.JWS.to_map(protected_struct)

      {:ok, %__MODULE__{claims: claims, header: header}}
    rescue
      _ -> {:error, :invalid_jwt}
    catch
      _, _ -> {:error, :invalid_jwt}
    end
  end

  def decode(_), do: {:error, :invalid_jwt}

  @spec validate_proof(String.t(), keyword()) :: {:ok, t()} | {:error, validate_reason()}
  def validate_proof(jwt, opts \\ [])
  def validate_proof(jwt, opts) when is_binary(jwt) do
    security_profile = Keyword.get(opts, :security_profile, %SecurityProfile.Resolved{})

    with {:ok, %__MODULE__{} = decoded} <- decode(jwt),
         :ok <- check_typ(decoded.header),
         {:ok, public_jwk} <- header_public_jwk(decoded.header),
         {:ok, %__MODULE__{} = verified} <- verify_signature(jwt, public_jwk, security_profile),
         :ok <- validate_claims(verified.claims, opts) do
      {:ok,
       %__MODULE__{
         verified
         | public_jwk: public_jwk,
           jkt: public_jwk |> thumbprint!()
       }}
    end
  end

  def validate_proof(_jwt, _opts), do: {:error, :invalid_jwt}

  @spec thumbprint(JOSE.JWK.t() | map()) :: {:ok, String.t()} | {:error, :invalid_jwk}
  def thumbprint(%JOSE.JWK{} = jwk) do
    {:ok, thumbprint!(JOSE.JWK.to_public(jwk))}
  rescue
    _ -> {:error, :invalid_jwk}
  catch
    _, _ -> {:error, :invalid_jwk}
  end

  def thumbprint(jwk_map) when is_map(jwk_map) do
    with {:ok, public_jwk} <- parse_header_jwk(jwk_map) do
      thumbprint(public_jwk)
    end
  end

  def thumbprint(_), do: {:error, :invalid_jwk}

  defp validate_claims(_claims, []), do: :ok

  defp validate_claims(claims, opts) when is_map(claims) and is_list(opts) do
    with {:ok, method, target_uri, now, max_age, clock_skew} <- parse_validation_opts(opts),
         :ok <- check_htm(claims, method),
         :ok <- check_htu(claims, target_uri),
         :ok <- check_iat(claims, now, max_age, clock_skew),
         :ok <- check_jti(claims) do
      :ok
    end
  end

  defp validate_claims(_claims, _opts), do: {:error, :invalid_claims_options}

  defp verify_signature(jwt, public_jwk, %SecurityProfile.Resolved{effective_profile: profile}) do
    allowed_algs = SecurityProfile.allowed_signing_algorithms(profile)

    try do
      case JOSE.JWT.verify_strict(public_jwk, allowed_algs, jwt) do
        {true, %JOSE.JWT{} = jwt_struct, %JOSE.JWS{} = jws_struct} ->
          {_modules, claims} = JOSE.JWT.to_map(jwt_struct)
          {_modules, header} = JOSE.JWS.to_map(jws_struct)

          case check_typ(header) do
            :ok -> {:ok, %__MODULE__{claims: claims, header: header}}
            {:error, _} = error -> error
          end

        {false, _jwt_struct, _jws_struct} ->
          # verify_strict returns false if the algorithm is not in the list
          {_modules, header} = JOSE.JWS.to_map(JOSE.JWT.peek_protected(jwt))
          alg = Map.get(header, "alg")

          if alg not in allowed_algs do
            {:error, :unsupported_signing_algorithm}
          else
            {:error, :invalid_signature}
          end
      end
    rescue
      _ -> {:error, :invalid_signature}
    catch
      _, _ -> {:error, :invalid_signature}
    end
  end

  defp check_typ(%{"typ" => @required_typ}), do: :ok
  defp check_typ(_header), do: {:error, :invalid_typ}

  defp header_public_jwk(%{"jwk" => jwk_map}) when is_map(jwk_map), do: parse_header_jwk(jwk_map)
  defp header_public_jwk(_header), do: {:error, :missing_jwk}

  defp parse_header_jwk(%{"kty" => "oct"}), do: {:error, :invalid_jwk}

  defp parse_header_jwk(jwk_map) when is_map(jwk_map) do
    try do
      jwk = JOSE.JWK.from_map(jwk_map)
      public_jwk = JOSE.JWK.to_public(jwk)
      {_modules, public_map} = JOSE.JWK.to_public_map(jwk)

      if Map.equal?(public_map, jwk_map) do
        {:ok, public_jwk}
      else
        {:error, :invalid_jwk}
      end
    rescue
      _ -> {:error, :invalid_jwk}
    catch
      _, _ -> {:error, :invalid_jwk}
    end
  end

  defp parse_header_jwk(_), do: {:error, :invalid_jwk}

  defp parse_validation_opts(opts) do
    method = Keyword.get(opts, :method)
    target_uri = Keyword.get(opts, :target_uri)
    now = Keyword.get(opts, :now)
    max_age = Keyword.get(opts, :max_age)
    clock_skew = Keyword.get(opts, :clock_skew, 0)

    cond do
      not (is_binary(method) and method != "") ->
        {:error, :invalid_claims_options}

      not (is_binary(target_uri) and target_uri != "") ->
        {:error, :invalid_claims_options}

      not match?(%DateTime{}, now) ->
        {:error, :invalid_claims_options}

      not (is_integer(max_age) and max_age >= 0) ->
        {:error, :invalid_claims_options}

      not (is_integer(clock_skew) and clock_skew >= 0) ->
        {:error, :invalid_claims_options}

      true ->
        {:ok, String.upcase(method), canonical_htu(target_uri), now, max_age, clock_skew}
    end
  end

  defp check_htm(%{"htm" => htm}, expected_method) when is_binary(htm) do
    if String.upcase(htm) == expected_method, do: :ok, else: {:error, :invalid_htm}
  end

  defp check_htm(%{"htm" => _}, _expected_method), do: {:error, :invalid_htm}
  defp check_htm(_claims, _expected_method), do: {:error, :missing_htm}

  defp check_htu(%{"htu" => htu}, expected_htu) when is_binary(htu) do
    if canonical_htu(htu) == expected_htu, do: :ok, else: {:error, :invalid_htu}
  rescue
    _ -> {:error, :invalid_htu}
  end

  defp check_htu(%{"htu" => _}, _expected_htu), do: {:error, :invalid_htu}
  defp check_htu(_claims, _expected_htu), do: {:error, :missing_htu}

  defp check_iat(%{"iat" => iat}, now, max_age, clock_skew) when is_integer(iat) do
    now_unix = DateTime.to_unix(now)

    cond do
      iat > now_unix + clock_skew -> {:error, :future_iat}
      iat < now_unix - max_age -> {:error, :stale_iat}
      true -> :ok
    end
  end

  defp check_iat(%{"iat" => _}, _now, _max_age, _clock_skew), do: {:error, :invalid_iat}
  defp check_iat(_claims, _now, _max_age, _clock_skew), do: {:error, :missing_iat}

  defp check_jti(%{"jti" => jti}) when is_binary(jti) and jti != "", do: :ok
  defp check_jti(_claims), do: {:error, :missing_jti}

  defp canonical_htu(uri) do
    %URI{scheme: scheme, host: host} = parsed = URI.parse(uri)

    if is_nil(scheme) or is_nil(host) do
      raise ArgumentError, "invalid absolute URI"
    end

    normalized_host = String.downcase(host)
    port = normalized_port(parsed)
    path = if parsed.path in [nil, ""], do: "/", else: parsed.path
    authority = if is_nil(port), do: normalized_host, else: normalized_host <> ":" <> Integer.to_string(port)

    scheme <> "://" <> authority <> path
  end

  defp normalized_port(%URI{scheme: "https", port: 443}), do: nil
  defp normalized_port(%URI{scheme: "http", port: 80}), do: nil
  defp normalized_port(%URI{port: port}), do: port

  defp thumbprint!(%JOSE.JWK{} = jwk) do
    jwk
    |> JOSE.JWK.thumbprint()
    |> IO.iodata_to_binary()
  end
end
