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
    mount_path = fetch_required!(:mount_path)
    signing_alg = Application.get_env(@app, :signing_alg, "RS256")

    Policy.validate_issuer_and_mount_path!(issuer, mount_path)
    Policy.validate_signing_alg!(signing_alg)

    issuer
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
    Policy.fetch_required_config!(key, Application.get_env(@app, key))
  end
end
