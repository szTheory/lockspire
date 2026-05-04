defmodule Lockspire.Storage.Ecto.RepositoryUsedJtiTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Domain.UsedJti

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
  end

  describe "record_used_jti/1" do
    test "records a new JTI successfully" do
      jti = %UsedJti{
        client_id: "client-123",
        jti: "jti-abc",
        expires_at: DateTime.utc_now() |> DateTime.add(3600, :second)
      }

      assert {:ok, :accepted} = Repository.record_used_jti(jti)
    end

    test "returns {:ok, :replay} for a duplicate JTI on the same client_id" do
      jti = %UsedJti{
        client_id: "client-123",
        jti: "jti-def",
        expires_at: DateTime.utc_now() |> DateTime.add(3600, :second)
      }

      assert {:ok, :accepted} = Repository.record_used_jti(jti)
      assert {:ok, :replay} = Repository.record_used_jti(jti)
    end

    test "allows the same JTI for different client_ids" do
      jti1 = %UsedJti{
        client_id: "client-1",
        jti: "jti-xyz",
        expires_at: DateTime.utc_now() |> DateTime.add(3600, :second)
      }

      jti2 = %UsedJti{
        client_id: "client-2",
        jti: "jti-xyz",
        expires_at: DateTime.utc_now() |> DateTime.add(3600, :second)
      }

      assert {:ok, :accepted} = Repository.record_used_jti(jti1)
      assert {:ok, :accepted} = Repository.record_used_jti(jti2)
    end
  end
end
