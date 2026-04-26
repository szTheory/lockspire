defmodule Lockspire.Test.Fixtures.InitialAccessTokenFixtures do
  @moduledoc """
  Test fixtures for `Lockspire.Domain.InitialAccessToken`.

  Hashes plaintext via `Lockspire.Security.Policy.hash_token/1` (D-14) — NEVER a hand-rolled
  hash. Drift here would silently break Phase 26's atomic redemption (Pitfall — shared
  pattern §"Hash-at-rest via `Lockspire.Security.Policy.hash_token/1`" in 25-PATTERNS.md).
  """

  alias Lockspire.Domain.InitialAccessToken
  alias Lockspire.Security.Policy

  @default_lifetime_seconds 3600

  @doc """
  Build an `InitialAccessToken` struct. Pass `:plaintext` in `attrs` to deterministically
  set `token_hash`; otherwise a random 32-byte token is generated and hashed.

  Any other key in `attrs` overrides the corresponding struct field directly.
  """
  @spec initial_access_token(map()) :: InitialAccessToken.t()
  def initial_access_token(attrs \\ %{}) when is_map(attrs) do
    {plaintext, attrs} = Map.pop(attrs, :plaintext, default_plaintext())

    base = %InitialAccessToken{
      token_hash: Policy.hash_token(plaintext),
      expires_at: DateTime.add(DateTime.utc_now(), @default_lifetime_seconds, :second),
      single_use: true
    }

    struct!(base, attrs)
  end

  @doc """
  Persists an `InitialAccessToken` to the database.
  """
  def persist(attrs \\ %{}) do
    iat = initial_access_token(attrs)

    %Lockspire.Storage.Ecto.InitialAccessTokenRecord{}
    |> Lockspire.Storage.Ecto.InitialAccessTokenRecord.changeset(iat)
    |> Lockspire.TestRepo.insert()
    |> case do
      {:ok, record} -> {:ok, Lockspire.Storage.Ecto.InitialAccessTokenRecord.to_domain(record)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Persists an `InitialAccessToken` to the database and returns `{plaintext, struct}`.
  """
  def persist_with_plaintext(attrs \\ %{}) do
    plaintext = Map.get(attrs, :plaintext, default_plaintext())
    attrs = Map.put(attrs, :plaintext, plaintext)
    {:ok, record} = persist(attrs)
    {plaintext, record}
  end

  @doc """
  Default random plaintext (32 bytes, base64url, no padding). Mirrors the random-token
  idiom used elsewhere in the codebase.
  """
  @spec default_plaintext() :: String.t()
  def default_plaintext do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
