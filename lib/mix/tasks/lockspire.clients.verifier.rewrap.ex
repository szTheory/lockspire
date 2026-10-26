defmodule Mix.Tasks.Lockspire.Clients.Verifier.Rewrap do
  @moduledoc """
  Inspects and re-wraps stored client-secret JWT verifier custody.

  Bare Mix uses its loaded task-local configuration without starting Lockspire supervision.
  Calls through `bin/app rpc` use the running node's immutable startup context.
  """

  use Mix.Task

  alias Lockspire.Admin.ClientVerifierMaintenance, as: Maintenance
  alias Lockspire.Install.TaskError
  alias Lockspire.Security.ClientSecretVerifier.OperationContext

  @shortdoc "Re-wraps stored client-secret JWT verifier keys"
  @requirements ["app.config"]

  @switches [
    dry_run: :boolean,
    check: :boolean,
    help: :boolean,
    limit: :integer,
    after_client_id: :string
  ]

  @task_name "mix lockspire.clients.verifier.rewrap"
  @default_limit 100
  @min_limit 1
  @max_limit 500

  @impl Mix.Task
  def run(args) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)
    validate!(opts, argv, invalid, args)

    if Keyword.get(opts, :help, false) do
      Mix.shell().info(help())
    else
      execute(opts)
    end
  end

  @doc false
  def help do
    """
    #{@task_name} [--dry-run | --check] [--limit N] [--after-client-id ID]

    Re-wraps stored client-secret JWT verifier material under the current verifier key.
    Partner client secrets are not replaced. With no mode flag, the task applies eligible
    changes. --dry-run inspects and reports eligible pending work without writing. --check
    performs a fresh read-only scan and exits 1 unless every inspected client has current
    verifier custody or is a legitimate no-material client.

    Options:
      --dry-run             Preview eligible changes without writing.
      --check               Run a fresh read-only custody check; cannot be combined with
                            --dry-run or --after-client-id.
      --limit N             Page size from 1 through 500 (default: #{@default_limit}).
      --after-client-id ID  Resume inventory traversal from an exclusive client ID cursor.
                            This is progress only and never establishes readiness.
      --help                Show this text.

    Bare Mix loads application configuration and starts only the configured Repo for the
    operation. It does not start Lockspire supervision or change a running node's keys.
    On a running release node, call
    Lockspire.Admin.ClientVerifierMaintenance.run/1 through `bin/app rpc`; that call uses
    the node's immutable startup context. A successful apply still requires a separate
    fresh --check before a host considers removing an old read key.

    No key bytes, client secrets, hashes, or ciphertext are accepted as command-line options.
    """
  end

  defp validate!(opts, argv, invalid, args) do
    cond do
      invalid != [] or argv != [] ->
        Mix.raise("invalid arguments for #{@task_name}")

      duplicate_options?(args) ->
        Mix.raise("duplicate options are not allowed")

      Keyword.get(opts, :check, false) and Keyword.get(opts, :dry_run, false) ->
        Mix.raise("--check and --dry-run cannot be combined")

      Keyword.get(opts, :check, false) and Keyword.has_key?(opts, :after_client_id) ->
        Mix.raise("--check requires a fresh scan and cannot use --after-client-id")

      not valid_limit?(Keyword.get(opts, :limit, @default_limit)) ->
        Mix.raise("--limit must be an integer from #{@min_limit} through #{@max_limit}")

      not valid_cursor?(Keyword.get(opts, :after_client_id)) ->
        Mix.raise("--after-client-id must be a non-empty UTF-8 client ID")

      true ->
        :ok
    end
  end

  defp duplicate_options?(args) do
    options =
      args
      |> Enum.filter(&String.starts_with?(&1, "--"))
      |> Enum.map(&(String.split(&1, "=", parts: 2) |> hd()))

    length(options) != length(Enum.uniq(options))
  end

  defp valid_limit?(limit),
    do: is_integer(limit) and limit >= @min_limit and limit <= @max_limit

  defp valid_cursor?(nil), do: true

  defp valid_cursor?(cursor),
    do: is_binary(cursor) and cursor != "" and String.valid?(cursor)

  defp execute(opts) do
    case OperationContext.resolve() do
      {:ok, context} ->
        run_operation(opts, context)

      {:error, _safe_reason} ->
        Mix.raise("client-secret verifier configuration is invalid; check the configured keys")
    end
  end

  defp run_operation(opts, context) do
    repo = Lockspire.Config.repo!()
    mode = mode(opts)

    operation_opts = [
      mode: mode,
      limit: Keyword.get(opts, :limit, @default_limit),
      context_source: :task_local,
      client_secret_verifier_context: context
    ]

    operation_opts =
      case Keyword.fetch(opts, :after_client_id) do
        {:ok, cursor} -> Keyword.put(operation_opts, :after_client_id, cursor)
        :error -> operation_opts
      end

    case TaskError.run(repo, fn _started_repo -> Maintenance.run(operation_opts) end) do
      {:ok, result} -> finish(mode, result, Keyword.has_key?(opts, :after_client_id))
      {:error, phrase} -> Mix.raise(phrase)
    end
  end

  defp mode(opts) do
    cond do
      Keyword.get(opts, :check, false) -> :check
      Keyword.get(opts, :dry_run, false) -> :dry_run
      true -> :apply
    end
  end

  defp finish(mode, {:ok, report}, progress_only?) do
    render(report, progress_only?)

    case mode do
      :check ->
        Mix.shell().info("Current-key custody check passed.")

      :dry_run ->
        Mix.shell().info("Dry run complete. No verifier custody was changed.")

      :apply ->
        Mix.shell().info("Apply completed. Run a separate fresh --check before key retirement.")
    end
  end

  defp finish(mode, {:error, report}, progress_only?) when is_map(report) do
    render(report, progress_only?)
    Mix.raise(failure_message(mode, report))
  end

  defp finish(_mode, {:error, reason}, _progress_only?) when is_atom(reason) do
    Mix.raise("verifier maintenance could not complete (#{safe_reason(reason)})")
  end

  defp finish(_mode, _other, _progress_only?),
    do: Mix.raise("verifier maintenance could not complete; details are withheld")

  defp render(report, progress_only?) do
    Mix.shell().info(
      "mode=#{safe_atom(report.mode)} context_source=#{safe_atom(report.context_source)} " <>
        "scan_complete=#{report.scan_complete?} progress_only=#{progress_only?} " <>
        "custody_condition_met=#{report.custody_condition_met?}"
    )

    Mix.shell().info(
      "scanned=#{report.scanned} committed_changed=#{report.committed_changed} " <>
        "already_current=#{report.already_current} pending=#{report.pending} " <>
        "conflicts=#{report.conflicts} failed=#{report.failed} uninspected=#{report.uninspected} " <>
        "no_material=#{report.no_material} details_truncated=#{report.details_truncated?}"
    )

    Enum.each(report.details, &render_detail/1)
  end

  defp render_detail(detail) do
    identity = detail.client_id.value || "unavailable"
    encoding = safe_atom(detail.client_id.encoding)
    classification = safe_atom(detail.classification)
    reason = safe_optional_atom(detail.reason)
    action = safe_atom(detail.next_action)
    key_id = safe_key_id(detail.key_id)
    outcome = safe_optional_atom(detail.outcome)

    Mix.shell().info(
      "client=#{identity} id_encoding=#{encoding} classification=#{classification} " <>
        "reason=#{reason} next_action=#{action} key_id=#{key_id} outcome=#{outcome}"
    )
  end

  defp failure_message(:check, report) do
    "--check failed: current-key custody was not established " <>
      "(scanned=#{report.scanned}, failed=#{report.failed}, conflicts=#{report.conflicts}, " <>
      "uninspected=#{report.uninspected}); follow the safe next actions above and run a fresh check"
  end

  defp failure_message(:dry_run, report) do
    "--dry-run could not inspect every client safely " <>
      "(failed=#{report.failed}, conflicts=#{report.conflicts}, uninspected=#{report.uninspected})"
  end

  defp failure_message(:apply, report) do
    "apply did not complete cleanly " <>
      "(committed_changed=#{report.committed_changed}, failed=#{report.failed}, " <>
      "conflicts=#{report.conflicts}, uninspected=#{report.uninspected}); " <>
      "committed progress is retained; resolve the reported items and rerun"
  end

  defp safe_reason(reason)
       when reason in [
              :client_secret_verifier_maintenance_unsupported,
              :client_secret_verifier_maintenance_authority_mismatch,
              :client_secret_verifier_configuration_invalid,
              :client_secret_verifier_maintenance_invalid_options,
              :client_secret_verifier_maintenance_invalid_limit,
              :client_secret_verifier_inventory_invalid_cursor,
              :client_secret_verifier_maintenance_check_requires_fresh_scan
            ],
       do: Atom.to_string(reason)

  defp safe_reason(_), do: "maintenance_failed"

  defp safe_atom(value) when is_atom(value), do: Atom.to_string(value)
  defp safe_atom(_), do: "unavailable"

  defp safe_optional_atom(value) when is_atom(value), do: Atom.to_string(value)
  defp safe_optional_atom(_), do: "none"

  defp safe_key_id(value) when is_binary(value) and byte_size(value) <= 32 do
    if Regex.match?(~r/\A[A-Za-z0-9._-]{1,32}\z/, value), do: value, else: "unavailable"
  end

  defp safe_key_id(_), do: "none"
end
