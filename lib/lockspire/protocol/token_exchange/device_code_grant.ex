defmodule Lockspire.Protocol.TokenExchange.DeviceCodeGrant do
  @moduledoc false
  alias Lockspire.Protocol.TokenExchange.Compatibility
  alias Lockspire.Protocol.TokenExchange.Internal.DeviceCodeGrant, as: Internal
  alias Lockspire.Protocol.TokenExchange.Internal.LegacyOptions
  alias Lockspire.Protocol.TokenResult

  def exchange(request) when is_map(request) do
    with {:ok, dependencies} <- LegacyOptions.from_request(request, :device_code) do
      request |> Internal.exchange(dependencies) |> to_public_result()
    else
      {:error, error} -> {:error, Compatibility.to_public(error)}
    end
  end

  defp to_public_result({:ok, %TokenResult.Success{} = success}),
    do: {:ok, Compatibility.to_public(success)}

  defp to_public_result({:error, %TokenResult.Error{} = error}),
    do: {:error, Compatibility.to_public(error)}
end
