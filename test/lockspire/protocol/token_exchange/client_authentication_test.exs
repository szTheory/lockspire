defmodule Lockspire.Protocol.TokenExchange.ClientAuthenticationTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.TokenExchange.Internal.ClientAuthentication

  test "owns token-endpoint client authentication behind an explicit dependency bundle" do
    assert function_exported?(ClientAuthentication, :authenticate, 4)
  end
end
