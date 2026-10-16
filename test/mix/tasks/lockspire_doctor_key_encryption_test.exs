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
