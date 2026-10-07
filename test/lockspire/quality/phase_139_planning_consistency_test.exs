defmodule Lockspire.Quality.Phase139PlanningConsistencyTest do
  use ExUnit.Case, async: true

  @phase_dir ".planning/milestones/v1.38-phases/139-required-truth-reconciliation"
  @phase_141_dir ".planning/milestones/v1.38-phases/141-maintenance-baseline-closure"

  @tag :phase139_gap_closure
  test "maintained Phase 139 records expose one lifecycle posture across gap closure and historical completion" do
    roadmap = File.read!(".planning/milestones/v1.38-ROADMAP.md")
    state = File.read!(".planning/STATE.md")
    milestones = File.read!(".planning/MILESTONES.md")
    verification = File.read!("#{@phase_dir}/139-VERIFICATION.md")
    validation = File.read!("#{@phase_dir}/139-VALIDATION.md")
    baseline = File.read!(Path.join(@phase_141_dir, "141-BASELINE.md"))

    phase_141_summary = File.read!(Path.join(@phase_141_dir, "141-01-SUMMARY.md"))

    release_train = File.read!(".planning/RELEASE-TRAIN.md")

    plans = tracked_phase_files("139-??-PLAN.md")
    summaries = Path.wildcard(Path.join(@phase_dir, "139-??-SUMMARY.md"))
    plan_numbers = Enum.map(plans, &phase_number/1) |> Enum.sort()
    summary_numbers = Enum.map(summaries, &phase_number/1) |> Enum.sort()
    phase_139_roadmap = roadmap_section(roadmap, "Phase 139", "Phase 140")

    assert plan_numbers == Enum.to_list(1..length(plans))
    assert roadmap_plan_counts(phase_139_roadmap) == [length(summaries), length(plans)]
    assert Enum.all?(summary_numbers, &(&1 in plan_numbers))

    unsummarized_numbers = plan_numbers -- summary_numbers

    assert Enum.all?(unsummarized_numbers, fn number ->
             plan = File.read!(phase_plan_path(number))
             plan_frontmatter_gap_closure?(plan)
           end)

    for number <- 1..13 do
      assert phase_plan_tracked?(number)
      assert File.regular?(phase_summary_path(number))
    end

    assert roadmap =~ "### Phase 140: Bounded Operational Loose-End Triage"
    assert roadmap =~ "**Plans**: 18/18 plans complete with summaries."
    assert roadmap =~ "### Phase 141: Maintenance-Baseline Closure"
    assert roadmap =~ "**Plans**: 1/1 plan complete"

    assert roadmap =~
             "| 140. Bounded Operational Loose-End Triage | 18/18 | Complete | 2026-10-05 |"

    assert roadmap =~ "| 141. Maintenance-Baseline Closure | 1/1 | Complete"

    assert state =~ "milestone: v1.39"
    assert state =~ "current_phase: 143"
    assert state =~ "The 1.5.0 publication chain remains the latest public release."
    assert milestones =~ "**Phases completed:** **4** (**138-141**), **73** plans"
    assert milestones =~ "This is planning completion only; it did not publish a package."

    assert baseline =~ "accepts source tree `877a0f758aa0bbd5433cbe3d70f1476fa0e12223`"

    assert phase_141_summary =~
             "receipt proves only accepted source SHA `877a0f758aa0bbd5433cbe3d70f1476fa0e12223`; it does not prove the Task 1 baseline commit or the Task 3 reconciliation commit."

    assert release_train =~ "Release Please version metadata: `1.5.1`"
    assert release_train =~ "Latest public package: Hex lists `1.5.0`"
    refute release_train =~ ~r/1\.5\.1.*(?:published|released)/i

    assert validation_gap_ids(validation) ==
             Enum.map(1..11, &"G-139-#{String.pad_leading(Integer.to_string(&1), 2, "0")}")

    assert verification =~ ~r/^status:\s*gaps_found$/m
    assert baseline =~ "`latest_version` and `latest_stable_version` both `1.5.0`"
  end

  test "all completed-plan prohibitions have tracked executable owners" do
    validation = File.read!("#{@phase_dir}/139-VALIDATION.md")
    table = prohibition_rows(validation)

    statements =
      Enum.flat_map(1..13, fn number ->
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

  defp phase_number(path) do
    path
    |> Path.basename()
    |> String.slice(4, 2)
    |> String.to_integer()
  end

  defp phase_plan_path(number),
    do:
      Path.join(
        @phase_dir,
        "139-#{String.pad_leading(Integer.to_string(number), 2, "0")}-PLAN.md"
      )

  defp phase_summary_path(number),
    do:
      Path.join(
        @phase_dir,
        "139-#{String.pad_leading(Integer.to_string(number), 2, "0")}-SUMMARY.md"
      )

  defp phase_plan_tracked?(number) do
    case System.cmd("git", ["ls-files", "--error-unmatch", phase_plan_path(number)],
           stderr_to_stdout: true
         ) do
      {_, 0} -> true
      _ -> false
    end
  end

  defp plan_frontmatter_gap_closure?(source) do
    case Regex.run(~r/\A---\s*\n(.*?)\n---/s, source, capture: :all_but_first) do
      [frontmatter] -> Regex.match?(~r/^gap_closure:\s*true\s*$/m, frontmatter)
      _ -> false
    end
  end

  defp roadmap_section(roadmap, start_heading, next_heading) do
    [[section]] =
      Regex.scan(
        Regex.compile!(
          "(^### #{Regex.escape(start_heading)}:.*?)(?=^### #{Regex.escape(next_heading)}:)",
          "ms"
        ),
        roadmap,
        capture: :all_but_first
      )

    section
  end

  defp roadmap_plan_counts(section) do
    [[executed, total]] =
      Regex.scan(~r/^\*\*Plans\*\*: (\d+)\/(\d+)/m, section, capture: :all_but_first)

    Enum.map([executed, total], &String.to_integer/1)
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
