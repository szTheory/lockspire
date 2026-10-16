defmodule Lockspire.Protocol.PrivateJwkTest do
  use ExUnit.Case, async: false

  @moduletag :capture_log

  alias Lockspire.KeyEncryptionHelpers
  alias Lockspire.Protocol.PrivateJwk
  alias Lockspire.TestSupport.TelemetryCapture

  setup do
    KeyEncryptionHelpers.reset_decode_warnings()
    :ok
  end

  defp reject_mode do
    KeyEncryptionHelpers.put_key_encryption(
      keys: KeyEncryptionHelpers.config_keys(),
      current: "test-1",
      legacy_plaintext: :reject
    )
  end

  defp row(bin), do: %{kid: "kid-1", private_jwk_encrypted: bin}

  test "decodes JSON object and safe encoded map keys via the key map" do
    assert {:ok, %{"kty" => "RSA"}} = PrivateJwk.decode(row(~s({"kty":"RSA"})))
    assert {:ok, %{kty: :RSA}} = PrivateJwk.decode(row(:erlang.term_to_binary(%{kty: :RSA})))
  end

  test "decodes structs carrying kid and private_jwk_encrypted" do
    struct = %Lockspire.Domain.SigningKey{
      kid: "kid-1",
      private_jwk_encrypted: ~s({"kty":"RSA"})
    }

    assert {:ok, %{"kty" => "RSA"}} = PrivateJwk.decode(struct)
  end

  test "envelope round trip" do
    sealed = KeyEncryptionHelpers.seal_private_jwk("kid-1", %{"kty" => "RSA", "kid" => "kid-1"})
    assert {:ok, %{"kty" => "RSA", "kid" => "kid-1"}} = PrivateJwk.decode(row(sealed))
  end

  test "forged envelope whose JSON kid differs is rejected" do
    sealed = KeyEncryptionHelpers.seal_private_jwk("kid-1", %{"kty" => "RSA", "kid" => "other"})
    assert {:error, :kid_mismatch} = PrivateJwk.decode_with_reason(row(sealed))
    assert {:error, :invalid_signing_key} = PrivateJwk.decode(row(sealed))
  end

  test "envelope sealed for a different row kid does not open" do
    sealed = KeyEncryptionHelpers.seal_private_jwk("kid-2", %{"kty" => "RSA", "kid" => "kid-2"})
    assert {:error, :invalid_signing_key} = PrivateJwk.decode(row(sealed))
  end

  test "envelope without a configured KEK reports kek_not_configured" do
    sealed = KeyEncryptionHelpers.seal_private_jwk("kid-1", %{"kty" => "RSA", "kid" => "kid-1"})
    KeyEncryptionHelpers.put_key_encryption(nil)
    assert {:error, :kek_not_configured} = PrivateJwk.decode_with_reason(row(sealed))
    assert {:error, :invalid_signing_key} = PrivateJwk.decode(row(sealed))
  end

  test "fails closed for invalid material and never raises" do
    for value <- [
          %{},
          nil,
          42,
          :not_binary,
          %{kid: 1, private_jwk_encrypted: "x"},
          %{kid: "k", private_jwk_encrypted: nil},
          row("not-json"),
          row("[]"),
          row("null"),
          row(<<131, 104>>),
          row("LSK")
        ] do
      assert {:error, :invalid_signing_key} = PrivateJwk.decode(value)
    end
  end

  describe "legacy_plaintext: :reject" do
    setup do
      reject_mode()
      :ok
    end

    test "refuses legacy rows before any parser runs" do
      legacy = KeyEncryptionHelpers.legacy_json_row("kid-1")
      assert {:error, :plaintext_key_refused} = PrivateJwk.decode_with_reason(legacy)

      garbage = row(<<0xFF, 0x00, "not json">>)
      assert {:error, :plaintext_key_refused} = PrivateJwk.decode_with_reason(garbage)

      assert {:error, :invalid_signing_key} = PrivateJwk.decode(legacy)
    end

    test "refuses use: :enc rows too" do
      enc = KeyEncryptionHelpers.legacy_json_row("kid-1", use: :enc)
      assert {:error, :plaintext_key_refused} = PrivateJwk.decode_with_reason(enc)
    end

    test "envelope rows still decode" do
      sealed = KeyEncryptionHelpers.seal_private_jwk("kid-1", %{"kty" => "RSA", "kid" => "kid-1"})
      assert {:ok, %{"kid" => "kid-1"}} = PrivateJwk.decode(row(sealed))
    end

    test "read_stored/2 stays mode-agnostic" do
      legacy = KeyEncryptionHelpers.legacy_json_row("kid-1")

      assert {:ok, %{"kid" => "kid-1"}, :legacy} =
               PrivateJwk.read_stored(
                 legacy,
                 KeyEncryptionHelpers.config_keyset(legacy_plaintext: :reject)
               )
    end

    test "allow mode and no key set keep the legacy path" do
      legacy = KeyEncryptionHelpers.legacy_json_row("kid-1")

      KeyEncryptionHelpers.put_key_encryption(
        keys: KeyEncryptionHelpers.config_keys(),
        current: "test-1"
      )

      assert {:ok, _jwk} = PrivateJwk.decode(legacy)
      KeyEncryptionHelpers.put_key_encryption(nil)
      assert {:ok, _jwk} = PrivateJwk.decode(legacy)
    end
  end

  describe "decode_failed event" do
    setup do
      TelemetryCapture.attach([:lockspire, :key, :decode_failed])
      :ok
    end

    test "refusal emits one event with kid and reason only" do
      reject_mode()

      assert {:error, :invalid_signing_key} =
               PrivateJwk.decode(KeyEncryptionHelpers.legacy_json_row("kid-1"))

      assert_received {:telemetry_event, [:lockspire, :key, :decode_failed], %{count: 1},
                       metadata}

      assert metadata |> Map.keys() |> Enum.sort() == [:kid, :reason]
      assert metadata.reason == :plaintext_key_refused
      refute_received {:telemetry_event, _, _, _}
    end

    test "a tampered envelope adds the kek id" do
      sealed = KeyEncryptionHelpers.seal_private_jwk("kid-1", %{"kty" => "RSA", "kid" => "kid-1"})
      size = byte_size(sealed) - 1
      <<head::binary-size(size), last>> = sealed
      tampered = <<head::binary, Bitwise.bxor(last, 1)>>

      assert {:error, :invalid_signing_key} = PrivateJwk.decode(row(tampered))

      assert_received {:telemetry_event, [:lockspire, :key, :decode_failed], %{count: 1},
                       metadata}

      assert metadata |> Map.keys() |> Enum.sort() == [:kek_id, :kid, :reason]
      assert metadata.reason == :decryption_failed
    end

    test "decode_with_reason/1 and read_stored/2 emit nothing" do
      reject_mode()
      legacy = KeyEncryptionHelpers.legacy_json_row("kid-1")
      PrivateJwk.decode_with_reason(legacy)
      PrivateJwk.read_stored(legacy, KeyEncryptionHelpers.config_keyset())
      refute_received {:telemetry_event, _, _, _}
    end
  end
end
