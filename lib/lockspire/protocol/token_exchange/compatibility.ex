defmodule Lockspire.Protocol.TokenExchange.Compatibility do
  @moduledoc false

  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Protocol.TokenResult

  @spec to_public(TokenResult.Success.t() | TokenResult.Error.t()) ::
          TokenExchange.Success.t() | TokenExchange.Error.t()
  def to_public(%TokenResult.Success{} = result),
    do: struct(TokenExchange.Success, Map.from_struct(result))

  def to_public(%TokenResult.Error{} = result),
    do: struct(TokenExchange.Error, Map.from_struct(result))
end
