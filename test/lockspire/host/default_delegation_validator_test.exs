defmodule Lockspire.Host.DefaultDelegationValidatorTest do
  use ExUnit.Case, async: true

  alias Lockspire.Host.DefaultDelegationValidator
  alias Lockspire.Host.TokenExchangeContext

  describe "validate/1" do
    test "returns :ok when no actor_token is present" do
      context = %TokenExchangeContext{
        client_id: "client1",
        subject_token: %{},
        requested_scopes: [],
        actor_token: nil
      }

      assert :ok = DefaultDelegationValidator.validate(context)
    end

    test "returns new act claim based on actor_token without existing act" do
      context = %TokenExchangeContext{
        client_id: "client1",
        subject_token: %{},
        requested_scopes: [],
        actor_token: %{"sub" => "actor_sub", "client_id" => "actor_client"}
      }

      assert {:ok, %{claims: %{"act" => act}}} = DefaultDelegationValidator.validate(context)
      assert act == %{"sub" => "actor_sub", "client_id" => "actor_client"}
    end

    test "nests act claim properly when actor_token already has an act claim" do
      context = %TokenExchangeContext{
        client_id: "client1",
        subject_token: %{},
        requested_scopes: [],
        actor_token: %{
          "sub" => "actor_sub",
          "client_id" => "actor_client",
          "act" => %{
            "sub" => "nested_sub",
            "client_id" => "nested_client"
          }
        }
      }

      assert {:ok, %{claims: %{"act" => act}}} = DefaultDelegationValidator.validate(context)

      assert act == %{
               "sub" => "actor_sub",
               "client_id" => "actor_client",
               "act" => %{
                 "sub" => "nested_sub",
                 "client_id" => "nested_client"
               }
             }
    end

    test "ignores missing sub or client_id appropriately" do
      context = %TokenExchangeContext{
        client_id: "client1",
        subject_token: %{},
        requested_scopes: [],
        actor_token: %{"sub" => "actor_sub"}
      }

      assert {:ok, %{claims: %{"act" => act}}} = DefaultDelegationValidator.validate(context)
      assert act == %{"sub" => "actor_sub"}
    end
  end
end
