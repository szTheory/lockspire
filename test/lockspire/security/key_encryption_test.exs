defmodule Lockspire.Security.KeyEncryptionTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Lockspire.Config
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Security.KeyEncryption.KeySet

  defp kek(n), do: :crypto.hash(:sha256, "cipher-test-kek-#{n}") |> Base.encode64()

  defp keyset(ids, current) do
    {:ok, ks} = KeySet.new(keys: Enum.map(ids, &{&1, kek(&1)}), current: current)
    ks
  end

  defp flip(bin, index) do
    <<head::binary-size(index), byte, rest::binary>> = bin
    <<head::binary, Bitwise.bxor(byte, 1), rest::binary>>
  end

  @plaintext ~s({"kty":"oct","kid":"k1"})
  # header = 3 magic + 1 version + 1 id_len + id
  defp tag_offset(id), do: 5 + byte_size(id) + 12

  test "test.exs KEK flows through Config into seal/open" do
    keyset = Config.key_encryption!()
    assert %KeySet{current_id: "test-1"} = keyset

    assert {:ok, <<"LSK", 1, 6, "test-1", _::binary>> = envelope} =
             KeyEncryption.seal(keyset, "k1", @plaintext)

    assert {:ok, @plaintext} = KeyEncryption.open(keyset, "k1", envelope)
    assert {:ok, "test-1"} = KeyEncryption.envelope_kek_id(envelope)
  end

  describe "tamper resistance" do
    setup do
      ks = keyset(["test-1", "test-2"], "test-1")
      {:ok, envelope} = KeyEncryption.seal(ks, "k1", @plaintext)
      %{ks: ks, envelope: envelope}
    end

    test "flipped ciphertext byte fails", %{ks: ks, envelope: envelope} do
      tampered = flip(envelope, byte_size(envelope) - 1)
      assert {:error, :decryption_failed} = KeyEncryption.open(ks, "k1", tampered)
    end

    test "flipped tag byte fails", %{ks: ks, envelope: envelope} do
      tampered = flip(envelope, tag_offset("test-1"))
      assert {:error, :decryption_failed} = KeyEncryption.open(ks, "k1", tampered)
    end

    test "envelope swapped to another kid fails", %{ks: ks, envelope: envelope} do
      assert {:error, :decryption_failed} = KeyEncryption.open(ks, "other-kid", envelope)
    end

    test "unknown KEK id", %{envelope: _} do
      sealer = keyset(["test-2"], "test-2")
      {:ok, envelope} = KeyEncryption.seal(sealer, "k1", @plaintext)
      opener = keyset(["test-1"], "test-1")
      assert {:error, :unknown_kek} = KeyEncryption.open(opener, "k1", envelope)
    end

    test "envelope cut inside the tag is malformed", %{ks: ks, envelope: envelope} do
      cut = binary_part(envelope, 0, tag_offset("test-1") + 8)
      assert {:error, :malformed_envelope} = KeyEncryption.open(ks, "k1", cut)
    end

    test "dropping the last ciphertext byte fails authentication", %{ks: ks, envelope: envelope} do
      cut = binary_part(envelope, 0, byte_size(envelope) - 1)
      assert {:error, :decryption_failed} = KeyEncryption.open(ks, "k1", cut)
    end

    test "wrong version byte and bare magic are malformed", %{ks: ks, envelope: envelope} do
      <<"LSK", 1, rest::binary>> = envelope

      assert {:error, :malformed_envelope} =
               KeyEncryption.open(ks, "k1", <<"LSK", 2, rest::binary>>)

      assert {:error, :malformed_envelope} = KeyEncryption.open(ks, "k1", "LSK")
    end

    test "forged 31-byte key returns an error without raising", %{envelope: envelope} do
      forged = %KeySet{
        current_id: "test-1",
        ids: ["test-1"],
        keys: %{"test-1" => :binary.copy(<<7>>, 31)}
      }

      assert {:error, :decryption_failed} = KeyEncryption.open(forged, "k1", envelope)
    end

    test "nil keyset" do
      assert {:error, :kek_not_configured} = KeyEncryption.seal(nil, "k1", @plaintext)
      assert {:error, :kek_not_configured} = KeyEncryption.open(nil, "k1", "LSKx")
    end

    test "fresh IV per seal", %{ks: ks} do
      {:ok, a} = KeyEncryption.seal(ks, "k1", @plaintext)
      {:ok, b} = KeyEncryption.seal(ks, "k1", @plaintext)
      refute a == b
      assert {:ok, @plaintext} = KeyEncryption.open(ks, "k1", a)
      assert {:ok, @plaintext} = KeyEncryption.open(ks, "k1", b)
    end

    test "invalid input" do
      ks = keyset(["test-1"], "test-1")
      assert {:error, :invalid_input} = KeyEncryption.seal(ks, :kid, @plaintext)
      assert {:error, :invalid_input} = KeyEncryption.seal(ks, "k1", 42)
    end
  end

  test ":crypto accepts truncated tag prefixes, which is why the parse guard exists" do
    key = :binary.copy(<<9>>, 32)
    iv = :binary.copy(<<1>>, 12)
    {ct, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, "hello", "aad", 16, true)
    short = binary_part(tag, 0, 15)
    assert "hello" = :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ct, "aad", short, false)
  end

  describe "classify" do
    test "fixed legacy encodings" do
      map = %{"kty" => "RSA"}
      assert :legacy = KeyEncryption.classify(Jason.encode!(map))
      assert :legacy = KeyEncryption.classify(:erlang.term_to_binary(map))
      assert :legacy = KeyEncryption.classify(<<>>)
      assert :legacy = KeyEncryption.classify("  {\"kty\":1}")
      assert :invalid = KeyEncryption.classify(nil)
    end

    property "binaries without the LSK prefix are legacy" do
      check all(bin <- binary(), not String.starts_with?(bin, "LSK")) do
        assert KeyEncryption.classify(bin) == :legacy
      end
    end

    property "LSK-prefixed binaries are envelopes and open never raises" do
      ks = keyset(["test-1"], "test-1")

      check all(rest <- binary()) do
        bin = "LSK" <> rest
        assert KeyEncryption.classify(bin) == :envelope
        assert {:error, _reason} = KeyEncryption.open(ks, "k1", bin)
      end
    end
  end

  test "inspect of a keyset hides key material" do
    ks = keyset(["test-1"], "test-1")
    out = inspect(ks)
    assert out =~ "test-1"
    refute out =~ kek("test-1")
    refute out =~ "keys"
    refute out =~ inspect(ks.keys["test-1"])
  end
end
