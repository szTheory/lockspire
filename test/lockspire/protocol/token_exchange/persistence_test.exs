defmodule Lockspire.Protocol.TokenExchange.PersistenceTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.TokenExchange.Internal.GrantPersistence

  test "persistence owner exposes one atomic audited operation" do
    Code.ensure_loaded!(GrantPersistence)
    assert function_exported?(GrantPersistence, :transact_with_audit, 2)
    assert function_exported?(GrantPersistence, :redeem_authorization_code, 2)
  end
end
