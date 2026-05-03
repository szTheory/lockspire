defmodule Lockspire.Workers.Pruner do
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    :ok
  end
end