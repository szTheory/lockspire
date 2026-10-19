defmodule Lockspire.KekGuidanceContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @fallback_allowlist ["docs/upgrading/signing-key-encryption.md"]
  @guidance_files [
    "lib/lockspire/config.ex",
    "lib/lockspire/application.ex",
    "lib/lockspire/install/verify.ex",
    "lib/mix/tasks/lockspire.keys.reencrypt.ex",
    "lib/mix/tasks/lockspire.doctor.key_encryption.ex",
    "lib/lockspire/generators/kek_snippet.ex",
    "docs/upgrading/signing-key-encryption.md",
    "docs/install-and-onboard.md"
  ]

  defp scanned_files do
    wildcard =
      Enum.flat_map(["lib/**/*.{ex,exs}", "docs/**/*.md"], fn pattern ->
        @repo_root
        |> Path.join(pattern)
        |> Path.wildcard()
        |> Enum.map(&Path.relative_to(&1, @repo_root))
      end)

    Enum.sort(wildcard ++ ["README.md", "scripts/acceptance/clean_room/build_provider.py"])
  end

  defp read(rel), do: File.read!(Path.join(@repo_root, rel))

  defp files_containing(needle) do
    Enum.filter(scanned_files(), fn rel -> String.contains?(read(rel), needle) end)
  end

  test "no lib, docs or harness file recommends the OpenSSL key recipe" do
    scanned = scanned_files()
    assert "lib/lockspire/config.ex" in scanned
    assert "docs/upgrading/signing-key-encryption.md" in scanned

    assert files_containing("openssl rand") == []
  end

  test "the elixir -e fallback appears only in the upgrade guide, after gen.kek" do
    assert Enum.sort(files_containing("elixir -e")) == Enum.sort(@fallback_allowlist)

    for rel <- @fallback_allowlist do
      text = read(rel)
      {gen_index, _} = :binary.match(text, "mix lockspire.gen.kek")
      {fallback_index, _} = :binary.match(text, "elixir -e")
      assert gen_index < fallback_index, "#{rel} shows the fallback before mix lockspire.gen.kek"
    end

    refute read("lib/lockspire/config.ex") =~ "Base.encode64("
  end

  test "every key guidance site names mix lockspire.gen.kek" do
    for rel <- @guidance_files do
      assert read(rel) =~ "mix lockspire.gen.kek", "#{rel} must name mix lockspire.gen.kek"
    end
  end
end
