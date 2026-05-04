defmodule Lockspire.Storage.Ecto.UsedJtiRecord do
  @moduledoc """
  Ecto schema for storing used JTIs to prevent replay attacks.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "lockspire_used_jtis" do
    field(:client_id, :string)
    field(:jti, :string)
    field(:expires_at, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(used_jti_record, attrs) do
    used_jti_record
    |> cast(attrs, [:client_id, :jti, :expires_at])
    |> validate_required([:client_id, :jti, :expires_at])
    |> unique_constraint([:client_id, :jti], name: :lockspire_used_jtis_client_id_jti_index)
  end
end
