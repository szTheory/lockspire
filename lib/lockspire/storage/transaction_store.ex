defmodule Lockspire.Storage.TransactionStore do
  @moduledoc """
  Narrow transaction capability for domain orchestrators.
  """

  @type store_error :: term()

  @doc """
  Declares the one transaction identity and participating adapter modules for
  guarded client, grant, token and audit writes. A list of callbacks alone is
  not proof that those writes share rollback authority.
  """
  @callback transaction_authority() :: %{
              required(:identity) => term(),
              required(:participants) => %{required(atom()) => module()}
            }

  @callback transact((-> term())) :: {:ok, term()} | {:error, store_error()}
  @callback rollback(store_error()) :: no_return()
end
