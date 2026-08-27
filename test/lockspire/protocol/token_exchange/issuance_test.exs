defmodule Lockspire.Protocol.TokenExchange.IssuanceTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.TokenExchange.Internal.TokenIssuer

  test "issuance owner exposes only token construction entry points" do
    Code.ensure_loaded!(TokenIssuer)
    assert function_exported?(TokenIssuer, :issue_access, 3)
    assert function_exported?(TokenIssuer, :issue_exchange, 4)
    assert function_exported?(TokenIssuer, :issue_grant, 5)
    assert function_exported?(TokenIssuer, :build_success, 8)
    refute function_exported?(TokenIssuer, :store_token, 1)
    refute function_exported?(TokenIssuer, :append_audit_event, 1)
  end
end
