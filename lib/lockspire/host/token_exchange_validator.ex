defmodule Lockspire.Host.TokenExchangeValidator do
  @moduledoc """
  Behaviour for validating token exchange requests against host application business logic.
  """

  alias Lockspire.Host.TokenExchangeContext

  @doc """
  Validates a token exchange request.

  Returns:
    - `:ok` to permit the exchange with default claims.
    - `{:ok, %{claims: claims}}` to permit and merge additional claims.
    - `{:error, reason}` to deny the exchange.
  """
  @callback validate(context :: TokenExchangeContext.t()) ::
              :ok
              | {:ok, %{claims: map()}}
              | {:error, term()}
end
