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
        has_jwks and has_jwks_uri ->
          [issue(:jwks, :mutually_exclusive_with_jwks_uri, nil) | current]

        not has_jwks and not has_jwks_uri ->
          [issue(:token_endpoint_auth_method, :missing_cryptographic_material, nil) | current]

        has_jwks_uri and not https_uri?(attrs.jwks_uri) ->
          [issue(:jwks_uri, :invalid_uri_scheme, nil) | current]

        true ->
          current
      end
    end)
    |> validate_private_key_jwt_alg(attrs.token_endpoint_auth_signing_alg, opts)
  end

  defp validate_private_key_jwt(errors, attrs, opts) do
    if attrs.jwks_uri && not Keyword.get(opts, :allow_jwks_uri_for_encryption, false) do
      [issue(:jwks_uri, :unsupported_token_endpoint_auth_method, nil) | errors]
    else
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
