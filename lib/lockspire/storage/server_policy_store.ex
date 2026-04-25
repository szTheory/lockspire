defmodule Lockspire.Storage.ServerPolicyStore do
  @moduledoc """
  Domain-level persistence contract for Lockspire server policy.
  """

  alias Lockspire.Domain.ServerPolicy

  @type store_error :: term()

  @callback get_server_policy() :: {:ok, ServerPolicy.t()} | {:error, store_error()}
  @callback put_server_policy(ServerPolicy.t()) ::
              {:ok, ServerPolicy.t()} | {:error, store_error()}
end
