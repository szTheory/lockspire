defmodule Lockspire.Coverage.StorageOperatorBehaviorTest do
  use Lockspire.TokenExchangeCase

  alias Lockspire.Admin.Tokens
  alias Lockspire.Domain.Token
  alias Lockspire.Storage.Ecto.Repository

  test "operator token commands distinguish an absent durable record from an empty detail" do
    assert {:ok, nil} = Tokens.get_token(-1)
    assert {:error, :not_found} = Tokens.revoke_token(-1)
    assert {:error, :not_found} = Tokens.revoke_token_family(-1)
  end

  test "operator token detail exposes a redacted handle instead of the token hash" do
    now = DateTime.utc_now()
    raw_hash = "coverage-operator-secret-token-hash"

    assert {:ok, stored} =
             Repository.store_token(%Token{
               token_hash: raw_hash,
               token_type: :access_token,
               client_id: "coverage-operator-client",
               account_id: "coverage-operator-account",
               scopes: ["openid"],
               issued_at: now,
               expires_at: DateTime.add(now, 300, :second)
             })

    assert {:ok, detail} = Tokens.get_token(stored.id)
    assert detail.token.handle =~ "token_"
    refute detail.token.handle == raw_hash
    refute inspect(detail.token) =~ raw_hash
  end
end
