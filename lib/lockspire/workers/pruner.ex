defmodule Lockspire.Workers.Pruner do
  @moduledoc """
  Background worker to aggressively sweep and prune expired domain records.
  """

  use Oban.Worker,
    queue: :pruner,
    max_attempts: 1,
    unique: [
      period: 60
    ]

  alias Lockspire.Observability
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.TokenRecord
  alias Lockspire.Storage.Ecto.DpopReplayRecord
  alias Lockspire.Storage.Ecto.PushedAuthorizationRequestRecord
  alias Lockspire.Storage.Ecto.InteractionRecord
  alias Lockspire.Storage.Ecto.DeviceAuthorizationRecord
  alias Lockspire.Storage.Ecto.InitialAccessTokenRecord

  @schemas [
    TokenRecord,
    DpopReplayRecord,
    PushedAuthorizationRequestRecord,
    InteractionRecord,
    DeviceAuthorizationRecord,
    InitialAccessTokenRecord
  ]

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    now = DateTime.utc_now()

    for schema <- @schemas do
      deleted_count = Repository.prune_expired_records(schema, now)

      schema_name =
        schema
        |> Module.split()
        |> List.last()

      Observability.emit(:pruner, :completed, %{count: deleted_count}, %{model: schema_name})
    end

    :ok
  end
end
