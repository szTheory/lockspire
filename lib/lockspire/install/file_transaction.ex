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
         {:ok, committed_state} <- commit(state) do
      cleanup(committed_state)
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

    case File.lstat(journal) do
      {:error, :enoent} ->
        :ok

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

  defp recover_journal(project_root, journal) do
    with {:ok, encoded} <- File.read(journal),
         {:ok, state} <- Jason.decode(encoded),
         :ok <- valid_journal?(project_root, state),
         :ok <- rollback(serialized_state(project_root, journal, state)) do
      cleanup(serialized_state(project_root, journal, state))
      :ok
    else
      {:error, errors} when is_list(errors) ->
        {:error, errors}

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
    is_binary(path) and kind in [:migration, :managed, :manifest] and
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

    with :ok <- safe_ancestry(project_root, Path.dirname(tx_root), allow_missing?: true),
         :ok <- File.mkdir_p(tx_root),
         :ok <- safe_ancestry(project_root, tx_root, allow_missing?: false),
         {:ok, staged} <- stage_artifacts(tx_root, artifacts),
         :ok <- maybe_fail(:after_staging) do
      state = %{
        root: project_root,
        tx_root: tx_root,
        journal: journal,
        artifacts: staged,
        committed: []
      }

      :ok = write_journal(state)
      {:ok, state}
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

        {:simulated_interruption, _} = interruption ->
          {:halt, interruption}

        {:error, reason} ->
          case rollback(current) do
            :ok ->
              {:halt, {:error, reason}}

            {:error, rollback_reason} ->
              {:halt,
               {:error,
                [
                  error(:rollback_failed, safe_reason(rollback_reason)),
                  error(:transaction_failed, safe_reason(reason))
                ]}}
          end
      end
    end)
    |> case do
      {:ok, committed_state} -> {:ok, committed_state}
      other -> other
    end
  end

  defp commit_artifact(state, artifact) do
    target = Path.join(state.root, artifact.relative_path)

    with :ok <- before_commit_hook(artifact),
         :ok <- safe_ancestry(state.root, target, allow_missing?: true),
         :ok <- expected_preimage(target, artifact.expected),
         :ok <- checksum_stage(artifact),
         {:ok, committed} <- write_target(state, artifact, target),
         :ok <- write_journal(%{state | committed: [committed | state.committed]}),
         :ok <- commit_hook(artifact, [committed | state.committed]) do
      {:ok, %{state | committed: [committed | state.committed]}}
    end
  end

  defp write_target(state, %{expected: :absent} = artifact, target) do
    with :ok <- File.mkdir_p(Path.dirname(target)),
         :ok <- safe_ancestry(state.root, target, allow_missing?: true),
         :ok <- File.write(target, File.read!(artifact.stage_path), [:exclusive]) do
      {:ok,
       %{relative_path: artifact.relative_path, action: "created", checksum: artifact.checksum}}
    end
  end

  defp write_target(state, artifact, target) do
    backup = Path.join(state.tx_root, "backup-#{length(state.committed)}")

    temporary =
      Path.join(Path.dirname(target), ".lockspire-tx-#{System.unique_integer([:positive])}")

    try do
      with {:ok, before} <- File.read(target),
           true <- Manifest.checksum(before) == artifact.expected,
           :ok <- File.write(backup, before, [:exclusive]),
           :ok <- File.write(temporary, File.read!(artifact.stage_path), [:exclusive]),
           :ok <- safe_ancestry(state.root, target, allow_missing?: false),
           :ok <- expected_preimage(target, artifact.expected),
           :ok <- File.rename(temporary, target) do
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
    after
      if File.exists?(temporary), do: File.rm(temporary)
    end
  end

  defp before_commit_hook(%{kind: :manifest}), do: maybe_fail(:before_manifest_commit)
  defp before_commit_hook(_), do: :ok

  defp commit_hook(%{kind: :migration}, committed) do
    maybe_fail({:after_migration, Enum.count(committed, &(&1.action == "created"))})
  end

  defp commit_hook(%{kind: :managed, expected: expected}, _committed) when expected != :absent,
    do: maybe_fail(:after_first_managed_update)

  defp commit_hook(%{kind: :manifest}, _committed), do: :ok
  defp commit_hook(_, _), do: :ok

  defp checksum_stage(artifact),
    do:
      if(checksum_file?(artifact.stage_path, artifact.checksum),
        do: :ok,
        else: {:error, :stage_checksum_mismatch}
      )

  defp rollback(state) do
    state.committed
    |> Enum.reduce_while(:ok, fn committed, :ok ->
      target = Path.join(state.root, committed.relative_path)

      result =
        case committed.action do
          "created" ->
            if checksum_file?(target, committed.checksum),
              do: File.rm(target),
              else: {:error, :created_target_changed}

          "updated" ->
            if checksum_file?(target, committed.checksum) and
                 checksum_file?(committed.backup, committed.backup_checksum) do
              restore =
                Path.join(
                  Path.dirname(target),
                  ".lockspire-restore-#{System.unique_integer([:positive])}"
                )

              case File.write(restore, File.read!(committed.backup), [:exclusive]) do
                :ok -> File.rename(restore, target)
                error -> error
              end
            else
              {:error, :updated_target_changed}
            end
        end

      if result == :ok, do: {:cont, :ok}, else: {:halt, result}
    end)
  end

  defp valid_journal?(root, %{
         "root" => stored_root,
         "tx_root" => tx_root,
         "artifacts" => artifacts,
         "committed" => committed
       })
       when is_list(artifacts) and is_list(committed) do
    if Path.expand(stored_root) == root and safe_path?(root, tx_root) and
         Enum.all?(artifacts, &safe_serialized_artifact?(&1, root)) and
         Enum.all?(committed, &safe_committed?(&1, root, tx_root)),
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
        safe_path?(root, Path.join(root, entry["relative_path"] || ""))

  defp write_journal(state) do
    with :ok <- File.mkdir_p(Path.dirname(state.journal)),
         :ok <- safe_ancestry(state.root, state.journal, allow_missing?: true),
         :ok <- File.write(state.journal, Jason.encode!(journal_map(state), pretty: true)),
         {:ok, io} <- :file.open(String.to_charlist(state.journal), [:read, :write]),
         :ok <- :file.sync(io) do
      :file.close(io)
      :ok
    else
      {:error, reason} -> {:error, {:journal_write_failed, reason}}
    end
  end

  defp journal_map(state),
    do: %{
      root: state.root,
      tx_root: state.tx_root,
      artifacts: state.artifacts,
      committed: state.committed
    }

  defp cleanup(state) do
    case File.lstat(state.journal) do
      {:ok, %{type: :regular}} -> File.rm(state.journal)
      _ -> :ok
    end

    File.rm_rf(state.tx_root)
    :ok
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

  defp maybe_fail(hook),
    do:
      if(
        Process.get(@test_hook_key) == hook or
          (match?({:after_migration, _}, Process.get(@test_hook_key)) and
             match?({:after_migration, _}, hook) and
             elem(Process.get(@test_hook_key), 1) == elem(hook, 1)),
        do: {:simulated_interruption, hook},
        else: :ok
      )

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
      backup_checksum: map["backup_checksum"]
    }
  end
end
