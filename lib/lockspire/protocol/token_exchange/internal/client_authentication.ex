defmodule Lockspire.Protocol.TokenExchange.Internal.ClientAuthentication do
  @moduledoc false

  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenResult.Error

  defmodule VerifiedIdentity do
    @moduledoc false
    @enforce_keys [:client_id, :method, :fingerprint]
    @derive {Inspect, only: [:client_id, :method]}
    defstruct [:client_id, :method, :fingerprint]
  end

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

  @doc false
  def verified_identity(%Client{} = client) do
    method = client.token_endpoint_auth_method
    configuration = authentication_configuration(client, method)

    %VerifiedIdentity{
      client_id: client.client_id,
      method: method,
      fingerprint: :crypto.hash(:sha256, :erlang.term_to_binary(configuration, [:deterministic]))
    }
  end

  @doc false
  def verified_identity_matches?(%VerifiedIdentity{} = identity, %Client{} = current_client) do
    current = verified_identity(current_client)

    identity.client_id == current.client_id and identity.method == current.method and
      identity.fingerprint == current.fingerprint
  end

  def verified_identity_matches?(_identity, _current_client), do: false

  defp authentication_configuration(%Client{} = client, method)
       when method in [:client_secret_basic, :client_secret_post] do
    {client.client_id, method, client.client_secret_hash}
  end

  defp authentication_configuration(%Client{} = client, :client_secret_jwt) do
    {client.client_id, :client_secret_jwt, client.client_secret_hash,
     client.client_secret_jwt_verifier_encrypted, client.token_endpoint_auth_signing_alg}
  end

  defp authentication_configuration(%Client{} = client, :private_key_jwt) do
    {client.client_id, :private_key_jwt, client.jwks, client.jwks_uri,
     client.token_endpoint_auth_signing_alg}
  end

  defp authentication_configuration(%Client{} = client, method)
       when method in [:tls_client_auth, :self_signed_tls_client_auth] do
    {client.client_id, method, client.tls_client_auth_subject_dn, client.tls_client_auth_san_dns,
     client.tls_client_auth_san_uri, client.tls_client_auth_san_ip,
     client.tls_client_auth_san_email, client.jwks, client.jwks_uri}
  end

  defp authentication_configuration(%Client{} = client, method),
    do: {client.client_id, method}

  defp client_auth_options(%Dependencies{} = dependencies) do
    [
      client_store: dependencies.client_store,
      client_lifetime: dependencies.client_lifetime,
      now: dependencies.now,
      mtls_cert: dependencies.mtls_cert,
      supported_jwt_auth_methods: @supported_jwt_auth_methods
    ]
  end
end
