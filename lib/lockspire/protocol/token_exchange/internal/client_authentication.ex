defmodule Lockspire.Protocol.TokenExchange.Internal.ClientAuthentication do
  @moduledoc false

  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenResult.Error

  @supported_jwt_auth_methods [:private_key_jwt, :client_secret_jwt]

  @spec authenticate(map(), term(), map(), Dependencies.t()) ::
          {:ok, Client.t()} | {:error, Error.t()}
  def authenticate(params, authorization, _request, %Dependencies{} = dependencies) do
    case ClientAuth.authenticate(params, authorization, client_auth_options(dependencies)) do
      {:ok, %Client{} = client} ->
        {:ok, client}

      {:error, %ClientAuth.Error{} = error} ->
        {:error,
         %Error{
           status: error.status,
           error: error.error,
           error_description: error.error_description,
           reason_code: error.reason_code
         }}
    end
  end

  defp client_auth_options(%Dependencies{client_store: client_store}) do
    [client_store: client_store, supported_jwt_auth_methods: @supported_jwt_auth_methods]
  end
end
