defmodule Lockspire.Admin.Keys.Reencrypt do
  @moduledoc false

  # Re-encryption engine behind `Lockspire.Admin.Keys.reencrypt/1`. Each signing-key row is
  # converted in its own short transaction: the store locks the row, this module decides what
  # to do with its stored private material, and the store applies the decision.

  alias Lockspire.Domain.SigningKey
  alias Lockspire.Protocol.PrivateJwk
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Security.KeyEncryption.KeySet
  alias Lockspire.Storage.Ecto.Repository

  @default_page_size 100

  @spec run(KeySet.t(), map(), keyword()) :: map()
  def run(%KeySet{} = keyset, actor, opts) when is_map(actor) and is_list(opts) do
    page_size = Keyword.get(opts, :page_size, @default_page_size)
    store_opts = Keyword.take(opts, [:after_lock])
    decide = fn key -> decide(key, keyset, actor) end

    keyset
    |> new_report()
    |> walk_pages(0, page_size, decide, store_opts)
    |> finalize()
  end

  @doc false
  @spec decide(SigningKey.t(), KeySet.t(), map()) :: tuple()
  def decide(%SigningKey{private_jwk_encrypted: nil} = key, _keyset, _actor) do
    {:keep, info(key, %{class: :no_private_key})}
  end

  def decide(%SigningKey{private_jwk_encrypted: bin} = key, %KeySet{} = keyset, actor)
      when is_binary(bin) do
    case KeyEncryption.classify(bin) do
      :envelope -> decide_envelope(key, keyset)
      :legacy -> decide_legacy(key, keyset, actor)
      :invalid -> {:fail, :unreadable_legacy, info(key, %{})}
    end
  end

  defp decide_envelope(key, keyset) do
    {current_id, _material} = KeySet.current(keyset)

    with {:ok, kek_id} <- KeyEncryption.envelope_kek_id(key.private_jwk_encrypted),
         true <- kek_id == current_id,
         {:ok, _jwk, _source} <- PrivateJwk.read_stored(key, keyset) do
      {:keep, info(key, %{class: :already_current, kek_id: kek_id, source: kek_id})}
    else
      {:error, reason} when is_atom(reason) -> {:fail, reason, info(key, %{})}
      _other -> {:fail, :malformed_envelope, info(key, %{})}
    end
  end

  defp decide_legacy(key, keyset, actor) do
    with {:ok, jwk, :legacy} <- PrivateJwk.read_stored(key, keyset),
         true <- is_map(jwk) and Map.get(jwk, "kid") == key.kid,
         {:ok, json} <- Jason.encode(jwk),
         {:ok, sealed} <- KeyEncryption.seal(keyset, key.kid, json),
         {:ok, reopened} <- KeyEncryption.open(keyset, key.kid, sealed),
         {:ok, %{"kid" => kid}} when kid == key.kid <- Jason.decode(reopened) do
      {current_id, _material} = KeySet.current(keyset)
      details = %{kek_id: current_id, source: "legacy"}
      {:replace, sealed, audit_event(:key_encrypted, key, actor, details), info(key, details)}
    else
      _other -> {:fail, :unreadable_legacy, info(key, %{source: "legacy"})}
    end
  end

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
        add_failure(report, %{kid: nil, reason: :storage_error, kek_id: nil, status: nil})
    end
  end

  defp process_ref({id, kid}, report, decide, store_opts) do
    report = Map.update!(report, :scanned, &(&1 + 1))

    case Repository.reencrypt_signing_key(id, decide, store_opts) do
      {:ok, outcome} -> apply_outcome(report, kid, outcome)
      {:error, _reason} -> storage_failure(report, kid)
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
    counter = if info.kek_id && info[:previous_kek_id], do: :rewrapped, else: :encrypted
    action = if counter == :rewrapped, do: :rewrapped, else: :encrypted

    report
    |> Map.update!(counter, &(&1 + 1))
    |> count_source(info.source)
    |> Map.update!(:changes, &[%{kid: info.kid, action: action, from: info.source} | &1])
  end

  defp apply_outcome(report, kid, {:failed, reason, info}) do
    report
    |> count_source(info[:source])
    |> add_failure(%{kid: kid, reason: reason, kek_id: info[:kek_id], status: info[:status]})
  end

  defp apply_outcome(report, _kid, outcome) when outcome in [:conflict, :not_found],
    do: Map.update!(report, :conflicted, &(&1 + 1))

  defp storage_failure(report, kid),
    do: add_failure(report, %{kid: kid, reason: :storage_error, kek_id: nil, status: nil})

  defp add_failure(report, entry), do: Map.update!(report, :failed, &[entry | &1])

  defp count_source(report, nil), do: report

  defp count_source(report, source),
    do: Map.update!(report, :by_source_kek, &Map.update(&1, source, 1, fn n -> n + 1 end))

  defp info(%SigningKey{} = key, extra) do
    Map.merge(
      %{key_id: key.id, kid: key.kid, status: key.status, use: key.use, source: nil},
      extra
    )
  end

  defp audit_event(action, %SigningKey{} = key, actor, details) do
    metadata =
      %{key_id: key.id, kid: key.kid, status: key.status, use: key.use, kek_id: details.kek_id}
      |> maybe_put(:previous_kek_id, Map.get(details, :previous_kek_id))

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
