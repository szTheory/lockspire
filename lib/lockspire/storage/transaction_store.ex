defmodule Lockspire.Storage.TransactionStore do
  @moduledoc """
  Narrow transaction capability for domain orchestrators.
  """

  @type store_error :: term()

  @callback transact((-> term())) :: {:ok, term()} | {:error, store_error()}
  @callback rollback(store_error()) :: no_return()
end
