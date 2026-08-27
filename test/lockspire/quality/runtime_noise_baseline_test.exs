defmodule Lockspire.Quality.RuntimeNoiseBaselineTest do
  use ExUnit.Case, async: true

  alias Lockspire.TestSupport.QualityBaseline

  test "classifies routine startup, SQL, and telemetry noise separately from explicit evidence" do
    output = """
    [error] Failed to refresh KeyCache: repository unavailable during startup
    [debug] QUERY OK source=\"signing_keys\" db=0.1ms
    [warning] telemetry handler already attached
    redaction assertion captured plaintext-free telemetry payload
    """

    assert QualityBaseline.runtime_diagnostics(output) == [
             %{line: 1, kind: :key_cache_startup_noise, routine?: true},
             %{line: 2, kind: :ecto_query_noise, routine?: true},
             %{line: 3, kind: :telemetry_handler_noise, routine?: true},
             %{line: 4, kind: :explicit_redaction_evidence, routine?: false}
           ]
  end

  test "names the dedicated negative and redaction tests that must survive quieting" do
    assert File.exists?("test/lockspire/key_cache_test.exs")
    assert File.exists?("test/lockspire/protocol/dcr_telemetry_redaction_test.exs")

    dcr_source = File.read!("test/lockspire/protocol/dcr_telemetry_redaction_test.exs")
    assert dcr_source =~ ":telemetry.attach_many"
    assert dcr_source =~ "plaintext"
  end
end
