defmodule Lockspire do
  @moduledoc """
  Narrow public API for host applications embedding Lockspire.
  """

  alias Lockspire.Config

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

  @spec issuer() :: String.t()
  def issuer do
    Config.issuer!()
  end

  @spec mount_path() :: String.t()
  def mount_path do
    Config.mount_path()
  end

  @spec logout_path() :: String.t()
  def logout_path do
    Config.logout_path()
  end

  @spec account_resolver!() :: module()
  def account_resolver! do
    Config.account_resolver!()
  end
end
