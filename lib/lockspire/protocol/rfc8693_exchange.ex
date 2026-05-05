defmodule Lockspire.Protocol.Rfc8693Exchange do
  @moduledoc """
  Implements OAuth 2.0 Token Exchange (RFC 8693).
  """

  require Logger

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Host.TokenExchangeContext
  alias Lockspire.Protocol.TokenExchange.Error
  alias Lockspire.Protocol.TokenExchange.Success
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Security.Policy

  @spec exchange(Client.t(), map()) :: {:ok, Success.t()} | {:error, Error.t()}
  def exchange(%Client{} = client, request) do
    params = Map.get(request, :params, Map.get(request, "params", request))

    with {:ok, subject_token_string} <- fetch_subject_token(params),
         {:ok, %Token{} = subject_token} <- validate_subject_token(subject_token_string, request),
         {:ok, requested_scopes} <- validate_scopes(params["scope"], subject_token),
         context = %TokenExchangeContext{
           client_id: client.client_id,
           subject_token: subject_token,
           actor_token: nil,
           requested_scopes: requested_scopes
         },
         {:ok, validation_result} <- validate_exchange(context, request),
         {:ok, token_string, token_hash} <-
           sign_or_format_access_token(
             client,
             subject_token,
             requested_scopes,
             now(request),
             validation_result,
             request
           ) do
      issued_at = now(request)

      access_token = %Token{
        token_hash: token_hash,
        token_type: :access_token,
        family_id: subject_token.family_id || subject_token.token_hash,
        generation: subject_token.generation + 1,
        parent_token_id: subject_token.id,
        client_id: client.client_id,
        account_id: subject_token.account_id,
        interaction_id: subject_token.interaction_id,
        sid: subject_token.sid,
        scopes: requested_scopes,
        audience: subject_token.audience,
        cnf: subject_token.cnf,
        issued_at: issued_at,
        expires_at: DateTime.add(issued_at, 3600, :second)
      }

      case token_store(request).store_token(access_token) do
        {:ok, _persisted_token} ->
          {:ok,
           %Success{
             access_token: token_string,
             token_type: "Bearer",
             issued_token_type: "urn:ietf:params:oauth:token-type:access_token",
             expires_in: 3600,
             scope: Enum.join(requested_scopes, " ")
           }}

        {:error, _reason} ->
          {:error,
           %Error{
             status: 500,
             error: "server_error",
             error_description: "Unable to persist token",
             reason_code: :token_persistence_failed
           }}
      end
    else
      {:error, error} -> {:error, error}
    end
  end

  defp fetch_subject_token(params) do
    case normalize_optional_string(params["subject_token"]) do
      nil ->
        {:error,
         %Error{
           status: 400,
           error: "invalid_request",
           error_description: "subject_token is required",
           reason_code: :missing_subject_token
         }}

      token ->
        {:ok, token}
    end
  end

  defp validate_subject_token(token_string, request) do
    token_hash = Policy.hash_token(token_string)

    case token_store(request).fetch_lifecycle_token(token_hash) do
      {:ok, %Token{} = token} ->
        if token_valid?(token, now(request)) do
          {:ok, token}
        else
          {:error, invalid_grant_error(:invalid_subject_token)}
        end

      _error ->
        {:error, invalid_grant_error(:invalid_subject_token)}
    end
  end

  defp token_valid?(%Token{} = token, now) do
    is_nil(token.revoked_at) and
      is_nil(token.reuse_detected_at) and
      DateTime.compare(token.expires_at, now) == :gt
  end

  defp token_valid?(_, _), do: false

  defp validate_scopes(nil, %Token{} = subject_token) do
    {:ok, subject_token.scopes}
  end

  defp validate_scopes(scope_string, %Token{} = subject_token) when is_binary(scope_string) do
    requested_scopes = String.split(scope_string, " ", trim: true)

    requested_set = MapSet.new(requested_scopes)
    subject_set = MapSet.new(subject_token.scopes)

    if MapSet.subset?(requested_set, subject_set) do
      {:ok, requested_scopes}
    else
      {:error,
       %Error{
         status: 400,
         error: "invalid_scope",
         error_description: "Requested scopes exceed subject token scopes",
         reason_code: :invalid_scope
       }}
    end
  end

  defp invalid_grant_error(reason_code) do
    %Error{
      status: 400,
      error: "invalid_grant",
      error_description: "The provided token is invalid, expired, or revoked",
      reason_code: reason_code
    }
  end

  defp normalize_optional_string(val) when is_binary(val) do
    case String.trim(val) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_optional_string(_), do: nil

  defp token_store(request) do
    request
    |> Map.get(:opts, [])
    |> Keyword.get(:token_store, Config.repo!())
  end

  defp token_format_options(request) do
    request
    |> Map.get(:opts, [])
    |> Keyword.get(:token_format_options, [])
  end

  defp now(request) do
    request
    |> Map.get(:opts, [])
    |> Keyword.get_lazy(:now, fn -> &DateTime.utc_now/0 end)
    |> then(& &1.())
  end

  defp token_exchange_validator(request) do
    request
    |> Map.get(:opts, [])
    |> Keyword.get_lazy(:token_exchange_validator, fn -> Config.token_exchange_validator() end)
  end

  defp validate_exchange(context, request) do
    validator = token_exchange_validator(request)

    case validator.validate(context) do
      :ok ->
        {:ok, %{}}

      {:ok, %{claims: custom_claims}} ->
        {:ok, %{claims: custom_claims}}

      {:error, reason} ->
        Logger.warning("Token exchange denied by host validator. Reason: #{inspect(reason)}")

        {:error,
         %Error{
           status: 403,
           error: "access_denied",
           error_description: "The token exchange request was denied.",
           reason_code: :access_denied
         }}
    end
  end

  defp sign_or_format_access_token(
         client,
         subject_token,
         scopes,
         issued_at,
         validation_result,
         request
       ) do
    case Map.get(validation_result, :claims) do
      nil ->
        formatted = TokenFormatter.format_access_token(token_format_options(request))
        {:ok, formatted.token, formatted.token_hash}

      custom_claims when is_map(custom_claims) ->
        sign_jwt_access_token(client, subject_token, scopes, issued_at, custom_claims, request)
    end
  end

  defp sign_jwt_access_token(client, subject_token, scopes, issued_at, custom_claims, request) do
    case fetch_signing_key(request) do
      {:ok, %{kid: kid, alg: alg, private_jwk_encrypted: private_jwk}} ->
        {:ok, jwk_map} = decode_private_jwk(private_jwk)

        jti = TokenFormatter.format_access_token(token_format_options(request)).token

        base_claims = %{
          "iss" => Config.issuer!(),
          "sub" => subject_token.account_id,
          "aud" => client.client_id,
          "exp" => DateTime.add(issued_at, 3600, :second) |> DateTime.to_unix(),
          "iat" => DateTime.to_unix(issued_at),
          "client_id" => client.client_id,
          "jti" => jti,
          "scope" => Enum.join(scopes, " ")
        }

        restricted = ~w(iss sub aud exp iat jti client_id)
        safe_custom_claims = Map.drop(custom_claims, restricted)

        claims = Map.merge(base_claims, safe_custom_claims)

        {_, compact} =
          JOSE.JWT.sign(
            JOSE.JWK.from_map(jwk_map),
            %{"alg" => alg, "kid" => kid, "typ" => "at+jwt"},
            claims
          )
          |> JOSE.JWS.compact()

        {:ok, compact, Policy.hash_token(compact)}

      {:error, reason} ->
        Logger.error("Failed to sign token exchange JWT: #{inspect(reason)}")

        {:error,
         %Error{
           status: 500,
           error: "server_error",
           error_description: "Unable to sign access token.",
           reason_code: :token_signing_failed
         }}
    end
  end

  defp fetch_signing_key(request) do
    key_store =
      request
      |> Map.get(:opts, [])
      |> Keyword.get(:key_store, Config.repo!())

    case key_store.fetch_active_signing_key() do
      {:ok, %{alg: alg, private_jwk_encrypted: private_jwk} = key}
      when is_binary(private_jwk) and is_binary(alg) ->
        {:ok, key}

      {:ok, nil} ->
        {:error, :signing_key_not_found}

      {:ok, _key} ->
        {:error, :invalid_signing_key}

      {:error, _reason} ->
        {:error, :signing_key_lookup_failed}
    end
  end

  defp decode_private_jwk(binary) when is_binary(binary) do
    case Jason.decode(binary) do
      {:ok, %{} = jwk} -> {:ok, jwk}
      _other -> decode_erlang_jwk(binary)
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
