defmodule Lockspire.Quality.Phase138ProhibitionConsistencyTest do
  use ExUnit.Case, async: true

  @phase_dir ".planning/phases/138-baseline-inventory-evidence-taxonomy"
  @ledger Path.join(@phase_dir, "138-PROHIBITION-VALIDATION.md")
  @owner "test/lockspire/release/repository_hygiene_contract_test.exs"

  test "prohibition ledger exactly covers the original 108 source claims" do
    source = source_claims()
    rows = ledger_rows()

    assert length(source) == 108
    assert length(rows) == 108
    assert Enum.map(rows, & &1.identity) == Enum.map(source, & &1.identity)
    assert Enum.map(rows, & &1.statement) == Enum.map(source, & &1.statement)
    assert Enum.map(rows, & &1.original_form) == Enum.map(source, & &1.original_form)

    assert Enum.frequencies_by(source, & &1.original_form) == %{
             "string" => 8,
             "object:automated" => 4,
             "object:flagged-unverified" => 96
           }

    assert Enum.all?(rows, &valid_row?(&1))
    assert Enum.all?(rows, &owner_is_tracked?(&1.owner))
    assert Enum.all?(rows, &(&1.tier == "judgment" and &1.disposition == "UNVERIFIED"))
    assert ledger_text() =~ "| judgment | 108 | UNVERIFIED | 108 |"
    assert ledger_text() =~ "| test | 0 | ENFORCED | 0 |"
  end

  test "ledger validation rejects omissions, altered claims, unsupported tiers, and false enforcement" do
    rows = ledger_rows()
    first = hd(rows)

    refute valid_row?(%{first | disposition: "ENFORCED"})
    refute valid_row?(%{first | tier: "source-symbol"})
    refute valid_row?(%{first | owner: "missing/owner.ex"})

    assert Enum.map(tl(rows), & &1.identity) != Enum.map(source_claims(), & &1.identity)

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

  test "historical plans, summaries, and canonical inventory remain byte-identical to HEAD" do
    paths =
      Enum.flat_map(1..34, fn number ->
        number = String.pad_leading(Integer.to_string(number), 2, "0")

        [
          Path.join(@phase_dir, "138-#{number}-PLAN.md"),
          Path.join(@phase_dir, "138-#{number}-SUMMARY.md")
        ]
      end) ++ [Path.join(@phase_dir, "baseline-inventory-2026-08-28.md")]

    Enum.each(paths, fn path ->
      assert File.read!(path) == git_show!(path), "historical bytes changed: #{path}"
    end)
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
        disposition
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
        disposition: disposition
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
         true <- valid_disposition?(row) do
      true
    else
      _ -> false
    end
  end

  defp valid_disposition?(%{disposition: "UNVERIFIED", violation: violation}),
    do: String.trim(violation) != ""

  defp valid_disposition?(%{
         disposition: "ENFORCED",
         tier: "test",
         command: command,
         execution: execution,
         violation: violation
       }) do
    command != "" and execution =~ ~r/tests=([1-9]\d*) failures=0 exit=0/ and
      violation =~ "asserts rejection"
  end

  defp valid_disposition?(_), do: false

  defp owner_is_tracked?(path) do
    path == @owner and File.regular?(path) and
      case System.cmd("git", ["ls-files", "--error-unmatch", path], stderr_to_stdout: true) do
        {_, 0} -> true
        _ -> false
      end
  end

  defp ledger_text, do: File.read!(@ledger)

  defp git_show!(path) do
    case System.cmd("git", ["show", "HEAD:" <> path], stderr_to_stdout: true) do
      {contents, 0} -> contents
      {error, status} -> flunk("git show failed for #{path} (#{status}): #{error}")
    end
  end
end
