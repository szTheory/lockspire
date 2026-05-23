defmodule Lockspire.Application do
  @moduledoc """
  Lockspire OTP application.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Lockspire.Oban, Lockspire.Oban.runtime_config!()},
      Cachex.child_spec(name: :lockspire_jwks_cache),
      Lockspire.KeyCache
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Lockspire.Supervisor)
  end
end
