defmodule Lockspire.Storage.Ecto.DeviceAuthorizationRecord do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lockspire.Domain.DeviceAuthorization

  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_device_authorizations" do
    field(:device_code_hash, :string)
    field(:user_code_hash, :string)
    field(:client_id, :string)
    field(:scopes, {:array, :string}, default: [])
    field(:expires_at, :utc_datetime_usec)

    timestamps()
  end

  def changeset(record, %DeviceAuthorization{} = request) do
    attrs = Map.from_struct(request)

    record
    |> cast(attrs, [
      :device_code_hash,
      :user_code_hash,
      :client_id,
      :scopes,
      :expires_at
    ])
    |> validate_required([
      :device_code_hash,
      :user_code_hash,
      :client_id,
      :expires_at
    ])
    |> unique_constraint(:device_code_hash)
    |> unique_constraint(:user_code_hash)
  end
end
