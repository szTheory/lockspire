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
    issuer = fetch_required!(:issuer)
    mount_path = fetch_required!(:mount_path)

    validate_issuer!(issuer, mount_path)
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

  defp validate_issuer!(issuer, mount_path) do
    uri = URI.parse(issuer)
    issuer_path = uri.path || "/"

    cond do
      not absolute_uri?(uri) ->
        raise ArgumentError,
              "invalid :issuer for :lockspire. Expected an absolute URL with scheme and host."

      present?(uri.query) ->
        raise ArgumentError,
              "invalid :issuer for :lockspire. Query parameters are not allowed."

      present?(uri.fragment) ->
        raise ArgumentError,
              "invalid :issuer for :lockspire. Fragments are not allowed."

      issuer_path != mount_path ->
        raise ArgumentError,
              "invalid :issuer for :lockspire. Issuer path #{inspect(issuer_path)} must match mount_path #{inspect(mount_path)}."

      true ->
        issuer
    end
  end

  defp absolute_uri?(%URI{scheme: scheme, host: host})
       when is_binary(scheme) and scheme != "" and is_binary(host) and host != "",
       do: true

  defp absolute_uri?(_uri), do: false

  defp present?(value) when value in [nil, ""], do: false
  defp present?(_value), do: true
end
