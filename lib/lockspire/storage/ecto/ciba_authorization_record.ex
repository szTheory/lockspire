defmodule Lockspire.Storage.Ecto.CibaAuthorizationRecord do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lockspire.Domain.CibaAuthorization

  @timestamps_opts [type: :utc_datetime_usec]
  @statuses CibaAuthorization.statuses()

  schema "lockspire_ciba_authorizations" do
    field(:auth_req_id_hash, :string)
    field(:client_id, :string)
    field(:scopes, {:array, :string}, default: [])
    field(:status, Ecto.Enum, values: @statuses)
    field(:subject_id, :string)
    field(:approved_at, :utc_datetime_usec)
    field(:denied_at, :utc_datetime_usec)
    field(:consumed_at, :utc_datetime_usec)
    field(:expired_at, :utc_datetime_usec)
    field(:effective_poll_interval_seconds, :integer, default: 5)
    field(:next_poll_allowed_at, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)
    field(:binding_message, :string)
    field(:delivery_mode, Ecto.Enum, values: [:poll, :ping, :push], default: :poll)
    field(:client_notification_endpoint, :string)
    field(:client_notification_token_encrypted, :binary)
    field(:auth_req_id_encrypted, :binary)

    timestamps()
  end

  def changeset(record, %CibaAuthorization{} = request) do
    attrs = Map.from_struct(request)

    record
    |> cast(attrs, [
      :auth_req_id_hash,
      :client_id,
      :scopes,
      :status,
      :subject_id,
      :approved_at,
      :denied_at,
      :consumed_at,
      :expired_at,
      :effective_poll_interval_seconds,
      :next_poll_allowed_at,
      :expires_at,
      :binding_message,
      :delivery_mode,
      :client_notification_endpoint,
      :client_notification_token_encrypted,
      :auth_req_id_encrypted
    ])
    |> validate_required([
      :auth_req_id_hash,
      :client_id,
      :status,
      :effective_poll_interval_seconds,
      :next_poll_allowed_at,
      :expires_at,
      :delivery_mode
    ])
    |> unique_constraint(:auth_req_id_hash)
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
      :effective_poll_interval_seconds,
      :next_poll_allowed_at,
      :updated_at,
      :expires_at
    ])
    |> validate_required([:status])
  end

  def to_domain(%__MODULE__{} = record, extra \\ []) do
    %CibaAuthorization{
      id: record.id,
      auth_req_id_hash: record.auth_req_id_hash,
      client_id: record.client_id,
      scopes: record.scopes,
      status: record.status,
      subject_id: record.subject_id,
      approved_at: record.approved_at,
      denied_at: record.denied_at,
      consumed_at: record.consumed_at,
      expired_at: record.expired_at,
      effective_poll_interval_seconds: record.effective_poll_interval_seconds,
      next_poll_allowed_at: record.next_poll_allowed_at,
      expires_at: record.expires_at,
      binding_message: record.binding_message,
      delivery_mode: record.delivery_mode,
      client_notification_endpoint: record.client_notification_endpoint,
      client_notification_token_encrypted: record.client_notification_token_encrypted,
      auth_req_id_encrypted: record.auth_req_id_encrypted
    }
    |> Map.merge(Enum.into(extra, %{}))
  end
end
