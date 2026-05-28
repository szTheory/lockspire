defmodule Lockspire.Protocol.Rfc8693Exchange do
  @moduledoc """
  Implements OAuth 2.0 Token Exchange (RFC 8693).
  """

  require Logger

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Host.TokenExchangeContext
  alias Lockspire.Protocol.AccessTokenSigner
  alias Lockspire.Protocol.TokenExchange.Error
  alias Lockspire.Protocol.TokenExchange.Success
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Security.Policy

  @spec exchange(Client.t(), map()) :: {:ok, Success.t()} | {:error, Error.t()}
  def exchange(%Client{} = client, request) do
    params = Map.get(request, :params, Map.get(request, "params", request))
    issued_at = now(request)

    with {:ok, subject_token_string} <- fetch_subject_token(params),
         {:ok, %Token{} = subject_token} <- validate_subject_token(subject_token_string, request),
         {:ok, actor_token_string} <- fetch_actor_token(params),
         {:ok, actor_token_claims} <- validate_actor_token(actor_token_string, request),
         {:ok, requested_scopes} <- validate_scopes(params["scope"], subject_token),
         :ok <- check_delegation_depth(actor_token_claims, client, request),
         context = %TokenExchangeContext{
           client_id: client.client_id,
           subject_token: subject_token,
           actor_token: actor_token_claims,
           requested_scopes: requested_scopes
         },
         {:ok, validation_result} <- validate_exchange(context, request),
         {:ok, token_string, token_hash} <-
           sign_or_format_access_token(
             client,
             subject_token,
             requested_scopes,
             issued_at,
             validation_result,
             request
           ) do
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

  defp fetch_actor_token(params) do
    case normalize_optional_string(params["actor_token"]) do
      nil -> {:ok, nil}
      token -> {:ok, token}
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

  defp validate_actor_token(nil, _request), do: {:ok, nil}

  defp validate_actor_token(token_string, request) do
    token_hash = Policy.hash_token(token_string)

    case token_store(request).fetch_lifecycle_token(token_hash) do
      {:ok, %Token{} = token} ->
        if token_valid?(token, now(request)) do
          {:ok, extract_claims(token_string, token)}
        else
          {:error, invalid_grant_error(:invalid_actor_token)}
        end

      _error ->
        {:error, invalid_grant_error(:invalid_actor_token)}
    end
  end

  defp extract_claims(token_string, %Token{} = token) do
    case decode_jwt_claims(token_string) do
      {:ok, claims} ->
        claims

      :error ->
        %{"sub" => token.account_id, "client_id" => token.client_id}
    end
  end

  defp decode_jwt_claims(jwt) do
    # credo:disable-for-next-line
    try do
      payload_struct = JOSE.JWT.peek_payload(jwt)
      {_modules, claims} = JOSE.JWT.to_map(payload_struct)
      {:ok, claims}
    rescue
      _ -> :error
    catch
      _, _ -> :error
    end
  end

  defp check_delegation_depth(nil, _client, _request), do: :ok

  defp check_delegation_depth(actor_token_claims, client, request) do
    policy = server_policy(request)

    case Lockspire.Protocol.TokenExchange.Delegation.check_depth(
           actor_token_claims,
           client,
           policy
         ) do
      :ok ->
        :ok

      {:error, error, error_description} ->
        {:error,
         %Error{
           status: 400,
           error: error,
           error_description: error_description,
           reason_code: :max_delegation_depth_exceeded
         }}
    end
  end

  defp server_policy(request) do
    store =
      request
      |> Map.get(:opts, [])
      |> Keyword.get(:server_policy_store, Config.repo!())

    case store.get_server_policy() do
      {:ok, policy} -> policy
      %Lockspire.Domain.ServerPolicy{} = policy -> policy
      _ -> nil
    end
  end

  defp token_valid?(%Token{} = token, now) do
    is_nil(token.revoked_at) and
      is_nil(token.reuse_detected_at) and
      DateTime.compare(token.expires_at, now) == :gt
  end

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
        # Delegate all at+jwt signing to the shared module. issue_exchange/4 keeps
        # the exchange carve-out: a bare-STRING aud == client_id (AUD-03) and the
        # custom-claim merge with the iss/sub/aud/exp/iat/jti/client_id drop.
        token = %Token{
          token_type: :access_token,
          client_id: client.client_id,
          account_id: subject_token.account_id,
          scopes: scopes,
          cnf: subject_token.cnf,
          issued_at: issued_at,
          expires_at: DateTime.add(issued_at, 3600, :second)
        }

        AccessTokenSigner.issue_exchange(token, client, custom_claims, request)
    end
  end
end
