defmodule Lockspire.Storage.Ecto.RepositoryDeviceAuthorizationTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Domain.DeviceAuthorization
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

  describe "put_device_authorization/1" do
    test "inserts the record and returns it given a valid DeviceAuthorization struct" do
      now = DateTime.utc_now()
      
      auth = DeviceAuthorization.issue(%{
        device_code: "dev123",
        user_code: "usr456",
        client_id: "client_abc"
      }, now: now)

      assert {:ok, result} = Repository.put_device_authorization(auth)
      assert %DeviceAuthorization{} = result
      assert result.device_code_hash == auth.device_code_hash
      assert result.user_code_hash == auth.user_code_hash
      assert result.client_id == auth.client_id
    end

    test "inserting a duplicate code hash yields a constraint error" do
      now = DateTime.utc_now()
      
      auth = DeviceAuthorization.issue(%{
        device_code: "dev123",
        user_code: "usr456",
        client_id: "client_abc"
      }, now: now)

      assert {:ok, _} = Repository.put_device_authorization(auth)
      
      assert {:error, %Ecto.Changeset{} = changeset} = Repository.put_device_authorization(auth)
      assert {"has already been taken", _} = changeset.errors[:device_code_hash]
    end
  end
end
