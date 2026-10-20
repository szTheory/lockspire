defmodule Lockspire.Web.Live.Admin.KeysLive.Protection do
  @moduledoc false

  # Collapses the result of `Lockspire.Admin.encryption_status/0` into one
  # read-only summary for the Keys page. Pure and total: any term it does not
  # recognise reads as "could not check", never as healthy. The only status
  # value that ever enters the copy is the current key-encryption key id.

  @type state ::
          :could_not_check
          | :invalid_config
          | :not_set_up
          | :unreadable
          | :unencrypted
          | :older_key
          | :encrypted

  @type summary :: %{
          state: state(),
          tone: :success | :info | :warning | :danger | :neutral,
          value: String.t(),
          detail: String.t(),
          command: String.t() | nil
        }

  @spec summarize(term()) :: summary()
  def summarize({:error, {:invalid_config, _message}}), do: build(:invalid_config)

  def summarize({:ok, %{configured: false} = status}) do
    if orphaned_keys?(status), do: build(:not_set_up_orphaned), else: build(:not_set_up)
  end

  def summarize({:ok, %{configured: true} = status}) do
    status |> classify() |> build(Map.get(status, :current_kek_id))
  end

  def summarize(_other), do: build(:could_not_check)

  defp classify(status) do
    by_kek_id = Map.get(status, :by_kek_id) || %{}
    current = Map.get(status, :current_kek_id)

    cond do
      unreadable?(status) ->
        :unreadable

      positive?(Map.get(status, :legacy)) ->
        :unencrypted

      Enum.any?(Map.keys(by_kek_id), &(&1 != current)) ->
        :older_key

      true ->
        :encrypted
    end
  end

  defp unreadable?(status) do
    (Map.get(status, :unknown_kek) || %{}) != %{} or positive?(Map.get(status, :undecryptable)) or
      unsealable_legacy?(status) or reject_legacy?(status)
  end

  # Legacy rows the re-encryption engine cannot seal (corrupt bytes, mismatched id) are not
  # fixable by `mix lockspire.keys.reencrypt`, so they read as unreadable, not unencrypted.
  defp unsealable_legacy?(status) do
    status
    |> Map.get(:pending)
    |> List.wrap()
    |> Enum.any?(&(Map.get(&1, :state) == :unsealable_legacy))
  end

  # With `legacy_plaintext: :reject`, legacy rows are unreadable at runtime. This matches
  # `EncryptionStatus.broken_now?/1`, which doctor and install verification gate on.
  defp reject_legacy?(status),
    do: Map.get(status, :legacy_plaintext) == :reject and positive?(Map.get(status, :legacy))

  # Not set up, yet stored keys were encrypted with a key-encryption key that is gone. The state
  # stays :not_set_up (D-02); only the guidance changes. Ids and counts never reach the copy.
  defp orphaned_keys?(status) do
    (Map.get(status, :unknown_kek) || %{}) != %{} or positive?(Map.get(status, :undecryptable))
  end

  defp positive?(value), do: is_integer(value) and value > 0

  defp build(state, id \\ nil)

  defp build(:encrypted, id) do
    %{
      state: :encrypted,
      tone: :success,
      value: "Encrypted",
      detail:
        "Lockspire encrypts the private keys it stores with key-encryption key \"#{id}\". New keys use the same key-encryption key.",
      command: nil
    }
  end

  defp build(:older_key, id) do
    %{
      state: :older_key,
      tone: :info,
      value: "Encrypted, some with an older key-encryption key",
      detail:
        "Lockspire can still read those keys. New keys use key-encryption key \"#{id}\". To move the older ones to it, run:",
      command: "mix lockspire.keys.reencrypt"
    }
  end

  defp build(:unencrypted, _id) do
    %{
      state: :unencrypted,
      tone: :warning,
      value: "Some keys are stored unencrypted",
      detail:
        "Some private keys are stored without encryption, usually because an older Lockspire version created them. To encrypt them, run:",
      command: "mix lockspire.keys.reencrypt"
    }
  end

  defp build(:unreadable, _id) do
    %{
      state: :unreadable,
      tone: :danger,
      value: "Some keys cannot be read",
      detail:
        "Lockspire cannot open some stored private keys with the key-encryption keys it has. Do not delete them. For details, run:",
      command: "mix lockspire.doctor.key_encryption"
    }
  end

  defp build(:not_set_up, _id) do
    %{
      state: :not_set_up,
      tone: :warning,
      value: "Not set up",
      detail:
        "No key-encryption key is set up, so Lockspire cannot create new keys until one is. Create one with the command below, add it to your app's configuration, and restart the app.",
      command: "mix lockspire.gen.kek"
    }
  end

  defp build(:not_set_up_orphaned, _id) do
    %{
      state: :not_set_up,
      tone: :warning,
      value: "Not set up",
      detail:
        "No key-encryption key is set up, and some stored keys were encrypted with a key-encryption key that is no longer configured. Restore that key-encryption key in your app's configuration rather than creating a new one, then restart the app. Do not delete the keys. For details, run:",
      command: "mix lockspire.doctor.key_encryption"
    }
  end

  defp build(:invalid_config, _id) do
    %{
      state: :invalid_config,
      tone: :warning,
      value: "Setup needs attention",
      detail: "The key-encryption key setup is not valid. For details, run:",
      command: "mix lockspire.doctor.key_encryption"
    }
  end

  defp build(:could_not_check, _id) do
    %{
      state: :could_not_check,
      tone: :neutral,
      value: "Unknown",
      detail:
        "Lockspire could not check key protection right now. This does not mean your keys are protected or unprotected. Reload the page to try again.",
      command: nil
    }
  end
end
