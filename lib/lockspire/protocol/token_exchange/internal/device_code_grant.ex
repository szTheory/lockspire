defmodule Lockspire.Protocol.TokenExchange.Internal.DeviceCodeGrant do
  @moduledoc false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenExchange.Internal.GrantSupport
  alias Lockspire.Protocol.TokenExchange.Internal.TokenEndpointDPoP
  alias Lockspire.Protocol.TokenResult.Error
  alias Lockspire.Protocol.TokenResult.Success

  @spec exchange(map(), Dependencies.t()) :: {:ok, struct()} | {:error, struct()}
  def exchange(request, %Dependencies{} = dependencies) when is_map(request) do
    request = Dependencies.attach(request, dependencies)
    params = params(request)
    authorization = Map.get(request, :authorization, Map.get(request, "authorization"))

    with {:ok, %Client{} = client} <-
           GrantSupport.authenticate_client(params, authorization, request, dependencies),
         {:ok, %DeviceAuthorization{} = device_authorization} <-
           GrantSupport.fetch_device_authorization_for_exchange(
             params,
             client,
             request,
             dependencies
           ),
         {:ok, context} <- TokenEndpointDPoP.resolve_context(client, request, dependencies),
         {:ok, %Success{} = success} <-
           GrantSupport.redeem_device_authorization(
             client,
             device_authorization,
             context,
             request,
             dependencies
           ) do
      {:ok, success}
    else
      {:error, %Error{} = error} ->
        GrantSupport.emit_failure(error, params, request, dependencies)
        {:error, error}
    end
  end

  defp params(request), do: Map.get(request, :params, Map.get(request, "params", request))
end
