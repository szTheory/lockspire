defmodule Lockspire.Admin.Keys.Reencrypt do
  @moduledoc false

  # Re-encryption engine behind `Lockspire.Admin.Keys.reencrypt/1`. Each signing-key row is
  # converted in its own transaction: the store locks the row, this module decides what to do
  # with its stored private material, and the store applies the decision.
  #
  # Nothing here formats rows, maps or errors into strings, so key material cannot reach a
  # report, a log line or an audit entry by accident.

  alias Lockspire.Domain.SigningKey
  alias Lockspire.Protocol.PrivateJwk
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Security.KeyEncryption.KeySet
  alias Lockspire.Storage.Ecto.Repository

  @default_page_size 100

  @spec run(KeySet.t(), map(), keyword()) :: map()
  def run(%KeySet{} = keyset, actor, opts) when is_map(actor) and is_list(opts) do
    decide = fn key -> decide(key, keyset, actor) end
    report = new_report(keyset)

    report =
      if Keyword.get(opts, :dry_run, false) do
        dry_run(%{report | dry_run: true}, decide)
      else
        page_size = Keyword.get(opts, :page_size, @default_page_size)
        store_opts = Keyword.take(opts, [:after_lock])
        walk_pages(report, 0, page_size, decide, store_opts)
      end

    finalize(report)
  end

  # The single sealability rule. The engine and the readiness status both classify rows here,
  # so a row can never be sealable for one and unsealable for the other. It is pure: no
  # database access, no telemetry and no logging.
  @doc false
  @spec assess(SigningKey.t(), KeySet.t() | nil) ::
          :no_private_key
          | :sealable_legacy
          | {:envelope, String.t()}
          | {:unsealable, atom(), String.t() | nil}
  def assess(%SigningKey{private_jwk_encrypted: nil}, _keyset), do: :no_private_key

  def assess(%SigningKey{private_jwk_encrypted: bin} = key, keyset) when is_binary(bin) do
    case KeyEncryption.classify(bin) do
      :envelope -> assess_envelope(key, keyset)
      :legacy -> assess_legacy(key, keyset)
      :invalid -> {:unsealable, :unreadable_legacy, nil}
    end
  end

  def assess(%SigningKey{}, _keyset), do: {:unsealable, :unreadable_legacy, nil}

  defp assess_envelope(key, keyset) do
    case KeyEncryption.envelope_kek_id(key.private_jwk_encrypted) do
      {:ok, kek_id} -> assess_envelope(key, keyset, kek_id)
      {:error, _reason} -> {:unsealable, :malformed_envelope, nil}
    end
  end

  defp assess_envelope(_key, nil, kek_id), do: {:unsealable, :unknown_kek, kek_id}

  defp assess_envelope(key, keyset, kek_id) do
    case PrivateJwk.read_stored(key, keyset) do
      {:ok, _jwk, {:envelope, ^kek_id}} -> {:envelope, kek_id}
      {:error, reason} -> {:unsealable, envelope_reason(reason), kek_id}
    end
  end

  defp envelope_reason(:invalid_signing_key), do: :malformed_envelope
  defp envelope_reason(:kek_not_configured), do: :unknown_kek
  defp envelope_reason(reason) when is_atom(reason), do: reason

  defp assess_legacy(key, keyset) do
    case PrivateJwk.read_stored(key, keyset) do
      {:ok, %{} = jwk, :legacy} ->
        if Map.get(jwk, "kid") == key.kid,
          do: :sealable_legacy,
          else: {:unsealable, :kid_mismatch, nil}

      _other ->
        {:unsealable, :unreadable_legacy, nil}
    end
  end

  @doc false
  @spec decide(SigningKey.t(), KeySet.t(), map()) :: tuple()
  def decide(%SigningKey{} = key, %KeySet{} = keyset, actor) do
    {current_id, _material} = KeySet.current(keyset)

    case assess(key, keyset) do
      :no_private_key ->
        {:keep, info(key, %{class: :no_private_key})}

      {:unsealable, reason, kek_id} ->
        {:fail, reason, info(key, %{kek_id: kek_id, source: failure_source(key, kek_id)})}

      :sealable_legacy ->
        reseal(key, keyset, actor, %{action: :encrypted, source: "legacy", kek_id: current_id})

      {:envelope, ^current_id} ->
        {:keep, info(key, %{class: :already_current, kek_id: current_id, source: current_id})}

      {:envelope, previous} ->
        reseal(key, keyset, actor, %{
          action: :rewrapped,
          source: previous,
          previous_kek_id: previous,
          kek_id: current_id
        })
    end
  end

  defp failure_source(_key, kek_id) when is_binary(kek_id), do: kek_id

  defp failure_source(%SigningKey{private_jwk_encrypted: bin}, nil) when is_binary(bin),
    do: if(KeyEncryption.classify(bin) == :legacy, do: "legacy")

  defp reseal(key, keyset, actor, details) do
    with {:ok, %{} = jwk, _source} <- PrivateJwk.read_stored(key, keyset),
         {:ok, sealed} <- seal_and_verify(key, jwk, keyset) do
      action = if details.action == :encrypted, do: :key_encrypted, else: :key_rewrapped
      {:replace, sealed, audit_event(action, key, actor, details), info(key, details)}
    else
      {:error, :unreadable_legacy} -> reseal_failure(key, :unreadable_legacy, details)
      _other -> reseal_failure(key, :roundtrip_failed, details)
    end
  end

  defp reseal_failure(key, reason, details) do
    {:fail, reason, info(key, %{source: details.source, kek_id: details[:previous_kek_id]})}
  end

  defp seal_and_verify(key, jwk, keyset) do
    case Jason.encode(jwk) do
      {:ok, json} -> seal_and_open(key, keyset, json)
      {:error, _reason} -> {:error, :unreadable_legacy}
    end
  end

  # The same key set seals and re-opens the new bytes before anything is written, so a row
  # is never replaced with an envelope this node cannot read back.
  defp seal_and_open(key, keyset, json) do
    with {:ok, sealed} <- KeyEncryption.seal(keyset, key.kid, json),
         {:ok, reopened} <- KeyEncryption.open(keyset, key.kid, sealed),
         {:ok, %{} = back} <- Jason.decode(reopened),
         true <- Map.get(back, "kid") == key.kid do
      {:ok, sealed}
    else
      _other -> {:error, :roundtrip_failed}
    end
  end

  defp dry_run(report, decide) do
    case Repository.list_signing_keys() do
      {:ok, keys} ->
        keys
        |> Enum.sort_by(& &1.id)
        |> Enum.reduce(report, fn key, acc ->
          acc = Map.update!(acc, :scanned, &(&1 + 1))
          apply_outcome(acc, key.kid, simulate(decide.(key)))
        end)

      {:error, _reason} ->
        listing_failure(report)
    end
  end

  defp simulate({:replace, _binary, _audit_event, info}), do: {:replaced, info}
  defp simulate({:keep, info}), do: {:kept, info}
  defp simulate({:fail, reason, info}), do: {:failed, reason, info}

  defp new_report(keyset) do
    {current_id, _material} = KeySet.current(keyset)

    %{
      dry_run: false,
      current_kek_id: current_id,
      scanned: 0,
      encrypted: 0,
      rewrapped: 0,
      already_current: 0,
      no_private_key: 0,
      conflicted: 0,
      by_source_kek: %{},
      failed: [],
      changes: []
    }
  end

  defp finalize(report) do
    %{report | failed: Enum.reverse(report.failed), changes: Enum.reverse(report.changes)}
  end

  defp walk_pages(report, cursor, page_size, decide, store_opts) do
    case Repository.list_signing_key_refs(cursor, page_size) do
      {:ok, []} ->
        report

      {:ok, refs} ->
        report = Enum.reduce(refs, report, &process_ref(&1, &2, decide, store_opts))
        {last_id, _kid} = List.last(refs)
        walk_pages(report, last_id, page_size, decide, store_opts)

      {:error, _reason} ->
        listing_failure(report)
    end
  end

  defp listing_failure(report),
    do: add_failure(report, %{kid: nil, reason: :storage_error, kek_id: nil, status: nil})

  defp process_ref({id, kid}, report, decide, store_opts) do
    report = Map.update!(report, :scanned, &(&1 + 1))

    case Repository.reencrypt_signing_key(id, decide, store_opts) do
      {:ok, outcome} -> apply_outcome(report, kid, outcome)
      {:error, _reason} -> add_failure(report, storage_failure(kid))
    end
  end

  defp apply_outcome(report, _kid, {:kept, %{class: :no_private_key}}),
    do: Map.update!(report, :no_private_key, &(&1 + 1))

  defp apply_outcome(report, _kid, {:kept, %{class: :already_current} = info}) do
    report
    |> Map.update!(:already_current, &(&1 + 1))
    |> count_source(info.source)
  end

  defp apply_outcome(report, _kid, {:replaced, info}) do
    report
    |> Map.update!(info.action, &(&1 + 1))
    |> count_source(info.source)
    |> Map.update!(:changes, &[%{kid: info.kid, action: info.action, from: info.source} | &1])
  end

  defp apply_outcome(report, kid, {:failed, reason, info}) do
    report
    |> count_source(info.source)
    |> add_failure(%{kid: kid, reason: reason, kek_id: info.kek_id, status: info.status})
  end

  defp apply_outcome(report, _kid, outcome) when outcome in [:conflict, :not_found],
    do: Map.update!(report, :conflicted, &(&1 + 1))

  defp storage_failure(kid), do: %{kid: kid, reason: :storage_error, kek_id: nil, status: nil}

  defp add_failure(report, entry), do: Map.update!(report, :failed, &[entry | &1])

  defp count_source(report, nil), do: report

  defp count_source(report, source),
    do: Map.update!(report, :by_source_kek, &Map.update(&1, source, 1, fn n -> n + 1 end))

  defp info(%SigningKey{} = key, extra) do
    Map.merge(
      %{
        key_id: key.id,
        kid: key.kid,
        status: key.status,
        use: key.use,
        kek_id: nil,
        previous_kek_id: nil,
        source: nil
      },
      extra
    )
  end

  defp audit_event(action, %SigningKey{} = key, actor, details) do
    metadata =
      maybe_put(
        %{key_id: key.id, kid: key.kid, status: key.status, use: key.use, kek_id: details.kek_id},
        :previous_kek_id,
        Map.get(details, :previous_kek_id)
      )

    %{
      action: action,
      outcome: :succeeded,
      reason_code: action,
      actor: actor,
      resource: %{type: :signing_key, id: key.id},
      metadata: metadata
    }
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
