defmodule Lockspire.Maintainer.DefectLedgerContractTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Enforces phase 126 success criteria 4 and 5 over the committed defect ledger:

  - Criterion 4: the ledger is non-empty and every entry carries all six D-37 fields.
  - Criterion 5: every `# LOCKSPIRE_WALK_WORKAROUND: ADOPT-Dnn` marker under
    `scripts/maintainer/` has a matching ledger entry, and every ledger entry that claims a
    workaround has a matching marker -- set equality in both directions.

  This test does not gate on the walk task's own exit code, on it reaching its final step,
  or on an empty ledger passing. `126-VALIDATION.md` names all three as prohibited gates: a
  red walk with a complete, attributed ledger is this phase's definition of success.
  """

  @repo_root Path.expand("../../..", __DIR__)
  @ledger_path Path.join(
                 @repo_root,
                 ".planning/phases/126-adopter-path-walk-defect-ledger/126-DEFECT-LEDGER.md"
               )
  @maintainer_scripts_dir Path.join(@repo_root, "scripts/maintainer")

  @allowed_sources [
    "installer",
    "generated scaffolding",
    "guide",
    "reference demo",
    "library",
    "environment"
  ]
  @allowed_owning_phases ~w(127 128 129 130 future)

  @seeded_password "walk-adopter-password-2026"

  # ---------------------------------------------------------------------------------------
  # Parsing
  # ---------------------------------------------------------------------------------------

  defp ledger_body do
    unless File.regular?(@ledger_path) do
      flunk("""
      Missing committed defect ledger at #{@ledger_path}.

      Phase 126 success criterion 4 requires a committed, non-empty, fully-fielded defect
      ledger. This is expected to fail until plan 126-06's Task 2 authors that file.
      """)
    end

    File.read!(@ledger_path)
  end

  # Each entry is a `### ADOPT-Dnn` heading followed by `- **Field:** value` bullet lines, up
  # to the next `### ADOPT-Dnn` heading or the end of the document. The layout is deliberately
  # simple prose (per CONTEXT D-39, never JSON) so a human reviewer and this parser agree on
  # where one entry ends and the next begins.
  defp parse_entries(body) do
    ~r/^###\s+(ADOPT-D\d+)\s*\n(.*?)(?=\n###\s+ADOPT-D\d+|\z)/ms
    |> Regex.scan(body)
    |> Enum.map(fn [_full, id, section] -> {id, parse_fields(section)} end)
  end

  @field_labels %{
    walk_step: ~r/-\s*\*\*Walk step:\*\*\s*(.+)/,
    symptom: ~r/-\s*\*\*Symptom:\*\*\s*(.+)/,
    underlying_error: ~r/-\s*\*\*Underlying error:\*\*\s*(.+)/,
    source: ~r/-\s*\*\*Source:\*\*\s*(.+)/,
    owning_phase: ~r/-\s*\*\*Owning phase:\*\*\s*(.+)/,
    workaround: ~r/-\s*\*\*Workaround:\*\*\s*(.+)/
  }

  defp parse_fields(section) do
    Map.new(@field_labels, fn {key, regex} ->
      value =
        case Regex.run(regex, section) do
          [_full, captured] -> String.trim(captured)
          nil -> nil
        end

      {key, value}
    end)
  end

  # Every `# LOCKSPIRE_WALK_WORKAROUND: ADOPT-Dnn` marker across every file under
  # scripts/maintainer/ (both the shell harness and the Python flow driver).
  defp marker_ids do
    @maintainer_scripts_dir
    |> File.ls!()
    |> Enum.reject(&File.dir?(Path.join(@maintainer_scripts_dir, &1)))
    |> Enum.flat_map(fn filename ->
      path = Path.join(@maintainer_scripts_dir, filename)
      source = File.read!(path)

      ~r/LOCKSPIRE_WALK_WORKAROUND:\s*(ADOPT-D\d+)/
      |> Regex.scan(source)
      |> Enum.map(fn [_full, id] -> id end)
    end)
    |> MapSet.new()
  end

  # A ledger entry's workaround field either names a real marker ID or says "none" -- only the
  # named-marker case contributes to the reconciliation set.
  defp ledger_workaround_ids(entries) do
    entries
    |> Enum.flat_map(fn {_id, fields} ->
      case fields[:workaround] do
        nil -> []
        value -> Regex.scan(~r/ADOPT-D\d+/, value) |> List.flatten()
      end
    end)
    |> MapSet.new()
  end

  # ---------------------------------------------------------------------------------------
  # Criterion 4: completeness
  # ---------------------------------------------------------------------------------------

  test "the ledger file exists and parses into at least one entry" do
    entries = ledger_body() |> parse_entries()

    assert entries != [],
           "Expected at least one ADOPT-Dnn entry in #{@ledger_path}, found none. " <>
             "An empty ledger is not a passing phase 126 outcome."
  end

  test "every entry carries an ADOPT-D ID plus all six D-37 fields, none blank" do
    entries = ledger_body() |> parse_entries()

    for {id, fields} <- entries do
      assert String.match?(id, ~r/^ADOPT-D\d+$/), "Malformed entry ID: #{inspect(id)}"

      for field <- Map.keys(@field_labels) do
        value = fields[field]

        refute is_nil(value) or value == "",
               "#{id} is missing required field #{inspect(field)} " <>
                 "(D-37 requires walk step ID, symptom, underlying error, source, owning " <>
                 "phase, and workaround on every entry)"
      end
    end
  end

  # A defect can genuinely have joint attribution (e.g. "installer and guide") when the
  # installer omits a step and the guide never documents the gap either -- each individual
  # token still has to be one of the six allowed values.
  defp source_tokens(source) do
    source
    |> String.split(~r/\s+and\s+|,/)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  test "every entry's source is one of the six allowed values (or a joint combination of them)" do
    entries = ledger_body() |> parse_entries()

    for {id, fields} <- entries do
      tokens = source_tokens(fields[:source])

      assert tokens != [], "#{id} has an empty source field"

      for token <- tokens do
        assert token in @allowed_sources,
               "#{id} has source token #{inspect(token)}, expected one of #{inspect(@allowed_sources)}"
      end
    end
  end

  test "every entry's owning phase is 127, 128, 129, 130, or an explicit future marker" do
    entries = ledger_body() |> parse_entries()

    for {id, fields} <- entries do
      owning_phase = fields[:owning_phase]

      matches_allowed? =
        Enum.any?(@allowed_owning_phases, fn allowed -> owning_phase =~ allowed end)

      assert matches_allowed?,
             "#{id} has owning phase #{inspect(owning_phase)}, expected it to mention one of " <>
               inspect(@allowed_owning_phases)
    end
  end

  # ---------------------------------------------------------------------------------------
  # Criterion 5: two-way marker <-> ledger reconciliation
  # ---------------------------------------------------------------------------------------

  test "every LOCKSPIRE_WALK_WORKAROUND marker under scripts/maintainer/ has a matching ledger entry" do
    entries = ledger_body() |> parse_entries()

    markers = marker_ids()
    ledgered = ledger_workaround_ids(entries)

    unmatched = MapSet.difference(markers, ledgered)

    assert MapSet.size(unmatched) == 0,
           "The following harness markers have no matching ledger workaround entry " <>
             "(a workaround left silently in the harness): #{inspect(MapSet.to_list(unmatched))}"
  end

  test "no ledger entry claims a workaround ID that no marker in scripts/maintainer/ backs" do
    entries = ledger_body() |> parse_entries()

    markers = marker_ids()
    ledgered = ledger_workaround_ids(entries)

    unmatched = MapSet.difference(ledgered, markers)

    assert MapSet.size(unmatched) == 0,
           "The following ledger workaround IDs have no matching harness marker " <>
             "(a phantom claim about the harness's state): #{inspect(MapSet.to_list(unmatched))}"
  end

  # ---------------------------------------------------------------------------------------
  # Secret absence
  # ---------------------------------------------------------------------------------------

  test "the ledger never quotes the seeded walk password" do
    refute ledger_body() =~ @seeded_password
  end

  test "the ledger never quotes a bearer-token-shaped string" do
    refute ledger_body() =~ ~r/Bearer\s+[A-Za-z0-9._-]{20,}/
  end

  # ---------------------------------------------------------------------------------------
  # Prohibited gates (D-40/D-41, 126-VALIDATION.md)
  # ---------------------------------------------------------------------------------------

  test "this test file never gates on the walk task's own outcome" do
    source = File.read!(Path.expand(__ENV__.file))

    # Built at runtime, not as a literal in this file's own source: the forbidden substring
    # (the walk task's mix-alias name) must never appear here even as a search pattern, or
    # this very assertion would trip the same acceptance criterion it enforces.
    forbidden = Enum.join(["adopter", "walk"], ".")

    refute source =~ forbidden
  end
end
