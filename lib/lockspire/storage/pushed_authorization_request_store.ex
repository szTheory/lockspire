defmodule Lockspire.Storage.PushedAuthorizationRequestStore do
  @moduledoc """
  Domain-level persistence contract for pushed authorization request state.
  """

  alias Lockspire.Domain.PushedAuthorizationRequest

  @type store_error :: term()

  @callback put_pushed_authorization_request(PushedAuthorizationRequest.t()) ::
              {:ok, PushedAuthorizationRequest.t()} | {:error, store_error()}
  @callback fetch_active_pushed_authorization_request(String.t()) ::
              {:ok, PushedAuthorizationRequest.t() | nil} | {:error, store_error()}
  @callback consume_pushed_authorization_request(String.t(), String.t()) ::
              {:ok, PushedAuthorizationRequest.t() | nil} | {:error, store_error()}
end
