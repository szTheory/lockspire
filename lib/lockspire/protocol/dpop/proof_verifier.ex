defmodule Lockspire.Protocol.DPoP.ProofVerifier do
  @moduledoc false

  alias Lockspire.Protocol.DPoP.ProofParser
  alias Lockspire.Protocol.DPoPNonce
  alias Lockspire.Protocol.SecurityProfile

  @required_typ "dpop+jwt"

  @spec check_typ(map()) :: :ok | {:error, :invalid_typ}
  def check_typ(%{"typ" => @required_typ}), do: :ok
  def check_typ(_header), do: {:error, :invalid_typ}

  @spec verify_signature(String.t(), JOSE.JWK.t(), SecurityProfile.Resolved.t()) ::
          {:ok, ProofParser.decoded_proof()}
          | {:error, :invalid_typ | :invalid_signature | :unsupported_signing_algorithm}
  def verify_signature(jwt, public_jwk, %SecurityProfile.Resolved{effective_profile: profile}) do
    allowed_algs = SecurityProfile.allowed_signing_algorithms(profile)

    case JOSE.JWT.verify_strict(public_jwk, allowed_algs, jwt) do
      {true, %JOSE.JWT{} = jwt_struct, %JOSE.JWS{} = jws_struct} ->
        {_modules, claims} = JOSE.JWT.to_map(jwt_struct)
        {_modules, header} = JOSE.JWS.to_map(jws_struct)

        with :ok <- check_typ(header) do
          {:ok, %{claims: claims, header: header}}
        end

      {false, _jwt_struct, _jws_struct} ->
        unsupported_algorithm_or_invalid_signature(jwt, allowed_algs)
    end
  rescue
    _ -> {:error, :invalid_signature}
  catch
    _, _ -> {:error, :invalid_signature}
  end

  @spec validate_claims(map(), keyword()) :: :ok | {:error, atom()}
  def validate_claims(_claims, []), do: :ok

  def validate_claims(claims, opts) when is_map(claims) and is_list(opts) do
    with {:ok, method, target_uri, now, max_age, clock_skew} <- parse_validation_opts(opts),
         :ok <- check_htm(claims, method),
         :ok <- check_htu(claims, target_uri),
         :ok <- check_iat(claims, now, max_age, clock_skew),
         :ok <- check_jti(claims) do
      check_nonce(claims, opts)
    end
  end

  def validate_claims(_claims, _opts), do: {:error, :invalid_claims_options}

  defp unsupported_algorithm_or_invalid_signature(jwt, allowed_algs) do
    {_modules, header} = JOSE.JWS.to_map(JOSE.JWT.peek_protected(jwt))

    if Map.get(header, "alg") in allowed_algs do
      {:error, :invalid_signature}
    else
      {:error, :unsupported_signing_algorithm}
    end
  end

  defp parse_validation_opts(opts) do
    method = Keyword.get(opts, :method)
    target_uri = Keyword.get(opts, :target_uri)
    now = Keyword.get(opts, :now)
    max_age = Keyword.get(opts, :max_age)
    clock_skew = Keyword.get(opts, :clock_skew, 0)

    with :ok <- required_binary(method),
         :ok <- required_binary(target_uri),
         :ok <- datetime?(now),
         :ok <- nonnegative_integer?(max_age),
         :ok <- nonnegative_integer?(clock_skew) do
      {:ok, String.upcase(method), canonical_htu(target_uri), now, max_age, clock_skew}
    end
  end

  defp required_binary(value) when is_binary(value) and value != "", do: :ok
  defp required_binary(_value), do: {:error, :invalid_claims_options}

  defp datetime?(%DateTime{}), do: :ok
  defp datetime?(_value), do: {:error, :invalid_claims_options}

  defp nonnegative_integer?(value) when is_integer(value) and value >= 0, do: :ok
  defp nonnegative_integer?(_value), do: {:error, :invalid_claims_options}

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

  defp check_nonce(claims, opts) do
    case Keyword.get(opts, :nonce_purpose) do
      purpose when purpose in [:authorization_server, :resource_server] ->
        DPoPNonce.validate(
          claims,
          purpose,
          nonce_max_age: Keyword.get(opts, :nonce_max_age, Keyword.get(opts, :max_age, 300)),
          secret_key_base: Keyword.get(opts, :secret_key_base)
        )

      nil ->
        :ok

      _other ->
        {:error, :invalid_claims_options}
    end
  end

  defp canonical_htu(uri) do
    %URI{scheme: scheme, host: host} = parsed = URI.parse(uri)

    if is_nil(scheme) or is_nil(host) do
      raise ArgumentError, "invalid absolute URI"
    end

    normalized_host = String.downcase(host)
    port = normalized_port(parsed)
    path = if parsed.path in [nil, ""], do: "/", else: parsed.path

    authority =
      if is_nil(port),
        do: normalized_host,
        else: normalized_host <> ":" <> Integer.to_string(port)

    scheme <> "://" <> authority <> path
  end

  defp normalized_port(%URI{scheme: "https", port: 443}), do: nil
  defp normalized_port(%URI{scheme: "http", port: 80}), do: nil
  defp normalized_port(%URI{port: port}), do: port
end
