defmodule Lockspire.Security.KeyEncryptionTest do
  use ExUnit.Case, async: true

  alias Lockspire.Config
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Security.KeyEncryption.KeySet

  test "test.exs KEK flows through Config into seal/open" do
    keyset = Config.key_encryption!()
    assert %KeySet{current_id: "test-1"} = keyset

    plaintext = ~s({"kty":"oct","kid":"k1"})

    assert {:ok, <<"LSK", 1, 6, "test-1", _::binary>> = envelope} =
             KeyEncryption.seal(keyset, "k1", plaintext)

    assert {:ok, ^plaintext} = KeyEncryption.open(keyset, "k1", envelope)
    assert {:ok, "test-1"} = KeyEncryption.envelope_kek_id(envelope)
  end
end
