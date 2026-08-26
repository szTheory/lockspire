defmodule Lockspire.Install.FileTransactionTest do
  use ExUnit.Case, async: true

  alias Lockspire.Install.FileTransaction
  alias Lockspire.Install.Manifest

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "lockspire-file-transaction-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    %{root: root}
  end

  test "recovers an interrupted migration create before applying a new transaction", %{root: root} do
    artifacts = [
      artifact(
        "priv/repo/migrations/20260826000100_create_widgets.exs",
        :migration,
        :absent,
        "migration"
      ),
      manifest(:absent, "manifest")
    ]

    FileTransaction.with_test_failure({:after_migration, 1}, fn ->
      assert {:error, [%{type: :interrupted}]} = FileTransaction.apply(root, artifacts)
    end)

    assert File.exists?(Path.join(root, ".lockspire/install_transaction.json"))

    assert File.read!(Path.join(root, "priv/repo/migrations/20260826000100_create_widgets.exs")) ==
             "migration"

    assert :ok = FileTransaction.apply(root, artifacts)

    assert File.read!(Path.join(root, "priv/repo/migrations/20260826000100_create_widgets.exs")) ==
             "migration"

    refute File.exists?(Path.join(root, ".lockspire/install_transaction.json"))
  end

  test "refuses a symlinked managed destination without touching its target", %{root: root} do
    outside = Path.join(root, "outside")
    target = Path.join(root, "config/lockspire.exs")
    File.write!(outside, "sentinel")
    File.mkdir_p!(Path.dirname(target))
    File.ln_s!(outside, target)

    artifact =
      artifact("config/lockspire.exs", :managed, Manifest.checksum("sentinel"), "replacement")

    assert {:error, [%{type: :unsafe_path}]} =
             FileTransaction.apply(root, [artifact, manifest(:absent, "manifest")])

    assert File.read!(outside) == "sentinel"
  end

  test "refuses an unexpected create-only destination", %{root: root} do
    path = Path.join(root, "config/lockspire.exs")
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, "host-owned")

    assert {:error, [%{type: :unsafe_path}]} =
             FileTransaction.apply(root, [
               artifact("config/lockspire.exs", :managed, :absent, "generated"),
               manifest(:absent, "manifest")
             ])

    assert File.read!(path) == "host-owned"
  end

  defp artifact(relative_path, kind, expected, contents) do
    %{
      relative_path: relative_path,
      kind: kind,
      expected: expected,
      contents: contents,
      checksum: Manifest.checksum(contents),
      provenance: "test"
    }
  end

  defp manifest(expected, contents),
    do: artifact(".lockspire/install_manifest.json", :manifest, expected, contents)
end
