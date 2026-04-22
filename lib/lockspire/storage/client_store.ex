defmodule Lockspire.Storage.ClientStore do
  @moduledoc """
  Domain-level persistence contract for OAuth clients.
  """

  alias Lockspire.Domain.Client

  @type store_error :: term()

  # Acceptance marker: @callback register_client/1
  @callback register_client(Client.t()) :: {:ok, Client.t()} | {:error, store_error()}
  @callback fetch_client_by_id(String.t()) :: {:ok, Client.t() | nil} | {:error, store_error()}
end
