defmodule Lockspire.Quality.SourceQualityBaselineTest do
  use ExUnit.Case, async: true

  alias Lockspire.TestSupport.QualityBaseline

  test "finds structured file-wide and unnamed Credo directives without treating prose as configuration" do
    source = """
    # credo:disable-for-this-file
    # credo:disable-for-next-line
    def violating, do: :ok
    # credo:disable-for-next-line Credo.Check.Readability.ModuleDoc
    def allowed, do: :ok
    # docs: credo:disable-for-this-file is prose, not configuration
    """

    assert QualityBaseline.credo_directives("lib/example.ex", source) == [
             %{file: "lib/example.ex", line: 1, kind: :file_wide, check: nil},
             %{file: "lib/example.ex", line: 2, kind: :next_line, check: nil},
             %{
               file: "lib/example.ex",
               line: 4,
               kind: :next_line,
               check: "Credo.Check.Readability.ModuleDoc"
             }
           ]
  end

  test "requires zero file-wide or unnamed library Credo directives and reasons for named exceptions" do
    directives = QualityBaseline.credo_directives_in("lib")

    assert QualityBaseline.file_wide_files(directives) == []
    assert QualityBaseline.unnamed_next_line_locations(directives) == []
    assert QualityBaseline.named_directives_without_adjacent_reason(directives) == []
  end
end
