defmodule Lockspire.Web.Live.Admin.VocabularyContractTest do
  use ExUnit.Case, async: true

  # PRODUCT.md owns the retired-wording list so the vocabulary map and this
  # guard change together. This test only reads it.
  @product_path Path.join(File.cwd!(), "PRODUCT.md")
  @admin_sources [
    "lib/lockspire/web/live/admin/**/*.{ex,heex}",
    "lib/lockspire/web/live/admin_layout_live.ex",
    "lib/lockspire/web/components/admin_components.ex"
  ]

  test "admin UI source contains no retired wording" do
    retired = retired_phrases()
    assert length(retired) >= 10, "Expected the PRODUCT.md retired-wording table to be readable"

    hits =
      for path <- admin_source_paths(),
          {line, number} <- path |> File.read!() |> String.split("\n") |> Enum.with_index(1),
          {phrase, replacement} <- retired,
          String.contains?(String.downcase(line), phrase) do
        "#{Path.relative_to_cwd(path)}:#{number}: \"#{phrase}\" (use: #{replacement})"
      end

    assert hits == [],
           "Retired wording found. Update the copy, or the vocabulary map in PRODUCT.md:\n" <>
             Enum.join(hits, "\n")
  end

  defp retired_phrases do
    @product_path
    |> File.read!()
    |> String.split("### Retired wording", parts: 2)
    |> List.last()
    |> String.split("\n### ", parts: 2)
    |> hd()
    |> String.split("\n")
    |> Enum.flat_map(fn line ->
      case Regex.run(~r/^\| ([^|]+?) \| ([^|]+?) \|$/, line) do
        [_, "Retired phrase", _] -> []
        [_, "---", _] -> []
        [_, phrase, replacement] -> [{String.downcase(phrase), replacement}]
        nil -> []
      end
    end)
  end

  defp admin_source_paths do
    @admin_sources
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.uniq()
  end
end
