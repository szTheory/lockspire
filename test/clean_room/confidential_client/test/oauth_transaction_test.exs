defmodule CleanRoomClient.OAuthTransactionTest do
  use ExUnit.Case, async: true

  alias CleanRoomClient.Transactions

  test "creates independent browser-safe transactions and consumes exactly once" do
    transaction = Transactions.start(%{profile: :bearer, issuer: "https://issuer.example"})

    assert transaction.state != transaction.nonce
    assert transaction.verifier != transaction.state
    assert transaction.challenge == Transactions.s256(transaction.verifier)
    assert {:ok, _} = Transactions.consume(transaction.id, transaction.state)
    assert {:error, :terminal} = Transactions.consume(transaction.id, transaction.state)
  end
end
