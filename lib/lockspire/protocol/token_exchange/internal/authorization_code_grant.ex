defmodule Lockspire.Protocol.TokenExchange.Internal.AuthorizationCodeGrant do
  @moduledoc false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenExchange.Internal.GrantSupport
  alias Lockspire.Protocol.TokenExchange.Internal.TokenEndpointDPoP
  alias Lockspire.Protocol.TokenResult.Error

  @spec exchange(map(), Dependencies.t()) :: {:ok, struct()} | {:error, struct()}
  def exchange(request, %Dependencies{} = dependencies) when is_map(request) do
    request = Dependencies.attach(request, dependencies)
    params = params(request)
    authorization = Map.get(request, :authorization, Map.get(request, "authorization"))

    with :ok <- validate_grant_type(params),
         {:ok, %Client{} = client} <-
           GrantSupport.authenticate_client(params, authorization, request, dependencies),
         {:ok, context} <- TokenEndpointDPoP.resolve_context(client, request, dependencies),
         {:ok, %Token{} = code, code_hash} <-
           GrantSupport.fetch_authorization_code(params, request, dependencies) do
      GrantSupport.handle_code_exchange(
        client,
        code,
        code_hash,
        params,
        context,
        request,
        dependencies
      )
    else
      {:error, %Error{} = error} ->
        GrantSupport.emit_failure(error, params, request, dependencies)
        {:error, error}
    end
  end

  defp validate_grant_type(%{"grant_type" => "authorization_code"}), do: :ok

  defp validate_grant_type(_params) do
    {:error,
     %Error{
       status: 400,
       error: "unsupported_grant_type",
       error_description: "Only grant_type=authorization_code is supported",
       reason_code: :unsupported_grant_type
     }}
  end

  defp params(request), do: Map.get(request, :params, Map.get(request, "params", request))
end
