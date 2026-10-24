defmodule Lockspire.QualificationLedgerContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @phase_dir Path.join(@repo_root, ".planning/phases/171-accepted-baseline-finding-qualification")
  @ledger_path Path.join(@phase_dir, "171-QUALIFICATION.json")
  @downstream_requirement_ids [
    "AUTHR-01",
    "AUTHR-02",
    "AUTHR-03",
    "PARB-01",
    "PARB-02",
    "PARB-03"
  ]

  test "the phase qualification ledger exists and its evidence references resolve" do
    assert File.exists?(@ledger_path),
           "qualification ledger is required; missing ledger cannot be skipped"

    assert validate(load_ledger()) == []
  end

  test "the contract rejects missing or mismatched accepted-base identity" do
    ledger = load_ledger()
    assert_rejected(update_in(ledger, ["baseline", "implementation_base"], fn _ -> nil end))

    assert_rejected(
      update_in(ledger, ["baseline", "implementation_base"], fn _ ->
        "a" <> String.duplicate("0", 39)
      end)
    )
  end

  test "the contract rejects missing, empty, or nonpassing required gate evidence" do
    ledger = load_ledger()
    receipt = load_receipt(ledger)
    assert_rejected(ledger, Map.delete(receipt, "required_ci"))
    assert_rejected(ledger, Map.delete(receipt, "release_no_publish"))
    assert_rejected(ledger, put_in(receipt, ["required_ci", "status"], ""))
    assert_rejected(ledger, put_in(receipt, ["required_ci", "status"], "fail"))
    assert_rejected(ledger, put_in(receipt, ["release_no_publish", "status"], ""))
    assert_rejected(ledger, put_in(receipt, ["release_no_publish", "status"], "fail"))
  end

  test "the contract rejects a zero local test count and incomplete warning dispositions" do
    ledger = load_ledger()
    receipt = load_receipt(ledger)
    assert_rejected(ledger, put_in(receipt, ["local_gate", "exunit_tests"], 0))
    assert_rejected(ledger, put_in(receipt, ["warn_dispositions"], []))
  end

  test "the contract rejects duplicate, orphaned, and unsorted case or matrix IDs" do
    ledger = load_ledger()
    [item | _] = ledger["cases"]
    assert_rejected(%{ledger | "cases" => [item, item]})
    assert_rejected(put_in(ledger, ["matrix", "rows", Access.at(0), "case_id"], "orphan"))
    assert_rejected(%{ledger | "cases" => Enum.reverse(ledger["cases"])})
    assert_rejected(put_in(ledger, ["matrix", "rows"], Enum.reverse(ledger["matrix"]["rows"])))

    assert_rejected(
      put_in(
        ledger,
        ["matrix", "requirement_dispositions", Access.at(0), "requirement_id"],
        "ORPHAN"
      )
    )
  end

  test "a draft matrix requires all downstream dispositions and case-backed expected outcomes" do
    ledger = load_ledger()
    assert validate(ledger) == []

    assert Enum.map(ledger["matrix"]["requirement_dispositions"], & &1["requirement_id"]) ==
             @downstream_requirement_ids

    assert_rejected(
      put_in(
        ledger,
        ["matrix", "requirement_dispositions"],
        Enum.drop(ledger["matrix"]["requirement_dispositions"], -1)
      )
    )

    assert_rejected(
      update_in(ledger, ["cases", Access.at(0), "expected_outcome"], fn _ -> nil end)
    )

    assert_rejected(
      update_in(ledger, ["cases", Access.at(0), "regression_owner"], fn _ -> nil end)
    )
  end

  test "only a proved current counterexample may retain a correction" do
    ledger = load_ledger()
    correction_index = Enum.find_index(ledger["matrix"]["rows"], &(&1["case_id"] == "A171-003"))

    assert_rejected(
      put_in(
        ledger,
        ["matrix", "rows", Access.at(correction_index), "disposition"],
        "retain_proof"
      )
    )

    no_failure =
      ledger
      |> put_in(["cases", Access.at(2), "repro", "status"], "pass")
      |> put_in(["cases", Access.at(2), "repro", "failure_count"], 0)

    assert_rejected(no_failure)
  end

  test "blocked rows cannot be presented as ready" do
    ledger = load_ledger()
    index = Enum.find_index(ledger["matrix"]["rows"], &(&1["case_id"] == "P171-006"))

    blocked_but_ready =
      ledger
      |> put_in(["matrix", "rows", Access.at(index), "disposition"], "blocked")
      |> put_in(
        ["matrix", "rows", Access.at(index), "blocking_reason"],
        "Synthetic unresolved proof"
      )

    assert_rejected(blocked_but_ready)
  end

  test "null case and matrix collections are rejected" do
    ledger = load_ledger()
    assert_rejected(%{ledger | "cases" => nil})
    assert_rejected(put_in(ledger, ["matrix", "rows"], nil))
  end

  test "source and input identities and all three case owners are required" do
    ledger = load_ledger()

    assert_rejected(
      update_in(ledger, ["cases", Access.at(0), "source", "source_sha"], fn _ -> nil end)
    )

    assert_rejected(
      update_in(ledger, ["cases", Access.at(0), "input_identity", "request"], fn _ -> "" end)
    )

    assert_rejected(update_in(ledger, ["cases", Access.at(0), "next_owner"], fn _ -> "" end))
    assert_rejected(update_in(ledger, ["cases", Access.at(0), "repro_owner"], fn _ -> nil end))

    assert_rejected(
      update_in(ledger, ["cases", Access.at(0), "regression_owner"], fn _ -> nil end)
    )
  end

  test "an empty selected inventory is valid only with explicit exclusions and replan rationale" do
    ledger = load_ledger()

    empty =
      ledger
      |> draft_matrix("empty_requires_replan")
      |> Map.put("cases", [])
      |> Map.put("selection_status", "empty_requires_replan")
      |> put_in(["matrix", "rows"], [])
      |> put_in(["scope_revision", "required"], true)
      |> put_in(
        ["scope_revision", "rationale"],
        "Synthetic empty fixture requires an explicit scope review."
      )
      |> put_in(["matrix", "replan_required"], true)
      |> put_in(
        ["matrix", "requirement_dispositions"],
        Enum.map(@downstream_requirement_ids, fn id ->
          %{
            "requirement_id" => id,
            "disposition" => "revise",
            "case_ids" => [],
            "existing_proof" => [],
            "retained_cases" => [],
            "rationale" => "Synthetic explicit empty-scope replan.",
            "amendment_ref" => "REQUIREMENTS.md and ROADMAP.md synthetic fixture"
          }
        end)
      )
      |> update_in(["category_coverage"], fn categories ->
        Enum.map(categories, &%{&1 | "case_ids" => [], "status" => "excluded_fixture"})
      end)

    assert validate(empty) == []
    assert_rejected(put_in(empty, ["scope_revision", "rationale"], nil))
    assert_rejected(%{empty | "selection_status" => "draft"})
    assert_rejected(put_in(empty, ["scope_revision", "required"], false))
    assert_rejected(put_in(empty, ["matrix", "replan_required"], false))
  end

  test "a frozen empty inventory requires real requirement and roadmap amendments" do
    ledger = load_ledger()

    empty =
      ledger
      |> Map.put("cases", [])
      |> Map.put("selection_status", "empty_requires_replan")
      |> put_in(["matrix", "rows"], [])
      |> put_in(["scope_revision", "required"], true)
      |> put_in(["scope_revision", "rationale"], "No correction survives qualification.")
      |> put_in(["matrix", "replan_required"], true)
      |> put_in(
        ["matrix", "requirement_dispositions"],
        Enum.map(@downstream_requirement_ids, fn id ->
          %{
            "requirement_id" => id,
            "disposition" => "revise",
            "case_ids" => [],
            "existing_proof" => [],
            "retained_cases" => [],
            "rationale" => "The case inventory is empty and the downstream scope is revised.",
            "amendment_ref" => "REQUIREMENTS.md and ROADMAP.md"
          }
        end)
      )
      |> put_in(["matrix", "amendments"], [
        %{
          "file" => ".planning/REQUIREMENTS.md",
          "anchor" => "qualification-driven scope",
          "reason" => "Revise empty scope."
        },
        %{
          "file" => ".planning/ROADMAP.md",
          "anchor" => "phases 172-173",
          "reason" => "Revise empty scope."
        }
      ])
      |> update_in(["category_coverage"], fn categories ->
        Enum.map(categories, &%{&1 | "case_ids" => [], "status" => "excluded_fixture"})
      end)

    empty =
      empty
      |> put_in(["matrix", "status"], "frozen")
      |> put_in(["selection_status"], "frozen")
      |> put_in(["matrix", "frozen_at"], "2026-10-24T20:49:46Z")
      |> put_in(["matrix", "qualification_sha"], "6d9a5db65f8cc3cb8c64ea0dd51ad022a6b18945")
      |> put_in(["matrix", "blocking_entries"], [])
      |> put_in(["blockers"], [])

    empty = put_in(empty, ["matrix", "input_manifest"], frozen_empty_manifest(empty))

    empty =
      put_in(
        empty,
        ["matrix", "input_digest"],
        manifest_digest(empty["matrix"]["input_manifest"])
      )

    assert validate(empty) == []
    assert_rejected(put_in(empty, ["matrix", "amendments"], []))

    assert_rejected(
      put_in(
        empty,
        ["matrix", "requirement_dispositions", Access.at(0), "disposition"],
        "reuse_existing"
      )
    )
  end

  test "a frozen matrix rejects drifted inputs, retained blockers, and omitted requirements" do
    ledger = load_ledger()
    assert validate(ledger) == []

    assert_rejected(
      put_in(
        ledger,
        ["matrix", "input_manifest", Access.at(0), "sha256"],
        String.duplicate("0", 64)
      )
    )

    assert_rejected(put_in(ledger, ["matrix", "blocking_entries"], ["unresolved input"]))

    assert_rejected(
      put_in(
        ledger,
        ["matrix", "requirement_dispositions"],
        Enum.drop(ledger["matrix"]["requirement_dispositions"], -1)
      )
    )
  end

  test "a valid single case and matrix row remain admissible" do
    ledger = load_ledger()
    [item | _] = ledger["cases"]

    single =
      ledger
      |> draft_matrix("selected")
      |> Map.put("cases", [item])
      |> Map.put("selection_status", "selected")
      |> put_in(["matrix", "rows"], [
        Enum.find(ledger["matrix"]["rows"], &(&1["case_id"] == item["id"]))
      ])
      |> update_in(["category_coverage"], fn categories ->
        Enum.map(categories, fn category ->
          ids = Enum.filter(category["case_ids"], &(&1 == item["id"]))

          %{
            category
            | "case_ids" => ids,
              "status" => if(ids == [], do: "excluded_fixture", else: "enumerated")
          }
        end)
      end)
      |> update_in(["cases"], fn cases ->
        Enum.map(cases, fn case_item ->
          if case_item["id"] == item["id"],
            do: %{case_item | "requirement_ids" => ["FIND-01" | @downstream_requirement_ids]},
            else: case_item
        end)
      end)
      |> put_in(
        ["matrix", "requirement_dispositions"],
        Enum.map(@downstream_requirement_ids, fn id ->
          %{
            "requirement_id" => id,
            "disposition" => "reuse_existing",
            "case_ids" => [item["id"]],
            "existing_proof" => [item["id"]],
            "retained_cases" => [],
            "rationale" => "Synthetic single-case evidence fixture."
          }
        end)
      )
      |> update_in(["matrix", "rows"], fn rows ->
        [row] = rows
        [%{row | "requirement_ids" => ["FIND-01" | @downstream_requirement_ids]}]
      end)

    assert validate(single) == []
  end

  test "equal outcomes and classifications preserve distinct conditions and owners" do
    ledger = load_ledger()
    [first, second | _] = ledger["cases"]

    same_outcomes =
      second
      |> Map.put("observed_outcome", first["observed_outcome"])
      |> Map.put("expected_outcome", first["expected_outcome"])
      |> Map.put("cause", first["cause"])
      |> Map.put("condition_id", "different-condition")
      |> update_in(["observations", Access.at(0), "condition_id"], fn _ ->
        "different-condition"
      end)

    pair =
      ledger
      |> draft_matrix("selected")
      |> Map.put("cases", [first, same_outcomes])
      |> Map.put("selection_status", "selected")
      |> put_in(["matrix", "rows"], Enum.take(ledger["matrix"]["rows"], 2))
      |> update_in(["category_coverage"], fn categories ->
        Enum.map(categories, fn category ->
          ids = Enum.filter(category["case_ids"], &(&1 in [first["id"], same_outcomes["id"]]))

          %{
            category
            | "case_ids" => ids,
              "status" => if(ids == [], do: "excluded_fixture", else: "enumerated")
          }
        end)
      end)
      |> update_in(["cases"], fn cases ->
        Enum.map(cases, fn case_item ->
          if case_item["id"] in [first["id"], same_outcomes["id"]],
            do: %{case_item | "requirement_ids" => ["FIND-01" | @downstream_requirement_ids]},
            else: case_item
        end)
      end)
      |> put_in(
        ["matrix", "requirement_dispositions"],
        Enum.map(@downstream_requirement_ids, fn id ->
          %{
            "requirement_id" => id,
            "disposition" => "reuse_existing",
            "case_ids" => [first["id"], same_outcomes["id"]],
            "existing_proof" => [first["id"], same_outcomes["id"]],
            "retained_cases" => [],
            "rationale" => "Synthetic equal-outcome identity fixture."
          }
        end)
      )
      |> update_in(["matrix", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          %{
            row
            | "classification" => first["cause"],
              "requirement_ids" => ["FIND-01" | @downstream_requirement_ids]
          }
        end)
      end)

    assert validate(pair) == []
    assert first["id"] != same_outcomes["id"]
    assert first["next_owner"] != ""
    assert same_outcomes["next_owner"] != ""
  end

  test "repeat observations attach to one stable case when the condition is identical" do
    ledger = load_ledger()

    repeated =
      update_in(ledger, ["cases", Access.at(0), "observations"], fn observations ->
        [
          hd(observations),
          %{hd(observations) | "observation_id" => "A171-001-20261025-02", "date" => "2026-10-25"}
        ]
      end)
      |> draft_matrix("selected")

    assert validate(repeated) == []
    assert get_in(repeated, ["cases", Access.at(0), "id"]) == "A171-001"
  end

  test "qualified counterexamples stay distinct and interrupted or suite-level results cannot prove a case" do
    ledger = load_ledger()
    assert get_in(ledger, ["cases", Access.at(2), "cause"]) == "protocol"
    assert get_in(ledger, ["cases", Access.at(2), "repro", "status"]) == "counterexample"

    interrupted =
      ledger
      |> put_in(["cases", Access.at(0), "repro", "status"], "interrupted")
      |> put_in(["cases", Access.at(0), "repro", "result"], "interrupted")

    assert_rejected(interrupted)

    external =
      put_in(ledger, ["cases", Access.at(0), "repro", "evidence_kind"], "external_suite_run")

    assert_rejected(external)
  end

  test "controlled protocol counterexamples require the named final assertion and passing controls" do
    ledger = load_ledger()
    index = Enum.find_index(ledger["cases"], &(&1["id"] == "A171-003"))
    repro_path = ["cases", Access.at(index), "repro"]

    assert get_in(ledger, repro_path ++ ["status"]) == "counterexample"
    assert validate(ledger) == []

    assert_rejected(put_in(ledger, repro_path ++ ["controls_passed"], false))
    assert_rejected(put_in(ledger, repro_path ++ ["assertion_id"], nil))
    assert_rejected(put_in(ledger, repro_path ++ ["observed_projection"], %{}))
    assert_rejected(put_in(ledger, repro_path ++ ["probe_observation_id"], "missing"))

    falsely_passed =
      ledger
      |> put_in(repro_path ++ ["status"], "pass")
      |> put_in(repro_path ++ ["failure_count"], 0)

    assert_rejected(falsely_passed)
  end

  test "profile unavailability does not fabricate wrapper or receipt outcomes" do
    ledger = load_ledger()
    assert length(ledger["profiles"]) == 2

    for profile <- ledger["profiles"] do
      assert profile["status"] == "unavailable"
      assert profile["profile_attempt"]["started"] == false
      assert profile["profile_attempt"]["exit_code"] == nil
      assert profile["profile_attempt"]["result_classification"] == nil
      assert profile["artifact_output"]["receipt_path"] == nil
      assert profile["artifact_output"]["receipt_sha256"] == nil
      assert profile["next_owner"] != ""
    end

    fabricated =
      put_in(
        ledger,
        ["profiles", Access.at(0), "profile_attempt", "result_classification"],
        "suite_failure"
      )

    assert_rejected(fabricated)
  end

  defp load_ledger, do: @ledger_path |> File.read!() |> Jason.decode!()

  defp draft_matrix(ledger, selection_status) do
    ledger
    |> put_in(["selection_status"], selection_status)
    |> put_in(["matrix", "status"], "draft")
  end

  @ledger_relative_path ".planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json"

  defp frozen_empty_manifest(ledger) do
    [
      {@ledger_relative_path, "matrix-selection"},
      {@ledger_relative_path, "cases"},
      {".planning/REQUIREMENTS.md", "qualification-scope-map"},
      {".planning/ROADMAP.md", "phases-172-173-contract"}
    ]
    |> Enum.map(fn {path, selector} ->
      entry = %{"path" => path, "selector" => selector}
      Map.put(entry, "sha256", input_entry_hash(ledger, entry))
    end)
  end

  defp manifest_digest(manifest) do
    payload = Enum.map_join(manifest, "", &(manifest_identity(&1) <> " " <> &1["sha256"] <> "\n"))
    sha256(payload)
  end

  defp load_receipt(ledger) do
    ledger["baseline"]["receipt_ref"]
    |> then(&Path.join(@repo_root, &1))
    |> File.read!()
    |> Jason.decode!()
  end

  defp assert_rejected(ledger, receipt_override \\ nil),
    do: assert(validate(ledger, receipt_override) != [])

  defp validate(ledger, receipt_override \\ nil) do
    baseline = Map.get(ledger, "baseline", %{})
    cases = Map.get(ledger, "cases")
    rows = get_in(ledger, ["matrix", "rows"])
    receipt_path = Path.join(@repo_root, baseline["receipt_ref"] || "")

    []
    |> require(ledger["schema_version"] == 1, "schema_version must be 1")
    |> require(ledger["phase"] == 171, "phase must be 171")
    |> require(
      ledger["selection_status"] in ["draft", "selected", "empty_requires_replan", "frozen"],
      "selection_status is invalid"
    )
    |> require(
      is_list(ledger["profiles"]) and length(ledger["profiles"]) == 2,
      "both profile observations are required"
    )
    |> require(is_list(cases), "cases must be an array, not null")
    |> require(is_map(ledger["matrix"]), "matrix must be an object")
    |> require(ledger["matrix"]["status"] in ["draft", "frozen"], "matrix status is invalid")
    |> require(is_list(rows), "matrix rows must be an array, not null")
    |> require(
      is_list(ledger["matrix"]["requirement_dispositions"]),
      "requirement dispositions must be an array"
    )
    |> require(is_list(ledger["blockers"]), "blockers must be an array")
    |> require(is_list(ledger["exclusions"]), "exclusions must be an array")
    |> validate_selection_state(ledger, cases)
    |> validate_baseline(baseline, receipt_path, receipt_override)
    |> validate_profiles(ledger["profiles"])
    |> validate_case_ids(cases, rows)
    |> validate_matrix_rows(cases, rows, ledger["blockers"])
    |> validate_requirement_dispositions(
      ledger["matrix"]["requirement_dispositions"],
      cases,
      rows
    )
    |> validate_frozen_matrix(ledger, cases, rows)
    |> validate_category_references(ledger["category_coverage"], cases)
    |> validate_cases(cases, receipt_path)
  end

  defp validate_selection_state(errors, ledger, cases) do
    revision = Map.get(ledger, "scope_revision", %{})

    cond do
      not is_list(cases) ->
        errors

      cases == [] ->
        errors
        |> require(
          ledger["selection_status"] in ["empty_requires_replan", "frozen"],
          "empty case set requires a replan marker"
        )
        |> require(
          revision["required"] == true and nonempty?(revision["rationale"]),
          "empty case set requires scope-revision rationale"
        )
        |> require(
          ledger["matrix"]["replan_required"] == true,
          "empty case set requires explicit matrix replan"
        )
        |> require(
          Enum.all?(Map.get(ledger, "category_coverage", []), &(&1["case_ids"] == [])),
          "empty case set requires explicit category exclusions"
        )

      true ->
        errors
        |> require(
          ledger["selection_status"] in ["draft", "selected", "frozen"],
          "nonempty case set has invalid selection status"
        )
        |> require(
          revision["required"] == false and is_nil(revision["rationale"]),
          "nonempty case set must not claim an empty-scope replan"
        )
    end
  end

  defp validate_baseline(errors, baseline, receipt_path, receipt_override) do
    receipt =
      cond do
        is_map(receipt_override) -> receipt_override
        File.exists?(receipt_path) -> receipt_path |> File.read!() |> Jason.decode!()
        true -> %{}
      end

    receipt_sha256 =
      if File.exists?(receipt_path),
        do:
          receipt_path
          |> File.read!()
          |> then(&:crypto.hash(:sha256, &1))
          |> Base.encode16(case: :lower)

    errors
    |> require(
      full_sha?(baseline["accepted_sha"]),
      "baseline accepted_sha must be a full lowercase SHA"
    )
    |> require(
      full_sha?(baseline["implementation_base"]),
      "baseline implementation_base must be a full lowercase SHA"
    )
    |> require(
      baseline["implementation_base"] == baseline["accepted_sha"],
      "implementation base must equal accepted SHA"
    )
    |> require(
      is_binary(baseline["receipt_ref"]) and File.exists?(receipt_path),
      "baseline receipt_ref must resolve"
    )
    |> require(
      is_binary(baseline["receipt_sha256"]) and
        String.match?(baseline["receipt_sha256"], ~r/\A[0-9a-f]{64}\z/),
      "baseline receipt_sha256 must be a SHA-256"
    )
    |> require(
      baseline["receipt_sha256"] == receipt_sha256,
      "receipt SHA-256 must match retained bytes"
    )
    |> require(
      baseline["receipt_schema"] == "lockspire-phase-139-acceptance-v1",
      "baseline receipt schema must be retained"
    )
    |> require(
      receipt["schema"] == baseline["receipt_schema"],
      "receipt schema must match baseline"
    )
    |> require(
      receipt["baseline_sha"] == baseline["accepted_sha"],
      "receipt baseline SHA must match accepted SHA"
    )
    |> require(receipt["local_gate"]["status"] == "pass", "receipt local gate must pass")
    |> require(
      is_integer(receipt["local_gate"]["exunit_tests"]) and
        receipt["local_gate"]["exunit_tests"] > 0,
      "receipt must record a positive local test count"
    )
    |> require(receipt["hygiene"]["block"] == 0, "receipt hygiene must have zero blocks")
    |> require(receipt["required_ci"]["status"] == "pass", "receipt required CI must pass")
    |> require(
      receipt["release_no_publish"]["status"] == "pass",
      "receipt release no-publish must pass"
    )
    |> require(
      is_list(receipt["warn_dispositions"]),
      "receipt warning dispositions must be explicit"
    )
    |> require(
      length(receipt["warn_dispositions"] || []) == receipt["hygiene"]["warn"],
      "every warning must have one disposition"
    )
  end

  defp validate_profiles(errors, profiles) when is_list(profiles) do
    Enum.reduce(profiles, errors, fn profile, acc ->
      attempt = Map.get(profile, "profile_attempt", %{})
      output = Map.get(profile, "artifact_output", %{})
      source = Map.get(profile, "source_host", %{})
      inputs = Map.get(profile, "suite_inputs", %{})
      preflight = Map.get(profile, "preflight", %{})

      acc
      |> require(
        nonempty?(profile["observation_id"]) and nonempty?(profile["operator"]),
        "profile observation identity and operator are required"
      )
      |> require(
        source["kind"] == "repository_source_host" and full_sha?(source["source_sha"]),
        "source-host identity is required"
      )
      |> require(full_sha?(inputs["suite_commit"]), "profile suite commit is required")
      |> require(
        String.match?(inputs["plan_sha256"] || "", ~r/\A[0-9a-f]{64}\z/),
        "profile plan checksum must be SHA-256"
      )
      |> require(
        String.match?(inputs["lock_sha256"] || "", ~r/\A[0-9a-f]{64}\z/),
        "profile lock checksum must be SHA-256"
      )
      |> require(
        preflight["immutable_input_validator"]["exit_code"] == 0,
        "immutable profile inputs must validate"
      )
      |> require(
        nonempty?(profile["next_owner"]) and nonempty?(profile["next_action"]),
        "unavailable profile owner and retry action are required"
      )
      |> require(
        profile["status"] != "unavailable" or
          (attempt["started"] == false and attempt["exit_code"] == nil and
             attempt["result_classification"] == nil and
             output["receipt_path"] == nil and output["receipt_sha256"] == nil and
             nonempty?(profile["unavailable_cause"])),
        "an unlaunched profile cannot claim wrapper or receipt outcomes"
      )
    end)
  end

  defp validate_profiles(errors, _), do: require(errors, false, "profiles must be an array")

  defp validate_case_ids(errors, cases, rows) when is_list(cases) and is_list(rows) do
    ids = Enum.map(cases, & &1["id"])
    row_ids = Enum.map(rows, & &1["case_id"])

    errors
    |> require(length(ids) == length(Enum.uniq(ids)), "case IDs must be unique")
    |> require(ids == Enum.sort(ids), "cases must be sorted by stable case ID")
    |> require(row_ids == ids, "matrix IDs must exactly match sorted case IDs")
    |> require(
      Enum.zip(cases, rows)
      |> Enum.all?(fn {item, row} ->
        row["priority"] == item["priority"] and row["classification"] == item["cause"] and
          row["next_owner"] == item["next_owner"]
      end),
      "matrix row priority, classification, and owner must match its case"
    )
  end

  defp validate_case_ids(errors, _, _), do: errors

  defp validate_matrix_rows(errors, cases, rows, blockers)
       when is_list(cases) and is_list(rows) and is_list(blockers) do
    case_map = Map.new(cases, &{&1["id"], &1})

    Enum.reduce(rows, errors, fn row, acc ->
      item = Map.get(case_map, row["case_id"], %{})
      disposition = row["disposition"]
      readiness = row["readiness"]

      disposition_valid =
        case disposition do
          "reuse_existing" ->
            item["repro"]["status"] == "pass" and readiness == "ready"

          "retain_correction" ->
            item["cause"] == "protocol" and item["repro"]["status"] == "counterexample" and
              item["repro"]["controls_passed"] == true and readiness == "ready"

          "retain_proof" ->
            item["repro"]["status"] == "pass" and readiness == "ready"

          "exclude" ->
            nonempty?(row["reason"]) and nonempty?(row["next_owner"]) and readiness == "excluded"

          "blocked" ->
            readiness == "blocked" and nonempty?(row["blocking_reason"]) and
              Enum.any?(blockers, &String.contains?(&1, row["case_id"]))

          _ ->
            false
        end

      expected_facts_present =
        nonempty?(item["expected_outcome"]) and nonempty?(item["regression_owner"])

      acc
      |> require(
        expected_facts_present,
        "retained matrix case needs an expected outcome and regression owner"
      )
      |> require(disposition_valid, "matrix disposition must match proof and readiness")
      |> require(
        row["requirement_ids"] == item["requirement_ids"],
        "matrix requirement IDs must match case data"
      )
    end)
  end

  defp validate_matrix_rows(errors, _, _, _), do: errors

  defp validate_requirement_dispositions(errors, dispositions, cases, rows)
       when is_list(dispositions) and is_list(cases) and is_list(rows) do
    ids = Enum.map(dispositions, & &1["requirement_id"])
    case_map = Map.new(cases, &{&1["id"], &1})
    row_map = Map.new(rows, &{&1["case_id"], &1})

    initial_errors =
      require(
        errors,
        ids == @downstream_requirement_ids,
        "all six downstream requirement IDs must have exactly one sorted disposition"
      )

    Enum.reduce(dispositions, initial_errors, fn disposition, acc ->
      requirement_id = disposition["requirement_id"]
      case_ids = disposition["case_ids"]
      existing = disposition["existing_proof"]
      retained = disposition["retained_cases"]

      ids_valid =
        is_list(case_ids) and is_list(existing) and is_list(retained) and
          case_ids == Enum.sort(Enum.uniq(case_ids)) and
          Enum.all?(case_ids, &Map.has_key?(case_map, &1)) and
          Enum.sort(case_ids) == Enum.sort(Enum.uniq(existing ++ retained)) and
          Enum.all?(case_ids, fn case_id ->
            requirement_id in Map.get(case_map, case_id, %{})["requirement_ids"]
          end)

      proof_valid =
        Enum.all?(existing, fn case_id ->
          item = Map.get(case_map, case_id, %{})

          item["repro"]["status"] == "pass" and
            Map.get(row_map, case_id, %{})["disposition"] == "reuse_existing"
        end) and
          Enum.all?(retained, fn case_id ->
            item = Map.get(case_map, case_id, %{})

            item["cause"] == "protocol" and item["repro"]["status"] == "counterexample" and
              Map.get(row_map, case_id, %{})["disposition"] == "retain_correction"
          end)

      disposition_valid =
        cond do
          case_ids == [] ->
            disposition["disposition"] in ["revise", "remove"] and
              nonempty?(disposition["amendment_ref"]) and nonempty?(disposition["rationale"])

          retained != [] ->
            disposition["disposition"] == "retain_correction"

          true ->
            disposition["disposition"] == "reuse_existing" and existing != []
        end

      acc
      |> require(
        ids_valid,
        "requirement disposition case references must be complete and case-backed"
      )
      |> require(proof_valid, "requirement disposition proof must match the case evidence")
      |> require(
        disposition_valid and nonempty?(disposition["rationale"]),
        "requirement disposition needs an explicit rationale"
      )
    end)
  end

  defp validate_requirement_dispositions(errors, _, _, _),
    do: require(errors, false, "requirement_dispositions must be an array")

  defp validate_frozen_matrix(errors, ledger, cases, rows) do
    matrix = Map.get(ledger, "matrix", %{})

    if matrix["status"] == "frozen" do
      manifest = matrix["input_manifest"]

      errors
      |> require(
        ledger["selection_status"] == "frozen",
        "frozen matrix requires frozen selection status"
      )
      |> require(valid_iso8601?(matrix["frozen_at"]), "frozen matrix requires a UTC timestamp")
      |> require(
        full_sha?(matrix["qualification_sha"]) and
          source_revision_exists?(matrix["qualification_sha"]),
        "qualification SHA must resolve to a source commit"
      )
      |> require(
        matrix["blocking_entries"] == [],
        "frozen matrix must have zero blocking entries"
      )
      |> require(ledger["blockers"] == [], "frozen matrix cannot retain selected-case blockers")
      |> require(
        is_list(matrix["amendments"]) and matrix["amendments"] != [],
        "frozen matrix requires explicit amendments or no-change decisions"
      )
      |> require(
        is_list(manifest) and manifest != [],
        "frozen matrix requires an ordered input manifest"
      )
      |> require(
        valid_input_manifest?(ledger, manifest, matrix["input_digest"]),
        "frozen matrix input manifest or digest is invalid or drifted"
      )
      |> require(
        frozen_scope_reconciled?(ledger, cases, rows),
        "frozen scope requires requirement and roadmap reconciliation"
      )
    else
      require(
        errors,
        ledger["selection_status"] != "frozen",
        "draft matrix cannot claim frozen selection status"
      )
    end
  end

  defp frozen_scope_reconciled?(ledger, [], _rows) do
    matrix = ledger["matrix"]
    amendments = matrix["amendments"]
    files = if is_list(amendments), do: Enum.map(amendments, & &1["file"]), else: []
    dispositions = matrix["requirement_dispositions"]

    matrix["replan_required"] == true and ledger["scope_revision"]["required"] == true and
      ".planning/REQUIREMENTS.md" in files and ".planning/ROADMAP.md" in files and
      is_list(dispositions) and
      Enum.all?(dispositions, &(&1["disposition"] in ["revise", "remove"])) and
      Enum.all?(amendments, &(nonempty?(&1["anchor"]) and nonempty?(&1["reason"])))
  end

  defp frozen_scope_reconciled?(ledger, cases, rows) when is_list(cases) and cases != [] do
    matrix = ledger["matrix"]
    amendments = matrix["amendments"]
    files = if is_list(amendments), do: Enum.map(amendments, & &1["file"]), else: []

    is_list(amendments) and is_list(rows) and
      is_list(matrix["requirement_dispositions"]) and matrix["replan_required"] == true and
      Enum.all?(cases, fn item ->
        row = Enum.find(rows, &(&1["case_id"] == item["id"])) || %{}
        row["disposition"] in ["reuse_existing", "retain_correction", "retain_proof", "exclude"]
      end) and
      Enum.all?(matrix["requirement_dispositions"], fn disposition ->
        disposition["disposition"] in ["reuse_existing", "retain_correction"] and
          nonempty?(disposition["rationale"])
      end) and
      ".planning/REQUIREMENTS.md" in files and ".planning/ROADMAP.md" in files and
      Enum.all?(amendments, &(nonempty?(&1["anchor"]) and nonempty?(&1["reason"])))
  end

  defp frozen_scope_reconciled?(_ledger, _cases, _rows), do: false

  defp valid_input_manifest?(ledger, manifest, digest) when is_list(manifest) do
    valid_entries =
      Enum.all?(manifest, fn entry ->
        is_map(entry) and is_binary(entry["path"]) and nonempty?(entry["path"]) and
          full_sha256?(entry["sha256"]) and entry["sha256"] == input_entry_hash(ledger, entry)
      end)

    identities = if valid_entries, do: Enum.map(manifest, &manifest_identity/1), else: []

    is_binary(digest) and String.match?(digest, ~r/\A[0-9a-f]{64}\z/) and
      valid_entries and length(identities) == length(Enum.uniq(identities)) and
      digest == manifest_digest(manifest)
  end

  defp valid_input_manifest?(_, _, _), do: false

  defp manifest_identity(entry),
    do:
      entry["path"] <>
        if(nonempty?(entry["selector"]), do: "#" <> entry["selector"], else: "")

  defp input_entry_hash(ledger, %{
         "path" =>
           ".planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json",
         "selector" => selector
       }) do
    value =
      case selector do
        "matrix-selection" ->
          %{
            "matrix" =>
              Map.take(ledger["matrix"], [
                "status",
                "rows",
                "requirement_dispositions",
                "replan_required",
                "amendments",
                "blocking_entries"
              ]),
            "blockers" => ledger["blockers"],
            "exclusions" => ledger["exclusions"],
            "supplemental_limitations" => ledger["supplemental_limitations"]
          }

        "cases" ->
          ledger["cases"]

        "profiles" ->
          ledger["profiles"]

        "category-coverage" ->
          ledger["category_coverage"]

        "scope-revision" ->
          ledger["scope_revision"]

        _ ->
          nil
      end

    if is_nil(value), do: nil, else: sha256(canonical_json(value))
  end

  defp input_entry_hash(_ledger, %{
         "path" => ".planning/REQUIREMENTS.md",
         "selector" => "qualification-scope-map"
       }) do
    @repo_root
    |> Path.join(".planning/REQUIREMENTS.md")
    |> File.read!()
    |> extract_section("## Qualification-driven scope reconciliation (2026-10-24)", "\n## ")
    |> sha256()
  end

  defp input_entry_hash(_ledger, %{
         "path" => ".planning/ROADMAP.md",
         "selector" => "phases-172-173-contract"
       }) do
    @repo_root
    |> Path.join(".planning/ROADMAP.md")
    |> File.read!()
    |> extract_section("### Phase 172: Authorization Responses", "\n### Phase 174:")
    |> sha256()
  end

  defp input_entry_hash(_ledger, %{"path" => path} = entry) when is_binary(path) do
    full_path = Path.join(@repo_root, path)

    if is_nil(entry["selector"]) and File.regular?(full_path) do
      full_path |> File.read!() |> sha256()
    else
      nil
    end
  end

  defp input_entry_hash(_, _), do: nil

  defp extract_section(content, start_marker, end_marker) do
    with {start, _} <- :binary.match(content, start_marker),
         tail <- binary_part(content, start, byte_size(content) - start),
         {finish, _} <- :binary.match(tail, end_marker) do
      binary_part(tail, 0, finish)
    else
      _ -> ""
    end
  end

  defp canonical_json(value), do: value |> canonical_term() |> Jason.encode!()
  defp canonical_term(value) when is_list(value), do: Enum.map(value, &canonical_term/1)

  defp canonical_term(value) when is_map(value) do
    value
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Map.new(fn {key, child} -> {key, canonical_term(child)} end)
  end

  defp canonical_term(value), do: value
  defp sha256(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)

  defp valid_iso8601?(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, _datetime, 0} -> true
      _ -> false
    end
  end

  defp valid_iso8601?(_), do: false

  defp validate_category_references(errors, categories, cases)
       when is_list(categories) and is_list(cases) do
    ids = Enum.map(cases, & &1["id"])

    refs =
      Enum.flat_map(categories, fn category ->
        case Map.get(category, "case_ids") do
          ids when is_list(ids) -> ids
          _ -> []
        end
      end)

    errors
    |> require(
      Enum.all?(categories, &is_list(&1["case_ids"])),
      "category case_ids must be arrays"
    )
    |> require(
      Enum.all?(refs, &(&1 in ids)),
      "category coverage cannot reference orphan case IDs"
    )
  end

  defp validate_category_references(errors, _, _),
    do: require(errors, false, "category_coverage must be an array")

  defp validate_cases(errors, cases, receipt_path) when is_list(cases) do
    Enum.reduce(cases, errors, fn item, acc ->
      acc
      |> validate_case_fields(item)
      |> validate_case_references(item)
      |> validate_case_proof(item, receipt_path)
    end)
  end

  defp validate_cases(errors, _, _), do: errors

  defp validate_case_fields(errors, item) do
    source = Map.get(item, "source", %{})
    input = Map.get(item, "input_identity", %{})
    observations = Map.get(item, "observations")

    causes = [
      "protocol",
      "harness_transport_browser",
      "infrastructure",
      "unsupported",
      "already_correct_not_reproduced",
      "unresolved"
    ]

    errors
    |> require(
      nonempty?(item["id"]) and nonempty?(item["condition_id"]),
      "case ID and concrete condition ID are required"
    )
    |> require(nonempty?(item["family"]), "case family is required")
    |> require(
      is_list(item["requirement_ids"]) and item["requirement_ids"] != [],
      "case requirement_ids are required"
    )
    |> require(
      nonempty?(item["observed_outcome"]) and nonempty?(item["expected_outcome"]),
      "observed and expected outcomes are required independently"
    )
    |> require(
      item["cause"] in causes and nonempty?(item["cause_detail"]),
      "case cause must use a supported classification and explanation"
    )
    |> require(
      nonempty?(item["next_owner"]) and nonempty?(item["repro_owner"]) and
        nonempty?(item["regression_owner"]),
      "case proof and regression owners are required"
    )
    |> require(
      source["kind"] in ["repository_test", "repository_test_inventory"] and
        nonempty?(source["date"]) and full_sha?(source["source_sha"]),
      "case source identity and date are required"
    )
    |> require(
      String.match?(source["test_file_sha256"] || "", ~r/\A[0-9a-f]{64}\z/),
      "case test file checksum is required"
    )
    |> require(
      input["kind"] in ["repository_test", "planned_repository_repro"] and
        full_sha?(input["source_sha"]) and nonempty?(input["test_path"]) and
        nonempty?(input["request"]),
      "case input identity is required"
    )
    |> require(
      input["source_sha"] == source["source_sha"] and input["test_path"] == source["test_path"],
      "case source and input identities must align"
    )
    |> require(
      nonempty?(item["provider_identity"]) and nonempty?(item["supported_mount"]),
      "provider and mounted surface identity are required"
    )
    |> require(
      nonempty?(item["profile"]) and nonempty?(item["auth_mode"]) and
        nonempty?(item["safe_condition"]),
      "profile, auth mode and safe condition are required"
    )
    |> require(
      is_list(observations) and observations != [],
      "case observations must be a nonempty array"
    )
  end

  defp validate_case_references(errors, item) do
    repro = Map.get(item, "repro", %{})
    input = Map.get(item, "input_identity", %{})

    errors
    |> require(
      nonempty?(input["test_path"]) and nonempty?(input["request"]),
      "input reference must identify test and request"
    )
    |> require(
      (repro["status"] == "pass" and nonempty?(repro["command"]) and nonempty?(repro["test_path"]) and
         nonempty?(repro["test_name"]) and repro["evidence_kind"] == "repository_test" and
         File.exists?(Path.join(@repo_root, repro["test_path"]))) or
        (repro["status"] == "counterexample" and item["cause"] == "protocol" and
           repro["evidence_kind"] == "controlled_http_probe" and
           nonempty?(repro["command"]) and nonempty?(repro["test_path"]) and
           nonempty?(repro["test_name"]) and
           File.exists?(Path.join(@repo_root, repro["test_path"])) and
           nonempty?(repro["assertion_id"]) and repro["controls_passed"] == true and
           is_list(repro["control_ids"]) and repro["control_ids"] != [] and
           is_map(repro["expected_projection"]) and is_map(repro["observed_projection"]) and
           repro["expected_projection"] != repro["observed_projection"] and
           full_sha256?(repro["test_file_sha256"]) and nonempty?(repro["probe_observation_id"])) or
        (repro["status"] == "not_run" and item["cause"] == "unresolved" and
           repro["evidence_kind"] == "none" and nonempty?(repro["reason"])),
      "reproduction must be a named test, a controlled counterexample, or an explicit unresolved not-run boundary"
    )
    |> require(
      is_list(item["normative_references"]) and item["normative_references"] != [] and
        Enum.all?(item["normative_references"], &valid_url_reference?/1),
      "normative references must be resolvable URLs"
    )
    |> require(
      is_binary(item["support_reference"]["path"]) and
        File.exists?(Path.join(@repo_root, item["support_reference"]["path"])),
      "support reference must resolve"
    )
  end

  defp validate_case_proof(errors, item, receipt_path) do
    repro = Map.get(item, "repro", %{})
    obs = Map.get(item, "observations", [])

    deterministic_pass =
      repro["status"] == "pass" and
        repro["source_sha"] == item["source"]["source_sha"] and
        repro["evidence_kind"] == "repository_test"

    controlled_counterexample =
      repro["status"] == "counterexample" and item["cause"] == "protocol" and
        repro["source_sha"] == item["source"]["source_sha"] and
        repro["evidence_kind"] == "controlled_http_probe" and
        is_integer(repro["test_count"]) and repro["test_count"] > 0 and
        is_integer(repro["failure_count"]) and repro["failure_count"] > 0 and
        repro["controls_passed"] == true and nonempty?(repro["assertion_id"]) and
        probe_counterexample_matches?(item, repro)

    unresolved_not_run =
      repro["status"] == "not_run" and item["cause"] == "unresolved" and
        is_list(obs) and Enum.all?(obs, &(&1["status"] == "not_observed"))

    observations_match_result =
      cond do
        deterministic_pass ->
          Enum.all?(obs, &(&1["status"] == "pass"))

        controlled_counterexample ->
          Enum.count(obs, &(&1["status"] == "counterexample")) == 1 and
            Enum.any?(obs, fn observation ->
              observation["status"] == "counterexample" and
                observation["assertion_id"] == repro["assertion_id"] and
                observation["probe_observation_id"] == repro["probe_observation_id"]
            end)

        unresolved_not_run ->
          true

        true ->
          false
      end

    errors
    |> require(
      deterministic_pass or controlled_counterexample or unresolved_not_run,
      "only a deterministic pass, controlled normative counterexample, or explicit unresolved not-run case is valid"
    )
    |> require(
      source_revision_exists?(item["source"]["source_sha"]),
      "case source SHA must resolve to a Git commit"
    )
    |> require(
      not deterministic_pass or
        (is_integer(repro["test_count"]) and repro["test_count"] > 0 and
           repro["failure_count"] == 0),
      "passing repro must record positive tests and zero failures"
    )
    |> require(
      is_list(obs) and
        Enum.all?(obs, fn observation ->
          nonempty?(observation["observation_id"]) and
            observation["condition_id"] == item["condition_id"] and
            full_sha?(observation["source_sha"]) and
            source_revision_exists?(observation["source_sha"]) and
            nonempty?(observation["input_identity"]) and observation["date"] != nil and
            observation["status"] in ["pass", "not_observed", "counterexample"] and
            (observation["status"] != "counterexample" or
               (controlled_counterexample and observation["assertion_id"] == repro["assertion_id"] and
                  observation["probe_observation_id"] == repro["probe_observation_id"]))
        end),
      "observations must retain their own source, input, and outcome identities"
    )
    |> require(
      observations_match_result,
      "observations must support the current result at its own source identity"
    )
    |> require(
      is_list(obs) and
        length(Enum.map(obs, & &1["observation_id"])) ==
          length(Enum.uniq(Enum.map(obs, & &1["observation_id"]))),
      "observation IDs must be unique within a case"
    )
    |> require(File.exists?(receipt_path), "accepted receipt must resolve")
  end

  defp valid_url_reference?(%{"url" => url, "section" => section}),
    do: is_binary(url) and String.starts_with?(url, "https://") and nonempty?(section)

  defp valid_url_reference?(_), do: false

  defp probe_counterexample_matches?(item, repro) do
    path = Path.join(@phase_dir, "171-QUALIFICATION-PROBE.json")

    with {:ok, body} <- File.read(path),
         {:ok, probe} <- Jason.decode(body),
         result when is_map(result) <- Enum.find(probe["cases"], &(&1["case_id"] == item["id"])) do
      probe["observation_id"] == repro["probe_observation_id"] and
        probe["source_identity"]["source_sha_before"] == repro["source_sha"] and
        probe["source_identity"]["source_sha_after"] == repro["source_sha"] and
        probe["source_identity"]["changed_during_observation"] == false and
        probe["source_identity"]["probe_sha256"] == repro["test_file_sha256"] and
        probe["execution"]["mix_exit_code"] == 2 and
        probe["execution"]["test_count"] == repro["test_count"] and
        probe["execution"]["failure_count"] == repro["failure_count"] and
        result["assertion_id"] == repro["assertion_id"] and
        result["expected_projection"] == repro["expected_projection"] and
        result["observed_projection"] == repro["observed_projection"] and
        result["protocol_assertion_status"] == "counterexample" and
        result["controls"] != [] and Enum.all?(result["controls"], &(&1["status"] == "pass"))
    else
      _ -> false
    end
  end

  defp require(errors, true, _message), do: errors
  defp require(errors, false, message), do: [message | errors]
  defp full_sha?(value), do: is_binary(value) and String.match?(value, ~r/\A[0-9a-f]{40}\z/)
  defp full_sha256?(value), do: is_binary(value) and String.match?(value, ~r/\A[0-9a-f]{64}\z/)
  defp nonempty?(value), do: is_binary(value) and String.trim(value) != ""

  defp source_revision_exists?(sha) when is_binary(sha) do
    case System.cmd("git", ["cat-file", "-e", "#{sha}^{commit}"], cd: @repo_root) do
      {_, 0} -> true
      _ -> false
    end
  end

  defp source_revision_exists?(_), do: false
end
