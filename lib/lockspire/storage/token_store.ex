defmodule Lockspire.Storage.TokenStore do
  @moduledoc """
  Domain-level persistence contract for access and refresh token state.
  """

  alias Lockspire.Domain.Token

  @type store_error :: term()

  # Acceptance marker: @callback revoke_token_family/1
  @callback store_token(Token.t()) :: {:ok, Token.t()} | {:error, store_error()}
  @callback revoke_token_family(String.t()) :: {:ok, non_neg_integer()} | {:error, store_error()}
end
