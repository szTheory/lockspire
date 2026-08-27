defmodule Lockspire.Protocol.TokenExchange.Internal.TokenIssuer do
  @moduledoc false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange.Internal.AccessTokenSigner
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies

  @doc false
  @spec issue_access(Token.t(), Client.t(), Dependencies.t()) ::
          {:ok, String.t(), String.t()} | {:error, struct()}
  def issue_access(%Token{} = token, %Client{} = client, %Dependencies{} = dependencies) do
    # This is intentionally a construction/signing boundary. It does not receive a
    # store, transaction, audit sink, or telemetry dependency, so issuance cannot
    # create a durable side effect.
    AccessTokenSigner.issue(token, client, %{}, dependencies)
  end

  @doc false
  @spec issue_exchange(Token.t(), Client.t(), map(), Dependencies.t()) ::
          {:ok, String.t(), String.t()} | {:error, struct()}
  def issue_exchange(%Token{} = token, %Client{} = client, claims, %Dependencies{} = dependencies)
      when is_map(claims) do
    AccessTokenSigner.issue_exchange(token, client, claims, %{}, dependencies)
  end
end
