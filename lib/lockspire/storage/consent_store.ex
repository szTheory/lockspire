defmodule Lockspire.Storage.ConsentStore do
  @moduledoc """
  Domain-level persistence contract for consent grants.
  """

  alias Lockspire.Domain.ConsentGrant

  @type store_error :: term()

  @callback grant_consent(ConsentGrant.t()) ::
              {:ok, ConsentGrant.t()} | {:error, store_error()}
  @callback list_consents(keyword()) ::
              {:ok, [ConsentGrant.t()]} | {:error, store_error()}
  @callback list_consents_for_account(String.t()) ::
              {:ok, [ConsentGrant.t()]} | {:error, store_error()}
  @callback fetch_consent_grant(integer()) ::
              {:ok, ConsentGrant.t() | nil} | {:error, store_error()}
  @callback list_reusable_consents(String.t(), String.t()) ::
              {:ok, [ConsentGrant.t()]} | {:error, store_error()}
  @callback revoke_consent_grant(integer(), map()) ::
              {:ok, ConsentGrant.t()} | {:error, store_error()}
end
