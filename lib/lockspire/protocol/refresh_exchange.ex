defmodule Lockspire.Protocol.RefreshExchange do
  @moduledoc """
  Public-compatible refresh-token rotation facade.
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.TokenExchange.Compatibility
  alias Lockspire.Protocol.TokenExchange.Error
  alias Lockspire.Protocol.TokenExchange.Internal.RefreshExchange, as: Internal
  alias Lockspire.Protocol.TokenExchange.Internal.LegacyOptions
  alias Lockspire.Protocol.TokenExchange.Success
  alias Lockspire.Protocol.TokenResult

  @spec exchange_refresh_token(Client.t(), map()) :: {:ok, Success.t()} | {:error, Error.t()}
  def exchange_refresh_token(%Client{} = client, request) when is_map(request) do
    with {:ok, dependencies} <- LegacyOptions.from_request(request, :refresh) do
      case Internal.exchange_refresh_token(client, request, dependencies) do
        {:ok, %TokenResult.Success{} = success} -> {:ok, Compatibility.to_public(success)}
        {:error, %TokenResult.Error{} = error} -> {:error, Compatibility.to_public(error)}
      end
    else
      {:error, %TokenResult.Error{} = error} -> {:error, Compatibility.to_public(error)}
    end
  end
end
