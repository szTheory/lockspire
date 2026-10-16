defmodule Lockspire.ApplicationKeyEncryptionTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Lockspire.KeyEncryptionHelpers

  alias Lockspire.Config
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Security.KeyEncryption.KeySet

  @sentinel "SENTINEL-KEK-VALUE"

  test "valid block validates and caches the key set" do
    assert :ok = Lockspire.Application.validate_key_encryption!()
    assert %KeySet{current_id: "test-1"} = :persistent_term.get(Config.key_encryption_cache_key())
    assert %KeySet{current_id: "test-1"} = Config.key_encryption_keyset()
  end

  test "absent block warns naming only the setting and caches :unconfigured" do
    capture_log(fn -> put_key_encryption(nil) end)

    assert Application.get_env(:lockspire, :key_encryption) == nil
    assert Config.key_encryption_keyset() == nil
    assert :persistent_term.get(Config.key_encryption_cache_key()) == :unconfigured

    log =
      capture_log([level: :warning], fn ->
        assert :ok = Lockspire.Application.validate_key_encryption!()
      end)

    assert log =~ ":key_encryption"
    assert log =~ "not configured"
  end

  test "invalid block raises a name-only error and does not leak the value" do
    Application.put_env(:lockspire, :key_encryption, keys: [{"a", @sentinel}], current: "a")
    on_exit(fn -> restore_default() end)

    error =
      assert_raise(ArgumentError, fn -> Lockspire.Application.validate_key_encryption!() end)

    assert Exception.message(error) =~ ":key_encryption"
    refute Exception.message(error) =~ @sentinel
  end

  test "helper restores env and cache after the test" do
    defaults = Application.get_env(:lockspire, :key_encryption)
    assert defaults != nil
  end

  test "put_key_encryption/1 swaps a valid config and seal_private_jwk round-trips" do
    keys = [{"swap-1", :crypto.hash(:sha256, "swap") |> Base.encode64()}]
    put_key_encryption(keys: keys, current: "swap-1")

    assert %KeySet{current_id: "swap-1"} = Config.key_encryption_keyset()

    jwk = %{"kty" => "oct", "kid" => "kid-1"}
    sealed = seal_private_jwk("kid-1", jwk)
    assert {:ok, json} = KeyEncryption.open(Config.key_encryption_keyset(), "kid-1", sealed)
    assert json == Jason.encode!(jwk)
  end

  defp restore_default do
    Application.put_env(:lockspire, :key_encryption,
      keys: [
        {"test-1", :crypto.hash(:sha256, "lockspire-test-kek-1") |> Base.encode64()},
        {"test-2", :crypto.hash(:sha256, "lockspire-test-kek-2") |> Base.encode64()}
      ],
      current: "test-1",
      legacy_plaintext: :allow
    )

    Lockspire.Application.validate_key_encryption!()
  end
end
