defmodule Mix.Tasks.Lockspire.Keys.Reencrypt do
  @moduledoc """
  Re-encrypts stored signing keys under the current key-encryption key.

  Plaintext keys written by older releases are sealed, and keys sealed under another
  configured key-encryption key are re-wrapped under the current one. Run it once after
  upgrading, and again after switching the current key id. `--dry-run` previews the work and
  `--check` reports readiness without writing. See `mix lockspire.keys.reencrypt --help`.
  """

  use Mix.Task

  alias Lockspire.Admin.Keys

  @shortdoc "Re-encrypts stored signing keys under the current key-encryption key"
  @requirements ["app.config"]

  @switches [dry_run: :boolean, check: :boolean, help: :boolean]
  @actor %{type: :operator, id: "mix lockspire.keys.reencrypt"}
  @unsealable_reasons [
    :unknown_kek,
    :decryption_failed,
    :malformed_envelope,
    :kid_mismatch,
    :unreadable_legacy
  ]

  @impl Mix.Task
  def run(args) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)
    validate!(opts, argv, invalid)

    if Keyword.get(opts, :help, false) do
      Mix.shell().info(help())
    else
      execute(mode(opts))
    end
  end

  def help do
    """
    mix lockspire.keys.reencrypt [--dry-run | --check]

    Seals stored signing keys with the current key-encryption key. Keys written by older
    releases as plaintext are encrypted, and keys sealed under another configured
    key-encryption key are re-wrapped under the current one. The key itself never changes.

    Options:
      --dry-run   Show what would change. Writes nothing. Exits 1 only if a key would fail
                  (stranded retired keys do not count).
      --check     Report whether every key is ready. Takes no locks and writes nothing.
                  Exits 1 until every key is sealed with the current key-encryption key.
      --help      Show this text.

    Run it only after every node runs this release with the same config for :key_encryption.
    It is safe to run again: keys already on the current key are left untouched. A failed key
    does not stop the others, which are saved. The exit code is 1 when any key failed,
    except stranded retired keys, which are listed but never fail the command.

    Upgrading from plaintext signing keys:
      - Deploy this release with config :lockspire, :key_encryption to every node.
      - Run mix lockspire.keys.reencrypt.
      - Run mix lockspire.keys.reencrypt --check until it passes.
      - Then set legacy_plaintext: :reject. A legacy_plaintext change takes effect on each
        node's next boot, so set :reject only after --check passes.

    Rotating the key-encryption key, in this order:
      1. Add the new key to :keys without changing :current, and deploy everywhere.
         A node that already uses the new :current could write keys that nodes not yet
         updated cannot read, so every node must know the new key first.
      2. Switch :current to the new id, and deploy everywhere.
      3. Run mix lockspire.keys.reencrypt.
      4. Run mix lockspire.keys.reencrypt --check.
      5. Remove the old id from :keys.

    On a running release node, call Lockspire.Admin.Keys.reencrypt/1 through bin/app rpc
    instead of starting a second VM. Key material is never printed.
    """
  end

  defp validate!(opts, argv, invalid) do
    cond do
      invalid != [] ->
        Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")

      argv != [] ->
        Mix.raise(
          "Unexpected argument: #{Enum.join(argv, " ")}. " <>
            "Options start with dashes, for example --#{List.first(argv)}."
        )

      Keyword.get(opts, :check, false) and Keyword.get(opts, :dry_run, false) ->
        Mix.raise("--check and --dry-run cannot be combined; --check never writes")

      true ->
        :ok
    end
  end

  defp mode(opts) do
    cond do
      Keyword.get(opts, :check, false) -> :check
      Keyword.get(opts, :dry_run, false) -> :dry_run
      true -> :apply
    end
  end

  defp execute(mode) do
    {:ok, _} = Application.ensure_all_started(:ecto_sql)

    result =
      case Ecto.Migrator.with_repo(
             Lockspire.Config.repo!(),
             fn _repo -> work(mode) end,
             mode: :temporary
           ) do
        {:ok, result, _apps} -> result
        {:error, _reason} -> Mix.raise(repo_failure())
      end

    finish(mode, result)
  end

  # Only computes. Printing and raising happen after the repo has been stopped again.
  defp work(:apply), do: Keys.reencrypt(actor: @actor)
  defp work(:dry_run), do: Keys.reencrypt(dry_run: true, actor: @actor)

  defp work(:check) do
    started = System.monotonic_time()
    status = Keys.encryption_status()
    {status, System.monotonic_time() - started}
  end

  defp finish(:check, {{:ok, status}, duration}) do
    Keys.emit_check_completed(status, @actor, duration)
    report_check(status)
  end

  defp finish(:check, {{:error, reason}, _duration}), do: raise_error(reason)
  defp finish(mode, {:ok, report}), do: report_run(mode, report)
  defp finish(_mode, {:error, reason}), do: raise_error(reason)

  @spec raise_error(term()) :: no_return()
  defp raise_error(:key_encryption_not_configured) do
    Mix.raise(
      "config :lockspire, :key_encryption is not set. Add keys: [{id, base64 of 32 random bytes}], " <>
        "current: id in config/runtime.exs (create a key with `openssl rand -base64 32`)."
    )
  end

  defp raise_error({:invalid_config, message}),
    do: Mix.raise("key_encryption: invalid. #{message}")

  defp raise_error(:storage_unavailable),
    do: Mix.raise("could not read stored signing keys; check the database and migrations")

  defp raise_error(_reason), do: Mix.raise(repo_failure())

  defp repo_failure, do: "could not start the repo; check database connectivity and config"

  # Apply and dry-run

  defp report_run(mode, report) do
    if mode == :dry_run, do: info("Dry run: no rows will be changed.")
    info("current_kek=#{report.current_kek_id} legacy_plaintext=#{legacy_mode()}")
    reject_warning()

    if mode == :dry_run, do: Enum.each(report.changes, &info(change_line(&1, report)))
    Enum.each(report.failed, &report_failed/1)

    info(summary_line(mode, report))
    # Stranded retired rows are listed with their fix line but never fail the run: a rerun can
    # not clear them and nothing reads retired material.
    blocking = Enum.reject(report.failed, &stranded?/1)
    failed = length(blocking) + report.conflicted

    cond do
      mode == :dry_run ->
        info("Dry run complete. Run without --dry-run to apply.")

        if blocking != [] do
          Mix.raise(
            failure_message(
              length(blocking),
              {"would not be re-encrypted. Follow the fix lines above, then rerun.",
               "would not be re-encrypted. Follow the fix lines above, then rerun."}
            )
          )
        end

      failed > 0 ->
        info(
          "Next: follow the fix lines above, then run `mix lockspire.keys.reencrypt --check`, " <>
            "which reports whether the failed keys block readiness."
        )

        Mix.raise(
          failure_message(
            failed,
            {"was not re-encrypted. All other keys were saved; rerunning is safe.",
             "were not re-encrypted. All other keys were saved; rerunning is safe."}
          )
        )

      true ->
        info(
          "Next: run `mix lockspire.keys.reencrypt --check`, then set legacy_plaintext: :reject " <>
            "once it passes." <> stranded_note(report)
        )
    end
  end

  defp stranded?(%{status: :retired, reason: reason}) when reason in @unsealable_reasons,
    do: true

  defp stranded?(_failed), do: false

  defp stranded_note(report) do
    if Enum.any?(report.failed, &stranded?/1) do
      " Retired keys listed as failed above are stranded: they do not block readiness and " <>
        "do not fail this command."
    else
      ""
    end
  end

  defp failure_message(1, {singular, _plural}), do: "1 key #{singular}"
  defp failure_message(count, {_singular, plural}), do: "#{count} keys #{plural}"

  defp summary_line(:dry_run, report) do
    "scanned=#{report.scanned} would_encrypt=#{report.encrypted} would_rewrap=#{report.rewrapped} " <>
      "already_current=#{report.already_current} failed=#{length(report.failed)} " <>
      "no_private_key=#{report.no_private_key}"
  end

  defp summary_line(:apply, report) do
    "scanned=#{report.scanned} encrypted=#{report.encrypted} rewrapped=#{report.rewrapped} " <>
      "already_current=#{report.already_current} failed=#{length(report.failed)} " <>
      "no_private_key=#{report.no_private_key} conflicted=#{report.conflicted}"
  end

  defp change_line(%{action: :encrypted} = change, report),
    do: "would encrypt  key=#{change.kid} from=#{change.from} to=#{report.current_kek_id}"

  defp change_line(%{action: :rewrapped} = change, report),
    do: "would re-wrap  key=#{change.kid} from=#{change.from} to=#{report.current_kek_id}"

  defp report_failed(failed) do
    info(
      "failed  key=#{failed.kid || "none"} reason=#{failed.reason} kek=#{failed.kek_id || "none"}"
    )

    info("  fix: " <> fix_text(failed.reason, failed.status))
  end

  # Check

  defp report_check(status) do
    current = status.current_kek_id || "none"
    on_current = Map.get(status.by_kek_id, status.current_kek_id, 0)
    other = status.by_kek_id |> Map.drop([status.current_kek_id]) |> Map.values() |> Enum.sum()

    info("current_kek=#{current} legacy_plaintext=#{status.legacy_plaintext}")

    info(
      "total=#{status.total} on_current=#{on_current} legacy=#{status.legacy} other_kek=#{other} " <>
        "unknown_kek=#{status.unknown_kek |> Map.values() |> Enum.sum()} " <>
        "undecryptable=#{status.undecryptable} no_private_key=#{status.no_private_key} " <>
        "stranded_retired=#{status.stranded_retired.count}"
    )

    info("ready=#{status.ready?}")

    if status.ready? do
      info("Ready: every signing key is sealed with key-encryption key #{current}.")
    else
      info(not_ready_sentence(status))
    end

    Enum.each(status.pending, &report_pending/1)
    report_stranded(status.stranded_retired)
    info(check_next(status))

    unless status.ready? do
      Mix.raise(
        "--check failed: signing keys are not all sealed with the current key-encryption key"
      )
    end
  end

  defp not_ready_sentence(%{configured: false}),
    do: "Not ready: no key-encryption key is configured."

  defp not_ready_sentence(status),
    do: "Not ready: #{length(status.pending)} signing keys still need re-encryption."

  defp report_pending(%{kid: kid, state: state}) do
    info("pending  key=#{kid} state=#{state}")

    case pending_fix(state) do
      nil -> :ok
      fix -> info("  fix: " <> fix)
    end
  end

  defp pending_fix(:unsealable_legacy), do: fix_text(:unreadable_legacy, nil)
  defp pending_fix(:unknown_kek), do: fix_text(:unknown_kek, nil)
  defp pending_fix(:undecryptable), do: fix_text(:decryption_failed, nil)
  defp pending_fix(_sealable_state), do: nil

  defp report_stranded(%{count: 0}), do: :ok

  defp report_stranded(%{count: count, kids: kids}) do
    info("stranded_retired=#{count}")
    Enum.each(kids, &info("stranded  key=#{&1} status=retired"))

    info(
      "note: these retired keys cannot be re-encrypted and do not block readiness; their " <>
        "stored bytes remain, and deleting them is a host database decision."
    )
  end

  defp check_next(%{ready?: true} = status) do
    "Next: you can set legacy_plaintext: :reject and remove key-encryption key ids other than " <>
      "#{status.current_kek_id}. Stranded retired keys may stay on old ids because nothing reads them."
  end

  defp check_next(_status), do: "Next: run `mix lockspire.keys.reencrypt`, then check again."

  # Fix lines

  defp fix_text(reason, :retired) when reason in @unsealable_reasons do
    "already retired; does not block readiness; its stored bytes remain, and deleting them is a " <>
      "host database decision."
  end

  defp fix_text(:unknown_kek, _status) do
    "add the key-encryption key with that id back to :keys (not as :current), deploy, and rerun; " <>
      "or " <> retire_route()
  end

  defp fix_text(:decryption_failed, _status) do
    "the material configured for that id is not the material that sealed this key. Restore the " <>
      "original material, or " <> retire_route()
  end

  defp fix_text(reason, _status)
       when reason in [:malformed_envelope, :kid_mismatch, :unreadable_legacy] do
    "the stored key cannot be re-encrypted; " <> retire_route()
  end

  defp fix_text(:roundtrip_failed, _status),
    do: "nothing was written for this key. Rerun; if it repeats, report it."

  defp fix_text(:storage_error, _status),
    do: "database error; nothing was written for this key. Rerun; if it repeats, report it."

  defp fix_text(_reason, _status), do: "rerun; if it repeats, report it."

  defp retire_route do
    "retire this key and generate a replacement. If the key is active, activate its replacement " <>
      "first so this key moves to retiring. An upcoming key cannot be retired, so only removing " <>
      "its row clears it. Once retired, the key no longer blocks readiness. Its stored bytes " <>
      "remain, and deleting them is a host database decision; Lockspire does not delete keys."
  end

  # Shared

  defp reject_warning do
    if legacy_mode() == :reject do
      info(
        "warning: legacy_plaintext is :reject, so legacy keys cannot sign until they are " <>
          "re-encrypted; this run re-encrypts them"
      )
    end
  end

  defp legacy_mode do
    case Lockspire.Config.key_encryption!() do
      nil -> :allow
      keyset -> keyset.legacy_plaintext
    end
  rescue
    ArgumentError -> :allow
  end

  defp info(line), do: Mix.shell().info(line)
end
