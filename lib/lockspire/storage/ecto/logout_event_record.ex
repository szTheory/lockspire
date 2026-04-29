defmodule Lockspire.Storage.Ecto.LogoutEventRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.LogoutEvent

  @timestamps_opts [type: :utc_datetime_usec]
  @initiated_by_values [:rp_initiated_logout]

  schema "lockspire_logout_events" do
    field(:event_id, :string)
    field(:sid, :string)
    field(:account_id, :string)
    field(:subject, :string)
    field(:initiated_by, Ecto.Enum, values: @initiated_by_values)
    field(:post_logout_redirect_uri, :string)
    field(:frontchannel_continue_to, :string)
    field(:completed_at, :utc_datetime_usec)

    timestamps()
  end

  def changeset(record, %LogoutEvent{} = event) do
    record
    |> cast(Map.from_struct(event), [
      :event_id,
      :sid,
      :account_id,
      :subject,
      :initiated_by,
      :post_logout_redirect_uri,
      :frontchannel_continue_to,
      :completed_at
    ])
    |> validate_required([:event_id, :initiated_by])
    |> unique_constraint(:event_id)
  end

  def to_domain(%__MODULE__{} = record) do
    %LogoutEvent{
      id: record.id,
      event_id: record.event_id,
      sid: record.sid,
      account_id: record.account_id,
      subject: record.subject,
      initiated_by: record.initiated_by,
      post_logout_redirect_uri: record.post_logout_redirect_uri,
      frontchannel_continue_to: record.frontchannel_continue_to,
      completed_at: record.completed_at,
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end
end
