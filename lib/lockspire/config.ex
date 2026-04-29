defmodule Lockspire.Config do
  @moduledoc """
  Runtime configuration helpers for the embedded Lockspire library.
  """

  alias Lockspire.Security.Policy

  @app :lockspire

  @spec repo!() :: module()
  def repo! do
    fetch_required!(:repo)
  end

  @spec account_resolver!() :: module()
  def account_resolver! do
    fetch_required!(:account_resolver)
  end

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

  @spec known_scopes() :: [String.t()]
  def known_scopes do
    @app
    |> Application.get_env(:known_scopes, [])
    |> List.wrap()
  end

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

  Consumed by `Lockspire.Protocol.RequestObject.consume/3` (Phase 22) and threaded
  into `Lockspire.Protocol.Jar.validate_claims/2`'s `:max_age` opt to enforce the
  ceiling at the protocol seam (D-13, WR-03).
  """
  @spec jar_max_age_seconds() :: pos_integer()
  def jar_max_age_seconds do
    Application.get_env(@app, :jar_max_age_seconds, @jar_max_age_default)
  end

  @spec oban_config() :: keyword()
  def oban_config do
    Application.get_env(@app, :oban, [])
  end

  defp fetch_required!(key) do
    Policy.fetch_required_config!(key, Application.get_env(@app, key))
  end
end
