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

  test "read-only recovery status leaves an interrupted create transaction byte-identical and retry recovers it",
       %{
         root: root
       } do
    artifacts = [
      artifact("lib/example_web/operator_authorization.ex", :host_owned, :absent, "deny policy"),
      artifact("lib/example_web/router/lockspire.ex", :managed, :absent, "native helper"),
      manifest(:absent, "committed last")
    ]

    FileTransaction.with_test_failure(:after_host_owned_create, fn ->
      assert {:error, [%{type: :interrupted}]} = FileTransaction.apply(root, artifacts)
    end)

    assert File.read!(Path.join(root, "lib/example_web/operator_authorization.ex")) ==
             "deny policy"

    assert FileTransaction.recovery_status(root) ==
             {:recovery_required,
              "An interrupted install transaction needs recovery. Rerun `mix lockspire.upgrade` without `--dry-run` before previewing again."}

    interrupted = tree_snapshot(root)
    assert FileTransaction.recovery_status(root) |> elem(0) == :recovery_required
    assert tree_snapshot(root) == interrupted

    assert :ok = FileTransaction.apply(root, artifacts)

    assert File.read!(Path.join(root, "lib/example_web/operator_authorization.ex")) ==
             "deny policy"

    assert File.read!(Path.join(root, "lib/example_web/router/lockspire.ex")) == "native helper"
    assert File.read!(Path.join(root, ".lockspire/install_manifest.json")) == "committed last"
    assert FileTransaction.recovery_status(root) == :clean
  end

  test "read-only recovery status refuses symlinked journal ancestry without creating or changing paths",
       %{
         root: root
       } do
    before = tree_snapshot(root)
    assert FileTransaction.recovery_status(root) == :clean
    assert tree_snapshot(root) == before

    outside = Path.join(root, "outside-state")
    File.mkdir_p!(outside)
    File.ln_s!(outside, Path.join(root, ".lockspire"))
    snapshot = tree_snapshot(root)

    assert {:error, [%{type: :unsafe_path}]} = FileTransaction.recovery_status(root)
    assert tree_snapshot(root) == snapshot
  end

  test "an interruption after both the new policy seam and managed helper recovers before retry",
       %{root: root} do
    helper = "lib/example_web/router/lockspire.ex"

    artifacts = [
      artifact("lib/example_web/operator_authorization.ex", :host_owned, :absent, "deny policy"),
      artifact(helper, :managed, :absent, "native helper"),
      manifest(:absent, "committed last")
    ]

    FileTransaction.with_test_failure({:after_artifact, helper}, fn ->
      assert {:error, [%{type: :interrupted}]} = FileTransaction.apply(root, artifacts)
    end)

    assert File.read!(Path.join(root, "lib/example_web/operator_authorization.ex")) ==
             "deny policy"

    assert File.read!(Path.join(root, helper)) == "native helper"
    refute File.exists?(Path.join(root, ".lockspire/install_manifest.json"))
    assert FileTransaction.recovery_status(root) |> elem(0) == :recovery_required

    assert :ok = FileTransaction.apply(root, artifacts)

    assert File.read!(Path.join(root, "lib/example_web/operator_authorization.ex")) ==
             "deny policy"

    assert File.read!(Path.join(root, helper)) == "native helper"
    assert File.read!(Path.join(root, ".lockspire/install_manifest.json")) == "committed last"
    assert FileTransaction.recovery_status(root) == :clean
  end

  test "a write-ahead intent recovers a create interrupted before completion is journaled", %{
    root: root
  } do
    path = "lib/example_web/operator_authorization.ex"

    FileTransaction.with_test_failure({:after_target_write, path}, fn ->
      assert {:error, [%{type: :interrupted}]} =
               FileTransaction.apply(root, [
                 artifact(path, :host_owned, :absent, "deny policy"),
                 manifest(:absent, "manifest")
               ])
    end)

    assert File.read!(Path.join(root, path)) == "deny policy"
    journal = Jason.decode!(File.read!(Path.join(root, ".lockspire/install_transaction.json")))
    assert journal["pending"]["relative_path"] == path
    assert journal["committed"] == []

    assert :ok = FileTransaction.recover(root)
    refute File.exists?(Path.join(root, path))
    refute File.exists?(Path.join(root, ".lockspire/install_transaction.json"))
  end

  test "an intent whose absent target now contains competing host bytes is preserved", %{
    root: root
  } do
    path = "lib/example_web/router/lockspire.ex"

    FileTransaction.with_test_failure(:after_intent_journal, fn ->
      assert {:error, [%{type: :interrupted}]} =
               FileTransaction.apply(root, [
                 artifact(path, :managed, :absent, "generated helper"),
                 manifest(:absent, "manifest")
               ])
    end)

    File.mkdir_p!(Path.dirname(Path.join(root, path)))
    File.write!(Path.join(root, path), "host-owned competing bytes")

    assert {:error, [%{type: :recovery_required}]} = FileTransaction.recover(root)
    assert File.read!(Path.join(root, path)) == "host-owned competing bytes"
    assert File.exists?(Path.join(root, ".lockspire/install_transaction.json"))
  end

  test "updated policy and helper intents restore old bytes after an interrupted write", %{
    root: root
  } do
    policy = "lib/example_web/operator_authorization.ex"
    helper = "lib/example_web/router/lockspire.ex"
    File.mkdir_p!(Path.dirname(Path.join(root, policy)))
    File.mkdir_p!(Path.dirname(Path.join(root, helper)))
    File.write!(Path.join(root, policy), "old policy")
    File.write!(Path.join(root, helper), "old helper")

    artifacts = [
      artifact(policy, :host_owned, Manifest.checksum("old policy"), "new policy"),
      artifact(helper, :managed, Manifest.checksum("old helper"), "new helper"),
      manifest(:absent, "manifest")
    ]

    FileTransaction.with_test_failure({:after_target_write, helper}, fn ->
      assert {:error, [%{type: :interrupted}]} = FileTransaction.apply(root, artifacts)
    end)

    assert File.read!(Path.join(root, policy)) == "new policy"
    assert File.read!(Path.join(root, helper)) == "new helper"
    assert :ok = FileTransaction.recover(root)
    assert File.read!(Path.join(root, policy)) == "old policy"
    assert File.read!(Path.join(root, helper)) == "old helper"
  end

  test "a failed journal replacement keeps the prior journal recoverable and does not mutate target",
       %{root: root} do
    path = "lib/example_web/operator_authorization.ex"

    FileTransaction.with_test_failure(:before_intent_journal_replace, fn ->
      assert {:error, [%{type: :interrupted}]} =
               FileTransaction.apply(root, [
                 artifact(path, :host_owned, :absent, "deny policy"),
                 manifest(:absent, "manifest")
               ])
    end)

    refute File.exists?(Path.join(root, path))
    journal_path = Path.join(root, ".lockspire/install_transaction.json")
    journal = Jason.decode!(File.read!(journal_path))
    assert is_nil(journal["pending"])
    assert FileTransaction.recovery_status(root) |> elem(0) == :recovery_required
    assert :ok = FileTransaction.recover(root)
    refute File.exists?(journal_path)
  end

  test "recovery finishes cleanup after a rolled-back terminal marker", %{root: root} do
    path = "lib/example_web/operator_authorization.ex"

    artifacts = [
      artifact(path, :host_owned, :absent, "deny policy"),
      manifest(:absent, "manifest")
    ]

    FileTransaction.with_test_failure(
      [:after_rolled_back_terminal, {:ordinary_failure, :before_manifest_commit}],
      fn ->
        assert {:error, [%{type: :interrupted}]} = FileTransaction.apply(root, artifacts)
      end
    )

    refute File.exists?(Path.join(root, path))
    journal_path = Path.join(root, ".lockspire/install_transaction.json")
    journal = Jason.decode!(File.read!(journal_path))
    assert journal["terminal"] == "rolled_back"

    journal =
      Map.put(journal, "committed", [
        %{
          "relative_path" => path,
          "action" => "created",
          "checksum" => Manifest.checksum("deny policy")
        }
      ])

    File.write!(journal_path, Jason.encode!(journal))

    assert :ok = FileTransaction.recover(root)
    assert :ok = FileTransaction.apply(root, artifacts)
    assert File.read!(Path.join(root, path)) == "deny policy"
  end

  test "a legacy journal without pending or terminal fields still recovers", %{root: root} do
    path = "priv/repo/migrations/legacy.exs"
    tx_root = Path.join(root, ".lockspire/.install-tx-legacy")
    stage_path = Path.join(tx_root, "staged-0")
    target = Path.join(root, path)
    File.mkdir_p!(Path.dirname(stage_path))
    File.mkdir_p!(Path.dirname(target))
    File.write!(stage_path, "legacy migration")
    File.write!(target, "legacy migration")

    File.write!(
      Path.join(root, ".lockspire/install_transaction.json"),
      Jason.encode!(%{
        "root" => root,
        "tx_root" => tx_root,
        "artifacts" => [%{"relative_path" => path, "stage_path" => stage_path}],
        "committed" => [
          %{
            "relative_path" => path,
            "action" => "created",
            "checksum" => Manifest.checksum("legacy migration")
          }
        ]
      })
    )

    assert :ok = FileTransaction.recover(root)
    refute File.exists?(target)
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
