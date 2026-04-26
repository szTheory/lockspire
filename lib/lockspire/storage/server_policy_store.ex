defmodule Lockspire.Storage.ServerPolicyStore do
  @moduledoc """
  Domain-level persistence contract for Lockspire server policy.
  """

  alias Lockspire.Domain.ServerPolicy

  @type store_error :: term()

  @callback get_server_policy() :: {:ok, ServerPolicy.t()} | {:error, store_error()}
  @callback put_server_policy(ServerPolicy.t()) ::
              {:ok, ServerPolicy.t()} | {:error, store_error()}

  @doc """
  Atomically read-merge-write the server-policy singleton row under `FOR UPDATE` lock.

  The mutator is invoked with the current `%ServerPolicy{}` (or a default struct when no
  durable row exists) inside the same transaction that locks the row, so concurrent admin
  writes serialise rather than racing across two `Repository` calls.

  Required by `Admin.ServerPolicy.put_server_policy/1` and
  `Admin.ServerPolicy.put_dcr_policy/1` to preserve unrelated fields on the singleton row
  without lost-update races.
  """
  @callback update_server_policy((ServerPolicy.t() -> ServerPolicy.t())) ::
              {:ok, ServerPolicy.t()} | {:error, store_error()}
end
