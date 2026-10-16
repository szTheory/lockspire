defmodule Mix.Tasks.Lockspire.Doctor.KeyEncryptionTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Lockspire.KeyEncryptionHelpers

  @sentinel "SENTINEL-KEK-MATERIAL"

  setup do
    for name <- ["lockspire.doctor", "lockspire.doctor.key_encryption"] do
      Mix.Task.reenable(name)
      on_exit(fn -> Mix.Task.reenable(name) end)
    end

    :ok
  end

  test "reports the configured key set" do
    output = capture_io(fn -> Mix.Task.run("lockspire.doctor", ["key_encryption"]) end)

    assert output =~ "key_encryption"
    assert output =~ "current=test-1"
    assert output =~ "ids=test-1,test-2"
    assert output =~ "legacy_plaintext=allow"
  end

  test "reports not configured and raises when absent" do
    KeyEncryptionHelpers.put_key_encryption(nil)

    output =
      capture_io(fn ->
        assert_raise Mix.Error, ~r/config\/runtime\.exs/, fn ->
          Mix.Task.run("lockspire.doctor", ["key_encryption"])
        end
      end)

    assert output =~ "not configured"
  end

  test "raises a name-only error for invalid config without leaking material" do
    # Registers env + cache restoration on exit, then the invalid env is set directly.
    KeyEncryptionHelpers.put_key_encryption(Application.fetch_env!(:lockspire, :key_encryption))

    Application.put_env(:lockspire, :key_encryption, keys: [{"bad", @sentinel}], current: "bad")

    output =
      capture_io(fn ->
        error =
          assert_raise Mix.Error, fn ->
            Mix.Task.run("lockspire.doctor", ["key_encryption"])
          end

        assert error.message =~ ":key_encryption"
        refute error.message =~ @sentinel
      end)

    refute output =~ @sentinel
  end

  describe "row counts" do
    setup do
      Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
      start_supervised!(Lockspire.TestRepo)
      Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

      owner = Ecto.Adapters.SQL.Sandbox.start_owner!(Lockspire.TestRepo, shared: true)
      on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(owner) end)

      KeyEncryptionHelpers.put_key_encryption(
        keys: KeyEncryptionHelpers.config_keys(),
        current: "test-1",
        legacy_plaintext: :allow
      )

      :ok
    end

    defp doctor do
      Mix.Task.reenable("lockspire.doctor")
      Mix.Task.reenable("lockspire.doctor.key_encryption")
      test_pid = self()

      output =
        capture_io(fn ->
          result =
            try do
              Mix.Task.run("lockspire.doctor", ["key_encryption"])
              :ok
            rescue
              error in Mix.Error -> {:error, error}
            end

          send(test_pid, {:doctor_result, result})
        end)

      assert_received {:doctor_result, result}
      {output, result}
    end

    defp insert(rows), do: Enum.each(rows, &KeyEncryptionHelpers.insert_signing_key_row!/1)

    test "an empty table keeps the config line and prints a rows line" do
      assert {output, :ok} = doctor()

      assert output =~ "key_encryption: configured current=test-1 ids=test-1,test-2"
      assert output =~ "rows: total=0 on_current=0 other_kek=0 legacy=0"
      refute output =~ "re-encryption"
    end

    test "legacy and other-key rows print per-id counts and a hint without failing" do
      insert([
        KeyEncryptionHelpers.legacy_json_row("a-legacy"),
        KeyEncryptionHelpers.sealed_row("b-other", "test-2"),
        KeyEncryptionHelpers.sealed_row("c-current", "test-1")
      ])

      assert {output, :ok} = doctor()

      assert output =~ "rows: total=3 on_current=1 other_kek=1 legacy=1"
      assert output =~ "kek=test-1 rows=1"
      assert output =~ "kek=test-2 rows=1"
      assert output =~ "2 rows still need re-encryption: run mix lockspire.keys.reencrypt"
    end

    test "an unknown-key row prints counts first and then fails" do
      insert([KeyEncryptionHelpers.sealed_row("a-gone", "gone-1")])

      assert {output, {:error, %Mix.Error{}}} = doctor()
      assert output =~ "unknown_kek=gone-1 rows=1"
    end

    test "an undecryptable row fails" do
      insert([KeyEncryptionHelpers.sealed_row("a-wrong", "test-1", salt: "different")])

      assert {output, {:error, %Mix.Error{}}} = doctor()
      assert output =~ "undecryptable=1"
    end

    test "a stranded retired row is listed and does not fail" do
      insert([
        KeyEncryptionHelpers.sealed_row("a-current", "test-1"),
        KeyEncryptionHelpers.unreadable_legacy_row("b-stranded", status: :retired)
      ])

      assert {output, :ok} = doctor()
      assert output =~ "stranded_retired=1"
      assert output =~ "stranded_retired=1 keys=b-stranded"
      assert output =~ "host database decision"
    end

    test "without a configured key it still shows the legacy count and then fails" do
      insert([KeyEncryptionHelpers.legacy_json_row("a-legacy")])
      KeyEncryptionHelpers.put_key_encryption(nil)

      assert {output, {:error, %Mix.Error{message: message}}} = doctor()
      assert output =~ "not configured"
      assert output =~ "legacy=1"
      assert message =~ "config/runtime.exs"
    end

    test "an unreadable database is reported and fails" do
      Application.put_env(:lockspire, :repo, Lockspire.NoSuchRepo)
      on_exit(fn -> Application.put_env(:lockspire, :repo, Lockspire.TestRepo) end)

      assert {output, {:error, %Mix.Error{}}} = doctor()
      assert output =~ "rows: not inspected (database unreadable)"
    end

    test "output never carries stored bytes or key material" do
      row = KeyEncryptionHelpers.legacy_json_row("a-legacy")
      private_d = Jason.decode!(row.private_jwk_encrypted)["d"]
      insert([row, KeyEncryptionHelpers.sealed_row("b-gone", "gone-1")])

      assert {output, _result} = doctor()
      refute output =~ private_d
      refute output =~ KeyEncryptionHelpers.config_material("test-1")
      refute output =~ "LSK"
    end
  end

  test "--help prints help" do
    output = capture_io(fn -> Mix.Task.run("lockspire.doctor", ["key_encryption", "--help"]) end)
    assert output =~ "mix lockspire.doctor key_encryption"
  end

  test "unknown command lists key_encryption" do
    assert_raise Mix.Error, ~r/mix lockspire\.doctor key_encryption/, fn ->
      Mix.Task.run("lockspire.doctor", ["bogus"])
    end
  end
end
