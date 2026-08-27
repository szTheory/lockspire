defmodule Lockspire.Protocol.TokenExchange.Internal.CibaGrant do
  @moduledoc false

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenExchange.Internal.GrantObservability
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
         {:ok, %CibaAuthorization{} = ciba_authorization} <-
           GrantSupport.fetch_ciba_authorization_for_exchange(
             params,
             client,
             request,
             dependencies
           ),
         {:ok, context} <- TokenEndpointDPoP.resolve_context(client, request, dependencies),
         {:ok, %Success{} = success} <-
           GrantSupport.redeem_ciba_authorization(
             client,
             ciba_authorization,
             context,
             request,
             dependencies
           ) do
      {:ok, success}
    else
      {:error, %Error{} = error} ->
        GrantObservability.emit_poll_failure(error, params, request, dependencies)
        {:error, error}
    end
  end

  @spec issue_tokens(Client.t(), CibaAuthorization.t(), map(), map(), Dependencies.t()) ::
          {:ok, Success.t()} | {:error, Error.t()}
  def issue_tokens(
        %Client{} = client,
        %CibaAuthorization{} = authorization,
        context,
        request,
        %Dependencies{} = dependencies
      ),
      do:
        GrantSupport.redeem_ciba_authorization(
          client,
          authorization,
          context,
          request,
          dependencies
        )

  defp params(request), do: Map.get(request, :params, Map.get(request, "params", request))
end
