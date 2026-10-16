defmodule Lockspire.Storage.ReencryptConcurrencyTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Lockspire.Admin
  alias Lockspire.KeyEncryptionHelpers, as: Helpers
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.Repository.SigningKeyStore
  alias Lockspire.Storage.Ecto.SigningKeyRecord

  @moduletag :integration

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    unless Process.whereis(Lockspire.TestRepo) do
      start_supervised!(Lockspire.TestRepo)
    end

    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    Helpers.put_key_encryption(
      keys: Helpers.config_keys(),
      current: "test-1",
      legacy_plaintext: :allow
    )

    prefix = "reenc-conc-" <> Base.url_encode64(:crypto.strong_rand_bytes(6), padding: false)
    test_pid = self()

    on_exit(fn -> cleanup(prefix) end)
    %{prefix: prefix, test_pid: test_pid}
  end

  describe "overlapping runs" do
    test "two runs in lockstep convert each row exactly once", %{prefix: prefix} do
      rows =
        seed([
          Helpers.legacy_json_row(prefix <> "-1", status: :retired),
          Helpers.legacy_json_row(prefix <> "-2", status: :retired),
          Helpers.sealed_row(prefix <> "-3", "test-2", status: :retired)
        ])

      kids = Enum.map(rows, & &1.kid)
      test_pid = self()

      a = start_run(:a, kids, test_pid)
      assert_receive {:locked, :a, first}, 10_000
      assert first == hd(kids)

      b = start_run(:b, kids, test_pid)
      assert_waiting_on_lock()
      release(a, :a, first)

      kids
      |> Enum.with_index()
      |> Enum.each(fn {kid, index} ->
        next = Enum.at(kids, index + 1)

        assert_receive {:locked, :b, ^kid}, 10_000
        if next, do: assert_receive({:locked, :a, ^next}, 10_000)
        release(b, :b, kid)

        if next do
          assert_waiting_on_lock()
          release(a, :a, next)
        end
      end)

      assert {:ok, report_a} = Task.await(a.task, 30_000)
      assert {:ok, report_b} = Task.await(b.task, 30_000)

      assert report_a |> ours(kids, :changes) |> Enum.map(& &1.kid) |> Enum.sort() ==
               Enum.sort(kids)

      assert ours(report_b, kids, :changes) == []
      assert ours(report_b, kids, :failed) == []
      assert ours(report_a, kids, :failed) == []
      assert report_a.scanned == report_b.scanned

      for kid <- kids, do: assert_single_layer(kid)
    end

    test "six simultaneous runs convert each row exactly once", %{prefix: prefix} do
      rows = seed(for n <- 1..6, do: Helpers.legacy_json_row("#{prefix}-#{n}", status: :retired))
      kids = Enum.map(rows, & &1.kid)
      parent = self()

      tasks =
        for _contender <- 1..6 do
          Task.async(fn ->
            send(parent, {:ready, self()})

            receive do
              :go -> unboxed(fn -> Admin.reencrypt() end)
            end
          end)
        end

      for _task <- tasks do
        assert_receive {:ready, pid}, 5_000
        send(pid, :go)
      end

      reports = for result <- Task.await_many(tasks, 60_000), do: elem_ok(result)

      changed = reports |> Enum.flat_map(&ours(&1, kids, :changes)) |> Enum.map(& &1.kid)
      assert Enum.sort(changed) == Enum.sort(kids)

      for report <- reports, do: assert(ours(report, kids, :failed) == [])
      assert reports |> Enum.map(& &1.scanned) |> Enum.uniq() |> length() == 1

      for row <- rows do
        assert_single_layer(row.kid)
        assert audit_count_for(row.id) == 1
      end
    end
  end

  describe "store branches" do
    test "a changed row is a conflict and nothing is written", %{prefix: prefix} do
      [row] = seed([Helpers.legacy_json_row(prefix <> "-cas", status: :retired)])
      replacement = Helpers.sealed_row(prefix <> "-cas", "test-1").private_jwk_encrypted

      decide = fn key ->
        {1, _} =
          Lockspire.TestRepo.update_all(
            from(k in SigningKeyRecord, where: k.id == ^key.id),
            set: [private_jwk_encrypted: "overwritten-elsewhere"]
          )

        {:replace, replacement, audit_event(key), %{key_id: key.id}}
      end

      assert {:ok, :conflict} =
               unboxed(fn ->
                 SigningKeyStore.reencrypt_signing_key(Lockspire.TestRepo, row.id, decide, [])
               end)

      assert stored_bytes(row.id) == "overwritten-elsewhere"
      assert audit_count_for(row.id) == 0
    end

    test "a rejected audit record rolls the replacement back", %{prefix: prefix} do
      [row] = seed([Helpers.legacy_json_row(prefix <> "-audit", status: :retired)])
      replacement = Helpers.sealed_row(prefix <> "-audit", "test-1").private_jwk_encrypted

      decide = fn key ->
        {:replace, replacement, %{audit_event(key) | action: nil}, %{key_id: key.id}}
      end

      assert {:error, _reason} =
               unboxed(fn ->
                 SigningKeyStore.reencrypt_signing_key(Lockspire.TestRepo, row.id, decide, [])
               end)

      assert stored_bytes(row.id) == row.private_jwk_encrypted
      assert audit_count_for(row.id) == 0
    end
  end

  describe "lock coexistence" do
    test "activation does not wait for a row the engine is holding", %{prefix: prefix} do
      assert_no_foreign_active_sig_key(prefix)

      [held, target] =
        seed([
          Helpers.legacy_json_row(prefix <> "-held", status: :retired),
          Helpers.legacy_json_row(prefix <> "-target",
            status: :upcoming,
            published_at: DateTime.utc_now()
          )
        ])

      a = start_run(:a, [held.kid], self())
      assert_receive {:locked, :a, kid}, 10_000
      assert kid == held.kid

      activation =
        Task.async(fn ->
          unboxed(fn -> Repository.activate_signing_key(target.id, DateTime.utc_now()) end)
        end)

      case Task.yield(activation, 5_000) do
        {:ok, result} ->
          assert {:ok, %{activated_key: %{kid: activated}}} = result
          assert activated == target.kid

        nil ->
          release(a, :a, held.kid)
          Task.shutdown(activation, :brutal_kill)
          flunk("activation waited on the row the engine holds; it should lock only its own set")
      end

      release(a, :a, held.kid)
      assert {:ok, _report} = Task.await(a.task, 30_000)
    end
  end

  defp start_run(name, kids, test_pid) do
    hook = fn key ->
      if key.kid in kids do
        send(test_pid, {:locked, name, key.kid})

        receive do
          {:release, ^name, kid} when kid == key.kid -> :ok
        after
          30_000 -> raise "run #{name} was never released on #{key.kid}"
        end
      end
    end

    task = Task.async(fn -> unboxed(fn -> Admin.reencrypt(after_lock: hook) end) end)
    %{task: task}
  end

  defp release(%{task: %Task{pid: pid}}, name, kid), do: send(pid, {:release, name, kid})

  defp assert_waiting_on_lock(attempts \\ 40) do
    waiting =
      unboxed(fn ->
        %{rows: [[count]]} =
          Lockspire.TestRepo.query!(
            "SELECT count(*) FROM pg_stat_activity WHERE wait_event_type = 'Lock' " <>
              "AND datname = current_database()"
          )

        count
      end)

    cond do
      waiting > 0 ->
        :ok

      attempts > 0 ->
        Process.sleep(50)
        assert_waiting_on_lock(attempts - 1)

      true ->
        flunk("no backend is waiting on a row lock")
    end
  end

  defp assert_no_foreign_active_sig_key(prefix) do
    pattern = prefix <> "%"

    count =
      unboxed(fn ->
        Lockspire.TestRepo.aggregate(
          from(k in SigningKeyRecord,
            where: k.status == :active and k.use == :sig and not like(k.kid, ^pattern)
          ),
          :count
        )
      end)

    assert count == 0,
           "the committed test database holds #{count} active sig signing key(s) this test " <>
             "did not seed; reset the committed test database before running this test"
  end

  defp assert_single_layer(kid) do
    bytes = unboxed(fn -> Lockspire.TestRepo.get_by!(SigningKeyRecord, kid: kid) end)
    stored = bytes.private_jwk_encrypted

    assert {:ok, plaintext} = KeyEncryption.open(Helpers.config_keyset(), kid, stored)
    refute String.starts_with?(plaintext, "LSK")
    assert {:ok, %{"kid" => ^kid}} = Jason.decode(plaintext)
  end

  defp ours(report, kids, field),
    do: Enum.filter(Map.fetch!(report, field), &(&1.kid in kids))

  defp elem_ok({:ok, report}), do: report

  defp audit_event(key) do
    %{
      action: :key_encrypted,
      outcome: :succeeded,
      reason_code: :key_encrypted,
      actor: %{type: :operator},
      resource: %{type: :signing_key, id: key.id},
      metadata: %{key_id: key.id, kid: key.kid}
    }
  end

  defp stored_bytes(id) do
    unboxed(fn -> Lockspire.TestRepo.get!(SigningKeyRecord, id).private_jwk_encrypted end)
  end

  defp audit_count_for(id) do
    unboxed(fn ->
      Lockspire.TestRepo.aggregate(
        from(a in AuditEventRecord,
          where:
            a.resource_type == "signing_key" and a.resource_id == ^to_string(id) and
              a.action in ["key_encrypted", "key_rewrapped"]
        ),
        :count
      )
    end)
  end

  defp seed(rows) do
    unboxed(fn -> Enum.map(rows, &Helpers.insert_signing_key_row!/1) end)
  end

  defp cleanup(prefix) do
    pattern = prefix <> "%"

    unboxed(fn ->
      ids =
        Lockspire.TestRepo.all(
          from(k in SigningKeyRecord, where: like(k.kid, ^pattern), select: k.id)
        )

      string_ids = Enum.map(ids, &to_string/1)

      Lockspire.TestRepo.delete_all(
        from(a in AuditEventRecord,
          where: a.resource_type == "signing_key" and a.resource_id in ^string_ids
        )
      )

      Lockspire.TestRepo.delete_all(from(k in SigningKeyRecord, where: k.id in ^ids))
    end)
  end

  defp unboxed(fun), do: Ecto.Adapters.SQL.Sandbox.unboxed_run(Lockspire.TestRepo, fun)
end
