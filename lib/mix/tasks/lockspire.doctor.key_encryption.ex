defmodule Mix.Tasks.Lockspire.Doctor.KeyEncryption do
  @moduledoc """
  Reports whether the `:key_encryption` seam (the key-encryption keys that seal
  stored signing keys) is configured and valid.

  Validation is fresh on every run and never reads the boot-time cache. Output
  lists key ids, the current id and the legacy-plaintext mode only; it never
  prints key material. The task exits non-zero when the config is absent or
  invalid.
  """

  use Mix.Task

  alias Lockspire.Security.KeyEncryption.KeySet

  @shortdoc "Reports whether the signing-key encryption config is valid"
  @requirements ["app.config"]

  @switches [help: :boolean]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
    end

    if Keyword.get(opts, :help, false) do
      Mix.shell().info(help())
    else
      report()
    end
  end

  def help do
    """
    mix lockspire.doctor key_encryption

    Reports the state of config :lockspire, :key_encryption:
      - configured: prints the current key id, all key ids and the legacy plaintext mode
      - not configured: explains how to add it and exits non-zero
      - invalid: names the problem (never the key) and exits non-zero

    Key material is never printed.
    """
  end

  defp report do
    case fetch() do
      {:ok, %KeySet{} = keyset} ->
        Mix.shell().info(
          "key_encryption: configured current=#{keyset.current_id} " <>
            "ids=#{Enum.join(keyset.ids, ",")} legacy_plaintext=#{keyset.legacy_plaintext}"
        )

      {:ok, nil} ->
        Mix.shell().info("key_encryption: not configured")

        Mix.raise(
          "config :lockspire, :key_encryption is not set. Add keys: [{id, base64 of 32 random bytes}], " <>
            "current: id in config/runtime.exs (create a key with `openssl rand -base64 32`)."
        )

      {:error, message} ->
        Mix.raise("key_encryption: invalid. #{message}")
    end
  end

  defp fetch do
    {:ok, Lockspire.Config.key_encryption!()}
  rescue
    error in ArgumentError -> {:error, Exception.message(error)}
  end
end
