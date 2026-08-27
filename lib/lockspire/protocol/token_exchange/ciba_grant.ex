defmodule Lockspire.Protocol.TokenExchange.CibaGrant do
  @moduledoc false
  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.TokenExchange.Compatibility
  alias Lockspire.Protocol.TokenExchange.Internal.CibaGrant, as: Internal
  alias Lockspire.Protocol.TokenResult

  def exchange(request) when is_map(request),
    do: request |> Internal.exchange() |> to_public_result()

  def issue_tokens(%Client{} = client, %CibaAuthorization{} = authorization, context, request),
    do: Internal.issue_tokens(client, authorization, context, request) |> to_public_result()

  defp to_public_result({:ok, %TokenResult.Success{} = success}),
    do: {:ok, Compatibility.to_public(success)}

  defp to_public_result({:error, %TokenResult.Error{} = error}),
    do: {:error, Compatibility.to_public(error)}
end
