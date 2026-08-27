defmodule Lockspire.Protocol.Rfc8693Exchange do
  @moduledoc """
  Public-compatible RFC 8693 token-exchange facade.
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.TokenExchange.Compatibility
  alias Lockspire.Protocol.TokenExchange.Error
  alias Lockspire.Protocol.TokenExchange.Internal.Rfc8693Exchange, as: Internal
  alias Lockspire.Protocol.TokenExchange.Internal.LegacyOptions
  alias Lockspire.Protocol.TokenExchange.Success
  alias Lockspire.Protocol.TokenResult

  @spec exchange(Client.t(), map()) :: {:ok, Success.t()} | {:error, Error.t()}
  def exchange(%Client{} = client, request) when is_map(request) do
    with {:ok, dependencies} <- LegacyOptions.from_request(request, :rfc8693) do
      case Internal.exchange(client, request, dependencies) do
        {:ok, %TokenResult.Success{} = success} -> {:ok, Compatibility.to_public(success)}
        {:error, %TokenResult.Error{} = error} -> {:error, Compatibility.to_public(error)}
      end
    else
      {:error, %TokenResult.Error{} = error} -> {:error, Compatibility.to_public(error)}
    end
  end
end
