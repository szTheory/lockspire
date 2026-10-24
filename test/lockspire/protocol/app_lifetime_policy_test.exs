defmodule Lockspire.Protocol.AppLifetimePolicyTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.DcrPolicy
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.ServerPolicyRecord
  alias Lockspire.Test.Fixtures.DcrFixtures

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    :ok
  end

  test "supported app lifetime values persist and resolve" do
    for seconds <- [nil, 0, 1, 2_147_483_647] do
      policy =
        DcrFixtures.server_policy(%{
          id: ServerPolicyRecord.singleton_id(),
          dcr_default_client_lifetime_seconds: seconds
        })

      assert ServerPolicyRecord.changeset(%ServerPolicyRecord{}, policy).valid?
      assert {:ok, persisted} = Repository.put_server_policy(policy)
      assert persisted.dcr_default_client_lifetime_seconds == seconds

      assert {:ok, resolved} =
               DcrPolicy.resolve(
                 policy,
                 nil,
                 DcrFixtures.valid_metadata()
               )

      assert resolved.default_client_lifetime_seconds == seconds
    end
  end

  test "invalid app lifetime values fail resolution and persistence without writes" do
    baseline =
      DcrFixtures.server_policy(%{
        id: ServerPolicyRecord.singleton_id(),
        dcr_default_client_lifetime_seconds: 17
      })

    assert {:ok, _} = Repository.put_server_policy(baseline)
    assert {:ok, before_policy} = Repository.get_server_policy()
    assert {:ok, before_clients} = Repository.list_clients()

    for seconds <- [true, "1", 1.5, %{}, [], -1, 2_147_483_648] do
      invalid = %ServerPolicy{baseline | dcr_default_client_lifetime_seconds: seconds}
      changeset = ServerPolicyRecord.changeset(%ServerPolicyRecord{}, invalid)

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :dcr_default_client_lifetime_seconds)

      assert {:error, :invalid_client_metadata,
              %{field: :default_client_lifetime_seconds, reason: :invalid_duration}} =
               DcrPolicy.resolve(invalid, nil, DcrFixtures.valid_metadata())

      assert {:error, %Ecto.Changeset{errors: errors}} = Repository.put_server_policy(invalid)
      assert Keyword.has_key?(errors, :dcr_default_client_lifetime_seconds)
      assert {:ok, ^before_policy} = Repository.get_server_policy()
      assert {:ok, ^before_clients} = Repository.list_clients()
    end
  end
end
