defmodule Lockspire.Config do
  @moduledoc """
  Runtime configuration helpers for the embedded Lockspire library.
  """

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
    fetch_required!(:issuer)
  end

  @spec mount_path() :: String.t()
  def mount_path do
    fetch_required!(:mount_path)
  end

  @spec known_scopes() :: [String.t()]
  def known_scopes do
    @app
    |> Application.get_env(:known_scopes, [])
    |> List.wrap()
  end

  @spec oban_config() :: keyword()
  def oban_config do
    Application.get_env(@app, :oban, [])
  end

  defp fetch_required!(key) do
    case Application.get_env(@app, key) do
      value when value in [nil, ""] ->
        raise ArgumentError,
              "missing required config :#{key} for :lockspire. " <>
                "Set it in config/runtime.exs or config/*.exs."

      value ->
        value
    end
  end
end
