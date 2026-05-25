defmodule Lockspire.RemoteJwksDiagnostics do
  @moduledoc false

  alias Lockspire.Config
  alias Lockspire.Domain.Client

  @cache_name :lockspire_jwks_cache
  @diagnosis_ttl :timer.hours(6)

  @type diagnosis :: %{
          posture: atom(),
          posture_label: String.t(),
          category: atom(),
          summary: String.t(),
          detail: String.t(),
          remediation: [String.t()],
          supported?: boolean(),
          refresh_attempted?: boolean(),
          last_known_good_cache?: boolean(),
          source: atom(),
          trigger: atom() | nil,
          fetch_reason: term() | nil,
          observed_at: DateTime.t()
        }

  @spec latest_runtime(Client.t()) :: diagnosis() | nil
  def latest_runtime(%Client{} = client) do
    case Cachex.get(@cache_name, cache_key(client)) do
      {:ok, nil} -> nil
      {:ok, diagnosis} when is_map(diagnosis) -> diagnosis
      _other -> nil
    end
  end

  @spec diagnose_client(Client.t(), keyword()) :: {:ok, diagnosis()} | {:error, diagnosis() | atom()}
  def diagnose_client(%Client{jwks_uri: jwks_uri} = client, opts) when is_binary(jwks_uri) do
    fetcher = Keyword.get(opts, :jwks_fetcher, Config.jwks_fetcher())

    case fetcher.get_keys(jwks_uri, jwks_fetcher_opts(opts)) do
      {:ok, _jwk_set} ->
        diagnosis =
          healthy(client, %{
            source: :probe,
            detail: "Guarded fetch succeeded for the currently configured remote JWKS URI."
          })
          |> maybe_attach_runtime_observation(client)

        {:ok, diagnosis}

      {:error, {:jwks_fetch_failed, reason}} ->
        diagnosis =
          fetch_failure(client, reason, %{source: :probe})
          |> maybe_attach_runtime_observation(client)

        {:error, diagnosis}

      {:error, reason} ->
        diagnosis =
          fetch_failure(client, reason, %{source: :probe, category: :unknown})
          |> maybe_attach_runtime_observation(client)

        {:error, diagnosis}
    end
  end

  def diagnose_client(%Client{}, _opts), do: {:error, :not_applicable}

  @spec record_healthy(Client.t(), keyword() | map()) :: diagnosis()
  def record_healthy(%Client{} = client, attrs \\ %{}) do
    diagnosis = healthy(client, normalize_attrs(attrs))
    store(client, diagnosis)
  end

  @spec record_fetch_failure(Client.t(), term(), keyword() | map()) :: diagnosis()
  def record_fetch_failure(%Client{} = client, reason, attrs \\ %{}) do
    diagnosis = fetch_failure(client, reason, normalize_attrs(attrs))
    store(client, diagnosis)
  end

  @spec record_supported_refresh_recovery(Client.t(), atom(), keyword() | map()) :: diagnosis()
  def record_supported_refresh_recovery(%Client{} = client, trigger, attrs \\ %{}) do
    attrs = normalize_attrs(attrs)

    diagnosis =
      base_diagnosis(
        attrs[:source] || :runtime,
        :supported_refresh_recovery,
        "Supported refresh recovery",
        :freshness,
        attrs[:detail] ||
          "Lockspire detected a stale remote JWKS cache signal, performed one bounded refresh, and recovered with the refreshed key set.",
        [
          "Keep the previous key published until clients begin signing or encrypting with the new key.",
          "Publish rotated keys under a new `kid` whenever possible so Lockspire can prove the cache is stale."
        ],
        true,
        true,
        attrs[:last_known_good_cache?] || true,
        trigger,
        nil
      )

    store(client, diagnosis)
  end

  @spec record_refresh_failure(Client.t(), atom(), term(), keyword() | map()) :: diagnosis()
  def record_refresh_failure(%Client{} = client, trigger, reason, attrs \\ %{}) do
    attrs = normalize_attrs(attrs)
    {posture, label, category, remediation} = refresh_failure_shape(reason)

    diagnosis =
      base_diagnosis(
        attrs[:source] || :runtime,
        posture,
        label,
        category,
        attrs[:detail] ||
          "Lockspire attempted one bounded remote JWKS refresh after a stale-cache signal, preserved the last-known-good cache entry, and failed the current request closed.",
        remediation,
        false,
        true,
        true,
        trigger,
        reason
      )

    store(client, diagnosis)
  end

  @spec record_unsupported_rollover(Client.t(), atom(), keyword() | map()) :: diagnosis()
  def record_unsupported_rollover(%Client{} = client, trigger, attrs \\ %{}) do
    attrs = normalize_attrs(attrs)

    diagnosis =
      base_diagnosis(
        attrs[:source] || :runtime,
        :unsupported_rollover,
        "Unsupported rollover posture",
        :unsupported_rollover,
        attrs[:detail] ||
          "The remote JWKS rollover shape was ambiguous after Lockspire's bounded checks, so the runtime failed closed instead of implying automatic recovery support.",
        [
          "Publish the replacement key under a new `kid` and keep the previous key available during rollover.",
          "If overlap is impossible, re-register the client with inline `jwks` instead of relying on ambiguous remote rotation behavior."
        ],
        false,
        attrs[:refresh_attempted?] || false,
        attrs[:last_known_good_cache?] || true,
        trigger,
        nil
      )

    store(client, diagnosis)
  end

  defp healthy(_client, attrs) do
    base_diagnosis(
      attrs[:source] || :runtime,
      :healthy,
      "Healthy",
      :healthy,
      attrs[:detail] ||
        "Guarded remote JWKS retrieval succeeded and Lockspire is operating within the supported bounded-cache posture.",
      [
        "Keep using `https` and publish replacement keys with overlapping availability during rollover."
      ],
      true,
      attrs[:refresh_attempted?] || false,
      attrs[:last_known_good_cache?] || true,
      attrs[:trigger],
      nil
    )
  end

  defp fetch_failure(_client, reason, attrs) do
    attrs = normalize_attrs(attrs)
    {posture, label, category, remediation} = fetch_failure_shape(reason, attrs[:category])

    base_diagnosis(
      attrs[:source] || :runtime,
      posture,
      label,
      category,
      attrs[:detail] || fetch_failure_detail(reason, category),
      remediation,
      false,
      attrs[:refresh_attempted?] || false,
      attrs[:last_known_good_cache?] || false,
      attrs[:trigger],
      reason
    )
  end

  defp refresh_failure_shape(reason) do
    case fetch_failure_shape(reason, nil) do
      {:invalid_remote_target, _label, :target_safety, remediation} ->
        {:refresh_blocked_by_target, "Refresh blocked by target safety", :target_safety, remediation}

      {:malformed_remote_jwks, _label, :payload, remediation} ->
        {:refresh_failed_bad_payload, "Refresh failed with malformed remote JWKS", :payload, remediation}

      {:transient_fetch_failure, _label, category, remediation} ->
        {:refresh_failed_cached_entry_preserved, "Refresh failed, cached keys preserved", category, remediation}

      {:remote_http_failure, _label, :http, remediation} ->
        {:refresh_failed_cached_entry_preserved, "Refresh failed, cached keys preserved", :http, remediation}

      {_posture, _label, category, remediation} ->
        {:refresh_failed_cached_entry_preserved, "Refresh failed, cached keys preserved", category, remediation}
    end
  end

  defp fetch_failure_shape(reason, forced_category) do
    case forced_category || fetch_failure_category(reason) do
      :target_safety ->
        {:invalid_remote_target, "Invalid or unsafe remote JWKS target", :target_safety,
         [
           "Use an `https` JWKS URI with a resolvable public host and no redirects.",
           "Fix the configured `jwks_uri` before relying on remote key retrieval."
         ]}

      :transport ->
        {:transient_fetch_failure, "Transient remote JWKS fetch failure", :transport,
         [
           "Restore upstream network availability and retry the operation.",
           "Lockspire will continue using the last-known-good cache entry when one exists."
         ]}

      :http ->
        {:remote_http_failure, "Remote JWKS HTTP failure", :http,
         [
           "Check the remote JWKS endpoint status code, availability, and published path.",
           "Restore key overlap before retrying if the upstream rotated keys concurrently."
         ]}

      :payload ->
        {:malformed_remote_jwks, "Malformed remote JWKS payload", :payload,
         [
           "Publish a valid JWKS document that fits within Lockspire's bounded body limit.",
           "Do not expose redirect responses or non-JWKS JSON at the configured `jwks_uri`."
         ]}

      _other ->
        {:transient_fetch_failure, "Remote JWKS fetch failure", :unknown,
         [
           "Inspect the upstream JWKS endpoint and retry after the failure is corrected."
         ]}
    end
  end

  defp fetch_failure_category({:unsafe_target, _reason}), do: :target_safety
  defp fetch_failure_category(:https_required), do: :target_safety
  defp fetch_failure_category(:invalid_uri), do: :target_safety
  defp fetch_failure_category(:resolution_failed), do: :target_safety
  defp fetch_failure_category(:timeout), do: :transport
  defp fetch_failure_category(:transport_error), do: :transport
  defp fetch_failure_category({:http_status, _status}), do: :http
  defp fetch_failure_category(:redirect_disallowed), do: :http
  defp fetch_failure_category(:invalid_format), do: :payload
  defp fetch_failure_category(:payload_too_large), do: :payload
  defp fetch_failure_category(_reason), do: :unknown

  defp fetch_failure_detail(reason, :http) do
    case reason do
      {:http_status, status} ->
        "The remote JWKS endpoint returned HTTP #{status}, so Lockspire failed closed instead of trusting incomplete rollover state."

      :redirect_disallowed ->
        "The remote JWKS endpoint attempted a redirect, which Lockspire rejects to preserve exact-target trust."

      _other ->
        "The remote JWKS endpoint returned an HTTP response Lockspire does not treat as a usable key set."
    end
  end

  defp fetch_failure_detail(reason, :target_safety) do
    case reason do
      {:unsafe_target, unsafe_reason} ->
        "Lockspire blocked the remote JWKS target because it resolved to an unsafe destination (#{unsafe_reason})."

      :https_required ->
        "Lockspire only supports `https` remote JWKS targets."

      :invalid_uri ->
        "The configured remote JWKS URI is malformed or missing a usable host."

      :resolution_failed ->
        "Lockspire could not resolve the remote JWKS host safely."

      _other ->
        "Lockspire rejected the configured remote JWKS target before trusting any response body."
    end
  end

  defp fetch_failure_detail(reason, :payload) do
    case reason do
      :payload_too_large ->
        "The remote JWKS payload exceeded Lockspire's bounded body limit and was rejected."

      :invalid_format ->
        "The remote JWKS payload was not valid JWKS JSON."

      _other ->
        "The remote JWKS payload did not satisfy Lockspire's strict parsing rules."
    end
  end

  defp fetch_failure_detail(reason, :transport) do
    case reason do
      :timeout ->
        "The remote JWKS request timed out before Lockspire could safely refresh the cache."

      :transport_error ->
        "The remote JWKS request failed before Lockspire received a usable response."

      _other ->
        "The remote JWKS request failed during network transport."
    end
  end

  defp fetch_failure_detail(reason, _category) do
    "Lockspire could not complete the remote JWKS operation (#{inspect(reason)})."
  end

  defp base_diagnosis(
         source,
         posture,
         posture_label,
         category,
         detail,
         remediation,
         supported?,
         refresh_attempted?,
         last_known_good_cache?,
         trigger,
         fetch_reason
       ) do
    %{
      posture: posture,
      posture_label: posture_label,
      category: category,
      summary: posture_summary(posture),
      detail: detail,
      remediation: remediation,
      supported?: supported?,
      refresh_attempted?: refresh_attempted?,
      last_known_good_cache?: last_known_good_cache?,
      source: source,
      trigger: trigger,
      fetch_reason: fetch_reason,
      observed_at: DateTime.utc_now()
    }
  end

  defp posture_summary(:healthy),
    do: "Remote JWKS is operating inside Lockspire's supported bounded-cache posture."

  defp posture_summary(:supported_refresh_recovery),
    do: "Lockspire recovered from a supported stale-cache signal with one refresh."

  defp posture_summary(:unsupported_rollover),
    do: "The observed rollover shape is outside Lockspire's automatic recovery contract."

  defp posture_summary(:refresh_failed_cached_entry_preserved),
    do: "Lockspire preserved the last-known-good cache entry after a failed refresh."

  defp posture_summary(:refresh_failed_bad_payload),
    do: "Lockspire preserved the last-known-good cache entry after rejecting malformed remote JWKS."

  defp posture_summary(:refresh_blocked_by_target),
    do: "Lockspire preserved the last-known-good cache entry because the refresh target was unsafe."

  defp posture_summary(:invalid_remote_target),
    do: "The configured remote JWKS target is not in a supported posture."

  defp posture_summary(:malformed_remote_jwks),
    do: "The configured remote JWKS endpoint returned unusable key material."

  defp posture_summary(:remote_http_failure),
    do: "The configured remote JWKS endpoint returned an HTTP failure."

  defp posture_summary(:transient_fetch_failure),
    do: "The remote JWKS endpoint failed transiently and Lockspire failed closed."

  defp posture_summary(_posture),
    do: "Remote JWKS posture changed."

  defp maybe_attach_runtime_observation(diagnosis, client) do
    case latest_runtime(client) do
      nil -> diagnosis
      runtime -> Map.put(diagnosis, :last_runtime_observation, runtime)
    end
  end

  defp store(client, diagnosis) do
    _ = Cachex.put(@cache_name, cache_key(client), diagnosis, expire: @diagnosis_ttl)
    diagnosis
  end

  defp cache_key(%Client{client_id: client_id, jwks_uri: jwks_uri}),
    do: {:remote_jwks_diagnosis, client_id, jwks_uri}

  defp jwks_fetcher_opts(opts) do
    Config.jwks_fetcher_opts()
    |> Keyword.merge(Keyword.get(opts, :jwks_fetcher_opts, []))
  end

  defp normalize_attrs(attrs) when is_map(attrs), do: attrs
  defp normalize_attrs(attrs) when is_list(attrs), do: Enum.into(attrs, %{})
  defp normalize_attrs(_attrs), do: %{}
end
