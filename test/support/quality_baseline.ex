defmodule Lockspire.TestSupport.QualityBaseline do
  @moduledoc false

  @repo_root Path.expand("../..", __DIR__)
  @credo_directive ~r/^\s*#\s*credo:(?<kind>disable-for-this-file|disable-for-next-line)(?:\s+(?<check>Credo\.Check\.[A-Za-z0-9_.]+))?\s*$/

  @type credo_directive :: %{
          file: String.t(),
          line: pos_integer(),
          kind: :file_wide | :next_line,
          check: String.t() | nil
        }

  @spec credo_directives(String.t(), String.t()) :: [credo_directive()]
  def credo_directives(file, source) when is_binary(file) and is_binary(source) do
    source
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_number} ->
      case Regex.named_captures(@credo_directive, line) do
        %{"kind" => kind, "check" => check} ->
          [
            %{
              file: file,
              line: line_number,
              kind: credo_kind(kind),
              check: blank_to_nil(check)
            }
          ]

        nil ->
          []
      end
    end)
  end

  @spec credo_directives_in(String.t()) :: [credo_directive()]
  def credo_directives_in(relative_directory) when is_binary(relative_directory) do
    relative_directory
    |> source_files()
    |> Enum.flat_map(fn relative_path ->
      credo_directives(relative_path, File.read!(absolute_path(relative_path)))
    end)
    |> Enum.sort_by(&{&1.file, &1.line})
  end

  @spec file_wide_files([credo_directive()]) :: [String.t()]
  def file_wide_files(directives) do
    directives
    |> Enum.filter(&(&1.kind == :file_wide))
    |> Enum.map(& &1.file)
    |> Enum.sort()
  end

  @spec unnamed_next_line_locations([credo_directive()]) :: [{String.t(), pos_integer()}]
  def unnamed_next_line_locations(directives) do
    directives
    |> Enum.filter(&(&1.kind == :next_line and is_nil(&1.check)))
    |> Enum.map(&{&1.file, &1.line})
    |> Enum.sort()
  end

  defp source_files(relative_directory) do
    root = absolute_path(relative_directory)

    [Path.join(root, "**/*.ex"), Path.join(root, "**/*.exs")]
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.map(&Path.relative_to(&1, @repo_root))
    |> Enum.sort()
  end

  defp absolute_path(relative_path), do: Path.join(@repo_root, relative_path)

  defp credo_kind("disable-for-this-file"), do: :file_wide
  defp credo_kind("disable-for-next-line"), do: :next_line

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end
