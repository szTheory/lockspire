defmodule Lockspire.StaticAnalysisBaselineContractTest do
  use ExUnit.Case, async: true

  @credo Path.expand("../../.credo.exs", __DIR__)
  @mixfile Path.expand("../../mix.exs", __DIR__)
  @wrapper Path.expand("../../scripts/ci/run_credo.sh", __DIR__)

  test "Credo analyzes the full source set with a bounded parse budget" do
    config = File.read!(@credo)

    assert config =~ "parse_timeout: 30_000"
    assert config =~ "included: [\"lib/\", \"test/\"]"
    refute config =~ "excluded: [\"lib/\""
    refute config =~ "excluded: [\"test/\""
  end

  test "qa reaches a fail-closed Credo wrapper without persisting diagnostics" do
    assert File.read!(@mixfile) =~ "cmd bash scripts/ci/run_credo.sh"

    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-credo-contract-#{System.unique_integer([:positive])}"
      )

    bin = Path.join(fixture, "bin")
    diagnostics = Path.join(fixture, "diagnostics")

    try do
      File.mkdir_p!(bin)
      File.mkdir_p!(diagnostics)
      mix = Path.join(bin, "mix")

      File.write!(mix, """
      #!/usr/bin/env bash
      [[ "$*" == 'credo --strict' ]] || exit 99
      printf '%s\\n' "$FAKE_CREDO_STDOUT"
      printf '%s\\n' "$FAKE_CREDO_STDERR" >&2
      exit "$FAKE_CREDO_STATUS"
      """)

      File.chmod!(mix, 0o755)
      temp_marker = Path.join(fixture, "temporary-file-attempted")
      mktemp = Path.join(bin, "mktemp")

      File.write!(mktemp, """
      #!/usr/bin/env bash
      printf 'invoked\\n' > "$FAKE_CREDO_TEMP_MARKER"
      exit 73
      """)

      File.chmod!(mktemp, 0o755)
      parse_warning = "Some source files were not parsed in the time allotted"

      for {status, stdout, stderr, expected_status} <- [
            {0, "complete source inspected", "", 0},
            {23, "fixture diagnostic", "fixture error", 23},
            {0, parse_warning, "", 1},
            {0, "complete source inspected", parse_warning, 1}
          ] do
        {output, actual_status} =
          System.cmd("bash", [@wrapper],
            env: [
              {"PATH", bin <> ":" <> System.get_env("PATH", "")},
              {"TMPDIR", diagnostics},
              {"FAKE_CREDO_TEMP_MARKER", temp_marker},
              {"FAKE_CREDO_STATUS", Integer.to_string(status)},
              {"FAKE_CREDO_STDOUT", stdout},
              {"FAKE_CREDO_STDERR", stderr}
            ],
            stderr_to_stdout: true
          )

        assert actual_status == expected_status
        assert output =~ stdout
        assert output =~ stderr
        assert File.ls!(diagnostics) == []
        refute File.exists?(temp_marker)
      end
    after
      File.rm_rf!(fixture)
    end
  end
end
