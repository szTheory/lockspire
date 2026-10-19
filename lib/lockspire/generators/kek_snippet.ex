defmodule Lockspire.Generators.KekSnippet do
  @moduledoc false

  # Single builder for the key-encryption key value, its default id and the production
  # config/runtime.exs block. Shared by the installer and `mix lockspire.gen.kek`. No I/O here.

  alias Lockspire.Security.KeyEncryption.KeySet

  @env_var "LOCKSPIRE_KEY_ENCRYPTION_KEY"

  @spec env_var() :: String.t()
  def env_var, do: @env_var

  @spec generate_key() :: String.t()
  def generate_key, do: Base.encode64(:crypto.strong_rand_bytes(32))

  @spec default_id() :: String.t()
  def default_id, do: Calendar.strftime(DateTime.utc_now(), "%Y-%m")

  @spec prod_block(String.t(), non_neg_integer()) :: String.t()
  def prod_block(id, indent \\ 0) do
    unless KeySet.valid_id?(id) do
      raise ArgumentError,
            "key id must be 1-32 characters from A-Z, a-z, 0-9, dot, underscore or dash"
    end

    block = """
    if config_env() == :prod do
      config :lockspire, :key_encryption,
        keys: [
          {"#{id}",
           System.get_env("#{@env_var}") ||
             raise("#{@env_var} is missing. Generate one with: mix lockspire.gen.kek")}
        ],
        current: "#{id}",
        legacy_plaintext: :reject
    end
    """

    pad = String.duplicate(" ", indent)

    block
    |> String.split("\n")
    |> Enum.map_join("\n", fn
      "" -> ""
      line -> pad <> line
    end)
  end
end
