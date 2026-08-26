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

  test "ordinary failure rolls back committed files, removes transaction state, and retries", %{
    root: root
  } do
    migration = "priv/repo/migrations/20260826000100_create_widgets.exs"

    artifacts = [
      artifact(migration, :migration, :absent, "migration"),
      manifest(:absent, "manifest")
    ]

    before = tree_snapshot(root)

    FileTransaction.with_test_failure({:ordinary_failure, :before_manifest_commit}, fn ->
      assert {:error, [%{type: :transaction_failed}]} = FileTransaction.apply(root, artifacts)
    end)

    assert tree_snapshot(root) == before
    refute File.exists?(Path.join(root, ".lockspire/install_transaction.json"))
    assert Path.wildcard(Path.join(root, ".lockspire/.install-tx-*")) == []

    assert :ok = FileTransaction.apply(root, artifacts)
    assert File.read!(Path.join(root, migration)) == "migration"
  end

  test "refuses a journal below a symlinked .lockspire directory without touching outside state",
       %{root: root} do
    outside = Path.join(root, "outside-state")
    staged = Path.join(outside, ".install-tx-1/staged-0")
    journal = Path.join(outside, "install_transaction.json")
    File.mkdir_p!(Path.dirname(staged))
    File.write!(staged, "outside sentinel")

    File.write!(
      journal,
      Jason.encode!(%{
        "root" => root,
        "tx_root" => Path.dirname(staged),
        "artifacts" => [],
        "committed" => []
      })
    )

    before = %{journal: File.read!(journal), staged: File.read!(staged)}
    File.ln_s!(outside, Path.join(root, ".lockspire"))

    assert {:error, [%{type: :unsafe_path}]} = FileTransaction.recover(root)
    assert %{journal: File.read!(journal), staged: File.read!(staged)} == before
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

  defp tree_snapshot(root) do
    root
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.sort()
    |> Enum.reduce(%{}, fn path, snapshot ->
      relative = Path.relative_to(path, root)
      value = if File.regular?(path), do: File.read!(path), else: :directory
      Map.put(snapshot, relative, value)
    end)
  end
end
