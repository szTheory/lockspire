defmodule Lockspire.Quality.Phase139PlanningConsistencyTest do
  use ExUnit.Case, async: true

  @phase_dir ".planning/phases/139-required-truth-reconciliation"

  @tag :phase139_gap_closure
  test "maintained Phase 139 records expose one lifecycle posture" do
    roadmap = File.read!(".planning/ROADMAP.md")
    requirements = File.read!(".planning/REQUIREMENTS.md")
    state = File.read!(".planning/STATE.md")
    verification = File.read!("#{@phase_dir}/139-VERIFICATION.md")
    validation = File.read!("#{@phase_dir}/139-VALIDATION.md")

    plans = tracked_phase_files("139-??-PLAN.md")
    summaries = Path.wildcard(Path.join(@phase_dir, "139-??-SUMMARY.md"))
    completed_numbers = Enum.map(summaries, &String.slice(Path.basename(&1), 4, 2))

    assert length(plans) == length(summaries)

    assert Enum.all?(
             1..length(plans),
             &(String.pad_leading(Integer.to_string(&1), 2, "0") in completed_numbers)
           )

    assert state =~ ~r/^Phase: 140 — Bounded Operational Loose-End Triage$/m
    assert state =~ "Phase 139 complete, ready to plan Phase 140"
    assert state =~ "Plan: Not started"
    assert roadmap =~ ~r/Phase 139.*#{length(summaries)}\/#{length(plans)}/s
    assert roadmap =~ "Phase 140: Bounded Operational Loose-End Triage"
    assert roadmap =~ "blocking Phase 140 `plan:pre` hook"

    assert validation_gap_ids(validation) ==
             Enum.map(1..11, &"G-139-#{String.pad_leading(Integer.to_string(&1), 2, "0")}")

    if verification =~ ~r/^status:\s*gaps_found$/m do
      assert state =~ ~r/139.*gap|gap.*139/i

      refute requirements =~
               ~r/^\| (?:CI-06|CI-07|QUAL-05|HYGIENE-05|HYGIENE-06|TRUTH-03|TRUTH-04|TRUTH-05) \| Phase 139 \| Complete \|$/m
    end

    assert roadmap =~ ~r/v1\.37|1\.5\.0/
    refute roadmap =~ ~r/v1\.38.*(?:released|shipped)/i
  end

  test "all completed-plan prohibitions have tracked executable owners" do
    validation = File.read!("#{@phase_dir}/139-VALIDATION.md")
    table = prohibition_rows(validation)

    statements =
      Enum.flat_map(1..length(tracked_phase_files("139-??-PLAN.md")), fn number ->
        path =
          Path.join(
            @phase_dir,
            "139-#{String.pad_leading(Integer.to_string(number), 2, "0")}-PLAN.md"
          )

        source = File.read!(path)

        Regex.scan(~r/^\s*- statement: "(.+)"$/m, source, capture: :all_but_first)
        |> Enum.map(fn [statement] -> statement end)
      end)

    assert length(statements) == 19
    assert length(table) == 19
    assert Enum.sort(Enum.map(table, & &1.statement)) == Enum.sort(statements)
    assert Enum.all?(table, &(&1.status == "ENFORCED"))
    assert Enum.all?(table, &owner_is_executable?/1)
    assert validation =~ "**Unresolved:** 0"
    refute Enum.any?(table, &(&1.status == "flagged-unverified"))
  end

  defp tracked_phase_files(pattern) do
    @phase_dir
    |> Path.join(pattern)
    |> Path.wildcard()
    |> Enum.filter(fn path ->
      {_, 0} = System.cmd("git", ["ls-files", "--error-unmatch", path], stderr_to_stdout: true)
      true
    end)
    |> Enum.sort()
  end

  defp validation_gap_ids(validation) do
    Regex.scan(~r/^\| (G-139-\d{2}) \|/m, validation, capture: :all_but_first)
    |> List.flatten()
  end

  defp prohibition_rows(validation) do
    validation
    |> String.split("## Prohibition Enforcement", parts: 2)
    |> List.last()
    |> String.split("\n", trim: true)
    |> Enum.flat_map(fn line ->
      case Regex.run(~r/^\| "(.+)" \| `([^`]+)` \| `([^`]+)` \| (ENFORCED|UNRESOLVED) \|$/, line) do
        [_, statement, path, entry, status] ->
          [%{statement: statement, path: path, entry: entry, status: status}]

        _ ->
          []
      end
    end)
  end

  defp owner_is_executable?(%{path: path, entry: entry}) do
    with {_, 0} <-
           System.cmd("git", ["ls-files", "--error-unmatch", path], stderr_to_stdout: true),
         {:ok, source} <- File.read(path) do
      String.contains?(source, entry)
    else
      _ -> false
    end
  end
end
