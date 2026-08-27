defmodule Lockspire.Protocol.TokenExchange.CibaGrant do
  @moduledoc false
  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.TokenExchange.Compatibility
  alias Lockspire.Protocol.TokenExchange.Internal.CibaGrant, as: Internal
  alias Lockspire.Protocol.TokenExchange.Internal.LegacyOptions
  alias Lockspire.Protocol.TokenResult

  @spec exchange(map()) ::
          {:ok, Lockspire.Protocol.TokenExchange.Success.t()}
          | {:error, Lockspire.Protocol.TokenExchange.Error.t()}
  def exchange(request) when is_map(request) do
    case LegacyOptions.from_request(request, :ciba) do
      {:ok, dependencies} -> request |> Internal.exchange(dependencies) |> to_public_result()
      {:error, error} -> {:error, Compatibility.to_public(error)}
    end
  end

  @spec issue_tokens(Client.t(), CibaAuthorization.t(), map(), map()) ::
          {:ok, Lockspire.Protocol.TokenExchange.Success.t()}
          | {:error, Lockspire.Protocol.TokenExchange.Error.t()}
  def issue_tokens(%Client{} = client, %CibaAuthorization{} = authorization, context, request) do
    case LegacyOptions.from_request(request, :ciba) do
      {:ok, dependencies} ->
        Internal.issue_tokens(client, authorization, context, request, dependencies)
        |> to_public_result()

      {:error, error} ->
        {:error, Compatibility.to_public(error)}
    end
  end

  defp to_public_result({:ok, %TokenResult.Success{} = success}),
    do: {:ok, Compatibility.to_public(success)}

  defp to_public_result({:error, %TokenResult.Error{} = error}),
    do: {:error, Compatibility.to_public(error)}
end
