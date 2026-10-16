defmodule Mix.Tasks.Lockspire.Keys.ReencryptArgsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @task "lockspire.keys.reencrypt"

  @forbidden ~r/\b(phase|plan|wave|D-\d+|MIG-\d+|OPS-\d+|SAFE-\d+)\b/i

  setup do
    Mix.Task.reenable(@task)
    on_exit(fn -> Mix.Task.reenable(@task) end)
    :ok
  end

  for args <- [["check"], ["--bogus"], ["--check", "--dry-run"]] do
    test "#{inspect(args)} raises before the repo is touched" do
      assert_raise Mix.Error, fn -> Mix.Task.run(@task, unquote(args)) end
      refute Process.whereis(Lockspire.TestRepo)
    end
  end

  test "--check with --dry-run says why they cannot be combined" do
    error =
      assert_raise Mix.Error, fn -> Mix.Task.run(@task, ["--check", "--dry-run"]) end

    assert error.message == "--check and --dry-run cannot be combined; --check never writes"
  end

  test "a positional argument is rejected with the dashed flag suggested" do
    error = assert_raise Mix.Error, fn -> Mix.Task.run(@task, ["check"]) end
    assert error.message =~ "check"
    assert error.message =~ "--check"
  end

  test "--help prints the upgrade and rotation order" do
    output = capture_io(fn -> Mix.Task.run(@task, ["--help"]) end)

    assert output =~ "deploy"
    assert output =~ "mix lockspire.keys.reencrypt"
    assert output =~ "--check"
    assert output =~ ":reject"
    assert output =~ "next boot"
    assert output =~ "bin/app rpc"
    assert output =~ "same config"

    positions =
      for step <- [
            "1. Add the new key to :keys",
            "2. Switch :current",
            "3. Run mix lockspire.keys.reencrypt",
            "4. Run mix lockspire.keys.reencrypt --check",
            "5. Remove the old id"
          ] do
        {position, _length} = :binary.match(output, step)
        position
      end

    assert positions == Enum.sort(positions)
    refute output =~ @forbidden
    refute Process.whereis(Lockspire.TestRepo)
  end
end

