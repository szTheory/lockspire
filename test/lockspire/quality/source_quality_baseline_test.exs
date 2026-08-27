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

  test "pins the temporary Credo cleanup baseline scheduled for Plan 11" do
    directives = QualityBaseline.credo_directives_in("lib")

    assert QualityBaseline.file_wide_files(directives) == [
             "lib/lockspire/protocol/dpop.ex",
             "lib/lockspire/protocol/jar.ex",
             "lib/lockspire/protocol/request_object.ex"
           ]

    assert QualityBaseline.unnamed_next_line_locations(directives) == [
             {"lib/lockspire/domain/client.ex", 89},
             {"lib/lockspire/jwks_fetcher.ex", 190},
             {"lib/lockspire/protocol/authorization_request.ex", 900},
             {"lib/lockspire/protocol/token_exchange/internal/rfc8693_exchange.ex", 157},
             {"lib/lockspire/security/policy.ex", 82}
           ]
  end
end
