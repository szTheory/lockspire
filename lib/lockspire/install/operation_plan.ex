defmodule Lockspire.Install.OperationPlan do
  @moduledoc """
  A fully preflighted, immutable install or upgrade operation.

  The plan is deliberately built from rendered bytes and a complete migration
  inventory before it mutates a host project. Applying it is the only write
  boundary and always writes the manifest last.
  """

  alias Lockspire.Install.Manifest
  alias Lockspire.Install.Migrations

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
    build(assigns, :install, rendered_templates, nil)
  end

  @spec upgrade(map(), [map()], map()) :: {:ok, t()} | {:error, [map()]}
  def upgrade(assigns, rendered_templates, manifest) when is_map(manifest) do
    build(assigns, :upgrade, rendered_templates, manifest)
  end

  @doc "Reports the same immutable plan used by dry-run and apply."
  @spec report(t(), :apply | :dry_run) :: :ok
  def report(%__MODULE__{} = plan, mode) when mode in [:apply, :dry_run] do
    prefix = if mode == :dry_run, do: "DRY-RUN ", else: ""

    Enum.each(plan.migration_plan.operations, fn operation ->
      action = if operation.status == :copy, do: "COPY", else: "UNCHANGED"
      Mix.shell().info("#{prefix}#{action} #{operation.relative_path}")
    end)

    Enum.each(plan.file_operations, fn operation ->
      action =
        case operation.status do
          :create -> "CREATE"
          :update -> "UPDATE"
          :unchanged -> "UNCHANGED"
        end

      message =
        if mode == :dry_run do
          "DRY-RUN #{operation.relative_path}"
        else
          case action do
            "CREATE" -> "* created #{operation.relative_path}"
            "UPDATE" -> "* updated #{operation.relative_path}"
            "UNCHANGED" -> "* unchanged #{operation.relative_path}"
          end
        end

      Mix.shell().info(message)
    end)

    :ok
  end

  @spec apply(t()) :: {:ok, t()} | {:error, [map()]}
  def apply(%__MODULE__{} = plan) do
    with :ok <- validate_file_operations(plan.file_operations),
         {:ok, _migration_result} <- Migrations.apply(plan.migration_plan),
         :ok <- apply_file_operations(plan.file_operations),
         :ok <- Manifest.write(plan.assigns.project_root, plan.manifest) do
      {:ok, plan}
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

  defp apply_file_operations(operations) do
    operations
    |> Enum.reduce_while(:ok, fn operation, :ok ->
      case apply_file_operation(operation) do
        :ok -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, [error]}}
      end
    end)
  end

  defp apply_file_operation(%{status: :unchanged}), do: :ok

  defp apply_file_operation(%{status: status, destination: destination, rendered: rendered})
       when status in [:create, :update] do
    with :ok <- File.mkdir_p(Path.dirname(destination)),
         :ok <- write_file(destination, rendered, status) do
      :ok
    else
      {:error, reason} ->
        {:error,
         error(:apply_failed, "Could not write #{relative_path(destination)}: #{inspect(reason)}")}
    end
  end

  defp write_file(destination, rendered, :create),
    do: File.write(destination, rendered, [:exclusive])

  defp write_file(destination, rendered, :update), do: File.write(destination, rendered)

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
