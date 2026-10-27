defmodule Lockspire.QualificationLedgerContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @phase_dir Path.join(@repo_root, ".planning/phases/171-accepted-baseline-finding-qualification")
  @ledger_path Path.join(@phase_dir, "171-QUALIFICATION.json")
  @ledger_relative_path ".planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json"
  # This retained snapshot binds the final frozen inputs separately from the
  # earlier qualification execution. These pins authenticate historical evidence;
  # they do not qualify today's workspace. Keep the provenance in this selected
  # source file so the current delivery input closure authenticates it as well.
  # Local qualification requires full Git history, as fast/minimum CI already
  # provide with fetch-depth: 0. Missing objects fail closed without a fetch.
  @frozen_input_source %{
    "schema" => "lockspire-phase171-frozen-input-source-v1",
    "source_revision" => "173059a166e9ade0f5f57c9980b7b2400a98538c",
    "ledger_path" => @ledger_relative_path,
    "ledger_sha256" => "d4f790a7057ed967f105068631d44eae46d69fefc7013836b868c74121a403b7",
    "matrix_input_digest" => "3edc2b22eca506c063e1483a6a684ada300a54d56d55d1308c78b4812c144137"
  }
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

  test "malformed nested evidence values return validation errors instead of crashing" do
    ledger = load_ledger()
    profile = List.replace_at(ledger["profiles"], 0, "phase37")
    case_item = List.replace_at(ledger["cases"], 0, nil)
    row = List.replace_at(ledger["matrix"]["rows"], 0, 42)

    disposition =
      List.replace_at(ledger["matrix"]["requirement_dispositions"], 0, "AUTHR-01")

    malformed = [
      %{ledger | "profiles" => profile},
      %{ledger | "cases" => case_item},
      put_in(ledger, ["matrix", "rows"], row),
      put_in(ledger, ["matrix", "requirement_dispositions"], disposition),
      put_in(
        ledger,
        ["matrix", "requirement_dispositions", Access.at(0), "existing_proof"],
        "A171-001"
      ),
      put_in(ledger, ["matrix", "requirement_dispositions", Access.at(0), "existing_proof"], nil)
    ]

    Enum.each(malformed, &assert_rejected/1)
  end

  test "malformed case requirement IDs return validation errors instead of crashing" do
    ledger = load_ledger()
    [disposition | _] = ledger["matrix"]["requirement_dispositions"]
    [case_id | _] = disposition["case_ids"]
    case_index = Enum.find_index(ledger["cases"], &(&1["id"] == case_id))

    malformed = [
      put_in(ledger, ["cases", Access.at(case_index), "requirement_ids"], "AUTHR-01"),
      put_in(ledger, ["cases", Access.at(case_index), "requirement_ids"], nil),
      put_in(ledger, ["cases", Access.at(case_index), "requirement_ids"], ["AUTHR-01", 42])
    ]

    Enum.each(malformed, &assert_rejected/1)
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
      assert profile["profile_attempt"]["interrupted"] == false
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

  test "an unlaunched profile cannot claim interruption" do
    ledger = load_ledger()
    assert validate(draft_matrix(ledger, "draft")) == []

    interrupted =
      put_in(
        ledger,
        ["profiles", Access.at(0), "profile_attempt", "interrupted"],
        true
      )

    errors = validate(draft_matrix(interrupted, "draft"))
    assert "an unlaunched profile cannot claim wrapper or receipt outcomes" in errors
  end

  test "retained frozen input provenance binds the unchanged ledger and ordered digest" do
    source = load_frozen_input_source()

    assert valid_frozen_input_source?(source), "retained source must bind the original ledger"

    for field <- [
          "schema",
          "source_revision",
          "ledger_path",
          "ledger_sha256",
          "matrix_input_digest"
        ] do
      refute valid_frozen_input_source?(Map.delete(source, field)),
             "incomplete retained source identity must be rejected"
    end

    for field <- ["ledger_sha256", "matrix_input_digest"] do
      refute valid_frozen_input_source?(Map.put(source, field, String.duplicate("0", 64))),
             "mismatched retained source identity must be rejected"
    end
  end

  test "frozen file hashes use the retained snapshot separately from the qualification execution" do
    ledger = load_ledger()

    entry =
      Enum.find(ledger["matrix"]["input_manifest"], &(&1["path"] == "docs/supported-surface.md"))

    assert input_entry_hash(ledger, entry) == entry["sha256"],
           "retained document must match its original frozen hash"

    refute input_entry_hash(ledger, entry, ledger["matrix"]["qualification_sha"]) ==
             entry["sha256"],
           "earlier qualification execution must not impersonate the final input snapshot"
  end

  test "unavailable or mismatched retained sources cannot fall back to workspace bytes" do
    ledger = load_ledger()
    source = load_frozen_input_source()
    entry = Enum.find(ledger["matrix"]["input_manifest"], &(&1["path"] == "test/test_helper.exs"))
    missing_revision = String.duplicate("0", 40)

    assert is_nil(input_entry_hash(ledger, entry, missing_revision)),
           "missing source must fail closed even when a workspace file exists"

    refute valid_frozen_input_source?(Map.put(source, "source_revision", missing_revision)),
           "missing retained source must be rejected"

    errors =
      validate_frozen_input_source([], Map.put(source, "source_revision", missing_revision))

    assert "retained frozen input source is unavailable; use a full-history checkout (fetch-depth: 0)" in errors,
           "missing historical objects must explain the full-history prerequisite"

    refute valid_frozen_input_source?(
             Map.put(source, "source_revision", ledger["matrix"]["qualification_sha"])
           ),
           "a different execution source must not replace the retained ledger snapshot"
  end

  defp load_ledger, do: @ledger_path |> File.read!() |> Jason.decode!()

  defp load_frozen_input_source, do: @frozen_input_source

  defp valid_frozen_input_source?(source) when is_map(source) do
    with true <- source["schema"] == "lockspire-phase171-frozen-input-source-v1",
         true <- source["ledger_path"] == @ledger_relative_path,
         true <- full_sha256?(source["ledger_sha256"]),
         {:ok, retained_ledger} <-
           frozen_source_file(source["source_revision"], @ledger_relative_path),
         {:ok, workspace_ledger} <- File.read(@ledger_path),
         true <- sha256(retained_ledger) == source["ledger_sha256"],
         true <- sha256(workspace_ledger) == source["ledger_sha256"],
         {:ok, ledger} <- Jason.decode(retained_ledger) do
      full_sha256?(source["matrix_input_digest"]) and
        source["matrix_input_digest"] == get_in(ledger, ["matrix", "input_digest"])
    else
      _ -> false
    end
  end

  defp valid_frozen_input_source?(_), do: false

  defp validate_frozen_input_source(errors, source) do
    available? =
      is_map(source) and
        match?({:ok, _}, frozen_source_file(source["source_revision"], @ledger_relative_path))

    errors
    |> require(
      available?,
      "retained frozen input source is unavailable; use a full-history checkout (fetch-depth: 0)"
    )
    |> require(
      valid_frozen_input_source?(source),
      "retained frozen input provenance must bind the unchanged ledger and ordered digest"
    )
  end

  defp draft_matrix(ledger, selection_status) do
    ledger
    |> put_in(["selection_status"], selection_status)
    |> put_in(["matrix", "status"], "draft")
  end

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
    |> validate_nested_shapes(ledger)
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

  defp validate_nested_shapes(errors, ledger) do
    matrix = Map.get(ledger, "matrix", %{})
    profiles = Map.get(ledger, "profiles")
    cases = Map.get(ledger, "cases")
    rows = if is_map(matrix), do: Map.get(matrix, "rows"), else: nil
    dispositions = if is_map(matrix), do: Map.get(matrix, "requirement_dispositions"), else: nil

    errors
    |> require(
      valid_profile_shapes?(profiles),
      "profile entries and nested evidence must be objects"
    )
    |> require(
      valid_case_shapes?(cases),
      "case entries and nested evidence must have valid shapes"
    )
    |> require(is_list(rows) and all_maps?(rows), "matrix row entries must be objects")
    |> require(
      is_list(dispositions) and valid_disposition_shapes?(dispositions),
      "requirement disposition entries must be objects with case_ids, existing_proof, and retained_cases arrays"
    )
  end

  defp valid_disposition_shapes?(dispositions) when is_list(dispositions) do
    Enum.all?(dispositions, fn disposition ->
      is_map(disposition) and
        Enum.all?(["case_ids", "existing_proof", "retained_cases"], &is_list(disposition[&1]))
    end)
  end

  defp valid_disposition_shapes?(_), do: false

  defp valid_profile_shapes?(profiles) when is_list(profiles) do
    Enum.all?(profiles, fn profile ->
      is_map(profile) and
        Enum.all?(
          ["profile_attempt", "artifact_output", "source_host", "suite_inputs", "preflight"],
          fn key ->
            is_map(Map.get(profile, key, %{}))
          end
        ) and
        is_map(get_in(profile, ["preflight", "immutable_input_validator"]) || %{})
    end)
  end

  defp valid_profile_shapes?(_), do: false

  defp valid_case_shapes?(cases) when is_list(cases) do
    Enum.all?(cases, fn item ->
      is_map(item) and
        valid_requirement_ids?(item) and
        Enum.all?(["source", "input_identity", "repro", "support_reference"], fn key ->
          is_map(Map.get(item, key, %{}))
        end) and
        is_list(Map.get(item, "normative_references", [])) and
        all_maps?(Map.get(item, "normative_references", [])) and
        is_list(Map.get(item, "observations", [])) and
        all_maps?(Map.get(item, "observations", []))
    end)
  end

  defp valid_case_shapes?(_), do: false

  defp valid_requirement_ids?(item) do
    requirement_ids = Map.get(item, "requirement_ids")
    is_list(requirement_ids) and Enum.all?(requirement_ids, &nonempty?/1)
  end

  defp all_maps?(values) when is_list(values), do: Enum.all?(values, &is_map/1)
  defp all_maps?(_), do: false

  defp validate_selection_state(errors, ledger, cases) do
    revision = Map.get(ledger, "scope_revision", %{})

    cond do
      not is_list(cases) or not all_maps?(cases) or not is_map(revision) ->
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
    if valid_profile_shapes?(profiles) do
      validate_profile_entries(errors, profiles)
    else
      require(errors, false, "profile entries must be objects")
    end
  end

  defp validate_profiles(errors, _), do: require(errors, false, "profiles must be an array")

  defp validate_profile_entries(errors, profiles) do
    Enum.reduce(profiles, errors, fn profile, acc ->
      acc
      |> validate_profile_identity(profile)
      |> validate_profile_inputs(profile)
      |> validate_profile_attempt(profile)
    end)
  end

  defp validate_profile_identity(errors, profile) do
    source = profile["source_host"] || %{}

    errors
    |> require(
      nonempty?(profile["observation_id"]) and nonempty?(profile["operator"]),
      "profile observation identity and operator are required"
    )
    |> require(
      source["kind"] == "repository_source_host" and full_sha?(source["source_sha"]),
      "source-host identity is required"
    )
    |> require(
      nonempty?(profile["next_owner"]) and nonempty?(profile["next_action"]),
      "unavailable profile owner and retry action are required"
    )
  end

  defp validate_profile_inputs(errors, profile) do
    inputs = profile["suite_inputs"] || %{}
    preflight = profile["preflight"] || %{}

    errors
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
  end

  defp validate_profile_attempt(errors, profile) do
    attempt = profile["profile_attempt"] || %{}
    output = profile["artifact_output"] || %{}

    require(
      errors,
      profile["status"] != "unavailable" or valid_unlaunched_profile?(profile, attempt, output),
      "an unlaunched profile cannot claim wrapper or receipt outcomes"
    )
  end

  defp valid_unlaunched_profile?(profile, attempt, output) do
    attempt["started"] == false and attempt["interrupted"] == false and
      attempt["exit_code"] == nil and attempt["result_classification"] == nil and
      output["receipt_path"] == nil and output["receipt_sha256"] == nil and
      nonempty?(profile["unavailable_cause"])
  end

  defp validate_case_ids(errors, cases, rows) when is_list(cases) and is_list(rows) do
    if valid_case_shapes?(cases) and all_maps?(rows) do
      validate_case_id_entries(errors, cases, rows)
    else
      require(errors, false, "case and matrix row entries must be objects")
    end
  end

  defp validate_case_ids(errors, _, _), do: errors

  defp validate_case_id_entries(errors, cases, rows) do
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

  defp validate_matrix_rows(errors, cases, rows, blockers)
       when is_list(cases) and is_list(rows) and is_list(blockers) do
    if valid_case_shapes?(cases) and all_maps?(rows) do
      validate_matrix_row_entries(errors, cases, rows, blockers)
    else
      require(errors, false, "case and matrix row entries must be objects")
    end
  end

  defp validate_matrix_rows(errors, _, _, _), do: errors

  defp validate_matrix_row_entries(errors, cases, rows, blockers) do
    case_map = Map.new(cases, &{&1["id"], &1})

    Enum.reduce(rows, errors, &validate_matrix_row(&2, &1, case_map, blockers))
  end

  defp validate_matrix_row(errors, row, case_map, blockers) do
    item = Map.get(case_map, row["case_id"], %{})

    errors
    |> require(
      nonempty?(item["expected_outcome"]) and nonempty?(item["regression_owner"]),
      "retained matrix case needs an expected outcome and regression owner"
    )
    |> require(
      valid_matrix_disposition?(row, item, blockers),
      "matrix disposition must match proof and readiness"
    )
    |> require(
      row["requirement_ids"] == item["requirement_ids"],
      "matrix requirement IDs must match case data"
    )
  end

  defp valid_matrix_disposition?(row, item, blockers) do
    case row["disposition"] do
      "reuse_existing" ->
        valid_reuse_row?(row, item)

      "retain_correction" ->
        valid_correction_row?(row, item)

      "retain_proof" ->
        valid_retained_proof_row?(row, item)

      "exclude" ->
        valid_excluded_row?(row)

      "blocked" ->
        valid_blocked_row?(row, blockers)

      _ ->
        false
    end
  end

  defp valid_reuse_row?(row, item),
    do: item["repro"]["status"] == "pass" and row["readiness"] == "ready"

  defp valid_correction_row?(row, item) do
    item["cause"] == "protocol" and item["repro"]["status"] == "counterexample" and
      item["repro"]["controls_passed"] == true and row["readiness"] == "ready"
  end

  defp valid_retained_proof_row?(row, item),
    do: item["repro"]["status"] == "pass" and row["readiness"] == "ready"

  defp valid_excluded_row?(row) do
    nonempty?(row["reason"]) and nonempty?(row["next_owner"]) and
      row["readiness"] == "excluded"
  end

  defp valid_blocked_row?(row, blockers) do
    row["readiness"] == "blocked" and nonempty?(row["blocking_reason"]) and
      Enum.any?(blockers, &String.contains?(&1, row["case_id"]))
  end

  defp validate_requirement_dispositions(errors, dispositions, cases, rows)
       when is_list(dispositions) and is_list(cases) and is_list(rows) do
    if valid_disposition_shapes?(dispositions) and valid_case_shapes?(cases) and all_maps?(rows) do
      validate_disposition_entries(errors, dispositions, cases, rows)
    else
      require(
        errors,
        false,
        "requirement disposition entries must be objects with case_ids, existing_proof, and retained_cases arrays"
      )
    end
  end

  defp validate_requirement_dispositions(errors, _, _, _),
    do: require(errors, false, "requirement_dispositions must be an array")

  defp validate_disposition_entries(errors, dispositions, cases, rows) do
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
      validate_disposition_entry(acc, disposition, case_map, row_map)
    end)
  end

  defp validate_disposition_entry(errors, disposition, case_map, row_map) do
    errors
    |> validate_disposition_references(disposition, case_map)
    |> validate_disposition_proof(disposition, case_map, row_map)
    |> validate_disposition_decision(disposition)
  end

  defp validate_disposition_references(errors, disposition, case_map) do
    case_ids = disposition["case_ids"]
    proof_ids = disposition["existing_proof"] ++ disposition["retained_cases"]

    valid =
      case_ids == Enum.sort(Enum.uniq(case_ids)) and
        Enum.all?(case_ids, &Map.has_key?(case_map, &1)) and
        Enum.sort(case_ids) == Enum.sort(Enum.uniq(proof_ids)) and
        Enum.all?(case_ids, fn case_id ->
          disposition["requirement_id"] in Map.get(case_map, case_id, %{})["requirement_ids"]
        end)

    require(
      errors,
      valid,
      "requirement disposition case references must be complete and case-backed"
    )
  end

  defp validate_disposition_proof(errors, disposition, case_map, row_map) do
    existing_valid? =
      Enum.all?(disposition["existing_proof"], &existing_case_proof?(&1, case_map, row_map))

    retained_valid? =
      Enum.all?(disposition["retained_cases"], &retained_case_proof?(&1, case_map, row_map))

    require(
      errors,
      existing_valid? and retained_valid?,
      "requirement disposition proof must match the case evidence"
    )
  end

  defp existing_case_proof?(case_id, case_map, row_map) do
    item = Map.get(case_map, case_id, %{})

    item["repro"]["status"] == "pass" and
      Map.get(row_map, case_id, %{})["disposition"] == "reuse_existing"
  end

  defp retained_case_proof?(case_id, case_map, row_map) do
    item = Map.get(case_map, case_id, %{})

    item["cause"] == "protocol" and item["repro"]["status"] == "counterexample" and
      Map.get(row_map, case_id, %{})["disposition"] == "retain_correction"
  end

  defp validate_disposition_decision(errors, disposition) do
    case_ids = disposition["case_ids"]
    retained = disposition["retained_cases"]
    existing = disposition["existing_proof"]

    valid =
      cond do
        case_ids == [] ->
          disposition["disposition"] in ["revise", "remove"] and
            nonempty?(disposition["amendment_ref"])

        retained != [] ->
          disposition["disposition"] == "retain_correction"

        true ->
          disposition["disposition"] == "reuse_existing" and existing != []
      end

    require(
      errors,
      valid and nonempty?(disposition["rationale"]),
      "requirement disposition needs an explicit rationale"
    )
  end

  defp validate_frozen_matrix(errors, ledger, cases, rows) do
    matrix = Map.get(ledger, "matrix", %{})

    if is_map(matrix) do
      validate_frozen_matrix_status(errors, ledger, cases, rows, matrix)
    else
      errors
    end
  end

  defp validate_frozen_matrix_status(errors, ledger, cases, rows, matrix) do
    if matrix["status"] == "frozen" and valid_case_shapes?(cases) and all_maps?(rows) and
         valid_disposition_shapes?(Map.get(matrix, "requirement_dispositions", [])) do
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
      |> validate_frozen_input_source(load_frozen_input_source())
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
    revision = Map.get(ledger, "scope_revision", %{})

    is_map(revision) and matrix["replan_required"] == true and
      revision["required"] == true and valid_scope_amendments?(matrix["amendments"]) and
      valid_empty_scope_dispositions?(matrix["requirement_dispositions"])
  end

  defp frozen_scope_reconciled?(ledger, cases, rows) when is_list(cases) and cases != [] do
    matrix = ledger["matrix"]

    matrix["replan_required"] == true and valid_nonempty_scope_rows?(cases, rows) and
      valid_retained_scope_dispositions?(matrix["requirement_dispositions"]) and
      valid_scope_amendments?(matrix["amendments"])
  end

  defp frozen_scope_reconciled?(_ledger, _cases, _rows), do: false

  defp valid_scope_amendments?(amendments) when is_list(amendments) and amendments != [] do
    if all_maps?(amendments) do
      files = Enum.map(amendments, & &1["file"])

      ".planning/REQUIREMENTS.md" in files and ".planning/ROADMAP.md" in files and
        Enum.all?(amendments, &(nonempty?(&1["anchor"]) and nonempty?(&1["reason"])))
    else
      false
    end
  end

  defp valid_scope_amendments?(_), do: false

  defp valid_empty_scope_dispositions?(dispositions) when is_list(dispositions) do
    all_maps?(dispositions) and
      Enum.all?(dispositions, &(&1["disposition"] in ["revise", "remove"]))
  end

  defp valid_empty_scope_dispositions?(_), do: false

  defp valid_retained_scope_dispositions?(dispositions) when is_list(dispositions) do
    all_maps?(dispositions) and
      Enum.all?(dispositions, fn disposition ->
        disposition["disposition"] in ["reuse_existing", "retain_correction"] and
          nonempty?(disposition["rationale"])
      end)
  end

  defp valid_retained_scope_dispositions?(_), do: false

  defp valid_nonempty_scope_rows?(cases, rows) when is_list(rows) do
    all_maps?(cases) and all_maps?(rows) and
      Enum.all?(cases, fn item ->
        row = Enum.find(rows, &(&1["case_id"] == item["id"])) || %{}
        row["disposition"] in ["reuse_existing", "retain_correction", "retain_proof", "exclude"]
      end)
  end

  defp valid_nonempty_scope_rows?(_, _), do: false

  defp valid_input_manifest?(ledger, manifest, digest) when is_list(manifest) do
    valid_frozen_input_source?(load_frozen_input_source()) and
      valid_manifest_entries?(ledger, manifest) and valid_manifest_digest?(manifest, digest)
  end

  defp valid_input_manifest?(_, _, _), do: false

  defp valid_manifest_entries?(ledger, manifest) do
    Enum.all?(manifest, fn entry ->
      is_map(entry) and is_binary(entry["path"]) and nonempty?(entry["path"]) and
        full_sha256?(entry["sha256"]) and entry["sha256"] == input_entry_hash(ledger, entry)
    end) and unique_manifest_identities?(manifest)
  end

  defp unique_manifest_identities?(manifest) do
    identities = Enum.map(manifest, &manifest_identity/1)
    length(identities) == length(Enum.uniq(identities))
  end

  defp valid_manifest_digest?(manifest, digest) do
    is_binary(digest) and String.match?(digest, ~r/\A[0-9a-f]{64}\z/) and
      digest == manifest_digest(manifest)
  end

  defp manifest_identity(entry),
    do:
      entry["path"] <>
        if(nonempty?(entry["selector"]), do: "#" <> entry["selector"], else: "")

  # Fixture projections remain live; retained file bytes belong to the frozen
  # snapshot, independently of later workspace edits or the earlier repro SHA.
  defp input_entry_hash(ledger, entry),
    do: input_entry_hash(ledger, entry, load_frozen_input_source()["source_revision"])

  defp input_entry_hash(
         ledger,
         %{
           "path" =>
             ".planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json",
           "selector" => selector
         },
         _source_revision
       ) do
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

  defp input_entry_hash(
         _ledger,
         %{
           "path" => ".planning/REQUIREMENTS.md",
           "selector" => "qualification-scope-map"
         },
         source_revision
       ) do
    frozen_section_hash(
      source_revision,
      ".planning/REQUIREMENTS.md",
      "## Qualification-driven scope reconciliation (2026-10-24)",
      "\n## "
    )
  end

  defp input_entry_hash(
         _ledger,
         %{
           "path" => ".planning/ROADMAP.md",
           "selector" => "phases-172-173-contract"
         },
         source_revision
       ) do
    frozen_section_hash(
      source_revision,
      ".planning/ROADMAP.md",
      "### Phase 172: Authorization Responses",
      "\n### Phase 174:"
    )
  end

  defp input_entry_hash(_ledger, %{"path" => path} = entry, source_revision)
       when is_binary(path) do
    with true <- is_nil(entry["selector"]),
         {:ok, bytes} <- frozen_source_file(source_revision, path) do
      sha256(bytes)
    else
      _ -> nil
    end
  end

  defp input_entry_hash(_, _, _), do: nil

  defp frozen_section_hash(source_revision, path, start_marker, end_marker) do
    with {:ok, bytes} <- frozen_source_file(source_revision, path) do
      bytes |> extract_section(start_marker, end_marker) |> sha256()
    else
      _ -> nil
    end
  end

  defp frozen_source_file(source_revision, path)
       when is_binary(source_revision) and is_binary(path) do
    if full_sha?(source_revision) do
      case System.cmd("git", ["cat-file", "blob", "#{source_revision}:#{path}"],
             cd: @repo_root,
             stderr_to_stdout: true
           ) do
        {bytes, 0} -> {:ok, bytes}
        _ -> :error
      end
    else
      :error
    end
  end

  defp frozen_source_file(_, _), do: :error

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
    if all_maps?(categories) and all_maps?(cases) do
      validate_category_entries(errors, categories, cases)
    else
      require(errors, false, "category and case entries must be objects")
    end
  end

  defp validate_category_references(errors, _, _),
    do: require(errors, false, "category_coverage must be an array")

  defp validate_category_entries(errors, categories, cases) do
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

  defp validate_cases(errors, cases, receipt_path) when is_list(cases) do
    if valid_case_shapes?(cases) do
      Enum.reduce(cases, errors, fn item, acc ->
        acc
        |> validate_case_fields(item)
        |> validate_case_references(item)
        |> validate_case_proof(item, receipt_path)
      end)
    else
      require(errors, false, "case entries must be objects")
    end
  end

  defp validate_cases(errors, _, _), do: errors

  defp validate_case_fields(errors, item) do
    errors
    |> validate_case_identity(item)
    |> validate_case_ownership(item)
    |> validate_case_source_identity(item)
    |> validate_case_input_identity(item)
    |> validate_case_supported_surface(item)
    |> validate_case_observation_presence(item)
  end

  defp validate_case_identity(errors, item) do
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
  end

  defp validate_case_ownership(errors, item) do
    require(
      errors,
      nonempty?(item["next_owner"]) and nonempty?(item["repro_owner"]) and
        nonempty?(item["regression_owner"]),
      "case proof and regression owners are required"
    )
  end

  defp validate_case_source_identity(errors, item) do
    source = Map.get(item, "source", %{})

    errors
    |> require(
      source["kind"] in ["repository_test", "repository_test_inventory"] and
        nonempty?(source["date"]) and full_sha?(source["source_sha"]),
      "case source identity and date are required"
    )
    |> require(
      String.match?(source["test_file_sha256"] || "", ~r/\A[0-9a-f]{64}\z/),
      "case test file checksum is required"
    )
  end

  defp validate_case_input_identity(errors, item) do
    input = Map.get(item, "input_identity", %{})
    source = Map.get(item, "source", %{})

    errors
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
  end

  defp validate_case_supported_surface(errors, item) do
    errors
    |> require(
      nonempty?(item["provider_identity"]) and nonempty?(item["supported_mount"]),
      "provider and mounted surface identity are required"
    )
    |> require(
      nonempty?(item["profile"]) and nonempty?(item["auth_mode"]) and
        nonempty?(item["safe_condition"]),
      "profile, auth mode and safe condition are required"
    )
  end

  defp validate_case_observation_presence(errors, item) do
    require(
      errors,
      is_list(item["observations"]) and item["observations"] != [],
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
      valid_reproduction_reference?(item, repro),
      "reproduction must be a named test, a controlled counterexample, or an explicit unresolved not-run boundary"
    )
    |> require(
      valid_normative_references?(item["normative_references"]),
      "normative references must be resolvable URLs"
    )
    |> require(
      valid_support_reference?(item["support_reference"]),
      "support reference must resolve"
    )
  end

  defp valid_reproduction_reference?(item, repro) do
    valid_named_test_reference?(repro) or valid_counterexample_reference?(item, repro) or
      valid_unresolved_reference?(item, repro)
  end

  defp valid_named_test_reference?(repro) do
    repro["status"] == "pass" and nonempty?(repro["command"]) and
      nonempty?(repro["test_path"]) and nonempty?(repro["test_name"]) and
      repro["evidence_kind"] == "repository_test" and existing_repo_file?(repro["test_path"])
  end

  defp valid_counterexample_reference?(item, repro) do
    valid_counterexample_identity?(item, repro) and valid_counterexample_controls?(repro) and
      valid_counterexample_projections?(repro)
  end

  defp valid_counterexample_identity?(item, repro) do
    repro["status"] == "counterexample" and item["cause"] == "protocol" and
      repro["evidence_kind"] == "controlled_http_probe" and
      nonempty?(repro["command"]) and nonempty?(repro["test_path"]) and
      nonempty?(repro["test_name"]) and existing_repo_file?(repro["test_path"])
  end

  defp valid_counterexample_controls?(repro) do
    nonempty?(repro["assertion_id"]) and repro["controls_passed"] == true and
      is_list(repro["control_ids"]) and repro["control_ids"] != [] and
      full_sha256?(repro["test_file_sha256"]) and nonempty?(repro["probe_observation_id"])
  end

  defp valid_counterexample_projections?(repro) do
    is_map(repro["expected_projection"]) and is_map(repro["observed_projection"]) and
      repro["expected_projection"] != repro["observed_projection"]
  end

  defp valid_unresolved_reference?(item, repro) do
    repro["status"] == "not_run" and item["cause"] == "unresolved" and
      repro["evidence_kind"] == "none" and nonempty?(repro["reason"])
  end

  defp valid_normative_references?(references) when is_list(references) and references != [],
    do: Enum.all?(references, &valid_url_reference?/1)

  defp valid_normative_references?(_), do: false

  defp valid_support_reference?(%{"path" => path}) when is_binary(path),
    do: existing_repo_file?(path)

  defp valid_support_reference?(_), do: false

  defp existing_repo_file?(path) when is_binary(path),
    do: File.exists?(Path.join(@repo_root, path))

  defp existing_repo_file?(_), do: false

  defp validate_case_proof(errors, item, receipt_path) do
    repro = Map.get(item, "repro", %{})
    obs = Map.get(item, "observations", [])
    proof = case_proof_status(item, repro, obs)

    errors
    |> require(
      proof.deterministic_pass or proof.controlled_counterexample or proof.unresolved_not_run,
      "only a deterministic pass, controlled normative counterexample, or explicit unresolved not-run case is valid"
    )
    |> require(
      source_revision_exists?(get_in(item, ["source", "source_sha"])),
      "case source SHA must resolve to a Git commit"
    )
    |> require(
      not proof.deterministic_pass or passing_repro_counts?(repro),
      "passing repro must record positive tests and zero failures"
    )
    |> validate_case_observations(item, repro, obs, proof)
    |> require(File.exists?(receipt_path), "accepted receipt must resolve")
  end

  defp case_proof_status(item, repro, observations) do
    deterministic_pass =
      repro["status"] == "pass" and
        repro["source_sha"] == get_in(item, ["source", "source_sha"]) and
        repro["evidence_kind"] == "repository_test"

    controlled_counterexample = valid_controlled_counterexample?(item, repro)
    unresolved_not_run = valid_unresolved_not_run?(item, repro, observations)

    %{
      deterministic_pass: deterministic_pass,
      controlled_counterexample: controlled_counterexample,
      unresolved_not_run: unresolved_not_run,
      assertion_id: repro["assertion_id"],
      probe_observation_id: repro["probe_observation_id"]
    }
  end

  defp valid_controlled_counterexample?(item, repro) do
    valid_counterexample_result?(item, repro) and
      valid_counterexample_counts?(repro) and probe_counterexample_matches?(item, repro)
  end

  defp valid_counterexample_result?(item, repro) do
    repro["status"] == "counterexample" and item["cause"] == "protocol" and
      repro["source_sha"] == get_in(item, ["source", "source_sha"]) and
      repro["evidence_kind"] == "controlled_http_probe" and
      repro["controls_passed"] == true and nonempty?(repro["assertion_id"])
  end

  defp valid_counterexample_counts?(repro) do
    is_integer(repro["test_count"]) and repro["test_count"] > 0 and
      is_integer(repro["failure_count"]) and repro["failure_count"] > 0
  end

  defp valid_unresolved_not_run?(item, repro, observations) do
    repro["status"] == "not_run" and item["cause"] == "unresolved" and
      all_maps?(observations) and Enum.all?(observations, &(&1["status"] == "not_observed"))
  end

  defp passing_repro_counts?(repro) do
    is_integer(repro["test_count"]) and repro["test_count"] > 0 and
      repro["failure_count"] == 0
  end

  defp validate_case_observations(errors, item, repro, observations, proof) do
    errors
    |> require(
      is_list(observations) and
        Enum.all?(observations, &valid_observation_identity?(&1, item, proof)),
      "observations must retain their own source, input, and outcome identities"
    )
    |> require(
      observations_match_result?(observations, repro, proof),
      "observations must support the current result at its own source identity"
    )
    |> require(
      observation_ids_unique?(observations),
      "observation IDs must be unique within a case"
    )
  end

  defp valid_observation_identity?(observation, item, proof) when is_map(observation) do
    nonempty?(observation["observation_id"]) and
      observation["condition_id"] == item["condition_id"] and
      full_sha?(observation["source_sha"]) and source_revision_exists?(observation["source_sha"]) and
      nonempty?(observation["input_identity"]) and observation["date"] != nil and
      observation["status"] in ["pass", "not_observed", "counterexample"] and
      valid_counterexample_observation?(observation, item, proof)
  end

  defp valid_observation_identity?(_, _, _), do: false

  defp valid_counterexample_observation?(observation, item, proof) do
    if observation["status"] == "counterexample" do
      proof.controlled_counterexample and probe_observation_resolves?(item["id"], observation)
    else
      true
    end
  end

  defp observations_match_result?(observations, repro, proof) when is_list(observations) do
    if all_maps?(observations) do
      cond do
        proof.deterministic_pass ->
          Enum.all?(observations, &(&1["status"] == "pass"))

        proof.controlled_counterexample ->
          current_counterexample_present?(observations, repro)

        proof.unresolved_not_run ->
          true

        true ->
          false
      end
    else
      false
    end
  end

  defp observations_match_result?(_, _, _), do: false

  defp current_counterexample_present?(observations, repro) do
    Enum.any?(observations, fn observation ->
      observation["status"] == "counterexample" and
        observation["assertion_id"] == repro["assertion_id"] and
        observation["probe_observation_id"] == repro["probe_observation_id"]
    end)
  end

  defp observation_ids_unique?(observations) when is_list(observations) do
    if all_maps?(observations) do
      ids = Enum.map(observations, & &1["observation_id"])
      length(ids) == length(Enum.uniq(ids))
    else
      false
    end
  end

  defp observation_ids_unique?(_), do: false

  defp valid_url_reference?(%{"url" => url, "section" => section}),
    do: is_binary(url) and String.starts_with?(url, "https://") and nonempty?(section)

  defp valid_url_reference?(_), do: false

  defp probe_counterexample_matches?(item, repro) do
    path = Path.join(@phase_dir, "171-QUALIFICATION-PROBE.json")

    with {:ok, body} <- File.read(path),
         {:ok, probe} <- Jason.decode(body),
         result when is_map(result) <- find_probe_case(probe, item["id"]) do
      probe_source_matches?(probe, repro) and probe_execution_matches?(probe, repro) and
        probe_result_matches?(result, repro)
    else
      _ -> false
    end
  end

  defp find_probe_case(%{"cases" => cases}, case_id) when is_list(cases) do
    Enum.find(cases, fn item -> is_map(item) and item["case_id"] == case_id end)
  end

  defp find_probe_case(_, _), do: nil

  defp probe_source_matches?(probe, repro) do
    source = probe["source_identity"]

    is_map(source) and probe["observation_id"] == repro["probe_observation_id"] and
      source["source_sha_before"] == repro["source_sha"] and
      source["source_sha_after"] == repro["source_sha"] and
      source["changed_during_observation"] == false and
      source["probe_sha256"] == repro["test_file_sha256"]
  end

  defp probe_execution_matches?(probe, repro) do
    execution = probe["execution"]

    is_map(execution) and execution["mix_exit_code"] == 2 and
      execution["test_count"] == repro["test_count"] and
      execution["failure_count"] == repro["failure_count"]
  end

  defp probe_result_matches?(result, repro) do
    controls = result["controls"]

    result["assertion_id"] == repro["assertion_id"] and
      result["expected_projection"] == repro["expected_projection"] and
      result["observed_projection"] == repro["observed_projection"] and
      result["protocol_assertion_status"] == "counterexample" and is_list(controls) and
      controls != [] and Enum.all?(controls, &(is_map(&1) and &1["status"] == "pass"))
  end

  defp probe_observation_resolves?(case_id, observation) do
    @phase_dir
    |> Path.join("171-QUALIFICATION-PROBE*.json")
    |> Path.wildcard()
    |> Enum.any?(&probe_file_matches_observation?(&1, case_id, observation))
  end

  defp probe_file_matches_observation?(path, case_id, observation) do
    with {:ok, body} <- File.read(path),
         {:ok, probe} when is_map(probe) <- Jason.decode(body),
         result when is_map(result) <- find_probe_case(probe, case_id) do
      source = probe["source_identity"]

      is_map(source) and probe["observation_id"] == observation["probe_observation_id"] and
        source["source_sha_before"] == observation["source_sha"] and
        source["source_sha_after"] == observation["source_sha"] and
        source["changed_during_observation"] == false and
        source["probe_sha256"] == observation["probe_sha256"] and
        result["protocol_assertion_status"] == "counterexample" and
        result["assertion_id"] == observation["assertion_id"] and
        probe_controls_passed?(result["controls"])
    else
      _ -> false
    end
  end

  defp probe_controls_passed?(controls) when is_list(controls) and controls != [] do
    Enum.all?(controls, &(is_map(&1) and &1["status"] == "pass"))
  end

  defp probe_controls_passed?(_), do: false

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
