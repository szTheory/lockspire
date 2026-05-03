defmodule Lockspire.Protocol.InitialAccessToken do
  @moduledoc """
  Initial access token (IAT) lifecycle — atomic redemption.

  Public entry: `redeem/1` accepts a plaintext IAT, hashes via
  `Lockspire.Security.Policy.hash_token/1`, delegates to
  `Lockspire.Storage.Ecto.Repository.redeem_initial_access_token/2`, and collapses
  every rejection axis (`:not_found | :revoked | :expired | :already_used`) to
  `{:error, :invalid_token}` per Phase 26 D-11. The discriminator is preserved only
  in telemetry on the `:iat_redemption_failed` event as a `failure_reason`
  measurement — never returned to callers, defending against IAT-existence
  enumeration.

  This module is distinct from `Lockspire.Domain.InitialAccessToken` (the defstruct).
  """

  alias Lockspire.Domain.InitialAccessToken, as: Domain
  alias Lockspire.Observability
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.Repository

  @spec redeem(String.t()) :: {:ok, Domain.t()} | {:error, :invalid_token}
  def redeem(plaintext) when is_binary(plaintext) do
    hash = Policy.hash_token(plaintext)

    case Repository.redeem_initial_access_token(hash, DateTime.utc_now()) do
      {:ok, %Domain{} = iat} ->
        Observability.emit(:iat, :use, %{count: 1}, %{status: :success, iat_id: iat.id})
        {:ok, iat}

      {:error, reason} when reason in [:not_found, :revoked, :expired, :already_used] ->
        Observability.emit(:iat, :use, %{count: 1}, %{status: :failure, failure_reason: reason})
        {:error, :invalid_token}

      {:error, other} ->
        Observability.emit(
          :iat,
          :use,
          %{count: 1},
          %{status: :failure, failure_reason: :unexpected, detail: inspect(other)}
        )

        {:error, :invalid_token}
    end
  end
end
