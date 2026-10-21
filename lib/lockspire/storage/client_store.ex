defmodule Lockspire.Storage.ClientStore do
  @moduledoc """
  Domain-level persistence contract for OAuth clients.
  """

  alias Lockspire.Domain.Client

  @type store_error :: term()

  @doc """
  Declares the adapter-owned app/credential lifetime contract and the single
  transaction authority shared by guarded client, grant, token and audit writes.
  The declaration must include `version: 1` and `transaction_authority`.
  """
  @callback lifetime_contract() :: %{
              required(:version) => 1,
              required(:transaction_authority) => term()
            }

  @doc """
  Locks and reloads current client rows for the lifetime of the caller's active
  transaction. Adapters deduplicate and order IDs by stable `client_id` before
  acquiring locks; ordinary fetch callbacks remain state-preserving.
  """
  @callback lock_clients([String.t()]) :: {:ok, [Client.t()]} | {:error, store_error()}

  @callback register_client(Client.t()) :: {:ok, Client.t()} | {:error, store_error()}
  @callback list_clients(keyword()) :: {:ok, [Client.t()]} | {:error, store_error()}
  @callback fetch_client_by_id(String.t()) :: {:ok, Client.t() | nil} | {:error, store_error()}
  @callback get_client_by_registration_access_token_hash(String.t()) ::
              {:ok, Client.t() | nil} | {:error, store_error()}
  @callback update_client(Client.t(), map()) :: {:ok, Client.t()} | {:error, store_error()}

  @callback replace_client_registration(Client.t(), Client.t(), String.t(), map()) ::
              {:ok, Client.t()} | {:error, store_error()}

  @callback rotate_registration_access_token(Client.t(), String.t(), map()) ::
              {:ok, Client.t()} | {:error, store_error()}

  @callback rotate_client_secret(
              Client.t(),
              String.t(),
              String.t(),
              DateTime.t() | (-> DateTime.t())
            ) ::
              {:ok, Client.t()} | {:error, store_error()}

  @callback set_client_active(Client.t(), boolean(), map()) ::
              {:ok, Client.t()} | {:error, store_error()}
end
