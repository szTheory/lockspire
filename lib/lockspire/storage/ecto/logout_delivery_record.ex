defmodule Lockspire.Storage.Ecto.LogoutDeliveryRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.LogoutDelivery

  @timestamps_opts [type: :utc_datetime_usec]
  @channel_values [:backchannel, :frontchannel]
  @status_values [
    :pending,
    :enqueued,
    :attempted,
    :succeeded,
    :retryable,
    :discarded,
    :rendered,
    :skipped
  ]

  schema "lockspire_logout_deliveries" do
    field(:delivery_id, :string)
    field(:client_id, :string)
    field(:channel, Ecto.Enum, values: @channel_values)
    field(:target_uri, :string)
    field(:session_required, :boolean, default: false)
    field(:status, Ecto.Enum, values: @status_values, default: :pending)
    field(:attempt_count, :integer, default: 0)
    field(:last_attempted_at, :utc_datetime_usec)
    field(:delivered_at, :utc_datetime_usec)
    field(:rendered_at, :utc_datetime_usec)
    field(:finalized_at, :utc_datetime_usec)
    field(:http_status, :integer)
    field(:failure_reason, :string)
    field(:logout_token_jti, :string)
    field(:oban_job_id, :integer)

    belongs_to(:logout_event, Lockspire.Storage.Ecto.LogoutEventRecord)

    timestamps()
  end

  def changeset(record, %LogoutDelivery{} = delivery) do
    record
    |> cast(Map.from_struct(delivery), [
      :delivery_id,
      :logout_event_id,
      :client_id,
      :channel,
      :target_uri,
      :session_required,
      :status,
      :attempt_count,
      :last_attempted_at,
      :delivered_at,
      :rendered_at,
      :finalized_at,
      :http_status,
      :failure_reason,
      :logout_token_jti,
      :oban_job_id
    ])
    |> validate_required([
      :delivery_id,
      :logout_event_id,
      :client_id,
      :channel,
      :target_uri,
      :session_required,
      :status,
      :attempt_count
    ])
    |> assoc_constraint(:logout_event)
    |> unique_constraint(:delivery_id)
    |> unique_constraint([:logout_event_id, :client_id, :channel])
  end

  def to_domain(%__MODULE__{} = record) do
    %LogoutDelivery{
      id: record.id,
      delivery_id: record.delivery_id,
      logout_event_id: record.logout_event_id,
      client_id: record.client_id,
      channel: record.channel,
      target_uri: record.target_uri,
      session_required: record.session_required,
      status: record.status,
      attempt_count: record.attempt_count || 0,
      last_attempted_at: record.last_attempted_at,
      delivered_at: record.delivered_at,
      rendered_at: record.rendered_at,
      finalized_at: record.finalized_at,
      http_status: record.http_status,
      failure_reason: record.failure_reason,
      logout_token_jti: record.logout_token_jti,
      oban_job_id: record.oban_job_id,
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end
end
