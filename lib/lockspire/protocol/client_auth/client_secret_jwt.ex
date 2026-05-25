defmodule Lockspire.Protocol.ClientAuth.ClientSecretJwt do
  @moduledoc false

  alias Lockspire.Audit.Event
  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.UsedJti
  alias Lockspire.Observability
  alias Lockspire.Protocol.Jar
  alias Lockspire.Protocol.SecurityProfile
  alias Lockspire.Security.Policy

  @max_assertion_age 600
  @clock_skew 30
  @allowed_algorithm "HS256"

  @spec verify(Client.t(), String.t(), keyword()) :: :ok | {:error, atom()}
  def verify(%Client{} = client, assertion, opts)
      when is_binary(assertion) and is_list(opts) do
    with {:ok, verifier_secret} <- resolve_verifier_secret(client, opts),
         {:ok, allowed_signing_algorithms} <- allowed_signing_algorithms(client, opts),
         {:ok, verified_assertion} <-
           verify_signature(assertion, verifier_secret, allowed_signing_algorithms),
         :ok <- validate_claims(verified_assertion, client, opts),
         :ok <- record_replay(verified_assertion, client, opts) do
      :ok
    else
      {:error, reason} = error ->
        record_failure(reason, client, opts)
        error
    end
  end

  defp resolve_verifier_secret(%Client{client_secret_jwt_verifier_encrypted: encrypted}, opts)
       when is_binary(encrypted) and encrypted != "" do
    case Policy.unseal_client_secret_jwt_verifier(encrypted, opts) do
      {:ok, secret} -> {:ok, secret}
      {:error, :invalid_client_secret_jwt_verifier} -> {:error, :client_secret_verifier_unavailable}
    end
  end

  defp resolve_verifier_secret(%Client{}, _opts), do: {:error, :client_secret_verifier_missing}

  defp allowed_signing_algorithms(%Client{} = client, opts) do
    case server_policy_store(opts).get_server_policy() do
      {:ok, %ServerPolicy{} = server_policy} ->
        resolved = SecurityProfile.resolve_effective_profile(server_policy, client)

        if resolved.fapi_2_0_security? do
          {:error, :client_assertion_auth_method_not_allowed}
        else
          {:ok, [@allowed_algorithm]}
        end

      _ ->
        {:error, :security_profile_unavailable}
    end
  end

  defp verify_signature(assertion, verifier_secret, allowed_signing_algorithms) do
    with {:ok, decoded_assertion} <- Jar.decode(assertion),
         :ok <- validate_algorithm(decoded_assertion, allowed_signing_algorithms) do
      verifier_secret
      |> JOSE.JWK.from_oct()
      |> JOSE.JWT.verify_strict(allowed_signing_algorithms, assertion)
      |> map_signature_result()
    else
      {:error, :invalid_jwt} -> {:error, :invalid_client_assertion}
      {:error, reason} -> {:error, reason}
    end
  end

  defp map_signature_result({true, %JOSE.JWT{} = jwt_struct, %JOSE.JWS{} = jws_struct}) do
    {_modules, claims} = JOSE.JWT.to_map(jwt_struct)
    {_modules, header} = JOSE.JWS.to_map(jws_struct)
    {:ok, %Jar{claims: claims, header: header}}
  rescue
    _ -> {:error, :invalid_client_assertion}
  end

  defp map_signature_result({false, _jwt_struct, _jws_struct}),
    do: {:error, :client_assertion_signature_invalid}

  defp map_signature_result(_other), do: {:error, :client_assertion_signature_invalid}

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

  defp record_failure(reason, %Client{} = client, opts) do
    metadata = failure_metadata(client, reason)
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

  defp failure_metadata(%Client{} = client, reason) do
    %{
      client_id: client.client_id,
      auth_method: :client_secret_jwt,
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
  defp audit_reason?(:client_assertion_algorithm_not_allowed), do: true
  defp audit_reason?(:client_assertion_auth_method_not_allowed), do: true
  defp audit_reason?(_reason), do: false

  defp audit_action(:client_assertion_replayed), do: :client_assertion_replayed
  defp audit_action(_reason), do: :client_auth_failed

  defp audit_outcome(:client_assertion_replayed), do: :denied
  defp audit_outcome(_reason), do: :failed

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
