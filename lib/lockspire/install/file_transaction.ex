defmodule Lockspire.Install.FileTransaction do
  @moduledoc """
  A recoverable filesystem transaction for generated install artifacts.

  Lockspire deliberately uses only OTP's portable filesystem API.  It validates
  every existing component with `File.lstat/1`, refuses links, revalidates before
  every write, uses exclusive creates, and journals enough information to undo an
  interrupted update.  This is a strong defence against stale plans and ordinary
  failures, but it is *not* descriptor-relative `openat(2)` containment: a hostile
  same-user process can still replace an ancestor between validation and a path
  operation.  That race needs native `O_NOFOLLOW`/`openat` support, which
  Lockspire intentionally does not ship.  Do not run generators in a project tree
  writable by an untrusted concurrent user.
  """

  alias Lockspire.Install.Manifest

  @journal_rel ".lockspire/install_transaction.json"
  @test_hook_key {__MODULE__, :failure_hook}

  @type artifact :: %{
          required(:relative_path) => String.t(),
          required(:kind) => :migration | :managed | :manifest,
          required(:expected) => :absent | String.t(),
          required(:contents) => binary(),
          required(:checksum) => String.t(),
          required(:provenance) => String.t()
        }

  @doc false
  def with_test_failure(hook, fun) when is_function(fun, 0) do
    previous = Process.get(@test_hook_key)
    Process.put(@test_hook_key, hook)

    try do
      fun.()
    after
      if is_nil(previous),
        do: Process.delete(@test_hook_key),
        else: Process.put(@test_hook_key, previous)
    end
  end

  @spec apply(String.t(), [artifact()], keyword()) :: :ok | {:error, [map()]}
  def apply(project_root, artifacts, opts \\ [])
      when is_binary(project_root) and is_list(artifacts) do
    project_root = Path.expand(project_root)

    with :ok <- recover(project_root),
         :ok <- validate(project_root, artifacts, opts),
         {:ok, state} <- stage(project_root, artifacts),
         {:ok, committed_state} <- commit(state),
         :ok <- finalize_committed(committed_state) do
      :ok
    else
      {:simulated_interruption, hook} ->
        {:error,
         [
           error(
             :interrupted,
             "Install transaction intentionally interrupted at #{inspect(hook)}; rerun the command to recover safely."
           )
         ]}

      {:error, reason} when is_list(reason) ->
        {:error, reason}

      {:error, reason} ->
        {:error, [error(:transaction_failed, safe_reason(reason))]}
    end
  end

  @doc "Recovers a previous interrupted transaction, if any, before planning a new one."
  @spec recover(String.t()) :: :ok | {:error, [map()]}
  def recover(project_root) when is_binary(project_root) do
    project_root = Path.expand(project_root)
    journal = Path.join(project_root, @journal_rel)

    case safe_ancestry(project_root, journal, allow_missing?: true) do
      :ok -> inspect_journal(project_root, journal)
      {:error, reason} -> {:error, [error(:unsafe_path, safe_reason(reason))]}
    end
  end

  @doc "Inspects transaction recovery state without creating, recovering, or removing files."
  @spec recovery_status(String.t()) ::
          :clean | {:recovery_required, String.t()} | {:error, [map()]}
  def recovery_status(project_root) when is_binary(project_root) do
    root = Path.expand(project_root)
    journal = Path.join(root, @journal_rel)

    case read_only_ancestry(root, journal) do
      :ok ->
        case File.lstat(journal) do
          {:error, :enoent} ->
            recovery_initial_journal_temp_status(root, journal)

          {:ok, %{type: :regular}} ->
            recovery_journal_status(root, journal)

          {:ok, %{type: :symlink}} ->
            {:error, [error(:unsafe_path, "Refusing symlinked install transaction journal")]}

          {:ok, _} ->
            {:error, [error(:unsafe_path, "Refusing non-regular install transaction journal")]}

          {:error, _reason} ->
            {:error, [error(:unsafe_path, "Could not inspect install transaction journal")]}
        end

      {:error, :symlink_refused} ->
        {:error, [error(:unsafe_path, "Refusing symlinked install transaction path")]}

      {:error, _reason} ->
        {:error, [error(:unsafe_path, "Could not safely inspect install transaction path")]}
    end
  end

  defp recovery_initial_journal_temp_status(root, journal) do
    temporary = initial_journal_temporary(journal)

    case read_only_ancestry(root, temporary) do
      :ok ->
        case File.lstat(temporary) do
          {:error, :enoent} ->
            :clean

          {:ok, %{type: :regular}} ->
            {:recovery_required,
             "An interrupted install journal publication needs cleanup. Rerun the command without dry-run before previewing again."}

          {:ok, _} ->
            {:error,
             [
               error(
                 :unsafe_path,
                 "Refusing non-regular initial transaction journal temporary file"
               )
             ]}

          {:error, _reason} ->
            {:error,
             [error(:unsafe_path, "Could not inspect initial transaction journal temporary file")]}
        end

      {:error, _reason} ->
        {:error,
         [
           error(
             :unsafe_path,
             "Could not safely inspect initial transaction journal temporary file"
           )
         ]}
    end
  end

  defp recovery_journal_status(root, journal) do
    with {:ok, encoded} <- File.read(journal),
         {:ok, state} <- Jason.decode(encoded),
         :ok <- valid_journal?(root, state) do
      {:recovery_required,
       "An interrupted install transaction needs recovery. Rerun `mix lockspire.upgrade` without `--dry-run` before previewing again."}
    else
      _ ->
        {:recovery_required,
         "Install transaction journal is invalid; inspect .lockspire/install_transaction.json before retrying."}
    end
  end

  defp read_only_ancestry(root, target) do
    cond do
      not safe_path?(root, target) ->
        {:error, :outside_project_root}

      true ->
        case File.lstat(root) do
          {:error, :enoent} ->
            :ok

          {:ok, %{type: :directory}} ->
            inspect_read_only_components(root, Path.relative_to(target, root))

          {:ok, %{type: :symlink}} ->
            {:error, :symlink_refused}

          {:ok, _} ->
            {:error, :invalid_project_root}

          {:error, _} ->
            {:error, :root_unavailable}
        end
    end
  end

  defp inspect_read_only_components(root, relative) do
    relative
    |> Path.split()
    |> Enum.reduce_while({:ok, root}, fn component, {:ok, current} ->
      next = Path.join(current, component)

      case File.lstat(next) do
        {:ok, %{type: :symlink}} -> {:halt, {:error, :symlink_refused}}
        {:ok, _} -> {:cont, {:ok, next}}
        {:error, :enoent} -> {:halt, :missing}
        {:error, _} -> {:halt, {:error, :path_unavailable}}
      end
    end)
    |> case do
      {:ok, _} -> :ok
      :missing -> :ok
      error -> error
    end
  end

  defp inspect_journal(project_root, journal) do
    case File.lstat(journal) do
      {:error, :enoent} ->
        cleanup_unpublished_journal_temp(project_root, journal)

      {:ok, %{type: :symlink}} ->
        {:error, [error(:unsafe_path, "Refusing symlinked install transaction journal")]}

      {:ok, %{type: :regular}} ->
        recover_journal(project_root, journal)

      {:ok, _} ->
        {:error, [error(:unsafe_path, "Refusing non-regular install transaction journal")]}

      {:error, reason} ->
        {:error,
         [
           error(
             :unsafe_path,
             "Could not inspect install transaction journal: #{inspect(reason)}"
           )
         ]}
    end
  end

  defp cleanup_unpublished_journal_temp(root, journal) do
    temporary = initial_journal_temporary(journal)

    with :ok <- safe_ancestry(root, temporary, allow_missing?: true),
         :ok <- remove_regular_journal(temporary),
         :ok <- remove_empty_transaction_parent(Path.dirname(journal)) do
      :ok
    else
      {:error, reason} -> {:error, [error(:unsafe_path, safe_reason(reason))]}
    end
  end

  defp recover_journal(project_root, journal) do
    with {:ok, encoded} <- File.read(journal),
         {:ok, state} <- Jason.decode(encoded),
         :ok <- valid_journal?(project_root, state),
         serialized = serialized_state(project_root, journal, state),
         :ok <- recover_rollback(serialized),
         :ok <- cleanup(serialized) do
      :ok
    else
      {:error, errors} when is_list(errors) ->
        {:error, errors}

      {:simulated_interruption, hook} ->
        {:error,
         [
           error(
             :interrupted,
             "Install transaction intentionally interrupted at #{inspect(hook)}; rerun the command to recover safely."
           )
         ]}

      _ ->
        {:error,
         [
           error(
             :recovery_required,
             "Install transaction journal is invalid; inspect .lockspire/install_transaction.json before retrying."
           )
         ]}
    end
  end

  defp recover_rollback(%{terminal: terminal}) when terminal in ["rolled_back", "committed"],
    do: :ok

  defp recover_rollback(state), do: rollback(state)

  defp validate(project_root, artifacts, opts) do
    manifest_count = Enum.count(artifacts, &(&1.kind == :manifest))
    require_manifest? = Keyword.get(opts, :require_manifest?, true)

    cond do
      require_manifest? and manifest_count != 1 ->
        {:error,
         [error(:invalid_plan, "Install transaction requires exactly one manifest artifact")]}

      not require_manifest? and manifest_count != 0 ->
        {:error,
         [error(:invalid_plan, "Migration transaction cannot include a manifest artifact")]}

      Enum.any?(artifacts, &(not valid_artifact?(&1))) ->
        {:error, [error(:invalid_plan, "Install transaction artifact is malformed")]}

      true ->
        artifacts
        |> Enum.map(&validate_artifact(project_root, &1))
        |> collect_errors()
    end
  end

  defp valid_artifact?(%{
         relative_path: path,
         kind: kind,
         expected: expected,
         contents: contents,
         checksum: checksum,
         provenance: provenance
       }) do
    is_binary(path) and kind in [:migration, :managed, :host_owned, :manifest] and
      (expected == :absent or is_binary(expected)) and is_binary(contents) and
      checksum == Manifest.checksum(contents) and is_binary(provenance) and safe_relative?(path)
  end

  defp valid_artifact?(_), do: false

  defp validate_artifact(root, artifact) do
    path = Path.join(root, artifact.relative_path)

    case safe_ancestry(root, path, allow_missing?: true) do
      :ok -> expected_preimage(path, artifact.expected)
      error -> error
    end
  end

  defp stage(project_root, artifacts) do
    tx_root =
      Path.join(
        project_root,
        ".lockspire/.install-tx-#{System.unique_integer([:positive, :monotonic])}"
      )

    journal = Path.join(project_root, @journal_rel)

    state = %{
      root: project_root,
      tx_root: tx_root,
      journal: journal,
      artifacts: [],
      committed: [],
      pending: nil
    }

    with :ok <- safe_ancestry(project_root, Path.dirname(tx_root), allow_missing?: true),
         :ok <- write_journal(state),
         :ok <- maybe_fail(:after_initial_journal),
         :ok <- File.mkdir_p(tx_root),
         :ok <- safe_ancestry(project_root, tx_root, allow_missing?: false),
         {:ok, staged} <- stage_artifacts(tx_root, artifacts),
         staged_state = %{state | artifacts: staged},
         :ok <- write_journal(staged_state),
         :ok <- maybe_fail(:after_staging) do
      {:ok, staged_state}
    else
      {:simulated_interruption, _} = interruption -> interruption
      {:error, reason} -> {:error, {:staging_failed, reason}}
    end
  end

  defp stage_artifacts(tx_root, artifacts) do
    artifacts
    |> Enum.sort_by(&{manifest_sort(&1), &1.relative_path})
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {artifact, index}, {:ok, staged} ->
      stage_path = Path.join(tx_root, "staged-#{index}")

      case File.write(stage_path, artifact.contents, [:exclusive]) do
        :ok ->
          if checksum_file?(stage_path, artifact.checksum),
            do: {:cont, {:ok, [Map.put(artifact, :stage_path, stage_path) | staged]}},
            else: {:halt, {:error, :stage_checksum_mismatch}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, staged} -> {:ok, Enum.reverse(staged)}
      error -> error
    end
  end

  defp commit(state) do
    Enum.reduce_while(state.artifacts, {:ok, state}, fn artifact, {:ok, current} ->
      case commit_artifact(current, artifact) do
        {:ok, next} ->
          {:cont, {:ok, next}}

        {:error, reason, failure_state} ->
          {:halt, halt_commit(failure_state, {:error, reason})}

        result ->
          {:halt, halt_commit(current, result)}
      end
    end)
    |> case do
      {:ok, committed_state} -> {:ok, committed_state}
      other -> other
    end
  end

  defp halt_commit(_current, {:simulated_interruption, _} = interruption), do: interruption

  defp halt_commit(current, {:error, reason}) do
    case rollback(current) do
      :ok -> rollback_completion(current, reason)
      {:simulated_interruption, _} = interruption -> interruption
      {:error, rollback_reason} -> rollback_failure(reason, rollback_reason)
    end
  end

  defp rollback_completion(current, reason) do
    case finalize_rolled_back(current) do
      :ok -> {:error, reason}
      {:simulated_interruption, _} = interruption -> interruption
      {:error, cleanup_reason} -> recovery_failure(reason, cleanup_reason)
    end
  end

  defp rollback_failure(reason, rollback_reason) do
    {:error,
     [
       error(:rollback_failed, safe_reason(rollback_reason)),
       error(:transaction_failed, safe_reason(reason))
     ]}
  end

  defp recovery_failure(reason, cleanup_reason) do
    {:error,
     [
       error(:recovery_required, safe_reason(cleanup_reason)),
       error(:transaction_failed, safe_reason(reason))
     ]}
  end

  defp commit_artifact(state, artifact) do
    target = Path.join(state.root, artifact.relative_path)

    with :ok <- before_commit_hook(artifact),
         :ok <- safe_ancestry(state.root, target, allow_missing?: true),
         :ok <- expected_preimage(target, artifact.expected),
         :ok <- checksum_stage(artifact),
         {:ok, intent} <- prepare_intent(state, artifact, target) do
      commit_intent(state, artifact, target, intent)
    end
  end

  defp commit_intent(state, artifact, target, intent) do
    pending_state = %{state | pending: intent}

    with :ok <- write_intent_journal(pending_state),
         :ok <- maybe_fail(:after_intent_journal),
         :ok <- write_target(pending_state, artifact, target, intent),
         :ok <- maybe_fail({:after_target_write, artifact.relative_path}) do
      next = %{state | pending: nil, committed: [intent | state.committed]}

      with :ok <- write_journal(next),
           :ok <- commit_hook(artifact, next.committed),
           :ok <- maybe_fail({:after_artifact, artifact.relative_path}) do
        {:ok, next}
      else
        {:simulated_interruption, _} = interruption -> interruption
        {:error, reason} -> {:error, reason, pending_state}
      end
    else
      {:simulated_interruption, _} = interruption -> interruption
      {:error, reason} -> {:error, reason, pending_state}
    end
  end

  defp prepare_intent(_state, %{expected: :absent} = artifact, _target) do
    with {:ok, _identity} <- file_identity(artifact.stage_path) do
      {:ok,
       %{
         relative_path: artifact.relative_path,
         action: "created",
         checksum: artifact.checksum,
         stage_path: artifact.stage_path
       }}
    end
  end

  defp prepare_intent(state, artifact, target) do
    backup = Path.join(state.tx_root, "backup-#{length(state.committed)}")

    with {:ok, before} <- File.read(target),
         true <- Manifest.checksum(before) == artifact.expected,
         :ok <- File.write(backup, before, [:exclusive]) do
      {:ok,
       %{
         relative_path: artifact.relative_path,
         action: "updated",
         checksum: artifact.checksum,
         backup: backup,
         backup_checksum: artifact.expected
       }}
    else
      false -> {:error, :preimage_changed}
      {:error, reason} -> {:error, reason}
    end
  end

  defp write_intent_journal(state) do
    case write_journal(state) do
      :ok -> :ok
      {:simulated_interruption, _} = interruption -> interruption
      error -> error
    end
  end

  defp write_target(state, %{expected: :absent} = artifact, target, _intent) do
    with :ok <- File.mkdir_p(Path.dirname(target)),
         :ok <- safe_ancestry(state.root, target, allow_missing?: true),
         :ok <- maybe_fail({:before_create_publish, artifact.relative_path}),
         :ok <- File.ln(artifact.stage_path, target) do
      :ok
    end
  end

  defp write_target(state, artifact, target, _intent) do
    with :ok <- safe_ancestry(state.root, target, allow_missing?: false),
         :ok <- expected_preimage(target, artifact.expected),
         :ok <- maybe_fail({:before_update_publish, artifact.relative_path}),
         :ok <- File.rename(artifact.stage_path, target) do
      :ok
    end
  end

  defp before_commit_hook(%{kind: :manifest}), do: maybe_fail(:before_manifest_commit)
  defp before_commit_hook(_), do: :ok

  defp commit_hook(%{kind: :migration}, committed) do
    maybe_fail({:after_migration, Enum.count(committed, &(&1.action == "created"))})
  end

  defp commit_hook(%{kind: :managed, expected: expected}, _committed) when expected != :absent,
    do: maybe_fail(:after_first_managed_update)

  defp commit_hook(%{kind: :host_owned}, committed) do
    if Enum.any?(committed, &(&1.action == "created")),
      do: maybe_fail(:after_host_owned_create),
      else: :ok
  end

  defp commit_hook(%{kind: :manifest}, _committed), do: :ok
  defp commit_hook(_, _), do: :ok

  defp checksum_stage(artifact),
    do:
      if(checksum_file?(artifact.stage_path, artifact.checksum),
        do: :ok,
        else: {:error, :stage_checksum_mismatch}
      )

  defp rollback(state) do
    [state.pending | state.committed]
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce_while(:ok, fn committed, :ok ->
      target = Path.join(state.root, committed.relative_path)

      result =
        case committed.action do
          "created" ->
            cond do
              not File.exists?(target) ->
                :ok

              checksum_file?(target, committed.checksum) and
                  created_target_is_transaction_file?(target, committed) ->
                remove_created_target(state.root, target)

              true ->
                {:error, :created_target_changed}
            end

          "updated" ->
            cond do
              checksum_file?(target, committed.backup_checksum) ->
                :ok

              checksum_file?(target, committed.checksum) and
                  checksum_file?(committed.backup, committed.backup_checksum) ->
                with :ok <- safe_ancestry(state.root, target, allow_missing?: false),
                     :ok <- safe_ancestry(state.root, committed.backup, allow_missing?: false),
                     :ok <- File.rename(committed.backup, target),
                     :ok <- maybe_fail(:after_restore_publish) do
                  :ok
                end

              true ->
                {:error, :updated_target_changed}
            end
        end

      if result == :ok, do: {:cont, :ok}, else: {:halt, result}
    end)
  end

  defp valid_journal?(
         root,
         %{
           "root" => stored_root,
           "tx_root" => tx_root,
           "artifacts" => artifacts,
           "committed" => committed
         } = journal
       )
       when is_list(artifacts) and is_list(committed) do
    pending = Map.get(journal, "pending")

    if Path.expand(stored_root) == root and safe_path?(root, tx_root) and
         Enum.all?(artifacts, &safe_serialized_artifact?(&1, root)) and
         Enum.all?(committed, &safe_committed?(&1, root, tx_root)) and
         (is_nil(pending) or safe_committed?(pending, root, tx_root)) and
         Map.get(journal, "terminal") in [nil, "rolled_back", "committed"],
       do: :ok,
       else: {:error, :invalid_journal}
  end

  defp valid_journal?(_, _), do: {:error, :invalid_journal}

  defp serialized_state(root, journal, state) do
    %{
      root: root,
      journal: journal,
      tx_root: state["tx_root"],
      committed: Enum.map(state["committed"], &atomize_keys/1),
      pending: if(state["pending"], do: atomize_keys(state["pending"]), else: nil),
      terminal: state["terminal"],
      artifacts: []
    }
  end

  defp safe_serialized_artifact?(artifact, root),
    do:
      is_map(artifact) and safe_relative?(artifact["relative_path"] || "") and
        safe_path?(root, artifact["stage_path"] || "")

  defp safe_committed?(entry, root, tx_root),
    do:
      is_map(entry) and safe_relative?(entry["relative_path"] || "") and
        entry["action"] in ["created", "updated"] and
        (entry["action"] == "created" or safe_path?(tx_root, entry["backup"] || "")) and
        (is_nil(entry["stage_path"]) or safe_path?(tx_root, entry["stage_path"])) and
        safe_path?(root, Path.join(root, entry["relative_path"] || ""))

  defp created_target_is_transaction_file?(target, %{stage_path: stage_path})
       when is_binary(stage_path) do
    case {file_identity(target), file_identity(stage_path)} do
      {{:ok, target_identity}, {:ok, stage_identity}} -> target_identity == stage_identity
      _ -> false
    end
  end

  defp created_target_is_transaction_file?(_target, _committed), do: true

  defp file_identity(path) do
    with {:ok, %{type: :regular} = stat} <- File.lstat(path),
         true <- is_integer(stat.inode) and stat.inode > 0,
         true <- is_integer(stat.major_device) and is_integer(stat.minor_device) do
      {:ok, {stat.major_device, stat.minor_device, stat.inode}}
    else
      _ -> {:error, :transaction_file_identity_unavailable}
    end
  end

  defp write_journal(state) do
    temporary = journal_temporary(state)

    result =
      with :ok <- File.mkdir_p(Path.dirname(state.journal)),
           :ok <- safe_ancestry(state.root, state.journal, allow_missing?: true),
           :ok <- safe_ancestry(state.root, temporary, allow_missing?: true),
           :ok <- write_synced_file(temporary, Jason.encode!(journal_map(state), pretty: true)),
           :ok <- maybe_fail_if_pending(state),
           :ok <- safe_ancestry(state.root, state.journal, allow_missing?: true),
           :ok <- File.rename(temporary, state.journal) do
        :ok
      else
        {:simulated_interruption, _} = interruption -> interruption
        {:error, reason} -> {:error, {:journal_write_failed, reason}}
      end

    if File.exists?(temporary), do: File.rm(temporary)
    result
  end

  defp journal_temporary(state) do
    case File.lstat(state.tx_root) do
      {:error, :enoent} ->
        initial_journal_temporary(state.journal)

      {:ok, %{type: :directory}} ->
        Path.join(
          state.tx_root,
          "journal-#{System.unique_integer([:positive, :monotonic])}.tmp"
        )

      _ ->
        Path.join(
          state.tx_root,
          "journal-#{System.unique_integer([:positive, :monotonic])}.tmp"
        )
    end
  end

  defp initial_journal_temporary(journal), do: journal <> ".initial-tmp"

  defp write_synced_file(path, contents) do
    case :file.open(String.to_charlist(path), [:write, :binary, :exclusive]) do
      {:ok, io} ->
        result =
          with :ok <- :file.write(io, contents),
               :ok <- :file.sync(io) do
            :ok
          end

        close_result = :file.close(io)
        if result == :ok, do: close_result, else: result

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_fail_if_pending(%{pending: pending}) when not is_nil(pending),
    do: maybe_fail(:before_intent_journal_replace)

  defp maybe_fail_if_pending(%{artifacts: [], committed: [], pending: nil, tx_root: tx_root}) do
    case File.lstat(tx_root) do
      {:error, :enoent} -> maybe_fail(:before_initial_journal_replace)
      _ -> :ok
    end
  end

  defp maybe_fail_if_pending(_state), do: :ok

  defp journal_map(state),
    do: %{
      root: state.root,
      tx_root: state.tx_root,
      artifacts: state.artifacts,
      committed: state.committed,
      terminal: Map.get(state, :terminal),
      pending: Map.get(state, :pending)
    }

  defp finalize_committed(state) do
    committed = Map.merge(state, %{committed: [], pending: nil, terminal: "committed"})

    with :ok <- write_journal(committed),
         :ok <- maybe_fail(:after_committed_terminal) do
      cleanup(committed)
    end
  end

  defp finalize_rolled_back(state) do
    rolled_back = Map.merge(state, %{committed: [], pending: nil, terminal: "rolled_back"})

    case write_journal(rolled_back) do
      :ok ->
        case maybe_fail(:after_rolled_back_terminal) do
          :ok -> cleanup(rolled_back)
          interruption -> interruption
        end

      error ->
        error
    end
  end

  defp cleanup(state) do
    cleanup_steps(state)
    |> run_steps()
  end

  defp cleanup_steps(state) do
    [
      fn -> safe_ancestry(state.root, state.journal, allow_missing?: true) end,
      fn -> safe_ancestry(state.root, state.tx_root, allow_missing?: true) end,
      fn ->
        with :ok <- remove_staging_directory(state.tx_root),
             :ok <- maybe_fail(:after_transaction_directory_cleanup) do
          :ok
        end
      end,
      fn -> remove_regular_journal(state.journal) end,
      fn -> remove_empty_transaction_parent(Path.dirname(state.journal)) end
    ]
  end

  defp run_steps(steps) do
    Enum.reduce_while(steps, :ok, fn step, :ok ->
      case step.() do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp remove_regular_journal(journal) do
    case File.lstat(journal) do
      {:error, :enoent} -> :ok
      {:ok, %{type: :regular}} -> File.rm(journal)
      {:ok, _} -> {:error, :unsafe_journal_cleanup}
      {:error, reason} -> {:error, reason}
    end
  end

  defp remove_staging_directory(tx_root) do
    case File.lstat(tx_root) do
      {:error, :enoent} ->
        :ok

      {:ok, %{type: :directory}} ->
        case File.rm_rf(tx_root) do
          {:ok, _removed} -> :ok
          {:error, reason, _path} -> {:error, reason}
        end

      {:ok, _} ->
        {:error, :unsafe_staging_cleanup}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp remove_empty_transaction_parent(parent) do
    case File.rmdir(parent) do
      :ok -> :ok
      {:error, reason} when reason in [:enotempty, :eexist] -> :ok
      {:error, :enoent} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp remove_created_target(root, target) do
    case File.rm(target) do
      :ok -> prune_empty_parents(root, Path.dirname(target))
      error -> error
    end
  end

  defp prune_empty_parents(root, directory) do
    if Path.expand(directory) == Path.expand(root) do
      :ok
    else
      with :ok <- safe_ancestry(root, directory, allow_missing?: false) do
        case File.rmdir(directory) do
          :ok -> prune_empty_parents(root, Path.dirname(directory))
          {:error, reason} when reason in [:enotempty, :eexist] -> :ok
          {:error, :enoent} -> :ok
          {:error, reason} -> {:error, reason}
        end
      end
    end
  end

  defp expected_preimage(path, :absent) do
    case File.lstat(path) do
      {:error, :enoent} -> :ok
      {:ok, _} -> {:error, :destination_appeared}
      {:error, reason} -> {:error, reason}
    end
  end

  defp expected_preimage(path, checksum) when is_binary(checksum) do
    case File.lstat(path) do
      {:ok, %{type: :regular}} ->
        if checksum_file?(path, checksum), do: :ok, else: {:error, :preimage_changed}

      {:ok, %{type: :symlink}} ->
        {:error, :symlink_refused}

      {:ok, _} ->
        {:error, :non_regular_target}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp safe_ancestry(root, target, opts) do
    root = Path.expand(root)
    target = Path.expand(target)
    allow_missing? = Keyword.fetch!(opts, :allow_missing?)

    with true <- safe_path?(root, target),
         :ok <- inspect_root(root),
         :ok <- inspect_components(root, Path.relative_to(target, root), allow_missing?) do
      :ok
    else
      false -> {:error, :outside_project_root}
      {:error, reason} -> {:error, reason}
    end
  end

  defp inspect_root(root) do
    case File.lstat(root) do
      {:ok, %{type: :directory}} -> :ok
      {:ok, %{type: :symlink}} -> {:error, :symlink_refused}
      {:ok, _} -> {:error, :invalid_project_root}
      {:error, :enoent} -> File.mkdir_p(root)
      {:error, reason} -> {:error, reason}
    end
  end

  defp inspect_components(root, relative, allow_missing?) do
    relative
    |> Path.split()
    |> Enum.reduce_while({:ok, root}, fn component, {:ok, current} ->
      next = Path.join(current, component)

      case File.lstat(next) do
        {:ok, %{type: :symlink}} -> {:halt, {:error, :symlink_refused}}
        {:ok, _} -> {:cont, {:ok, next}}
        {:error, :enoent} when allow_missing? -> {:cont, {:ok, next}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, _} -> :ok
      error -> error
    end
  end

  defp safe_relative?(path) when is_binary(path),
    do: path != "" and Path.type(path) != :absolute and not Enum.member?(Path.split(path), "..")

  defp safe_relative?(_), do: false

  defp safe_path?(root, path) when is_binary(path),
    do:
      Path.expand(path) == Path.expand(root) or
        String.starts_with?(Path.expand(path), Path.expand(root) <> "/")

  defp checksum_file?(path, checksum) do
    case File.read(path) do
      {:ok, contents} -> Manifest.checksum(contents) == checksum
      _ -> false
    end
  end

  defp manifest_sort(%{kind: :manifest}), do: 1
  defp manifest_sort(_), do: 0

  defp maybe_fail(hook) do
    configured = Process.get(@test_hook_key)
    if is_function(configured, 1), do: configured.(hook)

    cond do
      configured_hook?(configured, hook) or migration_hook?(configured, hook) ->
        {:simulated_interruption, hook}

      configured_hook?(configured, {:ordinary_failure, hook}) ->
        {:error, {:injected_failure, hook}}

      true ->
        :ok
    end
  end

  defp configured_hook?(configured, hook) when is_list(configured), do: hook in configured
  defp configured_hook?(configured, hook), do: configured == hook

  defp migration_hook?({:after_migration, number}, {:after_migration, number}), do: true
  defp migration_hook?(_, _), do: false

  defp collect_errors(results) do
    case Enum.filter(results, &(&1 != :ok)) do
      [] -> :ok
      errors -> {:error, Enum.map(errors, &error(:unsafe_path, safe_reason(&1)))}
    end
  end

  defp error(type, message), do: %{type: type, message: message}
  defp safe_reason(reason) when is_binary(reason), do: reason
  defp safe_reason(reason), do: inspect(reason)

  defp atomize_keys(map) do
    %{
      relative_path: map["relative_path"],
      action: map["action"],
      checksum: map["checksum"],
      backup: map["backup"],
      backup_checksum: map["backup_checksum"],
      stage_path: map["stage_path"]
    }
  end
end
