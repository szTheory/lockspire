defmodule Lockspire.Protocol.TokenExchange.ObservabilityTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.TokenExchange.Internal.GrantObservability

  test "observability owner retains explicit refresh contracts" do
    Code.ensure_loaded!(GrantObservability)
    assert function_exported?(GrantObservability, :emit_refresh_success, 4)
    assert function_exported?(GrantObservability, :emit_refresh_failure, 3)
  end
end
