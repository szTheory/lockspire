defmodule Lockspire.Quality.Phase138ProhibitionConsistencyTest do
  use ExUnit.Case, async: true

  @phase_dir ".planning/phases/138-baseline-inventory-evidence-taxonomy"
  @ledger Path.join(@phase_dir, "138-PROHIBITION-VALIDATION.md")
  @owner "test/lockspire/release/repository_hygiene_contract_test.exs"
  @historical_bytes_sha256 "1c95ce2813cdd6701f5e008f95ca95e8bf26194e28a89dc00266e1719dbb8ae2"

  test "prohibition ledger exactly covers the original 108 source claims" do
    source = source_claims()
    rows = ledger_rows()

    assert length(source) == 108
    assert length(rows) == 108
    assert ledger_errors(rows, source) == []

    assert Enum.frequencies_by(source, & &1.original_form) == %{
             "string" => 8,
             "object:automated" => 4,
             "object:flagged-unverified" => 96
           }

    assert published_source_counts() == Enum.frequencies_by(source, & &1.original_form)

    assert Enum.all?(rows, &owner_is_tracked?(&1.owner))

    assert Enum.frequencies_by(rows, &{&1.tier, &1.disposition}) == %{
             {"judgment", "UNVERIFIED"} => 98,
             {"test", "ENFORCED"} => 10
           }

    technical_totals = published_technical_totals()

    assert Map.new(technical_totals, fn {key, {tier_count, _disposition_count}} ->
             {key, tier_count}
           end) == Enum.frequencies_by(rows, &{&1.tier, &1.disposition})

    assert Enum.all?(technical_totals, fn {_key, {tier_count, disposition_count}} ->
             tier_count == disposition_count
           end)

    assert Enum.frequencies_by(rows, & &1.resolution) == %{
             "maintainer-affirmed" => 98,
             "evidence-backed" => 10
           }

    assert closure_valid?(rows)
    refute Enum.any?(rows, &(&1.resolution == "pending"))
  end

  test "closure fails while any row is pending and published totals must match the ledger" do
    rows = ledger_rows()
    assert row_resolution_counts(rows) == published_resolution_counts()

    first = hd(rows)

    pending = %{
      first
      | resolution: "pending",
        reviewer: "",
        reviewed_at: "",
        judgment_rationale: "",
        judgment_reference: ""
    }

    refute closure_valid?([pending | tl(rows)])

    refute closure_valid?([
             %{first | resolution: "maintainer-superseded", judgment_reference: ""} | tl(rows)
           ])
  end

  test "pending judgment is distinct from resolution and evidence-backed rows require focused proof" do
    pending = %{
      hd(ledger_rows())
      | resolution: "pending",
        reviewer: "",
        reviewed_at: "",
        judgment_rationale: "",
        judgment_reference: ""
    }

    assert valid_row?(pending)
    assert pending.resolution == "pending"
    assert pending.tier == "judgment" and pending.disposition == "UNVERIFIED"

    evidence_backed = %{
      pending
      | tier: "test",
        resolution: "evidence-backed",
        test_name: "138-01-1 rejects violating input [phase138_prohibition]",
        command: "mix test test/example_test.exs --only phase138_prohibition",
        execution: "tests=1 failures=0 exit=0",
        violation: "asserts rejection of violating input",
        disposition: "ENFORCED"
    }

    assert valid_row?(evidence_backed)
    refute valid_row?(%{evidence_backed | execution: "tests=0 failures=0 exit=0"})
    refute valid_row?(%{evidence_backed | violation: "no violating case"})
    refute valid_row?(%{evidence_backed | test_name: "missing selector"})
    refute valid_row?(%{evidence_backed | command: "mix test test/example_test.exs"})
    refute valid_row?(%{pending | resolution: "evidence-backed"})
    refute valid_row?(%{pending | disposition: "ENFORCED"})
  end

  test "maintainer outcomes require attributable review fields and retain judgment disposition" do
    pending = %{
      hd(ledger_rows())
      | resolution: "pending",
        reviewer: "",
        reviewed_at: "",
        judgment_rationale: "",
        judgment_reference: ""
    }

    resolved = %{
      pending
      | resolution: "maintainer-affirmed",
        reviewer: "maintainer@example.test",
        reviewed_at: "2026-09-25T12:00:00Z",
        judgment_reference: "138-01-PLAN.md#prohibitions[1]; 138-CONTEXT.md#d-01",
        judgment_rationale: "The claim remains applicable repository policy."
    }

    assert valid_row?(resolved)
    assert valid_row?(%{resolved | resolution: "maintainer-superseded"})
    assert valid_row?(%{resolved | resolution: "maintainer-not-applicable"})
    refute valid_row?(%{resolved | reviewer: ""})
    refute valid_row?(%{resolved | reviewed_at: "not-a-date"})
    refute valid_row?(%{resolved | reviewed_at: "2026-99-99T12:00:00Z"})
    refute valid_row?(%{resolved | judgment_reference: ""})
    refute valid_row?(%{resolved | judgment_reference: "138-CONTEXT.md#d-01"})
    refute valid_row?(%{resolved | tier: "test"})
    refute valid_row?(%{resolved | disposition: "ENFORCED"})
    refute valid_row?(%{pending | resolution: "maintainer-superseded"})
  end

  test "ledger validation rejects omissions, altered claims, unsupported tiers, and false enforcement" do
    rows = ledger_rows()
    first = hd(rows)

    refute valid_row?(%{first | disposition: "ENFORCED"})
    refute valid_row?(%{first | tier: "source-symbol"})
    refute valid_row?(%{first | owner: "missing/owner.ex"})

    source = source_claims()
    refute ledger_errors(tl(rows), source) == []

    altered = [%{first | statement: first.statement <> " altered"} | tl(rows)]
    refute ledger_errors(altered, source) == []

    duplicated = rows ++ [first]
    refute ledger_errors(duplicated, source) == []

    forged_receipt = %{
      first
      | tier: "test",
        disposition: "ENFORCED",
        command: "mix test test/lockspire/quality/phase_138_prohibition_consistency_test.exs",
        execution: "0 tests, 0 failures, exit 0",
        violation: "none"
    }

    refute valid_row?(forged_receipt)
  end

  test "historical plans, summaries, and canonical inventory match the pinned byte manifest" do
    paths =
      Enum.flat_map(1..34, fn number ->
        number = String.pad_leading(Integer.to_string(number), 2, "0")

        [
          Path.join(@phase_dir, "138-#{number}-PLAN.md"),
          Path.join(@phase_dir, "138-#{number}-SUMMARY.md")
        ]
      end) ++ [Path.join(@phase_dir, "baseline-inventory-2026-08-28.md")]

    current_digest =
      paths
      |> Enum.map(fn path -> [path, <<0>>, File.read!(path), <<0>>] end)
      |> IO.iodata_to_binary()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)

    assert current_digest == @historical_bytes_sha256,
           "historical plan, summary, or canonical inventory bytes changed"
  end

  defp source_claims do
    Enum.flat_map(1..34, fn number ->
      padded = String.pad_leading(Integer.to_string(number), 2, "0")
      path = Path.join(@phase_dir, "138-#{padded}-PLAN.md")
      source = File.read!(path)

      prohibition_block =
        source
        |> String.split("  prohibitions:\n", parts: 2)
        |> List.last()
        |> String.split(~r/^  [a-z_]+:/m, parts: 2)
        |> hd()

      prohibition_block
      |> String.split(~r/^    - /m, trim: true)
      |> Enum.with_index(1)
      |> Enum.map(fn {item, position} ->
        {statement_json, original_form} = source_item(item)

        %{
          identity: {number, position},
          statement: Jason.decode!(statement_json),
          original_form: original_form
        }
      end)
    end)
  end

  defp source_item(item) do
    case Regex.run(~r/^statement: ("(?:\\.|[^"])*")/s, item) do
      [_, statement] ->
        verification =
          case Regex.run(~r/^\s+verification: ([a-z-]+)/m, item) do
            [_, value] -> value
            _ -> "missing"
          end

        {statement, "object:" <> verification}

      _ ->
        [_, statement] = Regex.run(~r/^("(?:\\.|[^"])*")/s, item)
        {statement, "string"}
    end
  end

  defp ledger_rows do
    ledger_text()
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, "| 138-"))
    |> Enum.map(fn line ->
      cells =
        line
        |> String.trim_leading("|")
        |> String.trim_trailing("|")
        |> String.split("|")
        |> Enum.map(&String.trim/1)

      [
        plan,
        position,
        encoded,
        original_form,
        tier,
        owner,
        test_name,
        command,
        execution,
        violation,
        disposition,
        resolution,
        reviewer,
        reviewed_at,
        judgment_rationale,
        judgment_reference
      ] = cells

      [_, number] = Regex.run(~r/^138-(\d+)-PLAN\.md$/, plan)
      encoded = encoded |> String.trim("`") |> Jason.decode!()

      %{
        identity: {String.to_integer(number), String.to_integer(position)},
        statement: encoded,
        original_form: original_form,
        tier: tier,
        owner: owner,
        test_name: test_name,
        command: command,
        execution: execution,
        violation: violation,
        disposition: disposition,
        resolution: resolution,
        reviewer: reviewer,
        reviewed_at: reviewed_at,
        judgment_rationale: judgment_rationale,
        judgment_reference: judgment_reference
      }
    end)
  end

  defp valid_row?(row) do
    with true <- row.tier in ["test", "judgment"],
         true <- row.disposition in ["ENFORCED", "UNVERIFIED"],
         true <- row.original_form in ["string", "object:flagged-unverified", "object:automated"],
         true <- owner_is_tracked?(row.owner),
         true <- String.trim(row.test_name) != "",
         true <- row.statement |> String.contains?("\n") |> Kernel.not(),
         true <-
           row.resolution in [
             "pending",
             "evidence-backed",
             "maintainer-affirmed",
             "maintainer-superseded",
             "maintainer-not-applicable"
           ],
         true <- valid_disposition?(row) do
      true
    else
      _ -> false
    end
  end

  defp ledger_errors(rows, source) do
    identities = Enum.map(rows, & &1.identity)
    source_identities = Enum.map(source, & &1.identity)
    source_by_identity = Map.new(source, &{&1.identity, &1})

    row_errors =
      Enum.flat_map(rows, fn row ->
        source_claim = Map.get(source_by_identity, row.identity)

        cond do
          is_nil(source_claim) ->
            ["extra source identity #{inspect(row.identity)}"]

          row.statement != source_claim.statement ->
            ["altered statement at #{inspect(row.identity)}"]

          row.original_form != source_claim.original_form ->
            ["altered source form at #{inspect(row.identity)}"]

          not valid_row?(row) ->
            ["invalid evidence row at #{inspect(row.identity)}"]

          true ->
            []
        end
      end)

    duplicate_errors =
      if length(identities) == length(Enum.uniq(identities)),
        do: [],
        else: ["duplicate source identity"]

    missing_errors =
      if identities == source_identities, do: [], else: ["source identity set or order differs"]

    row_errors ++ duplicate_errors ++ missing_errors
  end

  defp valid_disposition?(
         %{
           disposition: "UNVERIFIED",
           tier: "judgment",
           resolution: "pending"
         } = row
       ),
       do:
         row.reviewer == "" and row.reviewed_at == "" and row.judgment_rationale == "" and
           row.judgment_reference == ""

  defp valid_disposition?(
         %{disposition: "UNVERIFIED", tier: "judgment", resolution: resolution} = row
       )
       when resolution in [
              "maintainer-affirmed",
              "maintainer-superseded",
              "maintainer-not-applicable"
            ] do
    {plan, position} = row.identity

    source_ref =
      "138-#{String.pad_leading(Integer.to_string(plan), 2, "0")}-PLAN.md#prohibitions[#{position}]"

    row.reviewer =~ ~r/\S/ and valid_utc_timestamp?(row.reviewed_at) and
      row.judgment_rationale =~ ~r/\S/ and row.judgment_reference =~ ~r/\Q#{source_ref}\E/ and
      row.judgment_reference =~ ~r/138-CONTEXT\.md#d-\d\d/
  end

  defp valid_disposition?(
         %{
           disposition: "ENFORCED",
           tier: "test",
           resolution: "evidence-backed",
           execution: execution,
           violation: violation
         } = row
       ) do
    {plan, position} = row.identity
    identity = "138-#{String.pad_leading(Integer.to_string(plan), 2, "0")}-#{position}"

    (row.command =~ ~r/--only phase138_prohibition/ or
       row.command =~ ~r/--test-name-pattern=138-\d+-\d+/) and row.test_name =~ identity and
      row.test_name =~ "[phase138_prohibition]" and
      execution =~ ~r/tests=([1-9]\d*) failures=0 exit=0/ and
      violation =~ "asserts rejection"
  end

  defp valid_disposition?(_), do: false

  defp valid_utc_timestamp?(value) do
    case DateTime.from_iso8601(value) do
      {:ok, _datetime, 0} -> String.ends_with?(value, "Z")
      _ -> false
    end
  end

  defp closure_valid?(rows) do
    Enum.all?(rows, &valid_row?/1) and
      Enum.all?(rows, &(&1.resolution != "pending")) and
      row_resolution_counts(rows) == published_resolution_counts()
  end

  defp row_resolution_counts(rows) do
    counts = Enum.frequencies_by(rows, & &1.resolution)

    Map.new(
      [
        "pending",
        "evidence-backed",
        "maintainer-affirmed",
        "maintainer-superseded",
        "maintainer-not-applicable"
      ],
      &{&1, Map.get(counts, &1, 0)}
    )
  end

  defp published_resolution_counts do
    ~r/^\| (pending|evidence-backed|maintainer-affirmed|maintainer-superseded|maintainer-not-applicable) \| (\d+) \|/m
    |> Regex.scan(ledger_text(), capture: :all_but_first)
    |> Map.new(fn [state, count] -> {state, String.to_integer(count)} end)
  end

  defp published_technical_totals do
    ~r/^\| (judgment|test) \| (\d+) \| (UNVERIFIED|ENFORCED) \| (\d+) \|/m
    |> Regex.scan(ledger_text(), capture: :all_but_first)
    |> Map.new(fn [tier, tier_count, disposition, disposition_count] ->
      {{tier, disposition}, {String.to_integer(tier_count), String.to_integer(disposition_count)}}
    end)
  end

  defp published_source_counts do
    ~r/^\| (string|object:flagged-unverified|object:automated) \| (\d+) \|/m
    |> Regex.scan(ledger_text(), capture: :all_but_first)
    |> Map.new(fn [form, count] -> {form, String.to_integer(count)} end)
  end

  defp owner_is_tracked?(path) do
    path in [
      @owner,
      "test/support/lockspire/release_proof/package_assertions.ex",
      "test/lockspire/workflow_supply_chain_contract_test.exs",
      "tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs",
      "tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs"
    ] and File.regular?(path) and
      case System.cmd("git", ["ls-files", "--error-unmatch", path], stderr_to_stdout: true) do
        {_, 0} -> true
        _ -> false
      end
  end

  defp ledger_text, do: File.read!(@ledger)
end