defmodule Mix.Tasks.Lockspire.Keys.ReencryptE2ETest do
  use ExUnit.Case, async: false

  import Ecto.Query
  import ExUnit.CaptureIO

  alias Lockspire.Admin
  alias Lockspire.Admin.Keys
  alias Lockspire.KeyEncryptionHelpers, as: Helpers
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.SigningKeyRecord
  alias Lockspire.TestSupport.TelemetryCapture

  @moduletag :integration

  @task "lockspire.keys.reencrypt"
  @completed [:lockspire, :key, :reencrypt_completed]

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

    seed([Helpers.legacy_json_row(legacy), Helpers.sealed_row(other, "test-2")])

    assert {_output, {:error, _}} = run_task(["--check"])
    refute Process.whereis(Lockspire.TestRepo)

    assert {output, :ok} = run_task([])
    assert output =~ "encrypted=1"
    assert output =~ "rewrapped=1"
    refute Process.whereis(Lockspire.TestRepo)

    assert {output, :ok} = run_task(["--check"])
    assert output =~ "ready=true"
    refute Process.whereis(Lockspire.TestRepo)

    rows = stored(prefix)
    assert length(rows) == 2

    for row <- rows do
      assert {:ok, "test-1"} = KeyEncryption.envelope_kek_id(row.private_jwk_encrypted)
    end
  end

  test "--dry-run lists the planned changes, exits 0 and writes nothing", %{prefix: prefix} do
    legacy = prefix <> "-legacy"
    other = prefix <> "-other"
    seed([Helpers.legacy_json_row(legacy), Helpers.sealed_row(other, "test-2")])
    before_bytes = Enum.map(stored(prefix), & &1.private_jwk_encrypted)
    audits = audit_count()

    assert {output, :ok} = run_task(["--dry-run"])

    assert output =~ "Dry run: no rows will be changed."
    assert output =~ "would encrypt  key=#{legacy} from=legacy to=test-1"
    assert output =~ "would re-wrap  key=#{other} from=test-2 to=test-1"
    assert output =~ "would_encrypt=1"
    assert output =~ "would_rewrap=1"
    assert output =~ "failed=0"
    assert output =~ "Dry run complete. Run without --dry-run to apply."

    assert Enum.map(stored(prefix), & &1.private_jwk_encrypted) == before_bytes
    assert audit_count() == audits
  end

  test "--dry-run exits 1 when a row would fail", %{prefix: prefix} do
    seed([Helpers.sealed_row(prefix <> "-gone", "gone-1")])

    assert {output, {:error, %Mix.Error{}}} = run_task(["--dry-run"])
    assert output =~ "reason=unknown_kek"
  end

  test "a failed row is reported with a fix line while the other rows are saved", %{
    prefix: prefix
  } do
    gone = prefix <> "-gone"
    legacy = prefix <> "-legacy"
    other = prefix <> "-other"

    seed([
      Helpers.sealed_row(gone, "gone-1"),
      Helpers.legacy_json_row(legacy),
      Helpers.sealed_row(other, "test-2")
    ])

    assert {output, {:error, %Mix.Error{message: message}}} = run_task([])

    assert output =~ "failed  key=#{gone} reason=unknown_kek kek=gone-1"
    assert output =~ "fix:"
    assert message =~ "All other keys were saved"
    assert message =~ "rerunning is safe"

    rows = Map.new(stored(prefix), &{&1.kid, &1})
    assert {:ok, "test-1"} = KeyEncryption.envelope_kek_id(rows[legacy].private_jwk_encrypted)
    assert {:ok, "test-1"} = KeyEncryption.envelope_kek_id(rows[other].private_jwk_encrypted)
    assert {:ok, "gone-1"} = KeyEncryption.envelope_kek_id(rows[gone].private_jwk_encrypted)
  end

  test "under :reject the run warns and still converts legacy rows", %{prefix: prefix} do
    Helpers.put_key_encryption(
      keys: Helpers.config_keys(),
      current: "test-1",
      legacy_plaintext: :reject
    )

    seed([Helpers.legacy_json_row(prefix <> "-legacy")])

    assert {output, :ok} = run_task([])
    assert output =~ "warning: legacy_plaintext is :reject"
    assert output =~ "encrypted=1"
  end

  test "output never contains key material", %{prefix: prefix} do
    [legacy_row, _] =
      seed([
        Helpers.legacy_json_row(prefix <> "-legacy"),
        Helpers.sealed_row(prefix <> "-g", "gone-1")
      ])

    private_d = Jason.decode!(legacy_row.private_jwk_encrypted)["d"]

    outputs =
      for args <- [["--dry-run"], [], ["--check"]] do
        {output, _result} = run_task(args)
        output
      end

    for output <- outputs do
      refute output =~ private_d
      refute output =~ Helpers.config_material("test-1")
      refute output =~ Helpers.config_material("test-2")
      refute output =~ "LSK"
    end
  end

  test "--check emits one completed event with the shared measurement schema", %{prefix: prefix} do
    seed([Helpers.legacy_json_row(prefix <> "-legacy")])
    TelemetryCapture.attach(@completed)

    assert {_output, {:error, _}} = run_task(["--check"])
    assert_receive {:telemetry_event, @completed, check_measurements, %{mode: :check}}
    refute_receive {:telemetry_event, @completed, _, _}, 50

    assert {_output, :ok} = run_task([])
    assert_receive {:telemetry_event, @completed, apply_measurements, %{mode: :apply}}

    assert Enum.sort(Map.keys(check_measurements)) == Enum.sort(Map.keys(apply_measurements))
    assert Map.has_key?(check_measurements, :pending)
    assert Map.has_key?(check_measurements, :stranded_retired)
    assert check_measurements.pending >= 1
  end

  test "the admin functions report the repo as not started while it is stopped" do
    assert {:error, :repo_not_started} = Keys.reencrypt()
    assert {:error, :repo_not_started} = Keys.encryption_status()
  end

  test "a stranded retired row does not block readiness and is listed", %{prefix: prefix} do
    stranded = prefix <> "-stranded"

    seed([
      Helpers.unreadable_legacy_row(stranded, status: :retired),
      Helpers.legacy_json_row(prefix <> "-legacy")
    ])

    assert {output, {:error, %Mix.Error{}}} = run_task([])
    assert output =~ "failed  key=#{stranded} reason=unreadable_legacy kek=none"
    assert output =~ "already retired"
    assert output =~ "does not block readiness"
    assert output =~ "host database decision"
    refute output =~ "generate a replacement"

    assert {:ok, status} = with_repo(fn -> Keys.encryption_status() end)
    assert status.stranded_retired == %{count: 1, kids: [stranded]}
    assert status.ready?

    assert {output, :ok} = run_task(["--check"])
    assert output =~ "ready=true"
    assert output =~ "stranded_retired=1"
    assert output =~ "stranded  key=#{stranded} status=retired"
    assert output =~ "stored bytes remain"
    assert output =~ "host database decision"
  end

  test "an active unreadable row blocks until it is retired", %{prefix: prefix} do
    unreadable = prefix <> "-active"
    [row] = seed([Helpers.unreadable_legacy_row(unreadable, status: :active)])

    assert {output, {:error, %Mix.Error{}}} = run_task(["--check"])
    assert output =~ "pending  key=#{unreadable} state=unsealable_legacy"
    assert output =~ "retire this key and generate a replacement"

    replacement_id =
      with_repo(fn ->
        {:ok, generated} = Admin.generate_key(:sig)
        id = generated.key.id
        {:ok, _} = Admin.publish_key(id)
        {:ok, _} = Admin.activate_key(id)
        {:ok, _} = Admin.retire_key(row.id)
        id
      end)

    on_exit(fn -> with_repo(fn -> delete_ids([replacement_id]) end) end)

    assert {output, :ok} = run_task(["--check"])
    assert output =~ "stranded  key=#{unreadable} status=retired"
  end

  defp run_task(args) do
    Mix.Task.reenable(@task)
    test_pid = self()

    output =
      capture_io(fn ->
        result =
          try do
            Mix.Task.run(@task, args)
            :ok
          rescue
            error in Mix.Error -> {:error, error}
          end

        send(test_pid, {:task_result, result})
      end)

    assert_received {:task_result, result}
    {output, result}
  end

  defp seed(rows) do
    with_repo(fn -> Enum.map(rows, &Helpers.insert_signing_key_row!/1) end)
  end

  defp stored(prefix) do
    with_repo(fn ->
      {:ok, rows} = Repository.list_signing_keys()
      rows |> Enum.filter(&String.starts_with?(&1.kid, prefix)) |> Enum.sort_by(& &1.id)
    end)
  end

  defp audit_count do
    with_repo(fn ->
      Lockspire.TestRepo.aggregate(
        from(a in AuditEventRecord,
          where: a.action in ["key_encrypted", "key_rewrapped"]
        ),
        :count
      )
    end)
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

      delete_ids(ids)
    end)
  end

  defp delete_ids(ids) do
    string_ids = Enum.map(ids, &to_string/1)

    Lockspire.TestRepo.delete_all(
      from(a in AuditEventRecord,
        where: a.resource_type == "signing_key" and a.resource_id in ^string_ids
      )
    )

    Lockspire.TestRepo.delete_all(from(k in SigningKeyRecord, where: k.id in ^ids))
  end
end
