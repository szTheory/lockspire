defmodule Lockspire.Storage.TokenStore do
  @moduledoc """
  Domain-level persistence contract for access and refresh token state.
  """

  alias Lockspire.Domain.Token

  @type store_error :: term()

  # Acceptance marker: @callback revoke_token_family/1
  @callback store_token(Token.t()) :: {:ok, Token.t()} | {:error, store_error()}
  @callback revoke_token_family(String.t()) :: {:ok, non_neg_integer()} | {:error, store_error()}
  @callback fetch_authorization_code(String.t()) ::
              {:ok, Token.t() | nil} | {:error, store_error()}
  @callback fetch_lifecycle_token(String.t()) ::
              {:ok, Token.t() | nil} | {:error, store_error()}
  @callback fetch_refresh_token(String.t()) ::
              {:ok, Token.t() | nil} | {:error, store_error()}
  @callback fetch_active_authorization_code(String.t()) ::
              {:ok, Token.t() | nil} | {:error, store_error()}
  @callback fetch_active_access_token(String.t()) ::
              {:ok, Token.t() | nil} | {:error, store_error()}
  @callback revoke_lifecycle_token(String.t(), String.t(), DateTime.t()) ::
              {:ok, Token.t() | nil} | {:error, store_error()}
  @callback mark_authorization_code_redeemed(String.t(), DateTime.t()) ::
              {:ok, Token.t()} | {:error, store_error()}
  @callback redeem_authorization_code(String.t(), DateTime.t(), Token.t()) ::
              {:ok, %{authorization_code: Token.t(), access_token: Token.t()}}
              | {:error, store_error()}
  @callback rotate_refresh_token(String.t(), String.t(), DateTime.t(), Token.t(), Token.t()) ::
              {:ok,
               %{
                 presented_refresh_token: Token.t(),
                 refresh_token: Token.t(),
                 access_token: Token.t()
               }}
              | {:error, store_error()}
end
