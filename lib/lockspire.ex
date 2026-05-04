defmodule Lockspire do
  @moduledoc """
  Narrow public API for host applications embedding Lockspire.
  """

  alias Lockspire.Config

  @doc """
  Returns a consolidated map of all Lockspire configuration.
  """
  @spec config() :: %{
          repo: module(),
          account_resolver: module(),
          issuer: String.t(),
          mount_path: String.t(),
          logout_path: String.t(),
          oban: keyword()
        }
  def config do
    %{
      repo: Config.repo!(),
      account_resolver: Config.account_resolver!(),
      issuer: Config.issuer!(),
      mount_path: Config.mount_path(),
      logout_path: Config.logout_path(),
      oban: Config.oban_config()
    }
  end

  @doc """
  Returns the configured OIDC issuer string.
  """
  @spec issuer() :: String.t()
  def issuer do
    Config.issuer!()
  end

  @spec mount_path() :: String.t()
  def mount_path do
    Config.mount_path()
  end

  @doc """
  Returns the configured logout path.
  """
  @spec logout_path() :: String.t()
  def logout_path do
    Config.logout_path()
  end

  @doc """
  Returns the configured account resolver module, or raises if missing.
  """
  @spec account_resolver!() :: module()
  def account_resolver! do
    Config.account_resolver!()
  end
end
