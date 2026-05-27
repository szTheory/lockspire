defmodule AdoptionDemo.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AdoptionDemo.Repo,
      {Lockspire.Oban, Lockspire.Oban.runtime_config!()},
      Cachex.child_spec(name: :lockspire_jwks_cache),
      Lockspire.KeyCache,
      AdoptionDemoWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: AdoptionDemo.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    AdoptionDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
