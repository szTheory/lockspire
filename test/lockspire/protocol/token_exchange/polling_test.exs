defmodule Lockspire.Protocol.TokenExchange.PollingTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.TokenExchange.Internal.GrantPolling

  test "keeps device and CIBA polling as separately explicit state translators" do
    Code.ensure_loaded!(GrantPolling)
    assert function_exported?(GrantPolling, :fetch_device, 3)
    assert function_exported?(GrantPolling, :fetch_ciba, 3)
  end
end
