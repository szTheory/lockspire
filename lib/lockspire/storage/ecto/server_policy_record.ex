defmodule Lockspire.Storage.Ecto.ServerPolicyRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.ServerPolicy

  @singleton_id 1
  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_server_policies" do
    field(:par_policy, Ecto.Enum, values: [:optional, :required], default: :optional)

    timestamps()
  end

  def singleton_id, do: @singleton_id

  def changeset(record, %ServerPolicy{} = policy) do
    record
    |> cast(Map.from_struct(policy), [:id, :par_policy])
    |> validate_required([:id, :par_policy])
  end

  def to_domain(%__MODULE__{} = record) do
    %ServerPolicy{
      id: record.id,
      par_policy: record.par_policy,
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end
end
