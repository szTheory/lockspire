defmodule Lockspire.Install.Migrations do
  @moduledoc """
  Safely plans and applies Lockspire's packaged Ecto migrations to a host project.

  Planning is read-only: it validates the complete packaged and host inventories before
  reporting any file that can be copied. Applying an approved plan copies only files
  that were absent during preflight and never overwrites a host-owned migration.
  """

  alias Lockspire.Install.Manifest

  @default_source_root Application.app_dir(:lockspire, "priv/repo/migrations")
  @test_source_root_key {__MODULE__, :test_source_root}
  @migration_pattern ~r/^(?<version>\d+)_(?<name>[A-Za-z0-9_]+)\.exs$/

  @type operation_status :: :copy | :unchanged
  @type operation :: %{
          required(:status) => operation_status(),
          required(:source) => String.t(),
          required(:destination) => String.t(),
          required(:version) => String.t(),
          required(:name) => String.t(),
          required(:relative_path) => String.t(),
          required(:checksum) => String.t()
        }

  @type plan :: %{
          required(:source_root) => String.t(),
          required(:destination_root) => String.t(),
          required(:operations) => [operation()]
        }

  @doc """
  Returns a complete, read-only copy plan for packaged migrations.

  `:source_root` and `:project_root` are injectable for tests. In normal use they
  default to Lockspire's packaged migrations and the current Mix project.
  """
  @spec plan(keyword()) :: {:ok, plan()} | {:error, [map()]}
  def plan(opts \\ []) do
    source_root = opts |> Keyword.get(:source_root, source_root()) |> Path.expand()
    project_root = opts |> Keyword.get(:project_root, File.cwd!()) |> Path.expand()
    destination_root = Path.join(project_root, "priv/repo/migrations")

    with {:ok, packaged} <- packaged_migrations(source_root),
         {:ok, host} <- host_migrations(destination_root),
         {:ok, operations} <- preflight(packaged, host, destination_root) do
      {:ok,
       %{
         source_root: source_root,
         destination_root: destination_root,
         operations: operations
       }}
    end
  end

  @doc false
  @spec with_test_source_root(String.t(), (-> result)) :: result when result: var
  def with_test_source_root(source_root, fun)
      when is_binary(source_root) and is_function(fun, 0) do
    if Mix.env() != :test do
      raise ArgumentError, "test migration source roots are only available in Mix.env() == :test"
    end

    previous = Process.get(@test_source_root_key)
    Process.put(@test_source_root_key, Path.expand(source_root))

    try do
      fun.()
    after
      if is_nil(previous) do
        Process.delete(@test_source_root_key)
      else
        Process.put(@test_source_root_key, previous)
      end
    end
  end

  @doc false
  @spec source_root() :: String.t()
  def source_root do
    Process.get(@test_source_root_key, @default_source_root)
  end

  @doc """
  Copies only the missing files from a successful `plan/1` result.

  Before making the destination directory, application confirms that both source and
  destination inventory still match the approved plan. This preserves the host's
  no-overwrite guarantee if files change between preflight and apply.
  """
  @spec apply(plan()) :: {:ok, %{operations: [map()], migrations: [map()]}} | {:error, [map()]}
  def apply(%{destination_root: destination_root, operations: operations} = approved_plan)
      when is_list(operations) do
    with :ok <- validate_approved_plan(approved_plan),
         :ok <- File.mkdir_p(destination_root),
         {:ok, applied_operations} <- copy_operations(operations) do
      {:ok,
       %{
         operations: applied_operations,
         migrations: Enum.map(operations, &inventory_entry/1)
       }}
    else
      {:error, errors} when is_list(errors) -> {:error, errors}
      {:error, reason} -> {:error, [apply_error(destination_root, reason)]}
    end
  end

  def apply(_plan), do: {:error, [%{type: :invalid_plan, message: "expected a migration plan"}]}

  defp packaged_migrations(source_root) do
    case File.ls(source_root) do
      {:ok, filenames} ->
        filenames
        |> Enum.sort()
        |> Enum.map(&packaged_migration(source_root, &1))
        |> collect_results()

      {:error, reason} ->
        {:error,
         [
           %{
             type: :package_source_unavailable,
             source: source_root,
             message: "Lockspire packaged migrations could not be read: #{inspect(reason)}"
           }
         ]}
    end
  end

  defp packaged_migration(source_root, filename) do
    source = Path.join(source_root, filename)

    with {:ok, %{type: :regular}} <- File.stat(source),
         {:ok, identity} <- parse_filename(filename),
         {:ok, contents} <- File.read(source) do
      {:ok,
       Map.merge(identity, %{
         filename: filename,
         source: source,
         checksum: Manifest.checksum(contents)
       })}
    else
      {:error, :invalid_filename} ->
        {:error,
         %{
           type: :invalid_package_migration,
           source: source,
           message: "Invalid packaged migration filename: #{source}"
         }}

      {:ok, _stat} ->
        {:error,
         %{
           type: :invalid_package_migration,
           source: source,
           message: "Packaged migration must be a regular file: #{source}"
         }}

      {:error, reason} ->
        {:error,
         %{
           type: :invalid_package_migration,
           source: source,
           message: "Packaged migration could not be read: #{source} (#{inspect(reason)})"
         }}
    end
  end

  defp host_migrations(destination_root) do
    case File.ls(destination_root) do
      {:ok, filenames} ->
        host =
          filenames
          |> Enum.sort()
          |> Enum.flat_map(fn filename ->
            case parse_filename(filename) do
              {:ok, identity} -> [Map.put(identity, :path, Path.join(destination_root, filename))]
              {:error, :invalid_filename} -> []
            end
          end)

        {:ok, host}

      {:error, :enoent} ->
        {:ok, []}

      {:error, reason} ->
        {:error,
         [
           %{
             type: :host_inventory_unavailable,
             destination: destination_root,
             message:
               "Host migration directory could not be read: #{destination_root} (#{inspect(reason)})"
           }
         ]}
    end
  end

  defp preflight(packaged, host, destination_root) do
    {operations, errors} =
      Enum.map_reduce(packaged, [], fn migration, errors ->
        destination = Path.join(destination_root, migration.filename)
        collision_errors = collision_errors(migration, destination, host)

        if collision_errors == [] do
          status = destination_status(destination, migration.checksum)
          {operation(migration, destination, status), errors}
        else
          {operation(migration, destination, :copy), errors ++ collision_errors}
        end
      end)

    if errors == [], do: {:ok, operations}, else: {:error, errors}
  end

  defp collision_errors(migration, destination, host) do
    exact_destination_error(migration, destination) ++
      version_collision_errors(migration, destination, host) ++
      name_collision_errors(migration, destination, host)
  end

  defp exact_destination_error(migration, destination) do
    case File.read(destination) do
      {:ok, contents} ->
        if Manifest.checksum(contents) == migration.checksum do
          []
        else
          [
            %{
              type: :content_collision,
              source: migration.source,
              destination: destination,
              message:
                "Content collision: #{destination} differs from packaged migration #{migration.source}. Lockspire will not overwrite host files."
            }
          ]
        end

      {:error, :enoent} ->
        []

      {:error, reason} ->
        [
          %{
            type: :host_inventory_unavailable,
            destination: destination,
            message: "Host migration could not be read: #{destination} (#{inspect(reason)})"
          }
        ]
    end
  end

  defp version_collision_errors(migration, destination, host) do
    host
    |> Enum.filter(&(&1.version == migration.version and &1.path != destination))
    |> Enum.map(fn conflicting ->
      %{
        type: :version_collision,
        source: migration.source,
        host: conflicting.path,
        version: migration.version,
        message:
          "Version collision: packaged migration #{migration.source} conflicts with host migration #{conflicting.path} for version #{migration.version}."
      }
    end)
  end

  defp name_collision_errors(migration, destination, host) do
    host
    |> Enum.filter(&(&1.name == migration.name and &1.path != destination))
    |> Enum.map(fn conflicting ->
      %{
        type: :name_collision,
        source: migration.source,
        host: conflicting.path,
        name: migration.name,
        message:
          "Name collision: packaged migration #{migration.source} conflicts with host migration #{conflicting.path} for name #{migration.name}."
      }
    end)
  end

  defp destination_status(destination, checksum) do
    case File.read(destination) do
      {:ok, contents} -> if Manifest.checksum(contents) == checksum, do: :unchanged, else: :copy
      _otherwise -> :copy
    end
  end

  defp operation(migration, destination, status) do
    %{
      status: status,
      source: migration.source,
      destination: destination,
      version: migration.version,
      name: migration.name,
      relative_path: Path.join("priv/repo/migrations", migration.filename),
      checksum: migration.checksum
    }
  end

  defp validate_approved_plan(%{operations: operations}) do
    errors =
      operations
      |> Enum.flat_map(&approved_operation_errors/1)

    if errors == [], do: :ok, else: {:error, errors}
  end

  # Revalidating both source and destination states is intentionally exhaustive at
  # this filesystem trust boundary; splitting it would obscure the approved-plan invariant.
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp approved_operation_errors(operation) do
    source_errors =
      case File.read(operation.source) do
        {:ok, contents} ->
          if Manifest.checksum(contents) == operation.checksum,
            do: [],
            else: [apply_error(operation.source, :source_changed)]

        {:error, reason} ->
          [apply_error(operation.source, reason)]
      end

    destination_errors =
      case {operation.status, File.read(operation.destination)} do
        {:copy, {:error, :enoent}} ->
          []

        {:copy, {:ok, _contents}} ->
          [apply_error(operation.destination, :destination_created)]

        {:copy, {:error, reason}} ->
          [apply_error(operation.destination, reason)]

        {:unchanged, {:ok, contents}} ->
          if Manifest.checksum(contents) == operation.checksum,
            do: [],
            else: [apply_error(operation.destination, :destination_changed)]

        {:unchanged, {:error, reason}} ->
          [apply_error(operation.destination, reason)]
      end

    source_errors ++ destination_errors
  end

  defp copy_operations(operations) do
    operations
    |> Enum.reduce_while({:ok, []}, fn operation, {:ok, applied} ->
      case copy_operation(operation) do
        {:ok, updated_operation} -> {:cont, {:ok, [updated_operation | applied]}}
        {:error, error} -> {:halt, {:error, [error]}}
      end
    end)
    |> then(fn
      {:ok, applied} -> {:ok, Enum.reverse(applied)}
      error -> error
    end)
  end

  defp copy_operation(%{status: :unchanged} = operation), do: {:ok, operation}

  defp copy_operation(%{status: :copy} = operation) do
    with {:ok, contents} <- File.read(operation.source),
         :ok <- File.write(operation.destination, contents, [:exclusive]) do
      {:ok, %{operation | status: :copied}}
    else
      {:error, reason} -> {:error, apply_error(operation.destination, reason)}
    end
  end

  defp inventory_entry(operation) do
    Map.take(operation, [:version, :name, :relative_path, :checksum])
  end

  defp parse_filename(filename) do
    case Regex.named_captures(@migration_pattern, filename) do
      %{"version" => version, "name" => name} -> {:ok, %{version: version, name: name}}
      nil -> {:error, :invalid_filename}
    end
  end

  defp collect_results(results) do
    {migrations, errors} =
      Enum.reduce(results, {[], []}, fn
        {:ok, migration}, {migrations, errors} -> {[migration | migrations], errors}
        {:error, error}, {migrations, errors} -> {migrations, [error | errors]}
      end)

    if errors == [], do: {:ok, Enum.reverse(migrations)}, else: {:error, Enum.reverse(errors)}
  end

  defp apply_error(path, reason) do
    %{
      type: :approved_plan_changed,
      path: path,
      message: "Migration plan is no longer safe to apply at #{path}: #{inspect(reason)}"
    }
  end
end
