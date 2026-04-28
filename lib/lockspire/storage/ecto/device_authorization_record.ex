defmodule Lockspire.Storage.Ecto.DeviceAuthorizationRecord do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lockspire.Domain.DeviceAuthorization

  @timestamps_opts [type: :utc_datetime_usec]
  @statuses DeviceAuthorization.statuses()

  schema "lockspire_device_authorizations" do
    field(:device_code_hash, :string)
    field(:user_code_hash, :string)
    field(:verification_handle, :string)
    field(:client_id, :string)
    field(:scopes, {:array, :string}, default: [])
    field(:status, Ecto.Enum, values: @statuses)
    field(:subject_id, :string)
    field(:approved_at, :utc_datetime_usec)
    field(:denied_at, :utc_datetime_usec)
    field(:consumed_at, :utc_datetime_usec)
    field(:expired_at, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)

    timestamps()
  end

  def changeset(record, %DeviceAuthorization{} = request) do
    attrs = Map.from_struct(request)

    record
    |> cast(attrs, [
      :device_code_hash,
      :user_code_hash,
      :verification_handle,
      :client_id,
      :scopes,
      :status,
      :subject_id,
      :approved_at,
      :denied_at,
      :consumed_at,
      :expired_at,
      :expires_at
    ])
    |> validate_required([
      :device_code_hash,
      :user_code_hash,
      :verification_handle,
      :client_id,
      :status,
      :expires_at
    ])
    |> unique_constraint(:device_code_hash)
    |> unique_constraint(:user_code_hash)
    |> unique_constraint(:verification_handle)
  end

  def update_changeset(record, attrs) when is_map(attrs) do
    record
    |> cast(attrs, [
      :status,
      :subject_id,
      :approved_at,
      :denied_at,
      :consumed_at,
      :expired_at,
      :updated_at,
      :expires_at
    ])
    |> validate_required([:status])
  end

  def to_domain(%__MODULE__{} = record, extra \\ []) do
    %DeviceAuthorization{
      id: record.id,
      device_code_hash: record.device_code_hash,
      user_code_hash: record.user_code_hash,
      verification_handle: record.verification_handle,
      client_id: record.client_id,
      scopes: record.scopes,
      status: record.status,
      subject_id: record.subject_id,
      approved_at: record.approved_at,
      denied_at: record.denied_at,
      consumed_at: record.consumed_at,
      expired_at: record.expired_at,
      expires_at: record.expires_at
    }
    |> Map.merge(Enum.into(extra, %{}))
  end
end
