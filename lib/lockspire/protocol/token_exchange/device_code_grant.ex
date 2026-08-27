defmodule Lockspire.Protocol.TokenExchange.DeviceCodeGrant do
  @moduledoc false
  alias Lockspire.Protocol.TokenExchange.Compatibility
  alias Lockspire.Protocol.TokenExchange.Internal.DeviceCodeGrant, as: Internal
  alias Lockspire.Protocol.TokenResult

  def exchange(request) when is_map(request),
    do: request |> Internal.exchange() |> to_public_result()

  defp to_public_result({:ok, %TokenResult.Success{} = success}),
    do: {:ok, Compatibility.to_public(success)}

  defp to_public_result({:error, %TokenResult.Error{} = error}),
    do: {:error, Compatibility.to_public(error)}
end
