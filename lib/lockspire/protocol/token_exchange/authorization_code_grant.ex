defmodule Lockspire.Protocol.TokenExchange.AuthorizationCodeGrant do
  @moduledoc false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenEndpointDPoP
  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Protocol.TokenExchange.GrantSupport

  @spec exchange(map()) :: TokenExchange.result()
  def exchange(request) when is_map(request) do
    params = params(request)
    authorization = Map.get(request, :authorization, Map.get(request, "authorization"))

    with :ok <- validate_grant_type(params),
         {:ok, %Client{} = client} <-
           GrantSupport.authenticate_client(params, authorization, request),
         {:ok, context} <- TokenEndpointDPoP.resolve_context(client, request),
         {:ok, %Token{} = code, code_hash} <-
           GrantSupport.fetch_authorization_code(params, request) do
      GrantSupport.handle_code_exchange(client, code, code_hash, params, context, request)
    else
      {:error, %TokenExchange.Error{} = error} ->
        GrantSupport.emit_failure(error, params, request)
        {:error, error}
    end
  end

  defp validate_grant_type(%{"grant_type" => "authorization_code"}), do: :ok

  defp validate_grant_type(_params) do
    {:error,
     %TokenExchange.Error{
       status: 400,
       error: "unsupported_grant_type",
       error_description: "Only grant_type=authorization_code is supported",
       reason_code: :unsupported_grant_type
     }}
  end

  defp params(request), do: Map.get(request, :params, Map.get(request, "params", request))
end
