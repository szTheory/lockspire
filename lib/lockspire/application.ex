defmodule Lockspire.Application do
  @moduledoc """
  Lockspire OTP application.
  """

  use Application

  require Logger

  alias Lockspire.Config
  alias Lockspire.Security.KeyEncryption.KeySet

  @impl true
  def start(_type, _args) do
    validate_key_encryption!()
    Lockspire.DiscoveryRoutes.install_default_capability()

    children = [
      {Lockspire.Oban, Lockspire.Oban.runtime_config!()},
      Cachex.child_spec(name: :lockspire_jwks_cache),
      {Lockspire.KeyCache, Application.get_env(:lockspire, Lockspire.KeyCache, [])}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Lockspire.Supervisor)
  end

  @doc false
  @spec validate_key_encryption!() :: :ok
  def validate_key_encryption! do
    case Config.key_encryption!() do
      %KeySet{} = keyset ->
        :persistent_term.put(Config.key_encryption_cache_key(), keyset)

      nil ->
        :persistent_term.put(Config.key_encryption_cache_key(), :unconfigured)

        Logger.warning(
          "Lockspire :key_encryption is not configured. Existing signing keys keep working, " <>
            "but new signing keys cannot be generated until config :lockspire, :key_encryption " <>
            "is set in config/runtime.exs (create a key with `openssl rand -base64 32`)."
        )
    end

    :ok
  end
end
