defmodule Mix.Tasks.Lockspire.Keys.ReencryptE2ETest do
  use ExUnit.Case, async: false

  import Ecto.Query
  import ExUnit.CaptureIO

  alias Lockspire.KeyEncryptionHelpers, as: Helpers
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.SigningKeyRecord

  @moduletag :integration

  @task "lockspire.keys.reencrypt"

  setup do
    refute Process.whereis(Lockspire.TestRepo),
           "the task must start the repo itself, so this test must begin with it stopped"

    foreign =
      with_repo(fn ->
        Lockspire.TestRepo.aggregate(
          from(k in SigningKeyRecord, where: not like(k.kid, "mig-task-%")),
          :count
        )
      end)

    assert foreign == 0,
           "the committed test database holds #{foreign} signing keys that this test did not " <>
             "create; reset the committed test database before running it"

    on_exit(&cleanup/0)
    Mix.Task.reenable(@task)
    on_exit(fn -> Mix.Task.reenable(@task) end)

    %{prefix: "mig-task-" <> Base.url_encode64(:crypto.strong_rand_bytes(6), padding: false)}
  end

  test "reencrypt then --check on a VM where the repo is not running", %{prefix: prefix} do
    legacy = prefix <> "-legacy"
    other = prefix <> "-other"

    with_repo(fn ->
      Helpers.insert_signing_key_row!(Helpers.legacy_json_row(legacy))
      Helpers.insert_signing_key_row!(Helpers.sealed_row(other, "test-2"))
    end)

    capture_io(fn ->
      assert_raise Mix.Error, fn -> Mix.Task.run(@task, ["--check"]) end
    end)

    refute Process.whereis(Lockspire.TestRepo)
    Mix.Task.reenable(@task)

    output = capture_io(fn -> Mix.Task.run(@task, []) end)
    assert output =~ "encrypted=1"
    assert output =~ "rewrapped=1"
    refute Process.whereis(Lockspire.TestRepo)
    Mix.Task.reenable(@task)

    output = capture_io(fn -> Mix.Task.run(@task, ["--check"]) end)
    assert output =~ "ready=true"
    refute Process.whereis(Lockspire.TestRepo)

    rows = with_repo(fn -> Enum.filter(stored_rows(), &(&1.kid in [legacy, other])) end)
    assert length(rows) == 2

    for row <- rows do
      assert {:ok, "test-1"} = KeyEncryption.envelope_kek_id(row.private_jwk_encrypted)
    end
  end

  defp stored_rows do
    {:ok, rows} = Repository.list_signing_keys()
    rows
  end

  defp with_repo(fun) do
    {:ok, result, _apps} =
      Ecto.Migrator.with_repo(Lockspire.TestRepo, fn _ -> fun.() end, mode: :temporary)

    result
  end

  defp cleanup do
    with_repo(fn ->
      ids =
        Lockspire.TestRepo.all(
          from(k in SigningKeyRecord, where: like(k.kid, "mig-task-%"), select: k.id)
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
end
