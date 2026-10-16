defmodule Lockspire.Storage.KeyStore do
  @moduledoc """
  Domain-level persistence contract for signing keys.
  """

  alias Lockspire.Domain.SigningKey

  @type store_error :: term()

  @callback publish_key(SigningKey.t()) :: {:ok, SigningKey.t()} | {:error, store_error()}
  @callback list_active_keys() :: {:ok, [SigningKey.t()]} | {:error, store_error()}
  @callback list_signing_keys(keyword()) :: {:ok, [SigningKey.t()]} | {:error, store_error()}
  @callback list_publishable_keys(keyword()) :: {:ok, [SigningKey.t()]} | {:error, store_error()}
  @callback list_decryption_keys() :: {:ok, [SigningKey.t()]} | {:error, store_error()}
  @callback fetch_active_signing_key(keyword()) ::
              {:ok, SigningKey.t() | nil} | {:error, store_error()}
  @callback fetch_signing_key_by_id(integer()) ::
              {:ok, SigningKey.t() | nil} | {:error, store_error()}
  @callback publish_signing_key(integer(), DateTime.t()) ::
              {:ok, SigningKey.t()} | {:error, store_error()}
  @callback activate_signing_key(integer(), DateTime.t()) ::
              {:ok, %{activated_key: SigningKey.t(), retiring_key: SigningKey.t() | nil}}
              | {:error, store_error()}
  @callback retire_signing_key(integer(), DateTime.t()) ::
              {:ok, SigningKey.t()} | {:error, store_error()}

  @doc """
  Pages signing-key ids in ascending order, returning `{id, kid}` pairs after `after_id`.
  """
  @callback list_signing_key_refs(after_id :: integer(), limit :: pos_integer()) ::
              {:ok, [{integer(), String.t()}]} | {:error, store_error()}

  @doc """
  Locks one signing-key row and lets `decide` choose what happens to its stored private material.

  `decide` receives the locked key and returns one of `{:replace, binary, audit_event, info}`,
  `{:keep, info}` or `{:fail, reason, info}`. The store never inspects the stored material itself.
  A replacement is written only if the row still holds the bytes that were read, and the audit
  record is appended in the same transaction.

  Outcomes are `{:replaced, info}`, `{:kept, info}`, `{:failed, reason, info}`, `:conflict`
  (the row changed underneath the decision) and `:not_found`.
  """
  @callback reencrypt_signing_key(integer(), (SigningKey.t() -> term()), keyword()) ::
              {:ok, term()} | {:error, store_error()}
end
