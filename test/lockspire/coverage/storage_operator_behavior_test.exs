defmodule Lockspire.Coverage.StorageOperatorBehaviorTest do
  use Lockspire.TokenExchangeCase

  alias Lockspire.Admin.Tokens

  test "operator token commands distinguish an absent durable record from an empty detail" do
    assert {:error, :not_found} = Tokens.get_token(-1)
    assert {:error, :not_found} = Tokens.revoke_token(-1)
    assert {:error, :not_found} = Tokens.revoke_token_family(-1)
  end
end
