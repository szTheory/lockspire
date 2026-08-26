defmodule Lockspire.Install.OperationPlan do
  @moduledoc """
  A fully preflighted, immutable install or upgrade operation.

  The plan is deliberately built from rendered bytes and a complete migration
  inventory before it mutates a host project. Applying it is the only write
  boundary and always writes the manifest last.
  """

  alias Lockspire.Install.Manifest
  alias Lockspire.Install.Migrations
  alias Lockspire.Install.FileTransaction

  @enforce_keys [:assigns, :mode, :migration_plan, :file_operations, :manifest]
  defstruct [:assigns, :mode, :migration_plan, :file_operations, :manifest]

  @type file_operation :: %{
          required(:relative_path) => String.t(),
          required(:destination) => String.t(),
          required(:rendered) => String.t(),
          required(:status) => :create | :update | :unchanged,
          optional(:expected_checksum) => String.t()
        }

  @type t :: %__MODULE__{
          assigns: map(),
          mode: :install | :upgrade,
          migration_plan: Migrations.plan(),
          file_operations: [file_operation()],
          manifest: map()
        }

  @spec install(map(), [map()]) :: {:ok, t()} | {:error, [map()]}
  def install(assigns, rendered_templates) do
    with :ok <- FileTransaction.recover(assigns.project_root) do
      build(assigns, :install, rendered_templates, nil)
    end
  end

  @spec upgrade(map(), [map()], map()) :: {:ok, t()} | {:error, [map()]}
  def upgrade(assigns, rendered_templates, manifest) when is_map(manifest) do
    with :ok <- FileTransaction.recover(assigns.project_root) do
      build(assigns, :upgrade, rendered_templates, manifest)
    end
  end

  @doc "Reports the same immutable plan used by dry-run and apply."
  @spec report(t(), :apply | :dry_run) :: :ok
  def report(%__MODULE__{} = plan, mode) when mode in [:apply, :dry_run] do
    Enum.each(plan.migration_plan.operations, &report_migration(&1, mode))
    Enum.each(plan.file_operations, &report_file(&1, mode))

    :ok
  end

  defp report_migration(operation, :dry_run) do
    action = if operation.status == :copy, do: "COPY", else: "UNCHANGED"
    Mix.shell().info("DRY-RUN #{action} #{operation.relative_path}")
  end

  defp report_migration(operation, :apply) do
    action = if operation.status == :copy, do: "COPY", else: "UNCHANGED"
    Mix.shell().info("#{action} #{operation.relative_path}")
  end

  defp report_file(operation, :dry_run),
    do: Mix.shell().info("DRY-RUN #{operation.relative_path}")

  defp report_file(%{status: :create, relative_path: path}, :apply),
    do: Mix.shell().info("* created #{path}")

  defp report_file(%{status: :update, relative_path: path}, :apply),
    do: Mix.shell().info("* updated #{path}")

  defp report_file(%{status: :unchanged, relative_path: path}, :apply),
    do: Mix.shell().info("* unchanged #{path}")

  @spec apply(t()) :: {:ok, t()} | {:error, [map()]}
  def apply(%__MODULE__{} = plan) do
    with :ok <- validate_file_operations(plan.file_operations),
         {:ok, artifacts} <- transaction_artifacts(plan),
         :ok <- FileTransaction.apply(plan.assigns.project_root, artifacts) do
      {:ok, plan}
    end
  end

  defp transaction_artifacts(plan) do
    migrations =
      plan.migration_plan.operations
      |> Enum.filter(&(&1.status == :copy))
      |> Enum.map(fn operation ->
        %{
          relative_path: operation.relative_path,
          kind: :migration,
          expected: :absent,
          contents: operation.contents,
          checksum: operation.checksum,
          provenance: "packaged migration"
        }
      end)

    managed =
      plan.file_operations
      |> Enum.reject(&(&1.status == :unchanged))
      |> Enum.map(fn operation ->
        %{
          relative_path: operation.relative_path,
          kind: :managed,
          expected:
            if(operation.status == :create, do: :absent, else: operation.expected_checksum),
          contents: operation.rendered,
          checksum: Manifest.checksum(operation.rendered),
          provenance: "managed generator template"
        }
      end)

    manifest_contents = Manifest.encode(plan.manifest)

    manifest = %{
      relative_path: ".lockspire/install_manifest.json",
      kind: :manifest,
      expected: manifest_expected(plan.assigns.project_root),
      contents: manifest_contents,
      checksum: Manifest.checksum(manifest_contents),
      provenance: "install manifest"
    }

    {:ok, migrations ++ managed ++ [manifest]}
  end

  defp manifest_expected(project_root) do
    case File.read(Manifest.path(project_root)) do
      {:ok, contents} -> Manifest.checksum(contents)
      {:error, :enoent} -> :absent
      {:error, _} -> :absent
    end
  end

  defp build(assigns, mode, rendered_templates, manifest) do
    with {:ok, migration_plan} <- Migrations.plan(project_root: assigns.project_root),
         {:ok, file_operations} <- file_operations(mode, rendered_templates, manifest),
         {:ok, final_manifest} <- final_manifest(assigns, rendered_templates, migration_plan) do
      {:ok,
       %__MODULE__{
         assigns: assigns,
         mode: mode,
         migration_plan: migration_plan,
         file_operations: file_operations,
         manifest: final_manifest
       }}
    end
  end

  defp final_manifest(assigns, rendered_templates, migration_plan) do
    managed = Enum.filter(rendered_templates, &(&1.template.ownership == :managed))
    migrations = Enum.map(migration_plan.operations, &migration_inventory/1)
    {:ok, Manifest.build(assigns, managed, migrations)}
  end

  defp migration_inventory(operation) do
    Map.take(operation, [:version, :name, :relative_path, :checksum])
  end

  defp file_operations(:install, rendered_templates, _manifest) do
    rendered_templates
    |> Enum.sort_by(& &1.relative_path)
    |> Enum.map(&install_operation/1)
    |> collect_operations()
  end

  defp file_operations(:upgrade, rendered_templates, manifest) do
    managed =
      rendered_templates
      |> Enum.filter(&(&1.template.ownership == :managed))
      |> Map.new(&{&1.relative_path, &1})

    manifest_entries = Map.get(manifest, "managed_files", [])

    with {:ok, expected} <- manifest_entries(manifest_entries, managed),
         {:ok, tracked_operations} <- upgrade_operations(expected),
         {:ok, new_operations} <- new_managed_operations(managed, expected) do
      {:ok, Enum.sort_by(tracked_operations ++ new_operations, & &1.relative_path)}
    end
  end

  defp manifest_entries(entries, managed) when is_list(entries) do
    entries
    |> Enum.map(fn entry ->
      with path when is_binary(path) <- entry["path"],
           checksum when is_binary(checksum) <- entry["checksum"],
           {:ok, rendered} <- Map.fetch(managed, path) do
        {:ok, {path, %{rendered: rendered, expected_checksum: checksum}}}
      else
        :error -> {:error, error(:invalid_manifest, "managed file is no longer shipped")}
        _ -> {:error, error(:invalid_manifest, "managed file entry is malformed")}
      end
    end)
    |> collect_pairs()
  end

  defp manifest_entries(_entries, _managed),
    do: {:error, [error(:invalid_manifest, "managed_files must be a list")]}

  defp upgrade_operations(expected) do
    expected
    |> Enum.map(fn {_path, %{rendered: rendered, expected_checksum: expected_checksum}} ->
      case File.read(rendered.destination) do
        {:ok, contents} ->
          current_checksum = Manifest.checksum(contents)
          next_checksum = Manifest.checksum(rendered.rendered)

          cond do
            current_checksum != expected_checksum ->
              {:error, drift_error(rendered.relative_path, "checksum drift detected")}

            current_checksum == next_checksum ->
              {:ok, file_operation(rendered, :unchanged, expected_checksum)}

            true ->
              {:ok, file_operation(rendered, :update, expected_checksum)}
          end

        {:error, :enoent} ->
          {:error, drift_error(rendered.relative_path, "managed file is missing")}

        {:error, reason} ->
          {:error, drift_error(rendered.relative_path, inspect(reason))}
      end
    end)
    |> collect_operations()
  end

  defp new_managed_operations(managed, expected) do
    managed
    |> Enum.reject(fn {path, _rendered} -> Map.has_key?(expected, path) end)
    |> Enum.map(fn {_path, rendered} -> install_operation(rendered) end)
    |> collect_operations()
  end

  defp install_operation(rendered) do
    case File.read(rendered.destination) do
      {:error, :enoent} ->
        {:ok, file_operation(rendered, :create)}

      {:ok, contents} when contents == rendered.rendered ->
        {:ok, file_operation(rendered, :unchanged)}

      {:ok, _contents} ->
        {:error,
         error(
           :managed_collision,
           "Refusing to overwrite modified file: #{relative_path(rendered.destination)}"
         )}

      {:error, reason} ->
        {:error,
         error(
           :host_file_unavailable,
           "Could not read #{relative_path(rendered.destination)}: #{inspect(reason)}"
         )}
    end
  end

  defp file_operation(rendered, status, expected_checksum \\ nil) do
    expected_checksum =
      if status == :create do
        expected_checksum
      else
        expected_checksum || Manifest.checksum(rendered.rendered)
      end

    %{
      relative_path: rendered.relative_path,
      destination: rendered.destination,
      rendered: rendered.rendered,
      status: status,
      expected_checksum: expected_checksum
    }
  end

  defp validate_file_operations(operations) do
    operations
    |> Enum.flat_map(&file_operation_errors/1)
    |> case do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  defp file_operation_errors(%{status: :create, destination: destination}) do
    case File.read(destination) do
      {:error, :enoent} ->
        []

      {:ok, _contents} ->
        [error(:approved_plan_changed, "Host file appeared: #{relative_path(destination)}")]

      {:error, reason} ->
        [
          error(
            :approved_plan_changed,
            "Could not read #{relative_path(destination)}: #{inspect(reason)}"
          )
        ]
    end
  end

  defp file_operation_errors(%{destination: destination, expected_checksum: expected_checksum}) do
    case File.read(destination) do
      {:ok, contents} when is_binary(expected_checksum) ->
        if Manifest.checksum(contents) == expected_checksum,
          do: [],
          else: [
            error(:approved_plan_changed, "Host file changed: #{relative_path(destination)}")
          ]

      {:ok, contents} ->
        [
          error(
            :approved_plan_changed,
            "Host file changed: #{relative_path(destination)} (#{Manifest.checksum(contents)})"
          )
        ]

      {:error, reason} ->
        [
          error(
            :approved_plan_changed,
            "Could not read #{relative_path(destination)}: #{inspect(reason)}"
          )
        ]
    end
  end

  defp collect_operations(results) do
    {operations, errors} =
      Enum.reduce(results, {[], []}, fn
        {:ok, operation}, {operations, errors} -> {[operation | operations], errors}
        {:error, error}, {operations, errors} -> {operations, [error | errors]}
      end)

    if errors == [], do: {:ok, Enum.reverse(operations)}, else: {:error, Enum.reverse(errors)}
  end

  defp collect_pairs(results) do
    {pairs, errors} =
      Enum.reduce(results, {[], []}, fn
        {:ok, pair}, {pairs, errors} -> {[pair | pairs], errors}
        {:error, error}, {pairs, errors} -> {pairs, [error | errors]}
      end)

    if errors == [], do: {:ok, Map.new(pairs)}, else: {:error, Enum.reverse(errors)}
  end

  defp drift_error(path, reason), do: error(:managed_drift, "#{path} (#{reason})")
  defp error(type, message), do: %{type: type, message: message}
  defp relative_path(path), do: Path.relative_to_cwd(path)
end
