defmodule Lockspire.Protocol.TokenEndpointDPoP do
  @moduledoc """
  Public-compatible DPoP token-endpoint context facade.
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange.Compatibility
  alias Lockspire.Protocol.TokenExchange.Error
  alias Lockspire.Protocol.TokenExchange.Internal.TokenEndpointDPoP, as: Internal
  alias Lockspire.Protocol.TokenResult

  @spec resolve_context(Client.t(), map()) :: {:ok, map()} | {:error, Error.t()}
  def resolve_context(%Client{} = client, request) do
    client
    |> Internal.resolve_context(request)
    |> to_public_result()
  end

  @spec resolve_refresh_context(Client.t(), Token.t(), map()) ::
          {:ok, map()} | {:error, Error.t()}
  def resolve_refresh_context(%Client{} = client, %Token{} = token, request) do
    client
    |> Internal.resolve_refresh_context(token, request)
    |> to_public_result()
  end

  defp to_public_result({:ok, context}), do: {:ok, context}

  defp to_public_result({:error, %TokenResult.Error{} = error}) do
    {:error, Compatibility.to_public(error)}
  end
end
