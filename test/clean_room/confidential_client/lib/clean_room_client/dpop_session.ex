defmodule CleanRoomClient.DPoPSession do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "clean_room_dpop_sessions" do
    field :handle, :string
    field :encrypted_key, :binary
    field :encrypted_access_token, :binary
    field :encrypted_accepted_resource_proof, :binary
    field :subject, :string
    field :jkt, :string
    field :expires_at, :utc_datetime_usec
    field :closed_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(session, attrs) do
    session
    |> cast(attrs, __schema__(:fields) -- [:id, :inserted_at, :updated_at])
    |> validate_required([:handle, :encrypted_key, :encrypted_access_token, :subject, :jkt, :expires_at])
    |> unique_constraint(:handle)
  end
end
