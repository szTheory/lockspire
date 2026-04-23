defmodule Lockspire.Admin do
  @moduledoc """
  Operator-facing service boundary for Lockspire admin workflows.
  """

  alias Lockspire.Admin.Clients

  defdelegate list_clients(opts \\ []), to: Clients
  defdelegate get_client(client_id), to: Clients
  defdelegate create_client(attrs), to: Clients
  defdelegate update_client(client_id, attrs), to: Clients
  defdelegate rotate_client_secret(client_id, attrs \\ %{}), to: Clients
  defdelegate disable_client(client_id, attrs \\ %{}), to: Clients
  defdelegate enable_client(client_id, attrs \\ %{}), to: Clients
end
