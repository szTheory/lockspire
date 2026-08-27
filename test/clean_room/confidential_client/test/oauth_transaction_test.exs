defmodule CleanRoomClient.OAuthTransactionTest do
  use ExUnit.Case, async: true

  alias CleanRoomClient.{DPoP, Transactions}

  test "creates independent browser-safe transactions and consumes exactly once" do
    transaction = Transactions.start(%{profile: :bearer, issuer: "https://issuer.example"})

    assert transaction.state != transaction.nonce
    assert transaction.verifier != transaction.state
    assert transaction.challenge == Transactions.s256(transaction.verifier)
    assert {:ok, _} = Transactions.consume(transaction.id, transaction.state)
    assert {:error, :terminal} = Transactions.consume(transaction.id, transaction.state)
  end

  test "creates an encrypted transaction-owned DPoP key" do
    key = DPoP.new_key()
    ciphertext = DPoP.encrypt(Jason.encode!(key.private_jwk))

    assert String.starts_with?(ciphertext, "XCP.")
    assert {:ok, plaintext} = DPoP.decrypt(ciphertext)
    refute plaintext == Jason.encode!(key.public_jwk)
    assert is_binary(key.jkt)
  end
end
