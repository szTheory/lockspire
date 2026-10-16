defmodule Lockspire.Admin.Keys.EncryptionStatus do
  @moduledoc false

  # Pure readiness summary over stored signing-key rows. Every row is classified by the
  # re-encryption engine's own `Reencrypt.assess/2`, so this summary can never disagree with the
  # engine about which rows can be sealed. Nothing here touches the database, telemetry or logs,
  # and the result carries key ids and counts only, never stored bytes.

  alias Lockspire.Admin.Keys.Reencrypt
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Security.KeyEncryption.KeySet

  @doc """
  Builds the status map for `rows` under `keyset` (nil when no key-encryption key is configured).

  Rows the engine can seal block readiness until they are on the current key id, whatever their
  status. Rows it cannot seal block readiness too, except retired ones: nothing reads a retired
  key, so those are listed as `stranded_retired` and never block.
  """
  @spec build(KeySet.t() | nil, [SigningKey.t()]) :: map()
  def build(keyset, rows) when is_list(rows) do
    initial = %{
      configured: keyset != nil,
      current_kek_id: current_id(keyset),
      configured_kek_ids: configured_ids(keyset),
      legacy_plaintext: legacy_mode(keyset),
      total: length(rows),
      no_private_key: 0,
      legacy: 0,
      by_kek_id: %{},
      unknown_kek: %{},
      undecryptable: 0,
      stranded_retired: %{count: 0, kids: []},
      pending: []
    }

    rows
    |> Enum.sort_by(&{&1.id, &1.kid})
    |> Enum.reduce(initial, &classify(&1, Reencrypt.assess(&1, keyset), keyset, &2))
    |> finalize()
  end

  @doc """
  True when stored keys are broken now: a reachable row uses an unknown key id or cannot be
  decrypted, or `legacy_plaintext: :reject` is set while legacy rows remain. Doctor and
  `Install.Verify` both gate on this one predicate.
  """
  @spec broken_now?(map()) :: boolean()
  def broken_now?(status) do
    status.unknown_kek != %{} or status.undecryptable > 0 or
      (status.legacy_plaintext == :reject and status.legacy > 0)
  end

  defp current_id(nil), do: nil
  defp current_id(%KeySet{} = keyset), do: elem(KeySet.current(keyset), 0)

  defp configured_ids(nil), do: []
  defp configured_ids(%KeySet{ids: ids}), do: ids

  defp legacy_mode(nil), do: :allow
  defp legacy_mode(%KeySet{legacy_plaintext: mode}), do: mode

  defp classify(_row, :no_private_key, _keyset, acc), do: bump(acc, :no_private_key)

  defp classify(row, :sealable_legacy, _keyset, acc),
    do: acc |> bump(:legacy) |> pend(row, :legacy)

  defp classify(row, {:envelope, id}, keyset, acc) do
    acc = update_in(acc.by_kek_id, &Map.update(&1, id, 1, fn n -> n + 1 end))

    if id == current_id(keyset), do: acc, else: pend(acc, row, :other_kek)
  end

  # With no key set there is no stranded classification: readiness is false anyway, and calling a
  # row stranded would hide that the key set is missing.
  defp classify(
         %SigningKey{status: :retired} = row,
         {:unsealable, _reason, _kek},
         %KeySet{},
         acc
       ),
       do: strand(acc, row)

  defp classify(row, {:unsealable, reason, kek_id}, _keyset, acc),
    do: classify_unsealable(row, reason, kek_id, acc)

  defp classify_unsealable(row, reason, nil, acc)
       when reason in [:unreadable_legacy, :kid_mismatch],
       do: acc |> bump(:legacy) |> pend(row, :unsealable_legacy)

  defp classify_unsealable(row, :unknown_kek, kek_id, acc) when is_binary(kek_id) do
    acc = update_in(acc.unknown_kek, &Map.update(&1, kek_id, 1, fn n -> n + 1 end))
    pend(acc, row, :unknown_kek)
  end

  defp classify_unsealable(row, _reason, _kek_id, acc),
    do: acc |> bump(:undecryptable) |> pend(row, :undecryptable)

  defp strand(acc, row) do
    update_in(acc.stranded_retired, fn stranded ->
      %{count: stranded.count + 1, kids: [row.kid | stranded.kids]}
    end)
  end

  defp bump(acc, field), do: Map.update!(acc, field, &(&1 + 1))

  defp pend(acc, row, state),
    do: Map.update!(acc, :pending, &[%{kid: row.kid, state: state} | &1])

  defp finalize(acc) do
    acc =
      acc
      |> Map.update!(:pending, &Enum.reverse/1)
      |> update_in([:stranded_retired, :kids], &Enum.reverse/1)

    Map.put(acc, :ready?, ready?(acc))
  end

  defp ready?(acc) do
    acc.configured and acc.legacy == 0 and acc.unknown_kek == %{} and acc.undecryptable == 0 and
      Enum.all?(Map.keys(acc.by_kek_id), &(&1 == acc.current_kek_id))
  end
end
