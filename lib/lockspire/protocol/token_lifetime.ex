defmodule Lockspire.Protocol.TokenLifetime do
  @moduledoc false

  @access_token_seconds 3_600
  @refresh_token_seconds 2_592_000

  @spec access_token() :: pos_integer()
  def access_token, do: @access_token_seconds

  @spec id_token() :: pos_integer()
  def id_token, do: @access_token_seconds

  @spec refresh_token() :: pos_integer()
  def refresh_token, do: @refresh_token_seconds

  @doc "Returns the ordinary token expiry capped by the authoritative app deadline."
  @spec effective_expiry(DateTime.t(), pos_integer(), DateTime.t() | nil) ::
          {:ok, DateTime.t()} | {:error, :expired}
  def effective_expiry(%DateTime{} = decided_at, ttl, app_deadline)
      when is_integer(ttl) and ttl > 0 do
    ordinary_expiry = DateTime.add(decided_at, ttl, :second)

    expiry =
      case app_deadline do
        %DateTime{} = deadline ->
          if DateTime.compare(deadline, ordinary_expiry) == :lt,
            do: deadline,
            else: ordinary_expiry

        nil ->
          ordinary_expiry
      end

    if DateTime.compare(expiry, decided_at) == :gt,
      do: {:ok, DateTime.from_unix!(DateTime.to_unix(expiry) * 1_000_000, :microsecond)},
      else: {:error, :expired}
  end

  @spec expires_in(DateTime.t(), DateTime.t()) :: non_neg_integer()
  def expires_in(%DateTime{} = decided_at, %DateTime{} = expiry),
    do: DateTime.diff(expiry, decided_at, :second)
end
