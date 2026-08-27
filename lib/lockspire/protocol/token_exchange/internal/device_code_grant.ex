defmodule Lockspire.Protocol.TokenExchange.Internal.DeviceCodeGrant do
  @moduledoc false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Protocol.TokenExchange.Internal.GrantSupport
  alias Lockspire.Protocol.TokenExchange.Internal.TokenEndpointDPoP
  alias Lockspire.Protocol.TokenResult.Error
  alias Lockspire.Protocol.TokenResult.Success

  @spec exchange(map()) :: {:ok, struct()} | {:error, struct()}
  def exchange(request) when is_map(request) do
    params = params(request)
    authorization = Map.get(request, :authorization, Map.get(request, "authorization"))

    with {:ok, %Client{} = client} <-
           GrantSupport.authenticate_client(params, authorization, request),
         {:ok, %DeviceAuthorization{} = device_authorization} <-
           GrantSupport.fetch_device_authorization_for_exchange(params, client, request),
         {:ok, context} <- TokenEndpointDPoP.resolve_context(client, request),
         {:ok, %Success{} = success} <-
           GrantSupport.redeem_device_authorization(
             client,
             device_authorization,
             context,
             request
           ) do
      {:ok, success}
    else
      {:error, %Error{} = error} ->
        GrantSupport.emit_failure(error, params, request)
        {:error, error}
    end
  end

  defp params(request), do: Map.get(request, :params, Map.get(request, "params", request))
end
