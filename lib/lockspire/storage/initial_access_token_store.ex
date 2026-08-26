defmodule Lockspire.Storage.InitialAccessTokenStore do
  @moduledoc """
  Domain-level persistence contract for initial access-token lifecycle operations.
  """

  alias Lockspire.Domain.InitialAccessToken

  @type store_error :: term()

  @callback redeem_initial_access_token(String.t(), DateTime.t()) ::
              {:ok, InitialAccessToken.t()} | {:error, store_error()}
  @callback list_initial_access_tokens(keyword()) ::
              {:ok, [InitialAccessToken.t()]} | {:error, store_error()}
  @callback save_initial_access_token(InitialAccessToken.t()) ::
              {:ok, InitialAccessToken.t()} | {:error, store_error()}
  @callback revoke_initial_access_token(integer(), DateTime.t()) :: :ok | {:error, store_error()}
end
