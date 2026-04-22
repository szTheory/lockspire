defmodule Lockspire.Application do
  @moduledoc """
  Lockspire OTP application.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Library-owned services will be added here as protocol, storage, and telemetry
      # components are introduced in later phases.
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Lockspire.Supervisor)
  end
end
