defmodule Lockspire.UpgradeGuideContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @guide_path Path.join(@repo_root, "docs/upgrading/signing-key-encryption.md")

  setup_all do
    {:ok, guide: File.read!(@guide_path)}
  end

  test "the guide gives the four upgrade steps in a safe order", %{guide: guide} do
    assert_in_order(guide, [
      "Before you start",
      "openssl rand -base64 32",
      "legacy_plaintext: :allow",
      "mix lockspire.keys.reencrypt --dry-run",
      "mix lockspire.keys.reencrypt --check",
      "legacy_plaintext: :reject",
      "mix lockspire.doctor key_encryption"
    ])
  end

  test "the guide covers releases and warns that a bare eval does not start the repo", %{
    guide: guide
  } do
    assert guide =~ "bin/app rpc"
    assert guide =~ "Ecto.Migrator.with_repo"
    assert guide =~ "A bare release `eval` does not start the repo"
  end

  test "the guide names the check as the required gate", %{guide: guide} do
    assert guide =~ "This is the required gate"
  end

  test "the guide carries the rotation runbook and the data-safety warnings", %{guide: guide} do
    for phrase <- [
          "Rotate the key-encryption key",
          "LOCKSPIRE_KEY_ENCRYPTION_KEY_NEXT",
          "Never remove an old KEK before `--check` passes",
          "Backup remanence",
          "Rollback",
          "earlier versions",
          "ERL_CRASH_DUMP_SECONDS=0",
          "env_keys",
          "same location as its key"
        ] do
      assert String.downcase(guide) =~ String.downcase(phrase), "guide is missing: #{phrase}"
    end
  end

  test "architecture and install docs describe envelope storage" do
    architecture = File.read!(Path.join(@repo_root, "docs/architecture.md"))
    install = File.read!(Path.join(@repo_root, "docs/install-and-onboard.md"))

    assert install =~ "LOCKSPIRE_KEY_ENCRYPTION_KEY"
    assert install =~ "upgrading/signing-key-encryption.md"
    refute architecture =~ "encrypted key material where appropriate"
  end

  test "the guide stays version-agnostic and free of local paths", %{guide: guide} do
    refute guide =~ ".planning/"
    refute guide =~ "/Users/"
    refute guide =~ ~r/\d+\.\d+\.\d+/
  end

  # Each phrase must appear after the previous one, so a later mention of an earlier
  # phrase (the doctor command is run twice) cannot hide a reordering.
  defp assert_in_order(text, needles) do
    Enum.reduce(needles, 0, fn needle, from ->
      rest = binary_part(text, from, byte_size(text) - from)

      case :binary.match(rest, needle) do
        {index, length} -> from + index + length
        :nomatch -> flunk("phrase missing or out of order: #{needle}")
      end
    end)
  end
end
