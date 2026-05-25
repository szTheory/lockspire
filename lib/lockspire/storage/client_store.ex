defmodule Lockspire.Storage.ClientStore do
  @moduledoc """
  Domain-level persistence contract for OAuth clients.
  """

  alias Lockspire.Domain.Client

  @type store_error :: term()

  # Acceptance marker: @callback register_client/1
  @callback register_client(Client.t()) :: {:ok, Client.t()} | {:error, store_error()}
  @callback list_clients(keyword()) :: {:ok, [Client.t()]} | {:error, store_error()}
  @callback fetch_client_by_id(String.t()) :: {:ok, Client.t() | nil} | {:error, store_error()}
  @callback update_client(Client.t(), map()) :: {:ok, Client.t()} | {:error, store_error()}

  @callback rotate_client_secret(Client.t(), String.t(), String.t(), DateTime.t()) ::
              {:ok, Client.t()} | {:error, store_error()}

  @callback set_client_active(Client.t(), boolean(), map()) ::
              {:ok, Client.t()} | {:error, store_error()}
end
