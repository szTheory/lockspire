defmodule Lockspire.Protocol.PrivateJwkTest do
  use ExUnit.Case, async: false

  alias Lockspire.KeyEncryptionHelpers
  alias Lockspire.Protocol.PrivateJwk

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
end
