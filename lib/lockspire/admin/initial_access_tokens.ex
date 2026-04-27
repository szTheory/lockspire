defmodule Lockspire.Admin.InitialAccessTokens do
  @moduledoc """
  Operator boundary for Initial Access Token lifecycle.
  """

  alias Lockspire.Domain.InitialAccessToken
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Security.Policy
  alias Lockspire.Observability

  @spec list_iats(keyword()) :: {:ok, [InitialAccessToken.t()]} | {:error, term()}
  def list_iats(opts \\ []) do
    Repository.list_initial_access_tokens(opts)
  end

  @spec mint_iat(map()) :: {:ok, InitialAccessToken.t(), String.t()} | {:error, term()}
  def mint_iat(attrs \\ %{}) do
    plaintext_secret = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    token_hash = Policy.hash_token(plaintext_secret)

    iat = %InitialAccessToken{
      token_hash: token_hash,
      expires_at: Map.get(attrs, :expires_at),
      single_use: Map.get(attrs, :single_use, true),
      policy_overrides: Map.get(attrs, :policy_overrides),
      created_by: Map.get(attrs, :created_by, "operator")
    }

    with {:ok, saved_iat} <- Repository.save_initial_access_token(iat) do
      Observability.emit_iat(:mint, %{count: 1}, %{iat_id: saved_iat.id})
      {:ok, saved_iat, plaintext_secret}
    end
  end

  @spec revoke_iat(integer()) :: :ok | {:error, term()}
  def revoke_iat(id) do
    revoked_at = DateTime.utc_now()

    with :ok <- Repository.revoke_initial_access_token(id, revoked_at) do
      Observability.emit_iat(:revoke, %{count: 1}, %{iat_id: id})
      :ok
    end
  end
end
