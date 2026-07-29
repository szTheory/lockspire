defmodule Lockspire.Maintainer.AdopterWalkBaselineContractTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Four static invariants binding scripts/maintainer/adopter_walk_baseline.json to the Phase
  126 defect ledger and to the walk harness's own `record_result` call sites, none requiring a
  run:

  1. Every baseline `defect` value resolves to a real `### ADOPT-Dnn` heading in the ledger --
     no phantom IDs.
  2. Every `record_result "FAIL"` call site (in the shell harness) or `[FAIL]` line (in the
     flow driver) whose detail names an `ADOPT-D\\d+` has a matching baseline row with that
     `step_id` and `defect`, and conversely every baseline `defect` is attributable to such a
     call site or driver line.
  3. Every row with `level: "FAIL"` and `defect: null` carries a non-empty `why`.
  4. The baseline file contains no `LOCKSPIRE_WALK_WORKAROUND` literal -- load-bearing, because
     `defect_ledger_contract_test.exs` harvests markers from every non-directory file under
     `scripts/maintainer/`, so a marker pasted into a `why` would inject a phantom ledger ID and
     fail an unrelated test with a baffling message.

  This file is intentionally new rather than an extension of `defect_ledger_contract_test.exs`,
  so that file's own self-refutation of the literal `"adopter.walk"` (D-40/D-41) stays
  untouched.
  """

  @repo_root Path.expand("../../..", __DIR__)
  @baseline_path Path.join(@repo_root, "scripts/maintainer/adopter_walk_baseline.json")
  @ledger_path Path.join(
                 @repo_root,
                 ".planning/phases/126-adopter-path-walk-defect-ledger/126-DEFECT-LEDGER.md"
               )
  @walk_script_path Path.join(@repo_root, "scripts/maintainer/adopter_path_walk.sh")
  @flow_driver_path Path.join(@repo_root, "scripts/maintainer/adopter_path_flow.py")

  # ---------------------------------------------------------------------------------------
  # Parsing
  # ---------------------------------------------------------------------------------------

  defp baseline do
    unless File.regular?(@baseline_path) do
      flunk("Missing committed baseline at #{@baseline_path}.")
    end

    @baseline_path
    |> File.read!()
    |> Jason.decode!()
  end

  defp ledger_defect_ids do
    unless File.regular?(@ledger_path) do
      flunk("Missing committed defect ledger at #{@ledger_path}.")
    end

    ~r/^###\s+(ADOPT-D\d+)\s*$/m
    |> Regex.scan(File.read!(@ledger_path), capture: :all_but_first)
    |> List.flatten()
    |> MapSet.new()
  end

  # Reuses shell_steps/1's regex shape (adopter_walk_contract_test.exs:150-154) narrowed to
  # only "FAIL" calls, and additionally extracts every ADOPT-D\d+ token from each FAIL call's
  # own detail text. A step can have zero, one, or several defect tokens across its FAIL call
  # sites; every (step_id, defect) pair found is a real static fact about the harness's source,
  # independent of whether the branch is reachable in any given run.
  #
  # Several `run_step_*` functions (03c-resolver, 03d-app-tree, 03e-protected-route) hold their
  # own step ID in a `local step_id="step-..."` variable and pass `"$step_id"` to every
  # `record_result` call rather than repeating the literal string -- a plain regex over the
  # quoted literal alone would silently miss every FAIL call site inside those functions. This
  # resolves `"$step_id"` to the nearest preceding `local step_id="..."` assignment by source
  # position, which is well-defined here because each of those functions defines the variable
  # exactly once, near its own top, and none of these functions overlap in the source text.
  defp assignment_positions(source) do
    ~r/local\s+step_id="(step-[a-zA-Z0-9_() -]+)"/
    |> Regex.scan(source, return: :index)
    |> Enum.map(fn [_full, {value_start, value_len}] ->
      {value_start, binary_part(source, value_start, value_len)}
    end)
  end

  defp fail_call_positions(source) do
    ~r/record_result\s+"FAIL"\s+"(?:(step-[a-zA-Z0-9_() -]+)|\$step_id)"\s+"((?:[^"\\]|\\.)*)"/
    |> Regex.scan(source, return: :index)
    |> Enum.map(fn [{full_start, _full_len}, literal_range, {detail_start, detail_len}] ->
      literal =
        case literal_range do
          {-1, 0} -> nil
          {literal_start, literal_len} -> binary_part(source, literal_start, literal_len)
        end

      {full_start, literal, binary_part(source, detail_start, detail_len)}
    end)
  end

  defp resolve_step_id(position, assignments) do
    assignments
    |> Enum.filter(fn {assignment_position, _value} -> assignment_position < position end)
    |> case do
      [] -> nil
      candidates -> candidates |> Enum.max_by(fn {pos, _value} -> pos end) |> elem(1)
    end
  end

  defp shell_fail_defect_pairs(source) do
    assignments = assignment_positions(source)

    source
    |> fail_call_positions()
    |> Enum.flat_map(fn {position, literal, detail} ->
      step_id = literal || resolve_step_id(position, assignments)

      ~r/ADOPT-D\d+/
      |> Regex.scan(detail)
      |> List.flatten()
      |> Enum.map(&{step_id, &1})
    end)
    |> Enum.uniq()
  end

  # Same shape, for the flow driver's own `record(f"[FAIL] step-...: ...")` lines -- these
  # always use a literal step ID, never a variable.
  defp driver_fail_defect_pairs(source) do
    ~r/\[FAIL\]\s+(step-[0-9]{2}[a-z]?-[a-zA-Z0-9_() -]+?):\s*([^\n"]*)/
    |> Regex.scan(source, capture: :all_but_first)
    |> Enum.flat_map(fn [step_id, detail] ->
      ~r/ADOPT-D\d+/
      |> Regex.scan(detail)
      |> List.flatten()
      |> Enum.map(&{step_id, &1})
    end)
    |> Enum.uniq()
  end

  defp source_fail_defect_pairs do
    shell_source = File.read!(@walk_script_path)

    driver_source =
      if File.regular?(@flow_driver_path) do
        File.read!(@flow_driver_path)
      else
        ""
      end

    (shell_fail_defect_pairs(shell_source) ++ driver_fail_defect_pairs(driver_source))
    |> Enum.uniq()
  end

  defp baseline_defect_pairs(rows) do
    rows
    |> Enum.filter(&(&1["defect"] not in [nil, ""]))
    |> Enum.map(&{&1["step_id"], &1["defect"]})
    |> Enum.uniq()
  end

  # ---------------------------------------------------------------------------------------
  # Invariant 1: every baseline defect resolves to a real ledger heading
  # ---------------------------------------------------------------------------------------

  test "every baseline defect value resolves to a real ADOPT-Dnn heading in the ledger" do
    %{"rows" => rows} = baseline()
    ledgered = ledger_defect_ids()

    for row <- rows, defect = row["defect"], defect not in [nil, ""] do
      assert defect in ledgered,
             "baseline row #{inspect(row["step_id"])} occurrence #{row["occurrence"]} " <>
               "claims #{inspect(defect)}, which has no '### #{defect}' heading in the ledger"
    end
  end

  # ---------------------------------------------------------------------------------------
  # Invariant 2: baseline defects <-> record_result/driver FAIL call sites, two-way
  # ---------------------------------------------------------------------------------------

  test "every FAIL call site naming an ADOPT-Dnn has a matching baseline row, and every baseline defect is attributable to one" do
    %{"rows" => rows} = baseline()

    source_pairs = MapSet.new(source_fail_defect_pairs())
    baseline_pairs = MapSet.new(baseline_defect_pairs(rows))

    missing_from_baseline = MapSet.difference(source_pairs, baseline_pairs)

    assert MapSet.size(missing_from_baseline) == 0,
           "the following (step_id, defect) pairs appear in a record_result \"FAIL\"/[FAIL] " <>
             "call site but have no matching baseline row: " <>
             inspect(MapSet.to_list(missing_from_baseline))

    phantom_in_baseline = MapSet.difference(baseline_pairs, source_pairs)

    assert MapSet.size(phantom_in_baseline) == 0,
           "the following baseline (step_id, defect) pairs are not attributable to any " <>
             "record_result \"FAIL\"/[FAIL] call site: " <>
             inspect(MapSet.to_list(phantom_in_baseline))
  end

  # ---------------------------------------------------------------------------------------
  # Invariant 3: every FAIL row with no defect carries a non-empty why
  # ---------------------------------------------------------------------------------------

  test "every FAIL row with defect: null carries a non-empty why" do
    %{"rows" => rows} = baseline()

    for row <- rows,
        row["level"] == "FAIL",
        row["defect"] in [nil, ""] do
      why = row["why"]

      refute is_nil(why) or why == "",
             "baseline row #{inspect(row["step_id"])} occurrence #{row["occurrence"]} is a " <>
               "FAIL with no defect and no why -- an unattributed FAIL row is unexplained by " <>
               "design here"
    end
  end

  # ---------------------------------------------------------------------------------------
  # Invariant 4: no LOCKSPIRE_WALK_WORKAROUND literal in the baseline
  # ---------------------------------------------------------------------------------------

  test "the baseline file contains no LOCKSPIRE_WALK_WORKAROUND literal" do
    refute File.read!(@baseline_path) =~ "LOCKSPIRE_WALK_WORKAROUND"
  end

  # ---------------------------------------------------------------------------------------
  # Structural sanity: authored_before_run and expected counts agree with the rows
  # ---------------------------------------------------------------------------------------

  test "the baseline is authored before any run, with expected counts matching its own rows" do
    %{
      "authored_before_run" => authored_before_run,
      "confirmed_by_run" => confirmed_by_run,
      "expected_pass_count" => expected_pass_count,
      "expected_fail_count" => expected_fail_count,
      "rows" => rows
    } = baseline()

    # `authored_before_run` is the load-bearing claim: the expectation was written down
    # before a run could influence it, so a run can refute it. `confirmed_by_run` records
    # which run subsequently agreed -- nil until one has, an ISO 8601 UTC stamp after.
    # Pinning it to nil forever would make a confirmed baseline unrepresentable.
    assert authored_before_run == true

    assert is_nil(confirmed_by_run) or
             confirmed_by_run =~ ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/

    assert expected_pass_count == Enum.count(rows, &(&1["level"] == "PASS"))
    assert expected_fail_count == Enum.count(rows, &(&1["level"] == "FAIL"))
  end
end
