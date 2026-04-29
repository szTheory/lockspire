defmodule Lockspire.Storage.Ecto.RepositorySidTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Domain.Token
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
  end

  defp token_with_sid(overrides \\ %{}) do
    base = %Token{
      token_hash: "sid_test_hash_#{System.unique_integer([:positive])}",
      token_type: :refresh_token,
      family_id: "family_sid_#{System.unique_integer([:positive])}",
      client_id: "client_sid",
      account_id: "account_sid",
      scopes: ["offline_access"],
      audience: [],
      sid: "test-sid-value",
      expires_at: DateTime.add(DateTime.utc_now(), 86_400, :second)
    }

    Map.merge(base, overrides)
  end

  describe "revoke_by_sid/1" do
    test "returns {:ok, 0} without querying when sid is nil" do
      assert {:ok, 0} = Repository.revoke_by_sid(nil)
    end

    test "bulk-revokes all non-redeemed, non-revoked tokens for a given sid" do
      sid = "session-abc-#{System.unique_integer([:positive])}"

      t1 = token_with_sid(%{
        token_hash: "sid_t1_#{System.unique_integer([:positive])}",
        family_id: "fam_t1_#{System.unique_integer([:positive])}",
        sid: sid
      })

      t2 = token_with_sid(%{
        token_hash: "sid_t2_#{System.unique_integer([:positive])}",
        family_id: "fam_t2_#{System.unique_integer([:positive])}",
        sid: sid
      })

      assert {:ok, _stored_t1} = Repository.store_token(t1)
      assert {:ok, _stored_t2} = Repository.store_token(t2)

      assert {:ok, 2} = Repository.revoke_by_sid(sid)
    end

    test "returns {:ok, 0} when no tokens exist for the given sid" do
      assert {:ok, 0} = Repository.revoke_by_sid("nonexistent-sid-xyz")
    end

    test "does not revoke tokens belonging to a different sid" do
      sid_a = "session-a-#{System.unique_integer([:positive])}"
      sid_b = "session-b-#{System.unique_integer([:positive])}"

      t_a = token_with_sid(%{
        token_hash: "sid_ta_#{System.unique_integer([:positive])}",
        family_id: "fam_a_#{System.unique_integer([:positive])}",
        sid: sid_a
      })

      t_b = token_with_sid(%{
        token_hash: "sid_tb_#{System.unique_integer([:positive])}",
        family_id: "fam_b_#{System.unique_integer([:positive])}",
        sid: sid_b
      })

      assert {:ok, _} = Repository.store_token(t_a)
      assert {:ok, _} = Repository.store_token(t_b)

      # Revoke only sid_a
      assert {:ok, 1} = Repository.revoke_by_sid(sid_a)

      # sid_b token should still be fetchable (not revoked)
      assert {:ok, %Token{revoked_at: nil}} = Repository.fetch_refresh_token(t_b.token_hash)
    end

    test "stores token with sid field and retrieves it" do
      sid = "session-store-#{System.unique_integer([:positive])}"

      t = token_with_sid(%{
        token_hash: "sid_store_#{System.unique_integer([:positive])}",
        family_id: "fam_store_#{System.unique_integer([:positive])}",
        sid: sid
      })

      assert {:ok, stored} = Repository.store_token(t)
      assert stored.sid == sid

      # Fetch back and verify sid is persisted
      assert {:ok, fetched} = Repository.fetch_refresh_token(t.token_hash)
      assert fetched.sid == sid
    end
  end
end
