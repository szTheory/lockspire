defmodule Lockspire.Install.Assets do
  @moduledoc false

  @doc false
  @spec path(String.t()) :: String.t()
  def path(relative) when is_binary(relative) do
    compiled_path = Application.app_dir(:lockspire, relative)

    if File.dir?(compiled_path) do
      compiled_path
    else
      source_path()
      |> Path.join(relative)
    end
  end

  defp source_path do
    Mix.Project.deps_paths()
    |> Map.fetch!(:lockspire)
  end
end
