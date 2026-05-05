defmodule Lockspire.Protocol.TokenExchange.DelegationTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.TokenExchange.Delegation

  describe "check_depth/3" do
    test "returns :ok when no act claim is present and depth is 1" do
      actor_token_claims = %{"sub" => "user"}
      client = %{max_delegation_depth: 1}
      policy = %{max_delegation_depth: 3}

      assert :ok = Delegation.check_depth(actor_token_claims, client, policy)
    end

    test "returns :ok when current depth + 1 is equal to max depth" do
      actor_token_claims = %{"act" => %{"sub" => "user1"}}
      client = %{max_delegation_depth: 2}
      policy = %{max_delegation_depth: 3}

      assert :ok = Delegation.check_depth(actor_token_claims, client, policy)
    end

    test "returns error when current depth + 1 exceeds max depth (client override)" do
      actor_token_claims = %{"act" => %{"sub" => "user1"}}
      client = %{max_delegation_depth: 1}
      policy = %{max_delegation_depth: 3}

      assert {:error, "invalid_request", "max_delegation_depth_exceeded"} =
               Delegation.check_depth(actor_token_claims, client, policy)
    end

    test "returns error when current depth + 1 exceeds max depth (policy fallback)" do
      actor_token_claims = %{
        "act" => %{
          "act" => %{
            "act" => %{"sub" => "user"}
          }
        }
      }

      client = %{max_delegation_depth: nil}
      policy = %{max_delegation_depth: 3}

      assert {:error, "invalid_request", "max_delegation_depth_exceeded"} =
               Delegation.check_depth(actor_token_claims, client, policy)
    end

    test "falls back to default of 3 if client and policy are nil" do
      actor_token_claims = %{
        "act" => %{
          "act" => %{
            "act" => %{"sub" => "user"}
          }
        }
      }

      client = %{max_delegation_depth: nil}
      policy = %{max_delegation_depth: nil}

      assert {:error, "invalid_request", "max_delegation_depth_exceeded"} =
               Delegation.check_depth(actor_token_claims, client, policy)

      # Depth 2 should be allowed (current + 1 = 3)
      allowed_claims = %{
        "act" => %{
          "act" => %{"sub" => "user"}
        }
      }

      assert :ok = Delegation.check_depth(allowed_claims, client, policy)
    end
  end
end
