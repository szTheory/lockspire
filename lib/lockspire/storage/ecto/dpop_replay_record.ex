defmodule Lockspire.Storage.Ecto.DpopReplayRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.DpopReplay

  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_dpop_replay" do
    field(:replay_key, :string)
    field(:jti, :string)
    field(:htm, :string)
    field(:htu, :string)
    field(:jkt, :string)
    field(:seen_at, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)

    timestamps()
  end

  def changeset(record, %DpopReplay{} = replay) do
    record
    |> cast(Map.from_struct(replay), [:replay_key, :jti, :htm, :htu, :jkt, :seen_at, :expires_at])
    |> validate_required([:replay_key, :jti, :htm, :htu, :jkt, :seen_at, :expires_at])
    |> unique_constraint(:replay_key)
  end

  def to_domain(%__MODULE__{} = record) do
    %DpopReplay{
      id: record.id,
      replay_key: record.replay_key,
      jti: record.jti,
      htm: record.htm,
      htu: record.htu,
      jkt: record.jkt,
      seen_at: record.seen_at,
      expires_at: record.expires_at,
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end
end
