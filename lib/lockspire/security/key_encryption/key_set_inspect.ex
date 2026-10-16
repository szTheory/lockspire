defimpl Inspect, for: Lockspire.Security.KeyEncryption.KeySet do
  import Inspect.Algebra

  def inspect(keyset, opts) do
    concat([
      "#Lockspire.KeyEncryption.KeySet<",
      to_doc(
        [current: keyset.current_id, ids: keyset.ids, legacy_plaintext: keyset.legacy_plaintext],
        opts
      ),
      ">"
    ])
  end
end
