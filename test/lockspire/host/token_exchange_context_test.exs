defmodule Lockspire.Host.TokenExchangeContextTest do
  use ExUnit.Case, async: true
  alias Lockspire.Host.TokenExchangeContext

  describe "struct" do
    test "enforces required keys" do
      assert_raise ArgumentError, fn ->
        struct!(TokenExchangeContext, [])
      end

      # Valid creation
      context =
        struct!(TokenExchangeContext,
          client_id: "client_123",
          subject_token: %{"sub" => "user_1"},
          requested_scopes: ["read", "write"]
        )

      assert context.client_id == "client_123"
      assert context.subject_token == %{"sub" => "user_1"}
      assert context.requested_scopes == ["read", "write"]
      assert context.actor_token == nil
    end
  end
end
