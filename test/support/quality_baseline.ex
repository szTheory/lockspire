defmodule Lockspire.TestSupport.QualityBaseline do
  @moduledoc false

  @repo_root Path.expand("../..", __DIR__)
  @credo_directive ~r/^\s*#\s*credo:(?<kind>disable-for-this-file|disable-for-next-line)(?:\s+(?<check>Credo\.Check\.[A-Za-z0-9_.]+))?\s*$/
  @dialyzer_warning ~r/^(?<file>lib\/.+?\.ex):(?<line>\d+)(?::\d+)?:?(?<kind>[a-z_]+)$/
  @phase_numbered_proof ~r/\bphase(?:[_ -]?\d+)\b/i
  @capability_proof_directories [
    "test/lockspire/web/live/admin",
    "test/lockspire/release",
    "test/support/lockspire/web/admin_lab",
    "test/support/lockspire/release_proof"
  ]
  @capability_proof_files [
    "test/lockspire/web/admin_router_test.exs",
    "test/lockspire/release_ci_evidence_contract_test.exs",
    "test/lockspire/release_please_runtime_contract_test.exs",
    "test/lockspire/release_readiness_contract_test.exs"
  ]
  @capability_proof_exclusions [
    "test/lockspire/web/live/admin/design_system/inventory_contract_test.exs"
  ]

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

  @spec named_directives_without_adjacent_reason([credo_directive()]) :: [
          {String.t(), pos_integer()}
        ]
  def named_directives_without_adjacent_reason(directives) do
    directives
    |> Enum.filter(&(&1.kind == :next_line and is_binary(&1.check)))
    |> Enum.reject(&adjacent_reason?/1)
    |> Enum.map(&{&1.file, &1.line})
    |> Enum.sort()
  end

  @spec proof_constructs(String.t(), String.t()) :: [map()]
  def proof_constructs(file, source) when is_binary(file) and is_binary(source) do
    source
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_number} ->
      case proof_kind(line) do
        nil -> []
        kind -> [%{file: file, line: line_number, kind: kind}]
      end
    end)
  end

  @spec proof_constructs_in(String.t()) :: [map()]
  def proof_constructs_in(relative_directory) do
    relative_directory
    |> source_files()
    |> Enum.flat_map(fn relative_path ->
      proof_constructs(relative_path, File.read!(absolute_path(relative_path)))
    end)
    |> Enum.sort_by(&{&1.file, &1.line})
  end

  @spec active_proof_constructs() :: [map()]
  def active_proof_constructs do
    proof_constructs_in("test")
    |> Enum.reject(&String.starts_with?(&1.file, "test/lockspire/quality/"))
  end

  @spec proof_locations([map()], atom()) :: [{String.t(), pos_integer()}]
  def proof_locations(constructs, kind) do
    constructs
    |> Enum.filter(&(&1.kind == kind))
    |> Enum.map(&{&1.file, &1.line})
  end

  @spec phase_numbered_proof_locations(String.t(), String.t()) :: [{String.t(), pos_integer()}]
  def phase_numbered_proof_locations(file, source) when is_binary(file) and is_binary(source) do
    source
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.filter(fn {line, _line_number} -> Regex.match?(@phase_numbered_proof, line) end)
    |> Enum.map(fn {_line, line_number} -> {file, line_number} end)
  end

  @spec active_phase_numbered_proof_locations() :: [{String.t(), pos_integer()}]
  def active_phase_numbered_proof_locations do
    capability_proof_files()
    |> Enum.flat_map(fn relative_path ->
      phase_numbered_proof_locations(relative_path, File.read!(absolute_path(relative_path)))
    end)
    |> Enum.sort()
  end

  @spec dialyzer_error_count(String.t()) :: non_neg_integer()
  def dialyzer_error_count(output) do
    case Regex.run(~r/Total errors:\s*(\d+)/, output, capture: :all_but_first) do
      [count] -> String.to_integer(count)
      _ -> 0
    end
  end

  @spec dialyzer_warning_locations(String.t()) :: [map()]
  def dialyzer_warning_locations(output) do
    output
    |> String.split("\n")
    |> Enum.flat_map(fn line ->
      case Regex.named_captures(@dialyzer_warning, line) do
        %{"file" => file, "line" => line_number, "kind" => kind} ->
          [%{file: file, line: String.to_integer(line_number), kind: kind}]

        nil ->
          []
      end
    end)
  end

  @spec dialyzer_warning_files([String.t()]) :: [String.t()]
  def dialyzer_warning_files(files), do: files |> Enum.uniq() |> Enum.sort()

  @spec runtime_diagnostics(String.t()) :: [map()]
  def runtime_diagnostics(output) do
    output
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_number} ->
      case runtime_kind(line) do
        nil -> []
        {kind, routine?} -> [%{line: line_number, kind: kind, routine?: routine?}]
      end
    end)
  end

  defp source_files(relative_directory) do
    root = absolute_path(relative_directory)

    [Path.join(root, "**/*.ex"), Path.join(root, "**/*.exs")]
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.map(&Path.relative_to(&1, @repo_root))
    |> Enum.sort()
  end

  defp capability_proof_files do
    directory_files = Enum.flat_map(@capability_proof_directories, &source_files/1)

    (directory_files ++ @capability_proof_files)
    |> Enum.uniq()
    |> Enum.reject(&(&1 in @capability_proof_exclusions))
    |> Enum.sort()
  end

  defp absolute_path(relative_path), do: Path.join(@repo_root, relative_path)

  defp adjacent_reason?(%{file: file, line: line}) do
    file
    |> absolute_path()
    |> File.read!()
    |> String.split("\n")
    |> Enum.at(line - 2, "")
    |> then(fn previous ->
      String.match?(previous, ~r/^\s*#\s+\S/) and
        not String.contains?(previous, "credo:disable")
    end)
  end

  defp credo_kind("disable-for-this-file"), do: :file_wide
  defp credo_kind("disable-for-next-line"), do: :next_line

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp proof_kind(line) do
    cond do
      Regex.match?(~r/\bdefmacro\s+__using__\b/, line) ->
        :macro_injection

      Regex.match?(~r/File\.read!\(@phase_/, line) ->
        :phase_archaeology

      Regex.match?(
        ~r/^\s*assert\s+(?:(?:assertion_count|Enum\.sum\(Map\.values\(test_counts\)\)|length\(Enum\.uniq\(test_names\)\)).*(?:==|>=)\s+\d+|test_counts\s*==)/,
        line
      ) ->
        :count_threshold

      true ->
        nil
    end
  end

  defp runtime_kind(line) do
    cond do
      String.contains?(line, "Failed to refresh KeyCache") ->
        {:key_cache_startup_noise, true}

      String.contains?(line, "QUERY") and String.contains?(line, "[debug]") ->
        {:ecto_query_noise, true}

      String.contains?(String.downcase(line), "telemetry handler") ->
        {:telemetry_handler_noise, true}

      String.contains?(String.downcase(line), "redaction") and String.contains?(line, "plaintext") ->
        {:explicit_redaction_evidence, false}

      true ->
        nil
    end
  end
end
