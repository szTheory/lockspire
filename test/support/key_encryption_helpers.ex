defmodule Lockspire.KeyEncryptionHelpers do
  @moduledoc """
  Test helpers for the `:key_encryption` seam. For `async: false` tests only.

  Cache-isolation rule: absent-KEK tests MUST call `put_key_encryption(nil)`.
  It clears both the `:key_encryption` app env and the `:persistent_term` cache.
  Deleting the env through `Lockspire.ConfigCase` (or a bare app-env delete) does
  NOT clear the cache, so `Lockspire.Config.key_encryption_keyset/0` would keep
  returning the boot-time key set and the test would silently see a configured KEK.
  """

  alias Lockspire.Config
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Security.KeyEncryption.KeySet

  @doc """
  Swaps the `:key_encryption` env (nil deletes it) and refreshes the cached key set;
  restores both on test exit.
  """
  @spec put_key_encryption(keyword() | nil) :: :ok
  def put_key_encryption(config) do
    original = Application.fetch_env(:lockspire, :key_encryption)

    apply_env(config)
    Lockspire.Application.validate_key_encryption!()

    ExUnit.Callbacks.on_exit(fn ->
      case original do
        {:ok, value} -> apply_env(value)
        :error -> apply_env(nil)
      end

      Lockspire.Application.validate_key_encryption!()
    end)

    :ok
  end

  @doc "Seals a private JWK map for `kid` with the cached key set."
  @spec seal_private_jwk(String.t(), map()) :: binary()
  def seal_private_jwk(kid, jwk_map) do
    case KeyEncryption.seal(Config.key_encryption_keyset(), kid, Jason.encode!(jwk_map)) do
      {:ok, envelope} -> envelope
      {:error, reason} -> raise "could not seal test private JWK: #{reason}"
    end
  end

  @doc "Builds a key set from fixed test material, independent of app env."
  @spec test_keyset(keyword()) :: KeySet.t()
  def test_keyset(opts \\ []) do
    ids = Keyword.get(opts, :ids, ["test-1", "test-2"])
    current = Keyword.get(opts, :current, List.first(ids))
    mode = Keyword.get(opts, :legacy_plaintext, :allow)

    keys = Enum.map(ids, &{&1, :crypto.hash(:sha256, "helper-kek-#{&1}") |> Base.encode64()})
    {:ok, keyset} = KeySet.new(keys: keys, current: current, legacy_plaintext: mode)
    keyset
  end

  defp apply_env(nil), do: Application.delete_env(:lockspire, :key_encryption)
  defp apply_env(config), do: Application.put_env(:lockspire, :key_encryption, config)
end
