defmodule Lockspire.ClientRegistration.Shape do
  @moduledoc false

  @device_code "urn:ietf:params:oauth:grant-type:device_code"
  @allowed_grant_types MapSet.new([
                         "authorization_code",
                         "refresh_token",
                         @device_code,
                         "urn:ietf:params:oauth:grant-type:token-exchange"
                       ])
  @allowed_response_types MapSet.new(["code"])
  @private_key_jwt_algs MapSet.new([:RS256, :ES256, :PS256, :EdDSA])

  @type issue :: %{field: atom(), reason: atom(), detail: term()}

  @spec validate(map(), keyword()) :: :ok | {:error, [issue()]}
  def validate(attrs, opts \\ []) when is_map(attrs) do
    errors =
      []
      |> validate_client_type(attrs.client_type)
      |> validate_auth_method(attrs.client_type, attrs.auth_method)
      |> validate_grant_types(attrs.allowed_grant_types)
      |> validate_response_types(attrs.allowed_response_types)
      |> validate_grant_response_coherence(
        attrs.allowed_grant_types,
        attrs.allowed_response_types
      )
      |> validate_redirect_uris(attrs.redirect_uris, redirect_required?(attrs))
      |> validate_scopes(attrs.allowed_scopes)
      |> validate_key_source_exclusivity(attrs)
      |> validate_private_key_jwt(attrs, opts)

    case Enum.reverse(errors) do
      [] -> :ok
      issues -> {:error, issues}
    end
  end

  @spec redirect_required?(map()) :: boolean()
  def redirect_required?(%{allowed_grant_types: grants, allowed_response_types: responses}) do
    "authorization_code" in grants or "code" in responses
  end

  @spec valid_redirect_uri?(term()) :: :ok | atom()
  def valid_redirect_uri?(""), do: :blank

  def valid_redirect_uri?(uri) when is_binary(uri) do
    case URI.parse(uri) do
      %URI{scheme: nil} -> :missing_scheme
      %URI{host: nil, scheme: scheme} when scheme not in ["http", "https"] -> :invalid_scheme
      %URI{scheme: scheme} when scheme not in ["http", "https"] -> :invalid_scheme
      %URI{host: host} when host in [nil, ""] -> :missing_host
      %URI{fragment: fragment} when fragment not in [nil, ""] -> :fragment_not_allowed
      %URI{} -> if String.contains?(uri, "*"), do: :wildcard_not_allowed, else: :ok
    end
  end

  def valid_redirect_uri?(_), do: :invalid

  defp validate_client_type(errors, type) when type in [:public, :confidential], do: errors

  defp validate_client_type(errors, type),
    do: [issue(:client_type, :invalid_client_type, type) | errors]

  defp validate_auth_method(errors, :public, :none), do: errors

  defp validate_auth_method(errors, :public, method),
    do: [issue(:token_endpoint_auth_method, :invalid_token_endpoint_auth_method, method) | errors]

  defp validate_auth_method(errors, :confidential, method)
       when method in [
              :client_secret_basic,
              :client_secret_post,
              :client_secret_jwt,
              :private_key_jwt
            ],
       do: errors

  defp validate_auth_method(errors, :confidential, method),
    do: [issue(:token_endpoint_auth_method, :invalid_token_endpoint_auth_method, method) | errors]

  defp validate_auth_method(errors, _type, _method), do: errors

  defp validate_grant_types(errors, grant_types) do
    Enum.reduce(grant_types, errors, fn grant, acc ->
      if MapSet.member?(@allowed_grant_types, grant),
        do: acc,
        else: [issue(:allowed_grant_types, :invalid_grant_type, grant) | acc]
    end)
  end

  defp validate_response_types(errors, response_types) do
    Enum.reduce(response_types, errors, fn response, acc ->
      if MapSet.member?(@allowed_response_types, response),
        do: acc,
        else: [issue(:allowed_response_types, :invalid_response_type, response) | acc]
    end)
  end

  defp validate_grant_response_coherence(errors, grants, responses) do
    cond do
      "refresh_token" in grants and "authorization_code" not in grants ->
        [issue(:allowed_grant_types, :incoherent_pair, "refresh_token") | errors]

      "code" in responses and "authorization_code" not in grants ->
        [issue(:allowed_response_types, :incoherent_pair, "code") | errors]

      true ->
        errors
    end
  end

  defp validate_redirect_uris(errors, [], true),
    do: [issue(:redirect_uris, :invalid_redirect_uri, :empty) | errors]

  defp validate_redirect_uris(errors, redirect_uris, _required?) do
    Enum.reduce(redirect_uris, errors, fn uri, acc ->
      case valid_redirect_uri?(uri) do
        :ok -> acc
        reason -> [issue(:redirect_uris, :invalid_redirect_uri, reason) | acc]
      end
    end)
  end

  defp validate_scopes(errors, []), do: [issue(:allowed_scopes, :invalid_scope, :empty) | errors]

  defp validate_scopes(errors, scopes) do
    Enum.reduce(scopes, errors, fn scope, acc ->
      if scope == "openid" or valid_scope_token?(scope),
        do: acc,
        else: [issue(:allowed_scopes, :invalid_scope, scope) | acc]
    end)
  end

  defp validate_private_key_jwt(errors, %{auth_method: :private_key_jwt} = attrs, opts) do
    has_jwks = is_map(attrs.jwks)
    has_jwks_uri = is_binary(attrs.jwks_uri) and attrs.jwks_uri != ""

    errors
    |> then(fn current ->
      cond do
        not has_jwks and not has_jwks_uri ->
          [issue(:token_endpoint_auth_method, :missing_cryptographic_material, nil) | current]

        has_jwks_uri and not https_uri?(attrs.jwks_uri) ->
          [issue(:jwks_uri, :invalid_uri_scheme, nil) | current]

        true ->
          current
      end
    end)
    |> validate_inline_jwks(
      attrs.jwks,
      attrs.token_endpoint_auth_signing_alg,
      Keyword.get(opts, :private_key_jwt_algs, @private_key_jwt_algs)
    )
    |> validate_private_key_jwt_alg(attrs.token_endpoint_auth_signing_alg, opts)
  end

  defp validate_private_key_jwt(errors, attrs, opts) do
    validate_non_private_key_sources(errors, attrs, opts)
  end

  defp validate_key_source_exclusivity(errors, attrs) do
    if is_map(attrs.jwks) and is_binary(attrs.jwks_uri) and attrs.jwks_uri != "" do
      [issue(:jwks, :mutually_exclusive_with_jwks_uri, nil) | errors]
    else
      errors
    end
  end

  defp validate_non_private_key_sources(errors, attrs, opts) do
    has_jwks_uri = is_binary(attrs.jwks_uri) and attrs.jwks_uri != ""

    cond do
      has_jwks_uri and not Keyword.get(opts, :allow_jwks_uri_for_encryption, false) ->
        [issue(:jwks_uri, :unsupported_token_endpoint_auth_method, nil) | errors]

      has_jwks_uri and not https_uri?(attrs.jwks_uri) ->
        [issue(:jwks_uri, :invalid_uri_scheme, nil) | errors]

      true ->
        errors
    end
  end

  defp validate_private_key_jwt_alg(errors, nil, _opts), do: errors

  defp validate_private_key_jwt_alg(errors, alg, opts) do
    allowed = MapSet.new(Keyword.get(opts, :private_key_jwt_algs, @private_key_jwt_algs))

    if MapSet.member?(allowed, alg) do
      errors
    else
      [
        issue(:token_endpoint_auth_signing_alg, :invalid_token_endpoint_auth_signing_alg, alg)
        | errors
      ]
    end
  end

  defp validate_inline_jwks(errors, nil, _signing_alg, _allowed_algs), do: errors

  defp validate_inline_jwks(errors, jwks, signing_alg, allowed_algs) when is_map(jwks) do
    allowed_algs = MapSet.new(allowed_algs)

    if usable_public_jwk_set?(jwks, signing_alg, allowed_algs) do
      errors
    else
      [issue(:jwks, :invalid_public_jwks, nil) | errors]
    end
  end

  defp validate_inline_jwks(errors, _jwks, _signing_alg, _allowed_algs), do: errors

  defp usable_public_jwk_set?(%{"keys" => keys}, signing_alg, allowed_algs)
       when is_list(keys) and keys != [] do
    Enum.all?(keys, &(public_jwk?(&1) and parseable_jwk?(&1))) and
      Enum.any?(keys, &usable_public_jwk?(&1, signing_alg, allowed_algs))
  end

  defp usable_public_jwk_set?(_jwks, _signing_alg, _allowed_algs), do: false

  defp usable_public_jwk?(jwk, signing_alg, allowed_algs) do
    public_jwk?(jwk) and parseable_jwk?(jwk) and
      Enum.any?(
        effective_private_key_jwt_algs(signing_alg, allowed_algs),
        &key_supports_alg?(jwk, &1)
      )
  end

  defp public_jwk?(jwk) when is_map(jwk) do
    Enum.all?(~w(d k p q dp dq qi oth), &(not Map.has_key?(jwk, &1)))
  end

  defp public_jwk?(_jwk), do: false

  defp parseable_jwk?(jwk) do
    _ = JOSE.JWK.from_map(jwk)
    true
  rescue
    _exception -> false
  end

  defp effective_private_key_jwt_algs(nil, allowed_algs), do: MapSet.to_list(allowed_algs)
  defp effective_private_key_jwt_algs(signing_alg, _allowed_algs), do: [signing_alg]

  defp key_supports_alg?(%{"kty" => "RSA"} = jwk, alg) when alg in [:RS256, :PS256],
    do: declared_alg_compatible?(jwk, alg)

  defp key_supports_alg?(%{"kty" => "EC", "crv" => "P-256"} = jwk, :ES256),
    do: declared_alg_compatible?(jwk, :ES256)

  defp key_supports_alg?(%{"kty" => "OKP", "crv" => "Ed25519"} = jwk, :EdDSA),
    do: declared_alg_compatible?(jwk, :EdDSA)

  defp key_supports_alg?(_jwk, _alg), do: false

  defp declared_alg_compatible?(jwk, alg) do
    case Map.get(jwk, "alg") do
      nil -> true
      declared when is_binary(declared) -> declared == Atom.to_string(alg)
      _other -> false
    end
  end

  defp https_uri?(uri) do
    case URI.parse(uri) do
      %URI{scheme: "https", host: host} when is_binary(host) and host != "" -> true
      _ -> false
    end
  end

  defp valid_scope_token?(scope) when is_binary(scope),
    do: Regex.match?(~r/^[A-Za-z0-9._:-]+$/, scope)

  defp valid_scope_token?(_), do: false

  defp issue(field, reason, detail), do: %{field: field, reason: reason, detail: detail}
end
