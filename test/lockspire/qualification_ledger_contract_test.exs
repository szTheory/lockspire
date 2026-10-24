defmodule Lockspire.QualificationLedgerContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @phase_dir Path.join(@repo_root, ".planning/phases/171-accepted-baseline-finding-qualification")
  @ledger_path Path.join(@phase_dir, "171-QUALIFICATION.json")

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
      |> Map.put("cases", [])
      |> Map.put("selection_status", "empty_requires_replan")
      |> put_in(["matrix", "rows"], [])
      |> put_in(["scope_revision", "required"], true)
      |> put_in(
        ["scope_revision", "rationale"],
        "Synthetic empty fixture requires an explicit scope review."
      )
      |> update_in(["category_coverage"], fn categories ->
        Enum.map(categories, &%{&1 | "case_ids" => [], "status" => "excluded_fixture"})
      end)

    assert validate(empty) == []
    assert_rejected(put_in(empty, ["scope_revision", "rationale"], nil))
    assert_rejected(%{empty | "selection_status" => "draft"})
    assert_rejected(put_in(empty, ["scope_revision", "required"], false))
  end

  test "a valid single case and matrix row remain admissible" do
    ledger = load_ledger()
    [item | _] = ledger["cases"]

    single =
      ledger
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

    assert validate(repeated) == []
    assert get_in(repeated, ["cases", Access.at(0), "id"]) == "A171-001"
  end

  test "unresolved conditions stay explicit and interrupted or suite-level results cannot prove a case" do
    ledger = load_ledger()
    assert get_in(ledger, ["cases", Access.at(2), "cause"]) == "unresolved"
    assert get_in(ledger, ["cases", Access.at(2), "repro", "status"]) == "not_run"

    interrupted =
      ledger
      |> put_in(["cases", Access.at(0), "repro", "status"], "interrupted")
      |> put_in(["cases", Access.at(0), "repro", "result"], "interrupted")

    assert_rejected(interrupted)

    external =
      put_in(ledger, ["cases", Access.at(0), "repro", "evidence_kind"], "external_suite_run")

    assert_rejected(external)
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
      ledger["selection_status"] in ["draft", "selected", "empty_requires_replan"],
      "selection_status is invalid"
    )
    |> require(
      is_list(ledger["profiles"]) and length(ledger["profiles"]) == 2,
      "both profile observations are required"
    )
    |> require(is_list(cases), "cases must be an array, not null")
    |> require(is_map(ledger["matrix"]), "matrix must be an object")
    |> require(ledger["matrix"]["status"] == "draft", "matrix status must be draft")
    |> require(is_list(rows), "matrix rows must be an array, not null")
    |> require(
      ledger["matrix"]["requirement_dispositions"] == [],
      "draft requirement dispositions must be empty"
    )
    |> require(is_list(ledger["blockers"]), "blockers must be an array")
    |> require(is_list(ledger["exclusions"]), "exclusions must be an array")
    |> validate_selection_state(ledger, cases)
    |> validate_baseline(baseline, receipt_path, receipt_override)
    |> validate_profiles(ledger["profiles"])
    |> validate_case_ids(cases, rows)
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
          ledger["selection_status"] == "empty_requires_replan",
          "empty case set requires a replan marker"
        )
        |> require(
          revision["required"] == true and nonempty?(revision["rationale"]),
          "empty case set requires scope-revision rationale"
        )
        |> require(
          Enum.all?(Map.get(ledger, "category_coverage", []), &(&1["case_ids"] == [])),
          "empty case set requires explicit category exclusions"
        )

      true ->
        errors
        |> require(
          ledger["selection_status"] in ["draft", "selected"],
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
        (repro["status"] == "not_run" and item["cause"] == "unresolved" and
           repro["evidence_kind"] == "none" and nonempty?(repro["reason"])),
      "reproduction must be a named repository test or an explicit unresolved not-run boundary"
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

    unresolved_not_run =
      repro["status"] == "not_run" and item["cause"] == "unresolved" and
        is_list(obs) and Enum.all?(obs, &(&1["status"] == "not_observed"))

    errors
    |> require(
      deterministic_pass or unresolved_not_run,
      "only a deterministic source-host pass or explicit unresolved not-run case is valid"
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
            observation["source_sha"] == item["source"]["source_sha"] and
            nonempty?(observation["input_identity"]) and observation["date"] != nil and
            observation["status"] == if(deterministic_pass, do: "pass", else: "not_observed")
        end),
      "observations must retain stable condition, source, and outcome identities"
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
  defp require(errors, true, _message), do: errors
  defp require(errors, false, message), do: [message | errors]
  defp full_sha?(value), do: is_binary(value) and String.match?(value, ~r/\A[0-9a-f]{40}\z/)
  defp nonempty?(value), do: is_binary(value) and String.trim(value) != ""

  defp source_revision_exists?(sha) when is_binary(sha) do
    case System.cmd("git", ["cat-file", "-e", "#{sha}^{commit}"], cd: @repo_root) do
      {_, 0} -> true
      _ -> false
    end
  end

  defp source_revision_exists?(_), do: false
end
