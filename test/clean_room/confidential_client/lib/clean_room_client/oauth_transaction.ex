defmodule CleanRoomClient.OAuthTransaction do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "clean_room_oauth_transactions" do
    field(:state, :string)
    field(:nonce, :string)
    field(:verifier, :string)
    field(:challenge, :string)
    field(:issuer, :string)
    field(:client_id, :string)
    field(:callback_uri, :string)
    field(:profile, Ecto.Enum, values: [:bearer, :dpop])
    field(:status, Ecto.Enum, values: [:pending, :consumed, :failed], default: :pending)
    field(:expires_at, :utc_datetime_usec)
    field(:encrypted_dpop_key, :binary)
    field(:dpop_jkt, :string)
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, __schema__(:fields) -- [:id, :inserted_at, :updated_at])
    |> validate_required([
      :state,
      :nonce,
      :verifier,
      :challenge,
      :issuer,
      :client_id,
      :callback_uri,
      :profile,
      :expires_at
    ])
    |> unique_constraint(:state)
  end
end
