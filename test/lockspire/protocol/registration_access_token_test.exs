defmodule Lockspire.Protocol.RegistrationAccessTokenTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.RegistrationAccessToken
  alias Lockspire.Security.Policy

  describe "generate/0" do
    test "returns a {plaintext, hash} tuple of binaries" do
      {plaintext, hash} = RegistrationAccessToken.generate()
      assert is_binary(plaintext)
      assert is_binary(hash)
    end

    test "plaintext is URL-safe Base64 unpadded" do
      {plaintext, _hash} = RegistrationAccessToken.generate()
      assert plaintext =~ ~r/^[A-Za-z0-9_-]+$/
      # 32 bytes -> ceil(32 * 4 / 3) = 44, minus 1 unpadded = 43 chars
      assert byte_size(plaintext) == 43
    end

    test "two calls return different plaintext" do
      {p1, _} = RegistrationAccessToken.generate()
      {p2, _} = RegistrationAccessToken.generate()
      refute p1 == p2
    end

    test "hash equals Policy.hash_token(plaintext)" do
      {plaintext, hash} = RegistrationAccessToken.generate()
      assert hash == Policy.hash_token(plaintext)
    end

    test "hash is 64 lowercase hex chars" do
      {_, hash} = RegistrationAccessToken.generate()
      assert byte_size(hash) == 64
      assert hash =~ ~r/^[0-9a-f]{64}$/
    end
  end

  describe "hash/1" do
    test "matches Policy.hash_token/1" do
      plaintext = "fixed-test-value"
      assert RegistrationAccessToken.hash(plaintext) == Policy.hash_token(plaintext)
    end

    test "is deterministic" do
      plaintext = "deterministic"
      h1 = RegistrationAccessToken.hash(plaintext)
      h2 = RegistrationAccessToken.hash(plaintext)
      assert h1 == h2
    end
  end

  describe "verify/2" do
    test "returns true when stored_hash matches hash_token(candidate)" do
      plaintext = "valid-rat"
      stored = Policy.hash_token(plaintext)
      assert RegistrationAccessToken.verify(stored, plaintext) == true
    end

    test "returns false on mismatch" do
      stored = Policy.hash_token("a-different-rat")
      assert RegistrationAccessToken.verify(stored, "not-the-rat") == false
    end

    test "returns false when stored_hash and computed hash differ in length" do
      # Plug.Crypto.secure_compare returns false on length mismatch, no raise
      assert RegistrationAccessToken.verify("short", "anything") == false
    end
  end
end
