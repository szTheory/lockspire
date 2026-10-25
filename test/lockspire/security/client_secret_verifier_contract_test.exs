defmodule Lockspire.Security.ClientSecretVerifierContract do
  @moduledoc false

  @required_cases ~w(
    LEG175-AGED-23H
    LEG175-AGED-2D
    LEG175-FUTURE
    LEG175-METADATA-SHAPES
    LEG175-HASH-MISMATCH
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

    cond do
      Enum.any?(ids, &(not is_binary(&1))) ->
        {:error, :missing_case_id}

      length(ids) != length(Enum.uniq(ids)) ->
        {:error, :duplicate_case_id}

      missing = Enum.find(@required_cases, &(&1 not in ids)) ->
        {:error, {:missing_case, missing}}

      invalid = Enum.find(cases, &(not valid_fields?(&1))) ->
        {:error, {:missing_fields, invalid["case_id"]}}

      invalid = Enum.find(cases, &(not valid_owner?(&1))) ->
        {:error, {:wrong_owner, invalid["case_id"]}}

      invalid =
          Enum.find(
            cases,
            &(not valid_evidence?(
                &1,
                caller_ids,
                metadata_ids,
                metadata_commit_short,
                metadata_source_sha,
                qualification
              ))
          ) ->
        {:error, {:invalid_evidence, invalid["case_id"]}}

      not valid_bounds?(Map.get(ledger, "format_bounds")) ->
        {:error, :invalid_format_bounds}

      not valid_maintenance_contract?(Map.get(ledger, "maintenance_contract")) ->
        {:error, :invalid_maintenance_contract}

      not valid_qualified_inputs?(ledger, qualification) ->
        {:error, :invalid_qualified_inputs}

      not qualified_anchor?(cases, qualification) ->
        {:error, :missing_qualified_anchor}

      true ->
        :ok
    end
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
    ids = evidence["ids"]
    source_sha = evidence["source_sha"]

    ids_are_caller =
      is_list(ids) and ids != [] and Enum.all?(ids, &MapSet.member?(caller_ids, &1))

    ids_are_metadata =
      is_list(ids) and ids != [] and Enum.all?(ids, &MapSet.member?(metadata_ids, &1))

    correct_source =
      (ids_are_caller and source_sha == qualification["tested_checkout_head"]) or
        (ids_are_metadata and is_binary(metadata_commit_short) and
           source_sha == metadata_source_sha and
           String.starts_with?(source_sha, metadata_commit_short))

    evidence["status"] == "pass" and correct_source
  end

  defp valid_evidence?(
         %{"status" => "pending", "owner_phase" => owner, "evidence" => evidence},
         _caller_ids,
         _metadata_ids,
         _metadata_commit_short,
         _metadata_source_sha,
         _qualification
       )
       when owner in [176, 177, 178],
       do:
         evidence["status"] == "pending" and evidence["ids"] == [] and
           is_nil(evidence["source_sha"])

  defp valid_evidence?(
         _row,
         _caller_ids,
         _metadata_ids,
         _metadata_commit_short,
         _metadata_source_sha,
         _qualification
       ),
       do: false

  defp valid_bounds?(bounds) when is_map(bounds) do
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

    is_integer(secret) and is_integer(client_id) and is_integer(kid) and is_integer(prefix) and
      is_integer(age) and is_integer(iv) and is_integer(tag) and is_integer(plaintext) and
      is_integer(payload) and is_integer(encoded) and is_integer(envelope) and
      secret == 1_048_576 and client_id == 1_048_576 and kid == 32 and prefix == 6 and age == 16 and
      iv == 12 and tag == 16 and plaintext == secret + prefix + age and
      payload == plaintext + iv + tag and encoded == div(payload * 8 + 5, 6) and
      envelope == 6 + kid + 1 + encoded and bounds["reserved_family_prefix"] == "LSCV"
  end

  defp valid_bounds?(_bounds), do: false

  defp valid_maintenance_contract?(contract) when is_map(contract) do
    contract["capability"] == "Lockspire.Storage.ClientVerifierMaintenance" and
      contract["authority_callback"] == "verifier_maintenance_contract/0" and
      contract["inventory_callback"] == "verifier_inventory_page(after_client_id, limit)" and
      contract["rewrap_callback"] ==
        "compare_and_rewrap(client_id, expected_client_secret_hash, expected_verifier, replacement_verifier, audit_attrs)" and
      contract["authority_return"] =~ "participants: %{client_store: module()" and
      contract["inventory_args"] =~ "limit integer 1..500" and
      contract["inventory_args"] =~ "default 100" and
      contract["inventory_return"] =~ ":client_secret_verifier_inventory_invalid_limit" and
      contract["authority_rule"] =~ "fails before inventory or mutation" and
      contract["authority_rule"] =~ "corresponding entries" and
      contract["selection"] =~ "never defaulted to Repository" and
      contract["inventory_order"] =~ "cursor exclusive" and
      contract["inventory_order"] =~ "empty inventory is [], nil, true" and
      contract["inventory_scope"] =~ "every persisted client" and
      contract["inventory_consistency"] =~ "not a database snapshot" and
      contract["rewrap_atomicity"] =~ "already-open transaction" and
      contract["rewrap_atomicity"] =~ "provisional until outer commit" and
      contract["rewrap_atomicity"] =~ "audit failure rolls back update" and
      contract["rewrap_atomicity"] =~ "never use direct Repository fallback" and
      contract["rewrap_preserves"] =~ "updated_at" and
      contract["status"] ==
        "contract-only; behavior and adapter composition evidence pending Phase 177/178"
  end

  defp valid_maintenance_contract?(_contract), do: false

  defp valid_qualified_inputs?(ledger, qualification) do
    inputs = ledger["qualified_input"]

    inputs["persisted_caller_tested_sha"] == qualification["tested_checkout_head"] and
      inputs["metadata_reader_tested_sha"] ==
        get_in(qualification, ["metadata_reader", "tested_source_sha"]) and
      inputs["metadata_reader_tested_sha"] ==
        get_in(qualification, ["compatibility_tests", "tested_source_sha"]) and
      Enum.all?(get_in(qualification, ["compatibility_tests", "tested_files_sha256"]), fn {path,
                                                                                           sha} ->
        contents = File.read!(Path.expand("../../../" <> path, __DIR__))
        Base.encode16(:crypto.hash(:sha256, contents), case: :lower) == sha
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
