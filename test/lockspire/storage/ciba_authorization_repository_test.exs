defmodule Lockspire.Storage.CibaAuthorizationRepositoryTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.CibaAuthorization
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

  describe "CIBA Authorization Storage" do
    test "can put and fetch CIBA authorization" do
      auth =
        CibaAuthorization.issue(%{
          auth_req_id: "auth-123",
          client_id: "client-1",
          scopes: ["openid"],
          subject_id: "user-1"
        })

      assert {:ok, %CibaAuthorization{} = stored} = Repository.put_ciba_authorization(auth)
      assert stored.id
      assert stored.auth_req_id_hash == auth.auth_req_id_hash

      assert {:ok, %CibaAuthorization{} = fetched} =
               Repository.fetch_ciba_authorization_by_auth_req_id_hash(auth.auth_req_id_hash)

      assert fetched.id == stored.id
      assert fetched.client_id == "client-1"
      assert fetched.subject_id == "user-1"
    end

    test "can transition CIBA authorization status" do
      auth =
        CibaAuthorization.issue(%{
          auth_req_id: "auth-456",
          client_id: "client-1"
        })

      {:ok, stored} = Repository.put_ciba_authorization(auth)

      now = DateTime.utc_now()

      assert {:ok, updated} =
               Repository.transition_ciba_authorization(
                 stored.auth_req_id_hash,
                 [:pending],
                 %{status: :approved, approved_at: now, subject_id: "user-99"}
               )

      assert updated.status == :approved
      assert updated.approved_at
      assert updated.subject_id == "user-99"
    end

    test "record_ciba_poll enforces polling intervals" do
      auth_req_id = "auth-poll"

      auth =
        CibaAuthorization.issue(%{
          auth_req_id: auth_req_id,
          client_id: "client-poll"
        })

      {:ok, stored} = Repository.put_ciba_authorization(auth)

      now = DateTime.utc_now()

      # First poll too early (next_poll_allowed_at is set to now + 5s in initial_next_poll_allowed_at)
      assert {:ok, %{result: :slow_down, effective_poll_interval_seconds: 10}} =
               Repository.record_ciba_poll(stored.auth_req_id_hash, "client-poll", now)

      # Second poll at next_poll_allowed_at (which was increased to now + 5 + 10 = now + 15)
      poll_time = DateTime.add(now, 16, :second)

      assert {:ok, %{result: :pending, effective_poll_interval_seconds: 10}} =
               Repository.record_ciba_poll(stored.auth_req_id_hash, "client-poll", poll_time)
    end
  end
end
