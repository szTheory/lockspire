defmodule Lockspire.Install.Manifest do
  @moduledoc """
  Manifest storage for Lockspire-managed generated scaffolding.
  """

  @manifest_rel_path ".lockspire/install_manifest.json"

  @spec path(String.t()) :: String.t()
  def path(project_root) do
    Path.join(project_root, @manifest_rel_path)
  end

  @spec load(String.t()) :: {:ok, map()} | {:error, term()}
  def load(project_root) do
    project_root
    |> path()
    |> File.read()
    |> case do
      {:ok, contents} -> Jason.decode(contents)
      {:error, reason} -> {:error, reason}
    end
  end

  @spec write(String.t(), map()) :: :ok
  def write(project_root, manifest) do
    destination = path(project_root)
    File.mkdir_p!(Path.dirname(destination))

    contents = Jason.encode!(manifest, pretty: true)

    case File.read(destination) do
      {:ok, ^contents} ->
        Mix.shell().info("* unchanged #{Path.relative_to_cwd(destination)}")

      {:ok, _existing} ->
        File.write!(destination, contents)
        Mix.shell().info("* updated #{Path.relative_to_cwd(destination)}")

      {:error, :enoent} ->
        File.write!(destination, contents)
        Mix.shell().info("* created #{Path.relative_to_cwd(destination)}")

      {:error, reason} ->
        Mix.raise("Could not read #{Path.relative_to_cwd(destination)}: #{inspect(reason)}")
    end

    :ok
  end

  @spec build(map(), [map()]) :: map()
  def build(assigns, rendered_templates) do
    %{
      "generator" => "lockspire.install",
      "version" => to_string(Mix.Project.config()[:version]),
      "inputs" => %{
        "mount_path" => assigns.mount_path,
        "web_module" => assigns.web_module,
        "scope_module" => assigns.scope_module
      },
      "managed_files" =>
        Enum.map(rendered_templates, fn rendered ->
          %{
            "path" => rendered.relative_path,
            "checksum" => checksum(rendered.rendered)
          }
        end)
    }
  end

  @spec checksum(binary()) :: String.t()
  def checksum(contents) when is_binary(contents) do
    :sha256
    |> :crypto.hash(contents)
    |> Base.encode16(case: :lower)
  end
end
