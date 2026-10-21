defmodule Lockspire.Protocol.TokenExchange.Internal.GrantPersistence do
  @moduledoc false

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange.Internal.ClientAuthentication
  alias Lockspire.Protocol.TokenExchange.Internal.TokenIssuer
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenResult.Error
  alias Lockspire.Protocol.TokenLifetime
  alias Lockspire.Storage.ClientLifetime

  @doc false
  @spec transact_with_audit(Dependencies.t(), (-> term())) :: {:ok, term()} | {:error, term()}
  def transact_with_audit(%Dependencies{} = dependencies, operation)
      when is_function(operation, 0) do
    dependencies.transaction_store.transact(fn ->
      operation.()
      |> append_audit_events(dependencies.audit_store)
    end)
    |> normalize_transaction()
  end

  @doc false
  @spec transact_with_audit(module(), module(), map(), (-> term())) :: term()
  def transact_with_audit(transaction_store, audit_store, audit_event, operation)
      when is_function(operation, 0) do
    transaction_store.transact(fn ->
      case operation.() do
        {:error, _reason} = error ->
          error

        result ->
          case audit_store.append_audit_event(audit_event) do
            {:ok, _event} -> result
            {:error, reason} -> {:error, reason}
          end
      end
    end)
  end

  @doc false
  @spec redeem_authorization_code(map(), Dependencies.t()) ::
          {:ok, map()} | {:error, term()}
  def redeem_authorization_code(
        %{
          code_hash: code_hash,
          client: %Client{} = authenticated_client,
          authorization_code: %Token{} = authorization_code,
          prepared_issuance: prepared_issuance,
          issuance_context: issuance_context,
          audit_event: audit_event
        } = intent,
        %Dependencies{} = dependencies
      ) do
    transact_with_audit(dependencies, fn ->
      with {:ok, [%Client{} = current_client]} <-
             dependencies.client_store.lock_clients([authenticated_client.client_id]),
           {:ok, current_client} <-
             validate_current_client(current_client, authenticated_client, issuance_context),
           {:ok, redeemed} <-
             dependencies.token_store.redeem_authorization_code(
               code_hash,
               nil,
               fn %Token{} = current_code ->
                 decide_and_build_code_issuance(
                   current_client,
                   current_code,
                   authorization_code,
                   prepared_issuance,
                   issuance_context,
                   dependencies
                 )
               end
             ),
           %Token{} = persisted_access_token <- redeemed.access_token,
           {:ok, persisted_refresh_token} <-
             maybe_store_token(
               dependencies.token_store,
               build_refresh_token(
                 Map.merge(intent, %{
                   issued_at: redeemed.issued_at,
                   refresh_expires_at: redeemed.refresh_expires_at
                 })
               )
             ) do
        {:ok,
         %{
           access_token: persisted_access_token,
           refresh_token: persisted_refresh_token,
           refresh_token_raw: refresh_token_raw(intent),
           raw_access_token: redeemed.raw_access_token,
           issued_at: redeemed.issued_at,
           expires_in: redeemed.expires_in
         }, [audit_event]}
      else
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  @doc false
  def validate_current_client(%Client{} = current, %Client{} = _authenticated, context) do
    identity = Map.get(context, :verified_client_identity)

    with {:ok, current} <- ClientLifetime.validate_client(current),
         :ok <- if(current.active, do: :ok, else: {:error, :client_disabled}),
         true <- ClientAuthentication.verified_identity_matches?(identity, current) do
      {:ok, current}
    else
      false -> {:error, client_authentication_error(:credential_changed)}
      {:error, :client_disabled} -> {:error, client_authentication_error(:client_disabled)}
      {:error, reason} -> {:error, reason}
      _ -> {:error, client_authentication_error(:credential_changed)}
    end
  end

  defp decide_and_build_code_issuance(
         %Client{} = current_client,
         %Token{} = current_code,
         %Token{} = authorization_code,
         prepared_issuance,
         _issuance_context,
         %Dependencies{} = dependencies
       ) do
    now = dependencies.now.()

    with :ok <- Client.app_eligibility(current_client, now, :guarded_token_redemption),
         true <- current_code.client_id == current_client.client_id,
         true <- DateTime.compare(current_code.expires_at, now) == :gt,
         {:ok, access_expires_at} <-
           TokenLifetime.effective_expiry(
             now,
             TokenLifetime.access_token(),
             current_client.client_expires_at
           ),
         {:ok, refresh_expires_at} <-
           maybe_refresh_expiry(
             now,
             current_client.client_expires_at,
             prepared_issuance.formatted_refresh_token
           ),
         {:ok, issued} <-
           TokenIssuer.issue_prepared_code_grant(
             current_client,
             %Token{current_code | audience: authorization_code.audience},
             now,
             access_expires_at,
             prepared_issuance,
             dependencies
           ) do
      {:ok,
       %{
         redeemed_at: to_utc_datetime_usec(now),
         issued_at: to_utc_datetime_usec(now),
         access_token: issued.access_token,
         raw_access_token: issued.raw_access_token,
         refresh_expires_at: refresh_expires_at,
         expires_in: TokenLifetime.expires_in(now, access_expires_at)
       }}
    else
      {:error, :expired} -> {:error, client_authentication_error(:client_app_expired)}
      {:error, :disabled} -> {:error, client_authentication_error(:client_disabled)}
      {:error, %Error{} = error} -> {:error, error}
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_grant}
    end
  end

  defp maybe_refresh_expiry(_now, _deadline, nil), do: {:ok, nil}

  defp maybe_refresh_expiry(now, deadline, _formatted_refresh_token),
    do: TokenLifetime.effective_expiry(now, TokenLifetime.refresh_token(), deadline)

  defp to_utc_datetime_usec(datetime),
    do: DateTime.from_unix!(DateTime.to_unix(datetime) * 1_000_000, :microsecond)

  defp client_authentication_error(reason) do
    %Error{
      status: 401,
      error: "invalid_client",
      error_description: "Client is no longer authorized to redeem this grant",
      reason_code: reason
    }
  end

  @doc false
  def redeem_device_authorization(intent, %Dependencies{} = dependencies) do
    redeem_poll_authorization(intent, dependencies, :device)
  end

  @doc false
  def redeem_ciba_authorization(intent, %Dependencies{} = dependencies) do
    redeem_poll_authorization(intent, dependencies, :ciba)
  end

  @doc false
  def append_poll_failure_audit(event, %Dependencies{} = dependencies) when is_map(event) do
    _ = dependencies.audit_store.append_audit_event(event)
    :ok
  end

  defp redeem_poll_authorization(
         %{access_token: %Token{} = access_token, audit_event: audit_event} = intent,
         %Dependencies{} = dependencies,
         kind
       ) do
    transact_with_audit(dependencies, fn ->
      with {:ok, _authorization} <- consume_poll_authorization(intent, dependencies, kind),
           {:ok, %Token{} = persisted_access_token} <-
             dependencies.token_store.store_token(access_token),
           {:ok, persisted_refresh_token} <-
             maybe_store_token(dependencies.token_store, build_poll_refresh_token(intent)) do
        {:ok,
         %{
           access_token: persisted_access_token,
           refresh_token: persisted_refresh_token,
           refresh_token_raw: refresh_token_raw(intent)
         }, [audit_event]}
      else
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  defp consume_poll_authorization(
         %{authorization: %DeviceAuthorization{} = authorization, issued_at: issued_at},
         %Dependencies{} = dependencies,
         :device
       ) do
    dependencies.device_authorization_store.consume_device_authorization(
      authorization.verification_handle,
      authorization.client_id,
      issued_at
    )
  end

  defp consume_poll_authorization(
         %{authorization: %CibaAuthorization{} = authorization, issued_at: issued_at},
         %Dependencies{} = dependencies,
         :ciba
       ) do
    dependencies.ciba_authorization_store.transition_ciba_authorization(
      authorization.auth_req_id_hash,
      [:approved],
      %{status: :consumed, consumed_at: issued_at}
    )
  end

  defp append_audit_events({:error, reason}, _audit_store), do: {:error, reason}

  defp append_audit_events({tag, value, events}, audit_store) when tag in [:ok, :durable_error] do
    case append_all(audit_store, events) do
      :ok -> {tag, value}
      {:error, reason} -> {:error, reason}
    end
  end

  defp append_all(_audit_store, []), do: :ok

  defp append_all(audit_store, [event | rest]) do
    with {:ok, _} <- audit_store.append_audit_event(event) do
      append_all(audit_store, rest)
    end
  end

  defp maybe_store_token(_store, nil), do: {:ok, nil}
  defp maybe_store_token(store, %Token{} = token), do: store.store_token(token)

  defp build_refresh_token(%{formatted_refresh_token: nil}), do: nil

  defp build_refresh_token(%{
         formatted_refresh_token: formatted_refresh_token,
         authorization_code: %Token{} = authorization_code,
         issued_at: issued_at,
         refresh_expires_at: refresh_expires_at,
         issuance_context: issuance_context
       }) do
    %Token{
      token_hash: formatted_refresh_token.token_hash,
      token_type: :refresh_token,
      family_id: formatted_refresh_token.token_hash,
      generation: 0,
      client_id: authorization_code.client_id,
      account_id: authorization_code.account_id,
      interaction_id: authorization_code.interaction_id,
      consent_grant_id: authorization_code.consent_grant_id,
      sid: authorization_code.sid,
      scopes: authorization_code.scopes,
      audience: authorization_code.audience,
      cnf: issuance_context.cnf,
      issued_at: issued_at,
      expires_at: refresh_expires_at
    }
  end

  defp build_poll_refresh_token(%{formatted_refresh_token: nil}), do: nil

  defp build_poll_refresh_token(%{
         formatted_refresh_token: formatted_refresh_token,
         grant: %Token{} = grant,
         issued_at: issued_at,
         issuance_context: issuance_context
       }) do
    %Token{
      token_hash: formatted_refresh_token.token_hash,
      token_type: :refresh_token,
      family_id: formatted_refresh_token.token_hash,
      generation: 0,
      client_id: grant.client_id,
      account_id: grant.account_id,
      interaction_id: grant.interaction_id,
      scopes: grant.scopes,
      audience: grant.audience,
      cnf: issuance_context.cnf,
      issued_at: issued_at,
      expires_at: DateTime.add(issued_at, TokenLifetime.refresh_token(), :second)
    }
  end

  defp refresh_token_raw(%{formatted_refresh_token: nil}), do: nil

  defp refresh_token_raw(%{formatted_refresh_token: formatted_refresh_token}),
    do: formatted_refresh_token.token

  defp normalize_transaction({:ok, {:durable_error, %Error{} = error}}), do: {:error, error}
  defp normalize_transaction({:ok, result}), do: {:ok, result}
  defp normalize_transaction({:error, %Error{} = error}), do: {:error, error}
  defp normalize_transaction({:error, reason}), do: {:error, reason}
end
