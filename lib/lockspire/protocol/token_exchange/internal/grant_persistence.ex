defmodule Lockspire.Protocol.TokenExchange.Internal.GrantPersistence do
  @moduledoc false

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange.Internal.ClientAuthentication
  alias Lockspire.Protocol.TokenExchange.Internal.TokenIssuer
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenExchange.Internal.ResourceSelection
  alias Lockspire.Protocol.TokenResult.Error
  alias Lockspire.Protocol.TokenLifetime
  alias Lockspire.Storage.ClientLifetime
  alias Lockspire.Security.Policy

  @doc false
  def persist_rfc8693(intent, %Dependencies{} = dependencies) when is_map(intent) do
    transact_with_audit(dependencies, fn ->
      with {:ok, current_clients} <-
             dependencies.client_store.lock_clients(intent.participant_client_ids),
           {:ok, current_by_id} <- validate_exchange_clients(current_clients, intent),
           {:ok, locked_tokens} <-
             dependencies.token_store.lock_lifecycle_tokens(intent.input_token_hashes),
           {:ok, now} <- final_exchange_time(dependencies),
           :ok <- validate_exchange_tokens(locked_tokens, intent, now),
           :ok <- validate_exchange_eligibility(current_by_id, intent, now),
           {:ok, expires_at} <-
             TokenLifetime.effective_expiry(
               now,
               TokenLifetime.access_token(),
               current_by_id[intent.requester.client_id].client_expires_at
             ),
           :ok <- expiry_after_now(expires_at, now),
           issued_token = %{intent.output_token | issued_at: now, expires_at: expires_at},
           {:ok, raw_token, token_hash} <- issue_exchange_token(issued_token, intent),
           issued_token = %{issued_token | token_hash: token_hash},
           {:ok, persisted} <- dependencies.token_store.store_token(issued_token) do
        {:ok,
         %{
           token: persisted,
           raw_token: raw_token,
           expires_in: TokenLifetime.expires_in(now, expires_at),
           issued_at: now
         }, [intent.audit_event]}
      else
        {:error, %Error{} = error} -> {:error, error}
        {:error, :expired} -> {:error, client_authentication_error(:client_app_expired)}
        {:error, :disabled} -> {:error, client_authentication_error(:client_disabled)}
        {:error, reason} -> {:error, reason}
        false -> {:error, invalid_grant(:input_token_changed)}
      end
    end)
  end

  defp validate_exchange_clients(current_clients, intent) do
    current_by_id = Map.new(current_clients, &{&1.client_id, &1})
    requester_id = intent.requester.client_id

    with %Client{} = requester <- current_by_id[requester_id],
         {:ok, requester} <- ClientLifetime.validate_client(requester),
         true <- requester.active,
         true <-
           ClientAuthentication.verified_identity_matches?(
             intent.verified_client_identity,
             requester
           ),
         :ok <- validate_issuer_client_rows(current_by_id, intent.issuer_client_ids) do
      {:ok, current_by_id}
    else
      nil -> {:error, client_authentication_error(:client_missing)}
      false -> {:error, client_authentication_error(:credential_or_client_changed)}
      {:error, :expired} -> {:error, client_authentication_error(:client_app_expired)}
      {:error, :disabled} -> {:error, client_authentication_error(:client_disabled)}
      {:error, reason} -> {:error, server_error(reason)}
      _ -> {:error, client_authentication_error(:client_state_invalid)}
    end
  end

  defp validate_issuer_client_rows(_clients, []), do: :ok

  defp validate_issuer_client_rows(clients, [client_id | rest]) do
    case clients[client_id] do
      %Client{} = client ->
        with {:ok, client} <- ClientLifetime.validate_client(client),
             true <- client.active do
          validate_issuer_client_rows(clients, rest)
        else
          false -> {:error, invalid_grant(:issuer_ineligible)}
          {:error, reason} -> {:error, server_error(reason)}
        end

      nil ->
        {:error, invalid_grant(:issuer_missing)}
    end
  end

  defp validate_exchange_tokens(locked_tokens, intent, now) do
    by_hash = Map.new(locked_tokens, &{&1.token_hash, &1})

    valid? =
      Enum.all?(intent.input_tokens, fn original ->
        exchange_token_current?(by_hash[original.token_hash], original, now)
      end)

    if valid?, do: :ok, else: {:error, invalid_grant(:input_token_changed)}
  end

  defp exchange_token_current?(%Token{} = current, original, now) do
    current.client_id == original.client_id and current.account_id == original.account_id and
      current.token_type == original.token_type and current.expires_at == original.expires_at and
      is_nil(current.revoked_at) and is_nil(current.reuse_detected_at) and
      DateTime.compare(current.expires_at, now) == :gt
  end

  defp exchange_token_current?(_current, _original, _now), do: false

  defp final_exchange_time(dependencies) do
    case dependencies.now.() do
      %DateTime{} = now -> {:ok, now}
      _ -> {:error, server_error(:clock_unavailable)}
    end
  rescue
    _ -> {:error, server_error(:clock_unavailable)}
  end

  defp validate_exchange_eligibility(clients, intent, now) do
    requester = clients[intent.requester.client_id]

    requester_context = %{
      verified_client_identity: intent.verified_client_identity
    }

    with :ok <-
           validate_current_authority(
             requester,
             requester_context,
             now,
             :guarded_token_exchange
           ) do
      validate_issuer_eligibility(clients, intent.issuer_client_ids, now)
    end
  end

  defp validate_issuer_eligibility(_clients, [], _now), do: :ok

  defp validate_issuer_eligibility(clients, [client_id | rest], now) do
    case Client.app_eligibility(clients[client_id], now, :guarded_token_exchange) do
      :ok -> validate_issuer_eligibility(clients, rest, now)
      {:error, _reason} -> {:error, invalid_grant(:issuer_ineligible)}
    end
  end

  defp expiry_after_now(expires_at, now) do
    if DateTime.compare(expires_at, now) == :gt,
      do: :ok,
      else: {:error, client_authentication_error(:client_app_expired)}
  end

  defp issue_exchange_token(_token, %{prepared_signing: nil, raw_token: raw_token}),
    do: {:ok, raw_token, Policy.hash_token(raw_token)}

  defp issue_exchange_token(token, intent) do
    TokenIssuer.issue_prepared_exchange(
      token,
      intent.requester,
      intent.custom_claims,
      intent.prepared_signing
    )
  end

  defp invalid_grant(reason) do
    %Error{
      status: 400,
      error: "invalid_grant",
      error_description: "The provided token is invalid, expired, or revoked",
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
          authorization_code: %Token{},
          selected_audience: selected_audience,
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
                   selected_audience,
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
                   authorization_code: %{
                     redeemed.authorization_code
                     | audience: redeemed.selected_audience
                   },
                   selected_audience: redeemed.selected_audience,
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
    end
  end

  @doc false
  def validate_current_authority(
        %Client{} = current,
        issuance_context,
        %DateTime{} = now,
        consumer
      )
      when is_map(issuance_context) and is_atom(consumer) do
    identity = Map.get(issuance_context, :verified_client_identity)

    with {:ok, current} <- ClientLifetime.validate_client(current),
         :ok <- require_active_client(current),
         :ok <- require_verified_identity(identity, current),
         :ok <- require_app_eligibility(current, now, consumer),
         :ok <- require_secret_eligibility(current, now, consumer) do
      :ok
    else
      {:error, %Error{} = error} -> {:error, error}
      {:error, reason} -> {:error, server_error(reason)}
    end
  end

  def validate_current_authority(%Client{}, _issuance_context, _now, _consumer),
    do: {:error, server_error(:client_lifetime_clock_failed)}

  defp require_active_client(%Client{active: true}), do: :ok

  defp require_active_client(%Client{}),
    do: {:error, client_authentication_error(:client_disabled)}

  defp require_verified_identity(identity, current) do
    if ClientAuthentication.verified_identity_matches?(identity, current),
      do: :ok,
      else: {:error, client_authentication_error(:credential_changed)}
  end

  defp require_app_eligibility(client, now, consumer) do
    case Client.app_eligibility(client, now, consumer) do
      :ok -> :ok
      {:error, :expired} -> {:error, client_authentication_error(:client_app_expired)}
      {:error, :disabled} -> {:error, client_authentication_error(:client_disabled)}
      {:error, reason} -> {:error, server_error(reason)}
    end
  end

  defp require_secret_eligibility(client, now, consumer) do
    case Client.secret_eligibility(client, now, consumer) do
      :ok -> :ok
      {:error, :expired} -> {:error, client_authentication_error(:client_secret_expired)}
      {:error, reason} -> {:error, server_error(reason)}
    end
  end

  defp final_authority_time(%Dependencies{} = dependencies) do
    case dependencies.now.() do
      %DateTime{} = now -> {:ok, now}
      _other -> {:error, server_error(:client_lifetime_clock_failed)}
    end
  rescue
    _error -> {:error, server_error(:client_lifetime_clock_failed)}
  end

  defp decide_and_build_code_issuance(
         %Client{} = current_client,
         %Token{} = current_code,
         selected_audience,
         prepared_issuance,
         issuance_context,
         %Dependencies{} = dependencies
       ) do
    with {:ok, now} <- final_authority_time(dependencies),
         :ok <-
           validate_current_authority(
             current_client,
             issuance_context,
             now,
             :guarded_token_redemption
           ),
         {:ok, selected_audience} <-
           ResourceSelection.select(%{"resource" => selected_audience}, current_code),
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
             %Token{current_code | audience: selected_audience},
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
         selected_audience: selected_audience,
         refresh_expires_at: refresh_expires_at,
         expires_in: TokenLifetime.expires_in(now, access_expires_at)
       }}
    else
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
         %{audit_event: audit_event} = intent,
         %Dependencies{} = dependencies,
         kind
       ) do
    result_key = make_ref()

    try do
      result =
        transact_with_audit(dependencies, fn ->
          with {:ok, [%Client{} = current_client]} <-
                 dependencies.client_store.lock_clients([intent.client.client_id]),
               {:ok, current_client} <-
                 validate_current_client(
                   current_client,
                   intent.client,
                   intent.issuance_context
                 ),
               {:ok, _authorization} <-
                 consume_poll_authorization(
                   intent,
                   dependencies,
                   kind,
                   current_client,
                   result_key
                 ) do
            case Process.get(result_key) do
              %{access_token: %Token{}} = issued -> {:ok, issued, [audit_event]}
              _ -> {:error, :poll_issuance_result_missing}
            end
          else
            {:error, reason} -> {:error, reason}
          end
        end)

      case result do
        {:ok, issued} -> {:ok, issued}
        error -> error
      end
    after
      Process.delete(result_key)
    end
  end

  defp consume_poll_authorization(
         %{authorization: %DeviceAuthorization{} = authorization} = intent,
         %Dependencies{} = dependencies,
         :device,
         %Client{} = current_client,
         result_key
       ) do
    dependencies.device_authorization_store.transition_device_authorization(
      authorization.verification_handle,
      [:approved],
      fn current_authorization ->
        finalize_poll_issuance(
          intent,
          current_authorization,
          current_client,
          dependencies,
          result_key,
          :device
        )
      end
    )
  end

  defp consume_poll_authorization(
         %{authorization: %CibaAuthorization{} = authorization} = intent,
         %Dependencies{} = dependencies,
         :ciba,
         %Client{} = current_client,
         result_key
       ) do
    dependencies.ciba_authorization_store.transition_ciba_authorization(
      authorization.auth_req_id_hash,
      [:approved],
      fn current_authorization ->
        finalize_poll_issuance(
          intent,
          current_authorization,
          current_client,
          dependencies,
          result_key,
          :ciba
        )
      end
    )
  end

  defp finalize_poll_issuance(
         intent,
         authorization,
         %Client{} = current_client,
         %Dependencies{} = dependencies,
         result_key,
         kind
       ) do
    now = dependencies.now.()
    original = intent.authorization

    with :ok <- current_authorization_matches(authorization, original, now, kind),
         :ok <- poll_authority_eligibility(current_client, intent.issuance_context, now),
         {:ok, access_expires_at} <-
           TokenLifetime.effective_expiry(
             now,
             TokenLifetime.access_token(),
             current_client.client_expires_at
           ),
         {:ok, refresh_expires_at} <-
           maybe_poll_refresh_expiry(now, current_client.client_expires_at, intent),
         {:ok, issued} <-
           TokenIssuer.issue_prepared_poll_grant(
             current_client,
             intent.grant,
             now,
             access_expires_at,
             intent.prepared_issuance,
             dependencies
           ),
         {:ok, persisted_access_token} <-
           dependencies.token_store.store_token(issued.access_token),
         {:ok, persisted_refresh_token} <-
           maybe_store_token(
             dependencies.token_store,
             build_poll_refresh_token(intent, now, refresh_expires_at)
           ) do
      Process.put(result_key, %{
        access_token: persisted_access_token,
        refresh_token: persisted_refresh_token,
        refresh_token_raw: refresh_token_raw(intent),
        raw_access_token: issued.raw_access_token,
        issued_at: to_utc_datetime_usec(now),
        expires_in: TokenLifetime.expires_in(now, access_expires_at)
      })

      %{status: :consumed, consumed_at: to_utc_datetime_usec(now)}
    else
      {:error, %Error{} = error} -> {:error, error}
      {:error, :expired} -> {:error, client_authentication_error(:client_app_expired)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp poll_authority_eligibility(
         %Client{} = current_client,
         %{authentication_authority: :client_request} = issuance_context,
         %DateTime{} = now
       ) do
    validate_current_authority(
      current_client,
      issuance_context,
      now,
      :guarded_token_redemption
    )
  end

  defp poll_authority_eligibility(
         %Client{} = current_client,
         %{authentication_authority: :queued_push},
         now
       ),
       do: app_eligibility(current_client, now)

  defp poll_authority_eligibility(%Client{}, _issuance_context, _now),
    do: {:error, server_error(:invalid_poll_authority)}

  defp current_authorization_matches(current, original, now, kind) do
    cond do
      not same_approved_authorization?(current, original) ->
        {:error, :invalid_state}

      DateTime.compare(current.expires_at, now) != :gt ->
        {:error, :expired_token}

      kind == :device and current.device_code_hash != original.device_code_hash ->
        {:error, :invalid_state}

      kind == :ciba and current.auth_req_id_hash != original.auth_req_id_hash ->
        {:error, :invalid_state}

      true ->
        :ok
    end
  end

  defp same_approved_authorization?(current, original) do
    current.client_id == original.client_id and current.status == :approved and
      current.subject_id == original.subject_id and current.approved_at == original.approved_at and
      current.expires_at == original.expires_at
  end

  defp app_eligibility(%Client{} = client, now) do
    case Client.app_eligibility(client, now, :guarded_token_redemption) do
      :ok -> :ok
      {:error, :expired} -> {:error, client_authentication_error(:client_app_expired)}
      {:error, :disabled} -> {:error, client_authentication_error(:client_disabled)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp maybe_poll_refresh_expiry(
         _now,
         _deadline,
         %{prepared_issuance: %{formatted_refresh_token: nil}}
       ),
       do: {:ok, nil}

  defp maybe_poll_refresh_expiry(now, deadline, _intent),
    do: TokenLifetime.effective_expiry(now, TokenLifetime.refresh_token(), deadline)

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

  defp build_poll_refresh_token(
         %{prepared_issuance: %{formatted_refresh_token: nil}},
         _issued_at,
         _expires_at
       ),
       do: nil

  defp build_poll_refresh_token(
         %{
           prepared_issuance: %{formatted_refresh_token: formatted_refresh_token},
           grant: %Token{} = grant,
           issuance_context: issuance_context
         },
         issued_at,
         refresh_expires_at
       ) do
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
      expires_at: refresh_expires_at
    }
  end

  defp refresh_token_raw(%{prepared_issuance: %{formatted_refresh_token: nil}}), do: nil

  defp refresh_token_raw(%{
         prepared_issuance: %{formatted_refresh_token: formatted_refresh_token}
       }),
       do: formatted_refresh_token.token

  defp refresh_token_raw(%{formatted_refresh_token: nil}), do: nil

  defp refresh_token_raw(%{formatted_refresh_token: formatted_refresh_token}),
    do: formatted_refresh_token.token

  defp normalize_transaction({:ok, {:durable_error, %Error{} = error}}), do: {:error, error}
  defp normalize_transaction({:ok, result}), do: {:ok, result}
  defp normalize_transaction({:error, %Error{} = error}), do: {:error, error}
  defp normalize_transaction({:error, reason}), do: {:error, reason}
end
