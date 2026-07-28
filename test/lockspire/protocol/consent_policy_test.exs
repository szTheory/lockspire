defmodule Lockspire.Protocol.ConsentPolicyTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Protocol.ConsentPolicy

  describe "duplicate_grant/2" do
    test "reuses an active remembered grant covering the same scopes" do
      existing = grant(scopes: ["email", "profile"])
      candidate = grant(scopes: ["email", "profile"])

      assert {:reuse, ^existing} = ConsentPolicy.duplicate_grant([existing], candidate)
    end

    test "reuses when the existing grant is broader than the approval" do
      existing = grant(scopes: ["email", "profile", "offline_access"])
      candidate = grant(scopes: ["email"])

      assert {:reuse, ^existing} = ConsentPolicy.duplicate_grant([existing], candidate)
    end

    # The negative cases below are the ones that matter: treating any of these
    # as a duplicate would silently reuse a grant that does not actually cover
    # what the subject just approved.

    test "does not reuse when the approval requests a scope the grant lacks" do
      existing = grant(scopes: ["email"])
      candidate = grant(scopes: ["email", "profile"])

      assert :none = ConsentPolicy.duplicate_grant([existing], candidate)
    end

    test "does not reuse across different clients or accounts" do
      existing = grant(client_id: "other-client")
      assert :none = ConsentPolicy.duplicate_grant([existing], grant())

      existing = grant(account_id: "user:someone-else")
      assert :none = ConsentPolicy.duplicate_grant([existing], grant())
    end

    test "does not reuse when authorization details differ" do
      existing = grant(authorization_details: [%{"type" => "payment", "amount" => "10"}])
      candidate = grant(authorization_details: [%{"type" => "payment", "amount" => "500"}])

      assert :none = ConsentPolicy.duplicate_grant([existing], candidate)
    end

    test "does not reuse revoked or inactive grants" do
      assert :none = ConsentPolicy.duplicate_grant([grant(status: :revoked)], grant())

      revoked_at = DateTime.utc_now()
      assert :none = ConsentPolicy.duplicate_grant([grant(revoked_at: revoked_at)], grant())
    end

    test "does not reuse or match one-time approvals" do
      assert :none = ConsentPolicy.duplicate_grant([grant(kind: :one_time)], grant())
      assert :none = ConsentPolicy.duplicate_grant([grant()], grant(kind: :one_time))
    end

    test "returns :none when the account has no grants" do
      assert :none = ConsentPolicy.duplicate_grant([], grant())
    end
  end

  defp grant(overrides \\ []) do
    defaults = [
      id: 1,
      account_id: "user:acct-alice",
      client_id: "billingo-dashboard-public",
      scopes: ["email", "profile"],
      granted_at: DateTime.from_unix!(1_700_000_000),
      status: :active,
      kind: :remembered,
      authorization_details: [],
      revoked_at: nil
    ]

    struct!(ConsentGrant, Keyword.merge(defaults, overrides))
  end
end
