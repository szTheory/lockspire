defmodule Lockspire.Domain.CibaAuthorizationTest do
  use ExUnit.Case, async: true
  alias Lockspire.Domain.CibaAuthorization

  describe "issue/2" do
    test "creates a pending authorization with hashed ID" do
      auth = CibaAuthorization.issue(%{
        auth_req_id: "test-auth-req-id",
        client_id: "client-1",
        scopes: ["openid", "profile"],
        subject_id: "user-1",
        binding_message: "Login code 1234"
      })

      assert auth.status == :pending
      assert auth.auth_req_id == "test-auth-req-id"
      assert auth.auth_req_id_hash == Lockspire.Security.Policy.hash_token("test-auth-req-id")
      assert auth.client_id == "client-1"
      assert auth.scopes == ["openid", "profile"]
      assert auth.subject_id == "user-1"
      assert auth.binding_message == "Login code 1234"
      assert %DateTime{} = auth.expires_at
      assert %DateTime{} = auth.next_poll_allowed_at
    end

    test "respects custom TTL and now" do
      now = ~U[2026-05-05 12:00:00Z]
      auth = CibaAuthorization.issue(%{
        auth_req_id: "id",
        client_id: "c1"
      }, now: now, ttl: 30)

      assert auth.expires_at == ~U[2026-05-05 12:00:30Z]
    end
  end
end
