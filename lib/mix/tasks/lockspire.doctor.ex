defmodule Mix.Tasks.Lockspire.Doctor do
  @moduledoc """
  Dispatcher for Lockspire runtime diagnostic subcommands.
  """

  use Mix.Task

  @shortdoc "Runs Lockspire runtime diagnostic commands"

  @impl Mix.Task
  def run(["remote-jwks" | rest]) do
    Mix.Task.run("lockspire.doctor.remote_jwks", rest)
  end

  def run(["token_format" | rest]) do
    Mix.Task.run("lockspire.doctor.token_format", rest)
  end

  def run(_args) do
    Mix.raise("""
    Unknown doctor command.

    Supported commands:
      mix lockspire.doctor remote-jwks --client CLIENT_ID
      mix lockspire.doctor token_format
    """)
  end
end
