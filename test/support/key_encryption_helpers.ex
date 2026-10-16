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
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Security.KeyEncryption.KeySet
  alias Lockspire.Storage.Ecto.Repository

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

  @doc """
  Base64 key material for `id`, derived with the same formula as `config/test.exs`
  (`test-1` and `test-2` match the configured keys). Pass `salt:` to derive different
  material under the same id.
  """
  @spec config_material(String.t(), keyword()) :: String.t()
  def config_material(id, opts \\ []) do
    suffix =
      case id do
        "test-" <> n -> n
        other -> other
      end

    label = "lockspire-test-kek-" <> suffix <> Keyword.get(opts, :salt, "")
    :crypto.hash(:sha256, label) |> Base.encode64()
  end

  @doc "The `config/test.exs` key list, for `put_key_encryption/1`."
  @spec config_keys([String.t()]) :: [{String.t(), String.t()}]
  def config_keys(ids \\ ["test-1", "test-2"]), do: Enum.map(ids, &{&1, config_material(&1)})

  @doc "Builds a key set from the `config/test.exs` material (options: `:ids`, `:current`, `:legacy_plaintext`)."
  @spec config_keyset(keyword()) :: KeySet.t()
  def config_keyset(opts \\ []) do
    ids = Keyword.get(opts, :ids, ["test-1", "test-2"])
    current = Keyword.get(opts, :current, List.first(ids))
    mode = Keyword.get(opts, :legacy_plaintext, :allow)

    {:ok, keyset} = KeySet.new(keys: config_keys(ids), current: current, legacy_plaintext: mode)
    keyset
  end

  @doc "A legacy row whose private JWK is stored as plain JSON."
  @spec legacy_json_row(String.t(), keyword()) :: SigningKey.t()
  def legacy_json_row(kid, opts \\ []) do
    signing_key_row(kid, Jason.encode!(private_jwk_map(kid, opts)), opts)
  end

  @doc "A legacy row whose private JWK is stored as a term-encoded map (`atom_keys: true` for atom keys)."
  @spec legacy_etf_row(String.t(), keyword()) :: SigningKey.t()
  def legacy_etf_row(kid, opts \\ []) do
    map = private_jwk_map(kid, opts)

    map =
      if Keyword.get(opts, :atom_keys, false),
        do: Map.new(map, fn {k, v} -> {String.to_atom(k), v} end),
        else: map

    signing_key_row(kid, :erlang.term_to_binary(map), opts)
  end

  @doc "A legacy row holding bytes that parse as neither JSON nor a safe term."
  @spec unreadable_legacy_row(String.t(), keyword()) :: SigningKey.t()
  def unreadable_legacy_row(kid, opts \\ []),
    do: signing_key_row(kid, <<0xFF, 0x00, "not json">>, opts)

  @doc """
  A row sealed under `kek_id` with the `config/test.exs` material formula. Pass `salt:` for
  material that differs from the configured key of the same id, and `seal_kid:` to bind the
  envelope to another kid.
  """
  @spec sealed_row(String.t(), String.t(), keyword()) :: SigningKey.t()
  def sealed_row(kid, kek_id, opts \\ []) do
    material = config_material(kek_id, Keyword.take(opts, [:salt]))
    {:ok, keyset} = KeySet.new(keys: [{kek_id, material}], current: kek_id)
    json = Jason.encode!(private_jwk_map(kid, opts))
    {:ok, envelope} = KeyEncryption.seal(keyset, Keyword.get(opts, :seal_kid, kid), json)
    signing_key_row(kid, envelope, opts)
  end

  @doc "A row with no stored private material."
  @spec nil_material_row(String.t(), keyword()) :: SigningKey.t()
  def nil_material_row(kid, opts \\ []), do: signing_key_row(kid, nil, opts)

  @doc "Inserts a row through the repository and returns the stored domain key."
  @spec insert_signing_key_row!(SigningKey.t()) :: SigningKey.t()
  def insert_signing_key_row!(%SigningKey{} = key) do
    {:ok, stored} = Repository.publish_key(key)
    stored
  end

  defp signing_key_row(kid, stored, opts) do
    use_type = Keyword.get(opts, :use, :sig)
    status = Keyword.get(opts, :status, :upcoming)
    now = DateTime.utc_now()

    %SigningKey{
      kid: kid,
      kty: :RSA,
      alg: "RS256",
      use: use_type,
      public_jwk: %{
        "kty" => "RSA",
        "kid" => kid,
        "alg" => "RS256",
        "use" => Atom.to_string(use_type)
      },
      private_jwk_encrypted: stored,
      status: status,
      published_at: Keyword.get(opts, :published_at, if(status == :upcoming, do: nil, else: now)),
      activated_at: if(status in [:active, :retiring, :retired], do: now),
      retiring_at: if(status in [:retiring, :retired], do: now),
      retired_at: if(status == :retired, do: now),
      inserted_at: now,
      updated_at: now
    }
  end

  defp private_jwk_map(kid, opts) do
    base = base_private_jwk()

    if Keyword.get(opts, :kid_in_jwk, true),
      do: Map.put(base, "kid", Keyword.get(opts, :jwk_kid, kid)),
      else: base
  end

  defp base_private_jwk do
    key = {__MODULE__, :base_private_jwk}

    case :persistent_term.get(key, nil) do
      nil ->
        {_, map} = JOSE.JWK.generate_key({:rsa, 2048}) |> JOSE.JWK.to_map()
        :persistent_term.put(key, map)
        map

      map ->
        map
    end
  end

  defp apply_env(nil), do: Application.delete_env(:lockspire, :key_encryption)
  defp apply_env(config), do: Application.put_env(:lockspire, :key_encryption, config)
end
