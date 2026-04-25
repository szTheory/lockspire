defmodule Lockspire.Admin.ServerPolicyTest do
  use ExUnit.Case, async: false

  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Domain.ServerPolicy, as: DomainServerPolicy
  alias Lockspire.Storage.Ecto.Repository

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

  test "get_server_policy/0 returns an optional default when no durable row exists" do
    assert {:ok, %DomainServerPolicy{} = policy} = ServerPolicy.get_server_policy()
    assert policy.par_policy == :optional
  end

  test "put_server_policy/1 persists optional and required modes across fresh fetches" do
    assert {:ok, %DomainServerPolicy{} = required_policy} = ServerPolicy.put_server_policy(:required)
    assert required_policy.par_policy == :required

    assert {:ok, %DomainServerPolicy{} = admin_policy} = ServerPolicy.get_server_policy()
    assert admin_policy.par_policy == :required

    assert {:ok, %DomainServerPolicy{} = stored_policy} = Repository.get_server_policy()
    assert stored_policy.par_policy == :required

    assert {:ok, %DomainServerPolicy{} = optional_policy} = ServerPolicy.put_server_policy(:optional)
    assert optional_policy.par_policy == :optional

    assert {:ok, %DomainServerPolicy{} = fresh_policy} = Repository.get_server_policy()
    assert fresh_policy.par_policy == :optional
  end

  test "put_server_policy/1 rejects modes outside optional and required" do
    assert {:error, [%{field: :par_policy, reason: :invalid_par_policy, detail: :inherit}]} =
             ServerPolicy.put_server_policy(:inherit)
  end
end
