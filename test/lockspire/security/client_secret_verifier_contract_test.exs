defmodule Lockspire.Security.ClientSecretVerifierContract do
  @moduledoc false

  @bound_integer_fields ~w(
    max_secret_bytes max_client_id_bytes max_key_id_bytes key_bytes iv_bytes tag_bytes
    payload_prefix_bytes migrated_age_suffix_bytes max_plaintext_bytes max_payload_bytes
    max_payload_base64url_unpadded_bytes max_envelope_bytes
  )

  @historical_metadata_source_files MapSet.new(~w(
    test/lockspire/security/client_secret_verifier_compatibility_test.exs
    test/support/client_secret_verifier_fixtures.ex
  ))

  @current_qualification_source_files MapSet.new(~w(
    test/integration/client_secret_jwt_legacy_age_test.exs
    test/lockspire/security/client_secret_verifier_compatibility_test.exs
    test/support/client_secret_verifier_fixtures.ex
  ))

  @fixed_bounds %{
    "max_secret_bytes" => 1_048_576,
    "max_client_id_bytes" => 1_048_576,
    "max_key_id_bytes" => 32,
    "key_bytes" => 32,
    "iv_bytes" => 12,
    "tag_bytes" => 16,
    "payload_prefix_bytes" => 6,
    "migrated_age_suffix_bytes" => 16
  }

  @maintenance_exact_fields %{
    "capability" => "Lockspire.Storage.ClientVerifierMaintenance",
    "authority_callback" => "verifier_maintenance_contract/0",
    "inventory_callback" => "verifier_inventory_page(after_client_id, limit)",
    "rewrap_callback" =>
      "compare_and_rewrap(client_id, expected_client_secret_hash, expected_verifier, replacement_verifier, audit_attrs)",
    "status" => "contract-only; behavior and adapter composition evidence pending Phase 177/178"
  }

  @maintenance_phrases [
    {"authority_return", "participants: %{client_store: module()"},
    {"inventory_args", "limit integer 1..500"},
    {"inventory_args", "default 100"},
    {"inventory_return", ":client_secret_verifier_inventory_invalid_limit"},
    {"authority_rule", "fails before inventory or mutation"},
    {"authority_rule", "corresponding entries"},
    {"selection", "never defaulted to Repository"},
    {"inventory_order", "cursor exclusive"},
    {"inventory_order", "empty inventory is [], nil, true"},
    {"inventory_scope", "every persisted client"},
    {"inventory_consistency", "not a database snapshot"},
    {"rewrap_atomicity", "already-open transaction"},
    {"rewrap_atomicity", "provisional until outer commit"},
    {"rewrap_atomicity", "audit failure rolls back update"},
    {"rewrap_atomicity", "never use direct Repository fallback"},
    {"rewrap_preserves", "updated_at"}
  ]

  @required_cases ~w(
    LEG175-AGED-23H
    LEG175-AGED-2D
    LEG175-FUTURE
    LEG175-METADATA-SHAPES
    LEG175-HASH-MISMATCH
    LEG175-METADATA-FUTURE-READINESS
    LEGACY-AGE-BOUNDARIES
    LEGACY-UNSUPPORTED-INPUTS
    CONFIG-ABSENT-LEGACY
    CONFIG-STAGED-READERS
    CONFIG-DEDICATED-WRITES-ALLOW
    CONFIG-DEDICATED-WRITES-REJECT
    CONFIG-INVALID-PRESENT
    CONFIG-CONTRADICTION-AND-READER-ONLY
    KEY-SET-GRAMMAR
    ENVELOPE-FORMAT
    ENVELOPE-STRICT-REJECTION
    MATERIAL-BOUNDS-AND-API-SCOPE
    WRITERS-FINAL-ID-AND-HANDOFF
    READERS-AND-AUTH-EXCLUSIONS
    WRITER-DIRECT-REGISTRATION
    WRITER-DCR
    WRITER-OPERATOR-ROTATION
    WRITER-HASH-ONLY-HELPER
    READER-TOKEN-EXCHANGE
    READER-INTROSPECTION-REVOCATION
    READER-PAR-DEVICE-CIBA
    READER-HS256-AUDIENCE-JTI-EXCLUSIONS
    MAINTENANCE-CAPABILITY-AUTHORITY
    MAINTENANCE-INVENTORY-PAGING
    MAINTENANCE-INVENTORY-READINESS
    MAINTENANCE-ATOMIC-CAS-AND-PRESERVATION
    MAINTENANCE-RACE-AND-ROLLBACK
    MAINTENANCE-INTERRUPTED-RESUME-IDEMPOTENCE-RECOVERY
    ROLLOUT-READER-FIRST-ROLLBACK-RETIREMENT
    DISCLOSURE-SENTINELS
    PACKAGES-ADAPTER-DELIVERY
  )

  @required_fields ~w(
    case_id requirement caller lifecycle stage storage operation expected mutation
    preserves redaction owner_phase evidence status blocking
  )

  @owners %{
    "LEG175-AGED-23H" => 175,
    "LEG175-AGED-2D" => 175,
    "LEG175-FUTURE" => 175,
    "LEG175-METADATA-SHAPES" => 175,
    "LEG175-HASH-MISMATCH" => 175,
    "LEG175-METADATA-FUTURE-READINESS" => 175,
    "LEGACY-AGE-BOUNDARIES" => 176,
    "LEGACY-UNSUPPORTED-INPUTS" => 176,
    "CONFIG-ABSENT-LEGACY" => 176,
    "CONFIG-STAGED-READERS" => 176,
    "CONFIG-DEDICATED-WRITES-ALLOW" => 176,
    "CONFIG-DEDICATED-WRITES-REJECT" => 176,
    "CONFIG-INVALID-PRESENT" => 176,
    "CONFIG-CONTRADICTION-AND-READER-ONLY" => 176,
    "KEY-SET-GRAMMAR" => 176,
    "ENVELOPE-FORMAT" => 176,
    "ENVELOPE-STRICT-REJECTION" => 176,
    "MATERIAL-BOUNDS-AND-API-SCOPE" => 176,
    "WRITERS-FINAL-ID-AND-HANDOFF" => 176,
    "READERS-AND-AUTH-EXCLUSIONS" => 176,
    "WRITER-DIRECT-REGISTRATION" => 176,
    "WRITER-DCR" => 176,
    "WRITER-OPERATOR-ROTATION" => 176,
    "WRITER-HASH-ONLY-HELPER" => 176,
    "READER-TOKEN-EXCHANGE" => 176,
    "READER-INTROSPECTION-REVOCATION" => 176,
    "READER-PAR-DEVICE-CIBA" => 176,
    "READER-HS256-AUDIENCE-JTI-EXCLUSIONS" => 176,
    "MAINTENANCE-CAPABILITY-AUTHORITY" => 177,
    "MAINTENANCE-INVENTORY-PAGING" => 177,
    "MAINTENANCE-INVENTORY-READINESS" => 177,
    "MAINTENANCE-ATOMIC-CAS-AND-PRESERVATION" => 177,
    "MAINTENANCE-RACE-AND-ROLLBACK" => 177,
    "MAINTENANCE-INTERRUPTED-RESUME-IDEMPOTENCE-RECOVERY" => 177,
    "ROLLOUT-READER-FIRST-ROLLBACK-RETIREMENT" => 177,
    "DISCLOSURE-SENTINELS" => 177,
    "PACKAGES-ADAPTER-DELIVERY" => 178
  }

  def validate(ledger, qualification, summary)
      when is_map(ledger) and is_map(qualification) and is_binary(summary) do
    cases = Map.get(ledger, "cases", [])

    if Enum.any?(cases, &(not is_map(&1))) do
      {:error, :invalid_case}
    else
      validate_cases(ledger, qualification, summary, cases)
    end
  end

  def validate(_ledger, _qualification, _summary), do: {:error, :invalid_ledger}

  defp validate_cases(ledger, qualification, summary, cases) do
    ids = Enum.map(cases, &Map.get(&1, "case_id"))

    caller_ids =
      qualification
      |> get_in(["persisted_caller", "cases"])
      |> Map.keys()
      |> MapSet.new()

    metadata_ids =
      (get_in(qualification, ["metadata_reader", "evidence_cases"]) ++
         get_in(qualification, ["compatibility_tests", "case_ids"]))
      |> MapSet.new()

    metadata_commit_short =
      case Regex.run(~r/\*\*Task 2:.*?`([0-9a-f]{7,40})`/s, summary) do
        [_, sha] -> sha
        _ -> nil
      end

    metadata_source_sha = get_in(qualification, ["compatibility_tests", "tested_source_sha"])

    checks = [
      fn -> validate_case_ids(ids) end,
      fn -> validate_required_cases(ids) end,
      fn -> validate_fields(cases) end,
      fn -> validate_owners(cases) end,
      fn ->
        validate_evidence_rows(
          cases,
          caller_ids,
          metadata_ids,
          metadata_commit_short,
          metadata_source_sha,
          qualification
        )
      end,
      fn -> validate_bounds(Map.get(ledger, "format_bounds")) end,
      fn -> validate_maintenance_contract(Map.get(ledger, "maintenance_contract")) end,
      fn -> validate_qualified_inputs(ledger, qualification) end,
      fn -> validate_anchor(cases, qualification) end
    ]

    run_checks(checks)
  end

  defp run_checks(checks) do
    Enum.reduce_while(checks, :ok, fn check, :ok ->
      case check.() do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_case_ids(ids) do
    cond do
      Enum.any?(ids, &(not is_binary(&1))) -> {:error, :missing_case_id}
      length(ids) != length(Enum.uniq(ids)) -> {:error, :duplicate_case_id}
      true -> :ok
    end
  end

  defp validate_required_cases(ids) do
    case Enum.find(@required_cases, &(&1 not in ids)) do
      nil -> :ok
      missing -> {:error, {:missing_case, missing}}
    end
  end

  defp validate_fields(cases) do
    case Enum.find(cases, &(not valid_fields?(&1))) do
      nil -> :ok
      invalid -> {:error, {:missing_fields, invalid["case_id"]}}
    end
  end

  defp validate_owners(cases) do
    case Enum.find(cases, &(not valid_owner?(&1))) do
      nil -> :ok
      invalid -> {:error, {:wrong_owner, invalid["case_id"]}}
    end
  end

  defp validate_evidence_rows(cases, caller_ids, metadata_ids, commit, source, qualification) do
    predicate = fn row ->
      valid_evidence?(row, caller_ids, metadata_ids, commit, source, qualification)
    end

    case Enum.find(cases, &(not predicate.(&1))) do
      nil -> :ok
      invalid -> {:error, {:invalid_evidence, invalid["case_id"]}}
    end
  end

  defp validate_bounds(bounds) do
    if valid_bounds?(bounds), do: :ok, else: {:error, :invalid_format_bounds}
  end

  defp validate_maintenance_contract(contract) do
    if valid_maintenance_contract?(contract),
      do: :ok,
      else: {:error, :invalid_maintenance_contract}
  end

  defp validate_qualified_inputs(ledger, qualification) do
    if valid_qualified_inputs?(ledger, qualification),
      do: :ok,
      else: {:error, :invalid_qualified_inputs}
  end

  defp validate_anchor(cases, qualification) do
    if qualified_anchor?(cases, qualification), do: :ok, else: {:error, :missing_qualified_anchor}
  end

  defp valid_fields?(row), do: Enum.all?(@required_fields, &Map.has_key?(row, &1))

  defp valid_owner?(%{"case_id" => id, "owner_phase" => owner}), do: Map.get(@owners, id) == owner
  defp valid_owner?(_row), do: false

  defp valid_evidence?(
         %{"status" => "qualified", "owner_phase" => 175, "evidence" => evidence},
         caller_ids,
         metadata_ids,
         metadata_commit_short,
         metadata_source_sha,
         qualification
       ) do
    evidence["status"] == "pass" and
      qualified_source?(
        evidence,
        caller_ids,
        metadata_ids,
        metadata_commit_short,
        metadata_source_sha,
        qualification
      )
  end

  defp valid_evidence?(
         %{"status" => "pending", "owner_phase" => owner, "evidence" => evidence},
         _caller_ids,
         _metadata_ids,
         _commit,
         _source,
         _qualification
       )
       when owner in [176, 177, 178],
       do: pending_evidence?(evidence)

  defp valid_evidence?(
         _row,
         _caller_ids,
         _metadata_ids,
         _metadata_commit_short,
         _metadata_source_sha,
         _qualification
       ),
       do: false

  defp qualified_source?(evidence, caller_ids, metadata_ids, commit, source, qualification) do
    ids = evidence["ids"]
    source_sha = evidence["source_sha"]

    (ids_in_set?(ids, caller_ids) and source_sha == qualification["tested_checkout_head"]) or
      metadata_source?(ids, metadata_ids, source_sha, commit, source) or
      current_source?(ids, source_sha, qualification["current_qualification_sources"])
  end

  defp ids_in_set?(ids, set) when is_list(ids) and ids != [],
    do: Enum.all?(ids, &MapSet.member?(set, &1))

  defp ids_in_set?(_ids, _set), do: false

  defp metadata_source?(ids, metadata_ids, source_sha, commit, metadata_source) do
    ids_in_set?(ids, metadata_ids) and is_binary(commit) and source_sha == metadata_source and
      String.starts_with?(source_sha, commit)
  end

  defp current_source?(ids, source_sha, %{
         "status" => "qualified",
         "tested_source_sha" => tested_source_sha,
         "case_ids" => case_ids
       }) do
    ids_in_set?(ids, MapSet.new(case_ids)) and source_sha == tested_source_sha
  end

  defp current_source?(_ids, _source_sha, _current_sources), do: false

  defp pending_evidence?(evidence) do
    evidence["status"] == "pending" and evidence["ids"] == [] and
      is_nil(evidence["source_sha"])
  end

  defp valid_bounds?(bounds) when is_map(bounds) do
    integer_bounds?(bounds) and fixed_bounds?(bounds) and derived_bounds?(bounds) and
      bounds["reserved_family_prefix"] == "LSCV"
  end

  defp valid_bounds?(_bounds), do: false

  defp integer_bounds?(bounds),
    do: Enum.all?(@bound_integer_fields, &is_integer(Map.get(bounds, &1)))

  defp fixed_bounds?(bounds),
    do: Enum.all?(@fixed_bounds, fn {key, value} -> Map.get(bounds, key) == value end)

  defp derived_bounds?(bounds) do
    secret = bounds["max_secret_bytes"]
    client_id = bounds["max_client_id_bytes"]
    kid = bounds["max_key_id_bytes"]
    prefix = bounds["payload_prefix_bytes"]
    age = bounds["migrated_age_suffix_bytes"]
    iv = bounds["iv_bytes"]
    tag = bounds["tag_bytes"]
    plaintext = bounds["max_plaintext_bytes"]
    payload = bounds["max_payload_bytes"]
    encoded = bounds["max_payload_base64url_unpadded_bytes"]
    envelope = bounds["max_envelope_bytes"]

    plaintext == secret + prefix + age and payload == plaintext + iv + tag and
      encoded == div(payload * 8 + 5, 6) and envelope == 6 + kid + 1 + encoded and
      client_id == secret
  end

  defp valid_maintenance_contract?(contract) when is_map(contract) do
    exact_maintenance_fields?(contract) and maintenance_phrases_present?(contract)
  end

  defp valid_maintenance_contract?(_contract), do: false

  defp exact_maintenance_fields?(contract),
    do:
      Enum.all?(@maintenance_exact_fields, fn {key, value} -> Map.get(contract, key) == value end)

  defp maintenance_phrases_present?(contract) do
    Enum.all?(@maintenance_phrases, fn {key, phrase} ->
      is_binary(Map.get(contract, key)) and String.contains?(Map.get(contract, key), phrase)
    end)
  end

  defp valid_qualified_inputs?(ledger, qualification) do
    inputs = ledger["qualified_input"]

    inputs["persisted_caller_tested_sha"] == qualification["tested_checkout_head"] and
      inputs["metadata_reader_tested_sha"] ==
        get_in(qualification, ["metadata_reader", "tested_source_sha"]) and
      inputs["metadata_reader_tested_sha"] ==
        get_in(qualification, ["compatibility_tests", "tested_source_sha"]) and
      valid_historical_metadata_sources?(qualification) and
      valid_current_qualification_sources?(qualification["current_qualification_sources"])
  end

  defp valid_historical_metadata_sources?(qualification) do
    metadata_reader = Map.get(qualification, "metadata_reader")
    compatibility_tests = Map.get(qualification, "compatibility_tests")
    history = get_in(qualification, ["qualification_history", "metadata_reader_e8"])

    if is_map(metadata_reader) and is_map(compatibility_tests) and is_map(history) do
      historical_metadata_sources_match?(metadata_reader, compatibility_tests, history)
    else
      false
    end
  end

  defp historical_metadata_sources_match?(metadata_reader, compatibility_tests, history) do
    historical_source_identity?(metadata_reader, compatibility_tests, history) and
      historical_source_manifests?(metadata_reader, compatibility_tests, history)
  end

  defp historical_source_identity?(metadata_reader, compatibility_tests, history) do
    metadata_reader["status"] == "qualified" and
      metadata_reader["tested_source_sha"] == "e8aa26f587e1f12ea7722acea9de42188a3a7e6c" and
      compatibility_tests["tested_source_sha"] == metadata_reader["tested_source_sha"] and
      history["tested_source_sha"] == metadata_reader["tested_source_sha"] and
      history["status"] == "historical_qualified"
  end

  defp historical_source_manifests?(metadata_reader, compatibility_tests, history) do
    reader_files = metadata_reader["tested_files_sha256"]
    compatibility_files = compatibility_tests["tested_files_sha256"]

    exact_manifest_keys?(reader_files, @historical_metadata_source_files) and
      exact_manifest_keys?(compatibility_files, @historical_metadata_source_files) and
      reader_files == compatibility_files and hashes_well_formed?(reader_files) and
      history["tested_files_sha256"] == reader_files
  end

  defp valid_current_qualification_sources?(%{
         "status" => status,
         "tested_source_sha" => tested_source_sha,
         "tested_files_sha256" => files,
         "case_ids" => case_ids
       })
       when status == "qualified" do
    exact_manifest_keys?(files, @current_qualification_source_files) and
      hashes_well_formed?(files) and live_manifest_matches?(files) and
      is_list(case_ids) and case_ids != [] and length(case_ids) == length(Enum.uniq(case_ids)) and
      "LEG175-METADATA-FUTURE-READINESS" in case_ids and
      is_binary(tested_source_sha) and Regex.match?(~r/^[0-9a-f]{40}$/, tested_source_sha)
  end

  defp valid_current_qualification_sources?(_current_sources), do: false

  defp exact_manifest_keys?(manifest, expected_keys) when is_map(manifest) do
    MapSet.new(Map.keys(manifest)) == expected_keys and
      map_size(manifest) == MapSet.size(expected_keys)
  end

  defp exact_manifest_keys?(_manifest, _expected_keys), do: false

  defp hashes_well_formed?(manifest) when is_map(manifest) and map_size(manifest) > 0 do
    Enum.all?(manifest, fn {_path, digest} ->
      is_binary(digest) and Regex.match?(~r/^[0-9a-f]{64}$/, digest)
    end)
  end

  defp hashes_well_formed?(_manifest), do: false

  defp live_manifest_matches?(manifest) do
    Enum.all?(manifest, fn {path, digest} ->
      contents = File.read!(Path.expand("../../../" <> path, __DIR__))
      Base.encode16(:crypto.hash(:sha256, contents), case: :lower) == digest
    end)
  end

  defp qualified_anchor?(cases, qualification) do
    anchor = Enum.find(cases, &(&1["case_id"] == "LEG175-AGED-23H"))
    caller_cases = get_in(qualification, ["persisted_caller", "cases"])

    anchor["status"] == "qualified" and anchor["evidence"]["status"] == "pass" and
      get_in(caller_cases, ["LEG175-AGED-23H", "result"]) == "authenticated" and
      get_in(caller_cases, ["LEG175-AGED-23H", "jti_inserted"]) == true and
      get_in(caller_cases, ["LEG175-AGED-23H", "tokens"]) == 0 and
      get_in(caller_cases, ["LEG175-AGED-23H", "grants"]) == 0
  end
end

defmodule Lockspire.Security.ClientSecretVerifierContractTest do
  use ExUnit.Case, async: true

  alias Lockspire.Security.ClientSecretVerifierContract, as: Contract

  @phase_dir Path.expand(
               "../../../.planning/phases/175-accepted-baseline-verifier-compatibility-contract",
               __DIR__
             )

  setup_all do
    ledger = @phase_dir |> Path.join("175-COMPATIBILITY.json") |> File.read!() |> Jason.decode!()

    qualification =
      @phase_dir |> Path.join("175-QUALIFICATION.json") |> File.read!() |> Jason.decode!()

    summary = @phase_dir |> Path.join("175-02-SUMMARY.md") |> File.read!()
    %{ledger: ledger, qualification: qualification, summary: summary}
  end

  test "finite ledger is complete, owned, and tied to qualified caller evidence", context do
    assert :ok = Contract.validate(context.ledger, context.qualification, context.summary)
  end

  test "semantic validator rejects missing families, duplicate IDs, incorrect owners, and false evidence",
       context do
    cases = context.ledger["cases"]
    [first | rest] = cases

    assert {:error, {:missing_case, "READERS-AND-AUTH-EXCLUSIONS"}} =
             Contract.validate(
               %{
                 context.ledger
                 | "cases" =>
                     Enum.reject(cases, &(&1["case_id"] == "READERS-AND-AUTH-EXCLUSIONS"))
               },
               context.qualification,
               context.summary
             )

    assert {:error, :duplicate_case_id} =
             Contract.validate(
               %{context.ledger | "cases" => [first, first | rest]},
               context.qualification,
               context.summary
             )

    wrong_owner = update_case(context.ledger, "LEG175-AGED-23H", &Map.put(&1, "owner_phase", 176))

    assert {:error, {:wrong_owner, "LEG175-AGED-23H"}} =
             Contract.validate(wrong_owner, context.qualification, context.summary)

    false_evidence =
      update_case(context.ledger, "LEG175-AGED-23H", fn row ->
        put_in(row, ["evidence", "status"], "pending")
      end)

    assert {:error, {:invalid_evidence, "LEG175-AGED-23H"}} =
             Contract.validate(false_evidence, context.qualification, context.summary)
  end

  test "qualification manifests require exact historical and current source sets", context do
    historical_files =
      get_in(context.qualification, ["compatibility_tests", "tested_files_sha256"])

    current_files =
      get_in(context.qualification, ["current_qualification_sources", "tested_files_sha256"])

    invalid_qualifications = [
      put_in(context.qualification, ["compatibility_tests", "tested_files_sha256"], %{}),
      put_in(
        context.qualification,
        ["compatibility_tests", "tested_files_sha256"],
        Map.delete(historical_files, "test/support/client_secret_verifier_fixtures.ex")
      ),
      put_in(
        context.qualification,
        ["compatibility_tests", "tested_files_sha256"],
        Map.put(historical_files, "test/extra_test.exs", String.duplicate("a", 64))
      ),
      put_in(
        context.qualification,
        ["current_qualification_sources", "tested_files_sha256"],
        Map.delete(current_files, "test/integration/client_secret_jwt_legacy_age_test.exs")
      ),
      put_in(
        context.qualification,
        ["current_qualification_sources", "tested_files_sha256"],
        Map.put(current_files, "test/extra_test.exs", String.duplicate("a", 64))
      ),
      put_in(
        context.qualification,
        [
          "current_qualification_sources",
          "tested_files_sha256",
          "test/support/client_secret_verifier_fixtures.ex"
        ],
        "not-a-sha256"
      )
    ]

    for qualification <- invalid_qualifications do
      assert {:error, :invalid_qualified_inputs} =
               Contract.validate(context.ledger, qualification, context.summary)
    end
  end

  test "future cases cannot be marked passed without observed evidence", context do
    false_pass =
      update_case(context.ledger, "ENVELOPE-FORMAT", fn row ->
        row
        |> Map.put("status", "qualified")
        |> put_in(["evidence", "status"], "pass")
        |> put_in(["evidence", "ids"], ["UNOBSERVED-ENVELOPE"])
        |> put_in(["evidence", "source_sha"], "deadbeef")
      end)

    assert {:error, {:invalid_evidence, "ENVELOPE-FORMAT"}} =
             Contract.validate(false_pass, context.qualification, context.summary)

    pending_future_proof =
      update_case(context.ledger, "LEG175-METADATA-FUTURE-READINESS", fn row ->
        row
        |> Map.put("status", "pending")
        |> put_in(["evidence", "status"], "pending")
        |> put_in(["evidence", "ids"], [])
        |> put_in(["evidence", "source_sha"], nil)
      end)

    assert {:error, {:invalid_evidence, "LEG175-METADATA-FUTURE-READINESS"}} =
             Contract.validate(pending_future_proof, context.qualification, context.summary)

    downgraded_qualification =
      put_in(context.qualification, ["current_qualification_sources", "status"], "pending")

    assert {:error, {:invalid_evidence, "LEG175-METADATA-FUTURE-READINESS"}} =
             Contract.validate(pending_future_proof, downgraded_qualification, context.summary)
  end

  test "validator rejects malformed rows and evidence IDs that only share a qualified prefix",
       context do
    malformed = Map.put(context.ledger, "cases", ["not-a-row"])

    assert {:error, :invalid_case} =
             Contract.validate(malformed, context.qualification, context.summary)

    false_reference =
      update_case(context.ledger, "LEG175-AGED-23H", fn row ->
        put_in(row, ["evidence", "ids"], ["LEG175-AGED-23H-UNQUALIFIED"])
      end)

    assert {:error, {:invalid_evidence, "LEG175-AGED-23H"}} =
             Contract.validate(false_reference, context.qualification, context.summary)
  end

  test "new-format size bound is derived from payload and Base64URL framing", context do
    bounds = context.ledger["format_bounds"]
    assert bounds["max_plaintext_bytes"] == 1_048_598
    assert bounds["max_payload_bytes"] == 1_048_626
    assert bounds["max_payload_base64url_unpadded_bytes"] == 1_398_168
    assert bounds["max_envelope_bytes"] == 1_398_207

    material =
      Enum.find(context.ledger["cases"], &(&1["case_id"] == "MATERIAL-BOUNDS-AND-API-SCOPE"))

    assert material["expected"] =~ "1,398,207 ASCII bytes"

    invalid = put_in(context.ledger, ["format_bounds", "max_envelope_bytes"], 16_384)

    assert {:error, :invalid_format_bounds} =
             Contract.validate(invalid, context.qualification, context.summary)
  end

  test "legacy age equality, migration rejection, and generated-size facts stay distinct",
       context do
    age = Enum.find(context.ledger["cases"], &(&1["case_id"] == "LEGACY-AGE-BOUNDARIES"))

    sizes =
      Enum.find(context.ledger["cases"], &(&1["case_id"] == "MATERIAL-BOUNDS-AND-API-SCOPE"))

    assert age["expected"] =~ "valid at equality and expired strictly after"
    assert age["expected"] =~ "configured app/secret deadlines reject at equality"
    assert sizes["expected"] =~ "43 unpadded Base64URL chars"
    assert sizes["expected"] =~ "no legacy helper cap is added"
    assert sizes["blocking"] =~ "unchanged"
  end

  test "maintenance capability, paging, authority, and atomic update contract are finite",
       context do
    contract = context.ledger["maintenance_contract"]
    assert contract["capability"] == "Lockspire.Storage.ClientVerifierMaintenance"
    assert contract["inventory_args"] =~ "limit integer 1..500"
    assert contract["inventory_args"] =~ "default 100"
    assert contract["inventory_order"] =~ "cursor exclusive"
    assert contract["rewrap_callback"] =~ "expected_client_secret_hash"
    assert contract["rewrap_atomicity"] =~ "audit failure rolls back update"

    invalid = put_in(context.ledger, ["maintenance_contract", "inventory_args"], "unbounded")

    assert {:error, :invalid_maintenance_contract} =
             Contract.validate(invalid, context.qualification, context.summary)

    false_ready =
      update_case(context.ledger, "MAINTENANCE-INVENTORY-READINESS", fn row ->
        row
        |> Map.put("status", "qualified")
        |> put_in(["evidence", "status"], "pass")
        |> put_in(["evidence", "ids"], ["UNOBSERVED-MAINTENANCE"])
        |> put_in(["evidence", "source_sha"], "deadbeef")
      end)

    assert {:error, {:invalid_evidence, "MAINTENANCE-INVENTORY-READINESS"}} =
             Contract.validate(false_ready, context.qualification, context.summary)
  end

  test "writer, reader, rollout, disclosure, and package cases retain explicit owners",
       context do
    cases = Map.new(context.ledger["cases"], &{&1["case_id"], &1})

    assert cases["WRITER-DIRECT-REGISTRATION"]["expected"] =~ "final persisted client_id"
    assert cases["WRITER-DCR"]["expected"] =~ "one-time plaintext response"
    assert cases["WRITER-OPERATOR-ROTATION"]["owner_phase"] == 176
    assert cases["WRITER-HASH-ONLY-HELPER"]["expected"] =~ "no discarded verifier"
    assert cases["READER-TOKEN-EXCHANGE"]["expected"] =~ "ciphertext-sensitive"
    assert cases["READER-INTROSPECTION-REVOCATION"]["owner_phase"] == 176
    assert cases["READER-PAR-DEVICE-CIBA"]["expected"] =~ "do not add JWT support"
    assert cases["READER-HS256-AUDIENCE-JTI-EXCLUSIONS"]["expected"] =~ "fresh assertion/JTI"

    assert cases["ROLLOUT-READER-FIRST-ROLLBACK-RETIREMENT"]["expected"] =~
             "before first dedicated write"

    assert cases["DISCLOSURE-SENTINELS"]["owner_phase"] == 177
    assert cases["PACKAGES-ADAPTER-DELIVERY"]["owner_phase"] == 178

    assert cases["MAINTENANCE-INTERRUPTED-RESUME-IDEMPOTENCE-RECOVERY"]["expected"] =~
             "restart a fresh full scan from nil"
  end

  defp update_case(ledger, id, update) do
    Map.update!(ledger, "cases", fn cases ->
      Enum.map(cases, fn row -> if row["case_id"] == id, do: update.(row), else: row end)
    end)
  end
end
