defmodule Lockspire.Protocol.AccessTokenSigner do
  @moduledoc """
  Public-compatible access-token signing facade.
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange.Compatibility
  alias Lockspire.Protocol.TokenExchange.Error
  alias Lockspire.Protocol.TokenExchange.Internal.AccessTokenSigner, as: Internal
  alias Lockspire.Protocol.TokenResult

  @type token_for_issuance :: %Token{token_hash: String.t() | nil}
  @type result :: {:ok, String.t(), String.t()} | {:error, Error.t()}

  @spec issue(token_for_issuance(), Client.t(), map()) :: result()
  def issue(%Token{} = token, %Client{} = client, request) do
    token
    |> Internal.issue(client, request)
    |> to_public_result()
  end

  @spec issue_exchange(token_for_issuance(), Client.t(), map(), map()) :: result()
  def issue_exchange(%Token{} = token, %Client{} = client, custom_claims, request)
      when is_map(custom_claims) do
    token
    |> Internal.issue_exchange(client, custom_claims, request)
    |> to_public_result()
  end

  defp to_public_result({:ok, raw, hash}), do: {:ok, raw, hash}

  defp to_public_result({:error, %TokenResult.Error{} = error}) do
    {:error, Compatibility.to_public(error)}
  end
end
