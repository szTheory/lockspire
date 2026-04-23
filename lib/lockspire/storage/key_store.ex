defmodule Lockspire.Storage.KeyStore do
  @moduledoc """
  Domain-level persistence contract for signing keys.
  """

  alias Lockspire.Domain.SigningKey

  @type store_error :: term()

  @callback publish_key(SigningKey.t()) :: {:ok, SigningKey.t()} | {:error, store_error()}
  @callback list_active_keys() :: {:ok, [SigningKey.t()]} | {:error, store_error()}
  @callback list_publishable_keys() :: {:ok, [SigningKey.t()]} | {:error, store_error()}
  @callback fetch_active_signing_key() :: {:ok, SigningKey.t() | nil} | {:error, store_error()}
end
