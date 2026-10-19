defmodule Lockspire.Config do
  @moduledoc """
  Runtime configuration helpers for the embedded Lockspire library.
  """

  alias Lockspire.Security.KeyEncryption.KeySet
  alias Lockspire.Security.Policy

  @app :lockspire

  @doc """
  Returns the configured Ecto repo module, or raises if missing.
  """
  @spec repo!() :: module()
  def repo! do
    fetch_required!(:repo)
  end

  @doc """
  Returns the configured account resolver module, or raises if missing.
  """
  @spec account_resolver!() :: module()
  def account_resolver! do
    fetch_required!(:account_resolver)
  end

  @doc """
  Returns the configured backchannel notification module, or nil if not set.
  """
  @spec backchannel_notification() :: module() | nil
  def backchannel_notification do
    Application.get_env(@app, :backchannel_notification)
  end

  @doc """
  Returns the configured token exchange validator module, or defaults to a delegation validator.
  """
  @spec token_exchange_validator() :: module()
  def token_exchange_validator do
    Application.get_env(
      @app,
      :token_exchange_validator,
      Lockspire.Host.DefaultDelegationValidator
    )
  end

  @doc """
  Returns the validated configured issuer string, or raises if invalid/missing.
  """
  @spec issuer!() :: String.t()
  def issuer! do
    issuer = fetch_required!(:issuer)
    mount_path = mount_path()
    signing_alg = Application.get_env(@app, :signing_alg, "RS256")

    Policy.validate_issuer_and_mount_path!(issuer, mount_path)
    Policy.validate_signing_alg!(signing_alg)

    issuer
  end

  @doc """
  Returns the configured Lockspire mount path.

  Accepts any binary, including the empty string (`""`), which is a deliberate
  signal that Lockspire is mounted at the host's root. Only `nil` (config
  unset) is rejected — host apps must set this explicitly to declare intent.
  """
  @spec mount_path() :: String.t()
  def mount_path do
    case Application.get_env(@app, :mount_path) do
      value when is_binary(value) ->
        value

      _missing ->
        raise ArgumentError,
              "missing required config :mount_path for :lockspire. " <>
                "Set it in config/runtime.exs or config/*.exs."
    end
  end

  @doc """
  Returns the configured Lockspire endpoint secret key base, or nil if unset.
  """
  @spec secret_key_base() :: String.t() | nil
  def secret_key_base do
    direct_secret_key_base(Lockspire.Web.Endpoint) ||
      inferred_secret_key_base()
  end

  @doc """
  Returns the configured logout path.
  """
  @spec logout_path() :: String.t()
  def logout_path do
    case Application.get_env(@app, :logout_path) do
      value when is_binary(value) and value != "" ->
        value

      _missing ->
        raise ArgumentError,
              "missing required config :logout_path for :lockspire. " <>
                "Set it in config/runtime.exs or config/*.exs."
    end
  end

  @doc """
  Returns the list of known scopes.
  """
  @spec known_scopes() :: [String.t()]
  def known_scopes do
    @app
    |> Application.get_env(:known_scopes, [])
    |> List.wrap()
  end

  @doc """
  Returns the configured RAR authorization detail types.
  """
  @spec rar_types_supported() :: [String.t()]
  def rar_types_supported do
    @app
    |> Application.get_env(:rar_types_supported, [])
    |> List.wrap()
  end

  @doc """
  Returns the configured RAR type validators.
  """
  @spec rar_validators() :: map()
  def rar_validators do
    @app
    |> Application.get_env(:rar_validators, %{})
    |> Map.new()
  end

  @doc """
  Returns the security profile configuration.
  """
  @spec security_profile() :: :none | :fapi_2_0_security
  def security_profile do
    Application.get_env(@app, :security_profile, :none)
  end

  @doc """
  Returns the computed device verification URI.
  """
  @spec device_verification_uri() :: String.t()
  def device_verification_uri do
    issuer!()
    |> URI.parse()
    |> Map.put(:path, "/verify")
    |> Map.put(:query, nil)
    |> Map.put(:fragment, nil)
    |> URI.to_string()
  end

  @jar_max_age_default 600

  @doc """
  Returns the configured JAR (`request` JWT) maximum age in seconds.

  Caps `exp - now` for inbound JAR request objects to bound the replay window
  between issuance and use. Default: #{@jar_max_age_default}s (10 minutes).

  Hosts can override via `config :lockspire, jar_max_age_seconds: 300`.
  Lower values reduce replay risk but may break clients with clock drift.

  `Lockspire.Protocol.RequestObject.consume/3` threads this value into
  `Lockspire.Protocol.Jar.validate_claims/2` so the ceiling is enforced at the
  protocol seam.
  """
  @spec jar_max_age_seconds() :: pos_integer()
  def jar_max_age_seconds do
    Application.get_env(@app, :jar_max_age_seconds, @jar_max_age_default)
  end

  @doc """
  Returns the Oban configuration keyword list.
  """
  @spec oban_config() :: keyword()
  def oban_config do
    Application.get_env(@app, :oban, [])
  end

  @doc """
  Returns the configured Postgres schema/prefix for Lockspire-owned tables.

  Missing config intentionally means "legacy/default search path" so existing
  public-schema installs do not silently point at an empty `lockspire` schema
  after upgrading. Generated new installs set `"lockspire"` explicitly.
  """
  @spec storage_prefix() :: String.t() | nil
  def storage_prefix do
    @app
    |> Application.get_env(:storage_prefix)
    |> Lockspire.Storage.Prefix.normalize()
  end

  @doc """
  Returns the configured Postgres schema/prefix for Lockspire's Oban tables.
  """
  @spec oban_prefix() :: String.t() | nil
  def oban_prefix do
    @app
    |> Application.get_env(:oban_prefix, storage_prefix())
    |> Lockspire.Storage.Prefix.normalize()
  end

  @doc """
  Returns the schedule string for the pruner, or false if disabled.
  """
  @spec pruner_schedule() :: String.t() | false
  def pruner_schedule do
    Application.get_env(@app, :pruner_schedule, "@hourly")
  end

  @doc """
  Returns optional JWKS fetcher overrides.

  This is primarily used by repo-owned tests that need to drive the guarded
  `jwks_uri` fetch path through `Req.Test` without changing the shipped runtime
  defaults.
  """
  @spec jwks_fetcher_opts() :: keyword()
  def jwks_fetcher_opts do
    Application.get_env(@app, :jwks_fetcher_opts, [])
  end

  @doc """
  Returns the JWKS fetcher module.
  """
  @spec jwks_fetcher() :: module()
  def jwks_fetcher do
    Application.get_env(@app, :jwks_fetcher, Lockspire.JwksFetcher)
  end

  @doc """
  Returns the MTLS issuer string if configured, or nil.
  """
  @spec mtls_issuer() :: String.t() | nil
  def mtls_issuer do
    Application.get_env(@app, :mtls_issuer)
  end

  @key_encryption_cache_key {Lockspire, :key_encryption}

  # Validates the `:key_encryption` block fresh from app env.
  #
  # Returns nil when the block is absent, a resolved key set when valid, and raises
  # `ArgumentError` naming only config keys (never values) when invalid.
  #
  # `{id, {:system, "VAR"}}` entries are read from the environment on each call; a
  # missing or empty variable raises (it never degrades to "not configured").
  @doc false
  @spec key_encryption!() :: KeySet.t() | nil
  def key_encryption! do
    case Application.get_env(@app, :key_encryption) do
      nil ->
        nil

      config ->
        with {:ok, resolved} <- resolve_env_entries(config),
             {:ok, %KeySet{} = keyset} <- KeySet.new(resolved) do
          keyset
        else
          {:error, {config_key, reason}} -> fail_key_encryption!(config_key, reason)
          {:error, {config_key, reason, var}} -> fail_key_encryption!(config_key, reason, var)
        end
    end
  end

  @spec resolve_env_entries(term()) ::
          {:ok, term()} | {:error, {:keys, :missing_env | :blank_env, String.t()}}
  defp resolve_env_entries(config) when is_list(config) do
    with true <- Keyword.keyword?(config),
         keys when is_list(keys) <- Keyword.get(config, :keys) do
      keys
      |> Enum.reduce_while({:ok, []}, fn
        {id, {:system, var}}, {:ok, acc} when is_binary(var) ->
          case System.fetch_env(var) do
            {:ok, value} when value != "" ->
              # The value is passed through untrimmed (fail closed); a whitespace-only
              # value is rejected here so the error names the variable.
              if String.trim(value) == "" do
                {:halt, {:error, {:keys, :blank_env, var}}}
              else
                {:cont, {:ok, [{id, value} | acc]}}
              end

            _unset_or_empty ->
              {:halt, {:error, {:keys, :missing_env, var}}}
          end

        entry, {:ok, acc} ->
          {:cont, {:ok, [entry | acc]}}
      end)
      |> case do
        {:ok, acc} -> {:ok, Keyword.replace!(config, :keys, Enum.reverse(acc))}
        {:error, _reason} = error -> error
      end
    else
      _not_resolvable -> {:ok, config}
    end
  end

  defp resolve_env_entries(config), do: {:ok, config}

  # Returns the cached key set (populated at boot), falling back to fresh validation.
  @doc false
  @spec key_encryption_keyset() :: KeySet.t() | nil
  def key_encryption_keyset do
    case :persistent_term.get(@key_encryption_cache_key, :miss) do
      %KeySet{} = keyset -> keyset
      :unconfigured -> nil
      _miss -> key_encryption!()
    end
  end

  @doc false
  @spec key_encryption_cache_key() :: {Lockspire, :key_encryption}
  def key_encryption_cache_key, do: @key_encryption_cache_key

  defp fail_key_encryption!(:keys, :missing_env, var) when is_binary(var) do
    raise ArgumentError,
          "invalid config :key_encryption (:keys: missing_env) for :lockspire. " <>
            "Environment variable #{var} is unset or empty. Set it before the app boots; " <>
            "generate a value with `mix lockspire.gen.kek`."
  end

  defp fail_key_encryption!(:keys, :blank_env, var) when is_binary(var) do
    raise ArgumentError,
          "invalid config :key_encryption (:keys: blank_env) for :lockspire. " <>
            "Environment variable #{var} contains only whitespace. Remove stray spaces or " <>
            "newlines from the secret; generate a value with `mix lockspire.gen.kek`."
  end

  defp fail_key_encryption!(config_key, reason) when is_atom(config_key) and is_atom(reason) do
    raise ArgumentError,
          "invalid config :key_encryption (#{inspect(config_key)}: #{reason}) for :lockspire. " <>
            "Each key must be base64 of 32 random bytes; generate one with " <>
            "`mix lockspire.gen.kek` and set it in config/runtime.exs. " <>
            "Note that `mix phx.gen.secret` output is not 32 bytes of base64 and will not work."
  end

  defp fetch_required!(key) do
    Policy.fetch_required_config!(key, Application.get_env(@app, key))
  end

  defp direct_secret_key_base(endpoint_module) do
    @app
    |> Application.get_env(endpoint_module, [])
    |> Keyword.get(:secret_key_base)
  end

  defp inferred_secret_key_base do
    @app
    |> Application.get_all_env()
    |> Enum.find_value(fn
      {_key, value} when is_list(value) ->
        Keyword.get(value, :secret_key_base)

      _other ->
        nil
    end)
  end
end
