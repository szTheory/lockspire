defmodule Lockspire.Protocol.ClientAuth.PrivateKeyJwt do
  @moduledoc false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.UsedJti
  alias Lockspire.Audit.Event
  alias Lockspire.Observability
  alias Lockspire.Protocol.Jar
  alias Lockspire.Protocol.SecurityProfile
  alias Lockspire.Config

  @max_assertion_age 600
  @clock_skew 30

  @spec verify(Client.t(), String.t(), keyword()) :: :ok | {:error, atom()}
  def verify(%Client{} = client, assertion, opts)
      when is_binary(assertion) and is_list(opts) do
    case resolve_keys(client, opts) do
      {:ok, verified_client, jwks_source} ->
        with {:ok, allowed_signing_algorithms} <-
               allowed_signing_algorithms(verified_client, opts),
             {:ok, verified_assertion} <-
               verify_signature(
                 assertion,
                 verified_client,
                 allowed_signing_algorithms,
                 jwks_source,
                 opts
               ),
             :ok <- validate_claims(verified_assertion, verified_client, opts),
             :ok <- record_replay(verified_assertion, verified_client, opts) do
          :ok
        else
          {:error, reason} = error ->
            record_failure(reason, client, jwks_source_for_failure(client, jwks_source), opts)
            error
        end

      {:error, reason} = error ->
        record_failure(reason, client, jwks_source_for_failure(client, nil), opts)
        error
    end
  end

  defp resolve_keys(%Client{jwks: jwks} = client, _opts) when is_map(jwks),
    do: {:ok, client, :inline_jwks}

  defp resolve_keys(%Client{jwks_uri: jwks_uri} = client, opts) when is_binary(jwks_uri) do
    fetcher = Keyword.get(opts, :jwks_fetcher, Config.jwks_fetcher())

    with {:ok, jwk_set} <- fetcher.get_keys(jwks_uri, jwks_fetcher_opts(opts)),
         {_modules, jwks} <- JOSE.JWK.to_map(jwk_set) do
      {:ok, %Client{client | jwks: jwks}, :jwks_uri}
    else
      {:error, _reason} -> {:error, :client_jwks_fetch_failed}
    end
  end

  defp resolve_keys(%Client{}, _opts), do: {:error, :client_jwks_missing}

  defp allowed_signing_algorithms(%Client{} = client, opts) do
    with {:ok, %ServerPolicy{} = server_policy} <- server_policy_store(opts).get_server_policy() do
      resolved = SecurityProfile.resolve_effective_profile(server_policy, client)
      {:ok, SecurityProfile.allowed_signing_algorithms(resolved.effective_profile)}
    else
      _ -> {:error, :security_profile_unavailable}
    end
  end

  defp verify_signature(assertion, client, allowed_signing_algorithms, jwks_source, opts) do
    case verify_signature_once(assertion, client, allowed_signing_algorithms) do
      {:error, :no_matching_key} when jwks_source == :jwks_uri ->
        retry_remote_signature_verification(assertion, client, allowed_signing_algorithms, opts)

      {:error, :invalid_signature} when jwks_source == :jwks_uri ->
        if stale_remote_kid?(client, assertion) do
          retry_remote_signature_verification(assertion, client, allowed_signing_algorithms, opts)
        else
          map_signature_result({:error, :invalid_signature})
        end

      other ->
        map_signature_result(other)
    end
  end

  defp verify_signature_once(assertion, client, allowed_signing_algorithms) do
    with {:ok, decoded_assertion} <- Jar.decode(assertion),
         :ok <- validate_algorithm(decoded_assertion, allowed_signing_algorithms) do
      Jar.verify_signature(assertion, client, allowed_signing_algorithms)
    else
      {:error, :invalid_jwt} -> {:error, :invalid_client_assertion}
      {:error, reason} -> {:error, reason}
    end
  end

  defp retry_remote_signature_verification(assertion, %Client{jwks_uri: jwks_uri} = client, allowed_signing_algorithms, opts) do
    fetcher = Keyword.get(opts, :jwks_fetcher, Config.jwks_fetcher())

    with {:ok, jwk_set} <- fetcher.refresh_keys(jwks_uri, jwks_fetcher_opts(opts)),
         {_modules, jwks} <- JOSE.JWK.to_map(jwk_set),
         refreshed_client = %Client{client | jwks: jwks},
         result <- verify_signature_once(assertion, refreshed_client, allowed_signing_algorithms) do
      map_signature_result(result)
    else
      {:error, _reason} -> {:error, :client_jwks_fetch_failed}
    end
  end

  defp map_signature_result({:ok, verified_assertion}), do: {:ok, verified_assertion}
  defp map_signature_result({:error, :invalid_signature}), do: {:error, :client_assertion_signature_invalid}
  defp map_signature_result({:error, :no_matching_key}), do: {:error, :client_assertion_signature_invalid}
  defp map_signature_result({:error, :invalid_client_keys}), do: {:error, :client_jwks_invalid}
  defp map_signature_result({:error, :invalid_typ}), do: {:error, :client_assertion_typ_invalid}
  defp map_signature_result({:error, reason}), do: {:error, reason}

  defp jwks_fetcher_opts(opts) do
    Config.jwks_fetcher_opts()
    |> Keyword.merge(Keyword.get(opts, :jwks_fetcher_opts, []))
  end

  defp stale_remote_kid?(%Client{jwks: jwks}, assertion) when is_map(jwks) do
    with {:ok, %Jar{header: header}} <- Jar.decode(assertion),
         kid when is_binary(kid) and kid != "" <- Map.get(header, "kid") do
      not jwks_contains_kid?(jwks, kid)
    else
      _ -> false
    end
  end

  defp stale_remote_kid?(_client, _assertion), do: false

  defp jwks_contains_kid?(%{"keys" => keys}, kid) when is_list(keys) do
    Enum.any?(keys, &(Map.get(&1, "kid") == kid))
  end

  defp jwks_contains_kid?(jwk, kid) when is_map(jwk) do
    Map.get(jwk, "kid") == kid
  end

  defp jwks_contains_kid?(_jwks, _kid), do: false

  defp validate_algorithm(%Jar{header: header}, allowed_signing_algorithms) do
    case Map.get(header, "alg") do
      alg when is_binary(alg) ->
        if alg in allowed_signing_algorithms do
          :ok
        else
          {:error, :client_assertion_algorithm_not_allowed}
        end

      _other ->
        {:error, :client_assertion_algorithm_not_allowed}
    end
  end

  defp validate_claims(%Jar{} = verified_assertion, %Client{} = client, opts) do
    with :ok <- validate_required_subject(verified_assertion, client.client_id),
         :ok <- validate_required_timing_claims(verified_assertion),
         :ok <- validate_assertion_lifetime(verified_assertion),
         :ok <-
           Jar.validate_claims(
             verified_assertion,
             expected_client_id: client.client_id,
             expected_audience: Config.issuer!(),
             now: now(opts),
             leeway: @clock_skew,
             max_age: @max_assertion_age
           ) do
      :ok
    else
      {:error, reason} -> {:error, map_claim_validation_reason(reason)}
    end
  end

  defp validate_required_subject(%Jar{claims: claims}, client_id) do
    case Map.get(claims, "sub") do
      nil -> {:error, :missing_subject}
      ^client_id -> :ok
      _other -> {:error, :invalid_subject}
    end
  end

  defp validate_required_timing_claims(%Jar{claims: claims}) do
    if is_integer(claims["iat"]) or is_integer(claims["nbf"]) do
      :ok
    else
      {:error, :missing_timing_claim}
    end
  end

  defp validate_assertion_lifetime(%Jar{claims: claims}) do
    with exp when is_integer(exp) <- claims["exp"],
         {:ok, start_time} <- assertion_start_time(claims) do
      if exp - start_time <= @max_assertion_age + @clock_skew do
        :ok
      else
        {:error, :expiration_too_far}
      end
    else
      nil -> {:error, :missing_expiration}
      {:error, reason} -> {:error, reason}
      _other -> {:error, :invalid_expiration}
    end
  end

  defp assertion_start_time(claims) do
    claims
    |> Enum.filter(fn {key, value} -> key in ["iat", "nbf"] and is_integer(value) end)
    |> Enum.map(&elem(&1, 1))
    |> case do
      [] -> {:error, :missing_timing_claim}
      values -> {:ok, Enum.min(values)}
    end
  end

  defp record_replay(%Jar{claims: claims}, %Client{} = client, opts) do
    with {:ok, jti} <- fetch_replay_claim(claims, "jti"),
         {:ok, exp} <- fetch_replay_expiration(claims),
         {:ok, expires_at} <- DateTime.from_unix((exp + @clock_skew) * 1_000_000, :microsecond),
         {:ok, result} <-
           replay_store(opts).record_used_jti(%UsedJti{
             client_id: client.client_id,
             jti: jti,
             expires_at: expires_at
           }) do
      case result do
        :accepted -> :ok
        :replay -> {:error, :client_assertion_replayed}
      end
    else
      {:error, :missing_jti} -> {:error, :client_assertion_jti_missing}
      {:error, :invalid_expiration} -> {:error, :client_assertion_expired}
      {:error, _reason} -> {:error, :client_assertion_replay_store_failed}
      _other -> {:error, :client_assertion_replay_store_failed}
    end
  end

  defp fetch_replay_claim(claims, key) do
    case Map.get(claims, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _other -> {:error, :missing_jti}
    end
  end

  defp fetch_replay_expiration(claims) do
    case Map.get(claims, "exp") do
      value when is_integer(value) -> {:ok, value}
      _other -> {:error, :invalid_expiration}
    end
  end

  defp map_claim_validation_reason(:missing_issuer), do: :client_assertion_issuer_missing
  defp map_claim_validation_reason(:invalid_issuer), do: :client_assertion_issuer_invalid
  defp map_claim_validation_reason(:missing_subject), do: :client_assertion_subject_missing
  defp map_claim_validation_reason(:invalid_subject), do: :client_assertion_subject_invalid
  defp map_claim_validation_reason(:missing_audience), do: :client_assertion_audience_missing
  defp map_claim_validation_reason(:invalid_audience), do: :client_assertion_audience_invalid
  defp map_claim_validation_reason(:missing_expiration), do: :client_assertion_expiration_missing
  defp map_claim_validation_reason(:invalid_expiration), do: :client_assertion_expiration_invalid
  defp map_claim_validation_reason(:expired_token), do: :client_assertion_expired
  defp map_claim_validation_reason(:expiration_too_far), do: :client_assertion_lifetime_too_long
  defp map_claim_validation_reason(:invalid_not_before), do: :client_assertion_not_before_invalid
  defp map_claim_validation_reason(:invalid_issued_at), do: :client_assertion_issued_at_invalid
  defp map_claim_validation_reason(:missing_timing_claim), do: :client_assertion_timing_missing
  defp map_claim_validation_reason(_reason), do: :invalid_client_assertion

  defp record_failure(reason, %Client{} = client, jwks_source, opts) do
    metadata = failure_metadata(client, reason, jwks_source)
    action = telemetry_action(reason)

    Observability.emit(:client_auth, action, %{}, metadata)
    append_audit_event(reason, client, metadata, opts)
  end

  defp append_audit_event(reason, %Client{} = client, metadata, opts) do
    store = replay_store(opts)

    if function_exported?(store, :append_audit_event, 1) and audit_reason?(reason) do
      event =
        Event.normalize(%{
          action: audit_action(reason),
          outcome: audit_outcome(reason),
          reason_code: reason,
          actor: %{type: :client, id: client.client_id, display: client.client_id},
          resource: %{type: :client_authentication, id: client.client_id},
          metadata: metadata
        })

      _ = store.append_audit_event(event)
      :ok
    else
      :ok
    end
  end

  defp failure_metadata(%Client{} = client, reason, jwks_source) do
    %{
      client_id: client.client_id,
      auth_method: :private_key_jwt,
      jwks_source: jwks_source,
      reason_code: reason
    }
  end

  defp telemetry_action(:client_assertion_replayed), do: :replay_detected
  defp telemetry_action(_reason), do: :failed

  defp audit_reason?(:client_assertion_replayed), do: true
  defp audit_reason?(:client_assertion_signature_invalid), do: true
  defp audit_reason?(:client_assertion_audience_invalid), do: true
  defp audit_reason?(:client_assertion_issuer_invalid), do: true
  defp audit_reason?(:client_assertion_subject_invalid), do: true
  defp audit_reason?(_reason), do: false

  defp audit_action(:client_assertion_replayed), do: :client_assertion_replayed
  defp audit_action(_reason), do: :client_auth_failed

  defp audit_outcome(:client_assertion_replayed), do: :denied
  defp audit_outcome(_reason), do: :failed

  defp jwks_source_for_failure(%Client{jwks: jwks}, _resolved_source) when is_map(jwks),
    do: :inline_jwks

  defp jwks_source_for_failure(%Client{jwks_uri: jwks_uri}, _resolved_source)
       when is_binary(jwks_uri), do: :jwks_uri

  defp jwks_source_for_failure(_client, resolved_source), do: resolved_source || :unknown

  defp replay_store(opts), do: Keyword.get(opts, :jti_store, Keyword.fetch!(opts, :client_store))

  defp server_policy_store(opts),
    do:
      Keyword.get_lazy(opts, :server_policy_store, fn ->
        case Keyword.get(opts, :client_store) do
          nil ->
            Config.repo!()

          store ->
            if function_exported?(store, :get_server_policy, 0), do: store, else: Config.repo!()
        end
      end)

  defp now(opts) do
    case Keyword.get(opts, :now) do
      %DateTime{} = now -> now
      now_fun when is_function(now_fun, 0) -> now_fun.()
      nil -> DateTime.utc_now()
    end
  end
end
