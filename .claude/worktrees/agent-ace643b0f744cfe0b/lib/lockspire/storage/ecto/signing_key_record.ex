defmodule Lockspire.Storage.Ecto.SigningKeyRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.SigningKey

  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_signing_keys" do
    field(:kid, :string)
    field(:kty, Ecto.Enum, values: [:RSA, :EC, :OKP])
    field(:alg, :string)
    field(:use, Ecto.Enum, values: [:sig])
    field(:public_jwk, :map)
    field(:private_jwk_encrypted, :binary)
    field(:status, Ecto.Enum, values: [:upcoming, :active, :retiring, :retired])
    field(:published_at, :utc_datetime_usec)
    field(:activated_at, :utc_datetime_usec)
    field(:retiring_at, :utc_datetime_usec)
    field(:retired_at, :utc_datetime_usec)
    field(:tenant_id, :string)
    field(:metadata, :map, default: %{})

    timestamps()
  end

  def changeset(record, %SigningKey{} = key) do
    record
    |> cast(Map.from_struct(key), [
      :kid,
      :kty,
      :alg,
      :use,
      :public_jwk,
      :private_jwk_encrypted,
      :status,
      :published_at,
      :activated_at,
      :retiring_at,
      :retired_at,
      :tenant_id,
      :metadata
    ])
    |> validate_required([:kid, :kty, :alg, :use, :public_jwk, :status])
    |> unique_constraint(:kid)
  end

  def update_changeset(record, attrs) when is_map(attrs) do
    record
    |> cast(attrs, [
      :status,
      :published_at,
      :activated_at,
      :retiring_at,
      :retired_at,
      :metadata
    ])
  end

  def to_domain(%__MODULE__{} = record) do
    %SigningKey{
      id: record.id,
      kid: record.kid,
      kty: record.kty,
      alg: record.alg,
      use: record.use,
      public_jwk: record.public_jwk || %{},
      private_jwk_encrypted: record.private_jwk_encrypted,
      status: record.status,
      published_at: record.published_at,
      activated_at: record.activated_at,
      retiring_at: record.retiring_at,
      retired_at: record.retired_at,
      tenant_id: record.tenant_id,
      metadata: record.metadata || %{},
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end
end
