defmodule Lockspire.QualificationLedgerContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @phase_dir Path.join(@repo_root, ".planning/phases/171-accepted-baseline-finding-qualification")
  @ledger_path Path.join(@phase_dir, "171-QUALIFICATION.json")

  test "the phase qualification ledger exists and its evidence references resolve" do
    assert File.exists?(@ledger_path),
           "qualification ledger is required; missing ledger cannot be skipped"

    ledger = @ledger_path |> File.read!() |> Jason.decode!()

    assert validate(ledger) == []
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

  test "the contract rejects duplicate cases and ownerless evidence" do
    ledger = load_ledger()
    [item] = ledger["cases"]

    assert_rejected(%{ledger | "cases" => [item, item]})
    assert_rejected(update_in(ledger, ["cases", Access.at(0), "next_owner"], fn _ -> "" end))

    assert_rejected(
      update_in(ledger, ["cases", Access.at(0), "regression_owner"], fn _ -> nil end)
    )
  end

  test "the contract rejects missing observed-versus-expected evidence" do
    ledger = load_ledger()

    assert_rejected(
      update_in(ledger, ["cases", Access.at(0), "observed_outcome"], fn _ -> "" end)
    )

    assert_rejected(
      update_in(ledger, ["cases", Access.at(0), "expected_outcome"], fn _ -> "" end)
    )

    equal_outcomes =
      update_in(ledger, ["cases", Access.at(0), "expected_outcome"], fn _ ->
        get_in(ledger, ["cases", Access.at(0), "observed_outcome"])
      end)

    assert validate(equal_outcomes) == []
  end

  test "the contract does not accept an external suite run as source-host case proof" do
    ledger = load_ledger()

    external_evidence =
      update_in(ledger, ["cases", Access.at(0), "repro", "evidence_kind"], fn _ ->
        "external_suite_run"
      end)

    assert_rejected(external_evidence)
  end

  defp load_ledger, do: @ledger_path |> File.read!() |> Jason.decode!()

  defp load_receipt(ledger) do
    ledger["baseline"]["receipt_ref"]
    |> then(&Path.join(@repo_root, &1))
    |> File.read!()
    |> Jason.decode!()
  end

  defp assert_rejected(ledger, receipt_override \\ nil) do
    assert validate(ledger, receipt_override) != []
  end

  defp validate(ledger, receipt_override \\ nil) do
    baseline = Map.get(ledger, "baseline", %{})
    cases = Map.get(ledger, "cases", [])
    receipt_path = Path.join(@repo_root, baseline["receipt_ref"] || "")

    []
    |> require(ledger["schema_version"] == 1, "schema_version must be 1")
    |> require(ledger["phase"] == 171, "phase must be 171")
    |> require(ledger["selection_status"] == "draft", "selection_status must remain draft")
    |> require(is_list(ledger["profiles"]), "profiles must be an array")
    |> require(is_list(cases) and cases != [], "cases must contain a qualified case")
    |> require(is_map(ledger["matrix"]), "matrix must be an object")
    |> require(ledger["matrix"]["status"] == "draft", "matrix status must be draft")
    |> require(ledger["matrix"]["rows"] == [], "draft matrix rows must be empty")
    |> require(
      ledger["matrix"]["requirement_dispositions"] == [],
      "draft requirement dispositions must be empty"
    )
    |> require(is_list(ledger["blockers"]), "blockers must be an array")
    |> require(is_list(ledger["exclusions"]), "exclusions must be an array")
    |> validate_baseline(baseline, receipt_path, receipt_override)
    |> validate_case_ids(cases)
    |> validate_cases(cases, receipt_path)
  end

  defp validate_baseline(errors, baseline, receipt_path, receipt_override) do
    receipt =
      cond do
        is_map(receipt_override) -> receipt_override
        File.exists?(receipt_path) -> receipt_path |> File.read!() |> Jason.decode!()
        true -> %{}
      end

    receipt_sha256 =
      if File.exists?(receipt_path) do
        receipt_path
        |> File.read!()
        |> then(&:crypto.hash(:sha256, &1))
        |> Base.encode16(case: :lower)
      end

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

  defp validate_case_ids(errors, cases) do
    ids = Enum.map(cases, & &1["id"])
    require(errors, length(ids) == length(Enum.uniq(ids)), "case IDs must be unique")
  end

  defp validate_cases(errors, cases, receipt_path) do
    Enum.reduce(cases, errors, fn item, acc ->
      acc
      |> validate_case_fields(item)
      |> validate_case_references(item)
      |> validate_case_proof(item, receipt_path)
    end)
  end

  defp validate_case_fields(errors, item) do
    source = Map.get(item, "source", %{})

    errors
    |> require(nonempty?(item["id"]), "case id is required")
    |> require(nonempty?(item["family"]), "case family is required")
    |> require(
      is_list(item["requirement_ids"]) and item["requirement_ids"] != [],
      "case requirement_ids are required"
    )
    |> require(nonempty?(item["observed_outcome"]), "case observed_outcome is required")
    |> require(nonempty?(item["expected_outcome"]), "case expected_outcome is required")
    |> require(nonempty?(item["cause"]), "case cause is required")
    |> require(
      nonempty?(item["next_owner"]) and nonempty?(item["regression_owner"]),
      "case owners are required"
    )
    |> require(full_sha?(item["source_sha"]), "case source_sha must be a full lowercase SHA")
    |> require(
      source["kind"] == "repository" and nonempty?(source["date"]),
      "case source identity and date are required"
    )
    |> require(nonempty?(item["provider_identity"]), "provider_identity is required")
    |> require(
      nonempty?(item["supported_mount"]) and nonempty?(item["profile"]) and
        nonempty?(item["auth_mode"]),
      "supported mount, profile, and auth mode are required"
    )
    |> require(nonempty?(item["safe_condition"]), "safe_condition is required")
    |> require(nonempty?(item["disposition"]), "case disposition is required")
  end

  defp validate_case_references(errors, item) do
    errors
    |> validate_case_run_references(item)
    |> validate_case_support_references(item)
    |> validate_case_scope_labels(item)
  end

  defp validate_case_run_references(errors, item) do
    repro = Map.get(item, "repro", %{})
    input = Map.get(item, "input_reference", %{})

    errors
    |> require(nonempty?(item["run_reference"]), "run reference is required")
    |> require(
      nonempty?(input["test_path"]) and nonempty?(input["request"]),
      "input reference must identify the test and input"
    )
    |> require(
      nonempty?(repro["command"]) and nonempty?(repro["test_path"]) and
        nonempty?(repro["test_name"]),
      "reproduction command and named test are required"
    )
    |> require(
      repro["evidence_kind"] == "repository_test",
      "deterministic case proof must be a repository test"
    )
    |> require(
      File.exists?(Path.join(@repo_root, repro["test_path"] || "")),
      "reproduction test path must resolve"
    )
  end

  defp validate_case_support_references(errors, item) do
    source = Map.get(item, "source", %{})
    normative = Map.get(item, "normative_references", [])
    support = Map.get(item, "support_reference", %{})

    errors
    |> require(
      nonempty?(source["historical_availability"]),
      "historical availability must be stated"
    )
    |> require(
      is_list(normative) and normative != [] and Enum.all?(normative, &valid_url_reference?/1),
      "normative references must be resolvable URLs"
    )
    |> require(
      is_binary(support["path"]) and File.exists?(Path.join(@repo_root, support["path"])),
      "support reference must resolve"
    )
  end

  defp validate_case_scope_labels(errors, item) do
    external = Map.get(item, "external_run", %{})
    package = Map.get(item, "package_receipt", %{})

    errors
    |> require(
      external["status"] == "not_applicable" and nonempty?(external["reason"]),
      "external suite evidence must be explicitly not applicable"
    )
    |> require(
      package["status"] == "not_applicable" and nonempty?(package["reason"]),
      "package evidence must be explicitly not applicable"
    )
  end

  defp validate_case_proof(errors, item, receipt_path) do
    repro = Map.get(item, "repro", %{})

    errors
    |> require(
      repro["result"] == "pass" and repro["source_sha"] == item["source_sha"],
      "reproduction result and source identity must match"
    )
    |> require(
      source_revision_exists?(item["source_sha"]),
      "case source SHA must resolve to a Git commit"
    )
    |> require(
      is_integer(repro["test_count"]) and repro["test_count"] > 0,
      "reproduction must have a positive test count"
    )
    |> require(repro["failure_count"] == 0, "reproduction must have zero failures")
    |> require(File.exists?(receipt_path), "accepted receipt must resolve")
  end

  defp valid_url_reference?(%{"url" => url, "section" => section}) do
    is_binary(url) and String.starts_with?(url, "https://") and nonempty?(section)
  end

  defp valid_url_reference?(_), do: false

  defp require(errors, true, _message), do: errors
  defp require(errors, false, message), do: [message | errors]

  defp full_sha?(value), do: is_binary(value) and String.match?(value, ~r/\A[0-9a-f]{40}\z/)
  defp nonempty?(value), do: is_binary(value) and String.trim(value) != ""

  defp source_revision_exists?(sha) do
    case System.cmd("git", ["cat-file", "-e", "#{sha}^{commit}"], cd: @repo_root) do
      {_, 0} -> true
      _ -> false
    end
  end
end
