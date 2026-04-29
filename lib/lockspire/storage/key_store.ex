defmodule Lockspire.Storage.KeyStore do
  @moduledoc """
  Domain-level persistence contract for signing keys.
  """

  alias Lockspire.Domain.SigningKey

  @type store_error :: term()

  @callback publish_key(SigningKey.t()) :: {:ok, SigningKey.t()} | {:error, store_error()}
  @callback list_active_keys() :: {:ok, [SigningKey.t()]} | {:error, store_error()}
  @callback list_signing_keys(keyword()) :: {:ok, [SigningKey.t()]} | {:error, store_error()}
  @callback list_publishable_keys() :: {:ok, [SigningKey.t()]} | {:error, store_error()}
  @callback list_decryption_keys() :: {:ok, [SigningKey.t()]} | {:error, store_error()}
  @callback fetch_active_signing_key() :: {:ok, SigningKey.t() | nil} | {:error, store_error()}
  @callback fetch_signing_key_by_id(integer()) ::
              {:ok, SigningKey.t() | nil} | {:error, store_error()}
  @callback publish_signing_key(integer(), DateTime.t()) ::
              {:ok, SigningKey.t()} | {:error, store_error()}
  @callback activate_signing_key(integer(), DateTime.t()) ::
              {:ok, %{activated_key: SigningKey.t(), retiring_key: SigningKey.t() | nil}}
              | {:error, store_error()}
  @callback retire_signing_key(integer(), DateTime.t()) ::
              {:ok, SigningKey.t()} | {:error, store_error()}
end
