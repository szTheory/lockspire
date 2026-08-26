defmodule Lockspire.Protocol.TokenExchange.CibaGrant do
  @moduledoc false

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.TokenExchange

  @spec exchange(map()) :: TokenExchange.result()
  def exchange(request) when is_map(request), do: TokenExchange.__exchange_ciba__(request)

  @spec issue_tokens(Client.t(), CibaAuthorization.t(), map(), map()) :: TokenExchange.result()
  def issue_tokens(%Client{} = client, %CibaAuthorization{} = authorization, context, request),
    do: TokenExchange.__issue_ciba_tokens__(client, authorization, context, request)
end
