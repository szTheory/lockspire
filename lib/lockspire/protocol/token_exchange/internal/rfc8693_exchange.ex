defmodule Lockspire.Protocol.TokenExchange.Internal.Rfc8693Exchange do
  @moduledoc """
  Implements OAuth 2.0 Token Exchange (RFC 8693).
  """

  require Logger

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Host.TokenExchangeContext
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenExchange.Internal.GrantPersistence
  alias Lockspire.Protocol.TokenExchange.Internal.ClientAuthentication
  alias Lockspire.Storage.ClientLifetime
  alias Lockspire.Protocol.TokenExchange.Internal.TokenIssuer
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Protocol.TokenResult.Error
  alias Lockspire.Protocol.TokenResult.Success
  alias Lockspire.Security.Policy

  @spec exchange(Client.t(), map(), map()) :: {:ok, struct()} | {:error, struct()}
  def exchange(%Client{} = client, request, %Dependencies{} = dependencies) do
    request = Dependencies.attach(request, dependencies)
    params = Map.get(request, :params, Map.get(request, "params", request))

    with {:ok, subject_token_string} <- fetch_subject_token(params),
         {:ok, %Token{} = subject_token} <- validate_subject_token(subject_token_string, request),
         {:ok, actor_token_string} <- fetch_actor_token(params),
         {:ok, actor_token, actor_token_claims} <-
           validate_actor_token(actor_token_string, request),
         :ok <- validate_requester_before_host(client, request),
         :ok <- validate_issuer_before_host(subject_token.client_id, request),
         :ok <- validate_optional_issuer_before_host(actor_token, request),
         {:ok, requested_scopes} <- validate_scopes(params["scope"], subject_token),
         :ok <- check_delegation_depth(actor_token_claims, client, request),
         context = %TokenExchangeContext{
           client_id: client.client_id,
           subject_token: subject_token,
           actor_token: actor_token_claims,
           actor_token_identity: actor_token,
           requested_scopes: requested_scopes
         },
         {:ok, validation_result} <- validate_exchange(context, request),
         {:ok, signing} <- prepare_output(client, validation_result, request) do
      output_token = %Token{
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
        issued_at: nil,
        expires_at: nil
      }

      intent = %{
        requester: client,
        verified_client_identity: ClientAuthentication.verified_identity(client),
        issuer_client_ids:
          [subject_token.client_id, actor_token && actor_token.client_id]
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()
          |> Enum.sort(),
        participant_client_ids:
          [client.client_id, subject_token.client_id, actor_token && actor_token.client_id]
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()
          |> Enum.sort(),
        input_tokens: Enum.reject([subject_token, actor_token], &is_nil/1),
        input_token_hashes:
          Enum.reject([subject_token, actor_token], &is_nil/1)
          |> Enum.map(& &1.token_hash),
        preflight_now: now(request),
        output_token: output_token,
        custom_claims: Map.get(validation_result, :claims),
        prepared_signing: signing.prepared_signing,
        raw_token: signing.raw_token,
        audit_event: exchange_audit_event(client, subject_token)
      }

      case GrantPersistence.persist_rfc8693(intent, dependencies) do
        {:ok, result} ->
          {:ok,
           %Success{
             access_token: result.raw_token,
             token_type: "Bearer",
             issued_token_type: "urn:ietf:params:oauth:token-type:access_token",
             expires_in: result.expires_in,
             scope: Enum.join(requested_scopes, " ")
           }}

        {:error, %Error{} = error} ->
          {:error, error}

        {:error, reason} ->
          {:error, server_error(reason)}
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

      {:ok, nil} ->
        {:error, invalid_grant_error(:invalid_subject_token)}

      {:error, :not_found} ->
        {:error, invalid_grant_error(:invalid_subject_token)}

      {:error, reason} ->
        {:error, server_error({:token_store_unavailable, reason})}
    end
  end

  defp validate_actor_token(nil, _request), do: {:ok, nil, nil}

  defp validate_actor_token(token_string, request) do
    token_hash = Policy.hash_token(token_string)

    case token_store(request).fetch_lifecycle_token(token_hash) do
      {:ok, %Token{} = token} ->
        if token_valid?(token, now(request)) do
          {:ok, token, extract_claims(token_string, token)}
        else
          {:error, invalid_grant_error(:invalid_actor_token)}
        end

      {:ok, nil} ->
        {:error, invalid_grant_error(:invalid_actor_token)}

      {:error, :not_found} ->
        {:error, invalid_grant_error(:invalid_actor_token)}

      {:error, reason} ->
        {:error, server_error({:token_store_unavailable, reason})}
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
    payload_struct = JOSE.JWT.peek_payload(jwt)
    {_modules, claims} = JOSE.JWT.to_map(payload_struct)
    {:ok, claims}
  rescue
    _ -> :error
  catch
    _, _ -> :error
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
    store = Dependencies.fetch!(request).server_policy_store

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

  defp token_store(request), do: Dependencies.fetch!(request).token_store

  defp token_format_options(request), do: Dependencies.fetch!(request).token_format_options

  defp now(request), do: Dependencies.fetch!(request).now.()

  defp token_exchange_validator(request),
    do: Dependencies.fetch!(request).token_exchange_validator

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

  defp validate_requester_before_host(%Client{} = client, request) do
    dependencies = Dependencies.fetch!(request)

    with {:ok, %Client{} = current} <-
           dependencies.client_store.fetch_client_by_id(client.client_id),
         {:ok, current} <- ClientLifetime.validate_client(current),
         true <- current.active,
         :ok <- Client.app_eligibility(current, now(request), :token_exchange_requester) do
      :ok
    else
      {:ok, nil} -> {:error, client_error(:unknown_client)}
      false -> {:error, client_error(:client_disabled)}
      {:error, :expired} -> {:error, client_error(:client_app_expired)}
      {:error, :disabled} -> {:error, client_error(:client_disabled)}
      {:error, reason} -> {:error, server_error({:invalid_client_state, reason})}
      _ -> {:error, server_error(:client_store_unavailable)}
    end
  end

  defp validate_optional_issuer_before_host(nil, _request), do: :ok

  defp validate_optional_issuer_before_host(%Token{} = token, request),
    do: validate_issuer_before_host(token.client_id, request)

  defp validate_issuer_before_host(client_id, request) when is_binary(client_id) do
    dependencies = Dependencies.fetch!(request)

    case dependencies.client_store.fetch_client_by_id(client_id) do
      {:ok, %Client{} = client} ->
        with {:ok, client} <- ClientLifetime.validate_client(client),
             true <- client.active,
             :ok <- Client.app_eligibility(client, now(request), :token_exchange_issuer) do
          :ok
        else
          false -> {:error, invalid_grant_error(:issuer_ineligible)}
          {:error, :expired} -> {:error, invalid_grant_error(:issuer_ineligible)}
          {:error, :disabled} -> {:error, invalid_grant_error(:issuer_ineligible)}
          {:error, reason} -> {:error, server_error({:invalid_issuer_state, reason})}
        end

      {:ok, nil} ->
        {:error, invalid_grant_error(:issuer_missing)}

      {:error, reason} ->
        {:error, server_error({:client_store_unavailable, reason})}
    end
  end

  defp validate_issuer_before_host(_client_id, _request),
    do: {:error, invalid_grant_error(:issuer_missing)}

  defp prepare_output(client, %{claims: claims}, request) when is_map(claims) do
    case TokenIssuer.prepare_exchange(client, Dependencies.fetch!(request)) do
      {:ok, prepared} -> {:ok, %{prepared_signing: prepared, raw_token: nil}}
      {:error, error} -> {:error, error}
    end
  end

  defp prepare_output(_client, _validation_result, request) do
    formatted = TokenFormatter.format_access_token(token_format_options(request))
    {:ok, %{prepared_signing: nil, raw_token: formatted.token}}
  end

  defp exchange_audit_event(%Client{} = client, %Token{} = subject) do
    %{
      action: :token_exchange,
      outcome: :success,
      reason_code: :token_exchange_succeeded,
      actor: %{type: :client, id: client.client_id, display: client.client_id},
      resource: %{type: :access_token, id: subject.id || subject.token_hash},
      metadata: %{client_id: client.client_id, subject_id: subject.account_id}
    }
  end

  defp client_error(reason) do
    %Error{
      status: 401,
      error: "invalid_client",
      error_description: "The requesting client is not eligible to exchange tokens",
      reason_code: reason
    }
  end

  defp server_error(reason) do
    %Error{
      status: 500,
      error: "server_error",
      error_description: "Token exchange storage or lifetime state is unavailable",
      reason_code: reason
    }
  end
end
