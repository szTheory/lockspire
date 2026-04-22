defmodule Lockspire.Storage.Ecto.ConsentGrantRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.ConsentGrant

  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_consent_grants" do
    field :account_id, :string
    field :client_id, :string
    field :scopes, {:array, :string}, default: []
    field :granted_at, :utc_datetime_usec
    field :revoked_at, :utc_datetime_usec
    field :tenant_id, :string
    field :metadata, :map, default: %{}

    timestamps()
  end

  def changeset(record, %ConsentGrant{} = grant) do
    record
    |> cast(Map.from_struct(grant), [
      :account_id,
      :client_id,
      :scopes,
      :granted_at,
      :revoked_at,
      :tenant_id,
      :metadata
    ])
    |> validate_required([:account_id, :client_id, :scopes, :granted_at])
  end

  def to_domain(%__MODULE__{} = record) do
    %ConsentGrant{
      id: record.id,
      account_id: record.account_id,
      client_id: record.client_id,
      scopes: record.scopes,
      granted_at: record.granted_at,
      revoked_at: record.revoked_at,
      tenant_id: record.tenant_id,
      metadata: record.metadata || %{},
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end
end
