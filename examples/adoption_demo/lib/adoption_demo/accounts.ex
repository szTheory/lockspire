defmodule AdoptionDemo.Accounts do
  @moduledoc false

  @accounts %{
    "alice" => %{
      id: "acct_alice",
      login: "alice",
      email: "alice@billingo.test",
      name: "Alice Rivera",
      tenant_id: "tenant_billingo",
      tenant_name: "Billingo",
      operator?: false
    },
    "bob" => %{
      id: "acct_bob",
      login: "bob",
      email: "bob@northstar.test",
      name: "Bob Chen",
      tenant_id: "tenant_northstar",
      tenant_name: "Northstar Retail",
      operator?: false
    },
    "ops" => %{
      id: "acct_ops",
      login: "ops",
      email: "ops@billingo.test",
      name: "Ops Maintainer",
      tenant_id: "tenant_billingo",
      tenant_name: "Billingo",
      operator?: true
    }
  }

  def all, do: Map.values(@accounts)

  def get(login) when is_binary(login), do: Map.get(@accounts, login)

  def get_by_id(id) when is_binary(id) do
    Enum.find(all(), &(&1.id == id))
  end
end
