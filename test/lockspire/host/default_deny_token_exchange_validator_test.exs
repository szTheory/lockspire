defmodule Lockspire.Host.DefaultDenyTokenExchangeValidatorTest do
  use ExUnit.Case, async: true
  alias Lockspire.Host.DefaultDenyTokenExchangeValidator
  alias Lockspire.Host.TokenExchangeContext

  describe "validate/1" do
    test "returns error with :exchange_not_configured" do
      context = %TokenExchangeContext{
        client_id: "client_123",
        subject_token: %{"sub" => "user_1"},
        requested_scopes: ["read"]
      }

      assert {:error, :exchange_not_configured} =
               DefaultDenyTokenExchangeValidator.validate(context)
    end
  end
end
