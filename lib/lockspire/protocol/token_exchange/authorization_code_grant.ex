defmodule Lockspire.Protocol.TokenExchange.AuthorizationCodeGrant do
  @moduledoc false

  alias Lockspire.Protocol.TokenExchange

  @spec exchange(map()) :: TokenExchange.result()
  def exchange(request) when is_map(request),
    do: TokenExchange.__exchange_authorization_code__(request)
end
