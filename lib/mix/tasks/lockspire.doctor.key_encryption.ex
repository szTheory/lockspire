defmodule Mix.Tasks.Lockspire.Doctor.KeyEncryption do
  @moduledoc """
  Reports whether the `:key_encryption` seam (the key-encryption keys that seal
  stored signing keys) is configured and valid.

  Validation is fresh on every run and never reads the boot-time cache. After the
  config line it counts stored signing keys per key-encryption key id, plus legacy,
  unknown and undecryptable rows. Output lists key ids, counts and the
  legacy-plaintext mode only; it never prints key material. The task exits non-zero
  when the config is absent or invalid, the database cannot be read, or a stored key
  uses an unknown key id or cannot be decrypted.
  """

  use Mix.Task

  alias Lockspire.Admin.Keys
  alias Lockspire.Install.RepoRunner
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
      - configured: prints the current key id, all key ids and the legacy plaintext mode,
        then row counts per key id, legacy rows, unknown and undecryptable rows
      - not configured: explains how to add it and exits non-zero
      - invalid: names the problem (never the key) and exits non-zero

    Legacy rows and rows on an older key id exit zero and print a hint to run
    mix lockspire.keys.reencrypt. Rows with an unknown key id, rows that cannot be
    decrypted, or an unreadable database exit non-zero.

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

        if report_rows() == :broken do
          Mix.raise(
            "key_encryption: stored signing keys need attention; see the row counts above."
          )
        end

      {:ok, nil} ->
        Mix.shell().info("key_encryption: not configured")
        report_rows()

        Mix.raise(
          "config :lockspire, :key_encryption is not set. Add keys: [{id, base64 of 32 random bytes}], " <>
            "current: id in config/runtime.exs (create a key with `openssl rand -base64 32`)."
        )

      {:error, message} ->
        Mix.raise("key_encryption: invalid. #{message}")
    end
  end

  defp report_rows do
    case fetch_status() do
      {:ok, status} ->
        print_rows(status)

        if status.unknown_kek == %{} and status.undecryptable == 0, do: :ok, else: :broken

      :error ->
        Mix.shell().info("rows: not inspected (database unreadable)")
        :broken
    end
  end

  defp print_rows(status) do
    on_current = Map.get(status.by_kek_id, status.current_kek_id, 0)
    other = status.by_kek_id |> Map.drop([status.current_kek_id]) |> Map.values() |> Enum.sum()
    unknown = status.unknown_kek |> Map.values() |> Enum.sum()

    Mix.shell().info(
      "rows: total=#{status.total} on_current=#{on_current} other_kek=#{other} " <>
        "legacy=#{status.legacy} no_private_key=#{status.no_private_key} " <>
        "unknown_kek=#{unknown} undecryptable=#{status.undecryptable} " <>
        "stranded_retired=#{status.stranded_retired.count}"
    )

    for {id, count} <- Enum.sort(status.by_kek_id),
        do: Mix.shell().info("kek=#{id} rows=#{count}")

    for {id, count} <- Enum.sort(status.unknown_kek),
        do: Mix.shell().info("unknown_kek=#{id} rows=#{count}")

    if status.legacy + other > 0 do
      Mix.shell().info(
        "#{status.legacy + other} rows still need re-encryption: run mix lockspire.keys.reencrypt"
      )
    end

    print_stranded(status.stranded_retired)
  end

  defp print_stranded(%{count: 0}), do: :ok

  defp print_stranded(%{count: count, kids: kids}) do
    Mix.shell().info("stranded_retired=#{count} keys=#{Enum.join(kids, ",")}")

    Mix.shell().info(
      "note: these retired keys cannot be re-encrypted and do not block readiness; their " <>
        "stored bytes remain, and deleting them is a host database decision."
    )
  end

  defp fetch_status do
    repo = Lockspire.Config.repo!()

    case RepoRunner.run(repo, fn _repo -> Keys.encryption_status() end) do
      {:ok, {:ok, status}} -> {:ok, status}
      _unavailable -> :error
    end
  rescue
    _error -> :error
  end

  defp fetch do
    {:ok, Lockspire.Config.key_encryption!()}
  rescue
    error in ArgumentError -> {:error, Exception.message(error)}
  end
end
