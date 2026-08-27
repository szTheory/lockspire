defmodule Lockspire.Protocol.TokenExchange.Internal.CibaGrant do
  @moduledoc false

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
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
         {:ok, %CibaAuthorization{} = ciba_authorization} <-
           GrantSupport.fetch_ciba_authorization_for_exchange(params, client, request),
         {:ok, context} <- TokenEndpointDPoP.resolve_context(client, request),
         {:ok, %Success{} = success} <-
           GrantSupport.redeem_ciba_authorization(client, ciba_authorization, context, request) do
      {:ok, success}
    else
      {:error, %Error{} = error} ->
        GrantSupport.emit_failure(error, params, request)
        {:error, error}
    end
  end

  @spec issue_tokens(Client.t(), CibaAuthorization.t(), map(), map()) ::
          {:ok, Success.t()} | {:error, Error.t()}
  def issue_tokens(%Client{} = client, %CibaAuthorization{} = authorization, context, request),
    do: GrantSupport.redeem_ciba_authorization(client, authorization, context, request)

  defp params(request), do: Map.get(request, :params, Map.get(request, "params", request))
end
