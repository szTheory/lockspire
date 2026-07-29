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

  @doc """
  Used by `mix lockspire.upgrade`, which has already decided a refresh is
  needed and computed the new manifest content itself. This is the one
  legitimate "content is expected to change" write path left in the codebase
  -- `mix lockspire.install`'s own manifest write goes through
  `Lockspire.Generators.Install.plan/1`'s classification instead, which
  refuses on drift (including a differing recorded input) like every other
  managed file rather than calling this function at all.
  """
  @spec write(String.t(), map()) :: :ok
  def write(project_root, manifest) do
    destination = path(project_root)
    File.mkdir_p!(Path.dirname(destination))

    contents = encode(manifest)

    case File.read(destination) do
      {:ok, ^contents} ->
        Mix.shell().info("* unchanged #{Path.relative_to_cwd(destination)}")

      {:ok, _existing} ->
        File.write!(destination, contents)
        Mix.shell().info("* upgraded #{Path.relative_to_cwd(destination)}")

      {:error, :enoent} ->
        File.write!(destination, contents)
        Mix.shell().info("* created #{Path.relative_to_cwd(destination)}")

      {:error, reason} ->
        Mix.raise("Could not read #{Path.relative_to_cwd(destination)}: #{inspect(reason)}")
    end

    :ok
  end

  @spec encode(map()) :: String.t()
  def encode(manifest), do: Jason.encode!(manifest, pretty: true)

  @spec build(map(), [map()]) :: map()
  def build(assigns, rendered_templates) do
    %{
      "generator" => "lockspire.install",
      "version" => Application.spec(:lockspire, :vsn) |> List.to_string(),
      "inputs" => %{
        "mount_path" => assigns.mount_path,
        "storage_prefix" => assigns.storage_prefix,
        "oban_prefix" => assigns.oban_prefix,
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
