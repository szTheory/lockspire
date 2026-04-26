defmodule Lockspire.Storage.Ecto.InitialAccessTokenRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.InitialAccessToken

  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_initial_access_tokens" do
    # D-11 / D-14: hash-at-rest only; plaintext is never stored. Hash is sha256-lowercase-hex
    # via Lockspire.Security.Policy.hash_token/1 (the only sanctioned IAT hash primitive).
    field(:token_hash, :string)

    field(:expires_at, :utc_datetime_usec)

    # D-13: boolean (NOT uses_remaining int); v1.5 mints single-use IATs only.
    field(:single_use, :boolean, default: true)

    # D-11: nullable lifecycle timestamps. used_at = registrant consumed; revoked_at = operator soft-deleted.
    field(:used_at, :utc_datetime_usec)
    field(:revoked_at, :utc_datetime_usec)

    # D-11: jsonb on disk, decoded as map. Untyped — Phase 28 mint-time enforces ⊆ server allowlist.
    field(:policy_overrides, :map)

    # D-11: nullable operator id (audit attribution).
    field(:created_by, :string)

    timestamps()
  end

  def changeset(record, %InitialAccessToken{} = iat) do
    record
    |> cast(Map.from_struct(iat), [
      :id,
      :token_hash,
      :expires_at,
      :single_use,
      :used_at,
      :revoked_at,
      :policy_overrides,
      :created_by
    ])
    |> validate_required([:token_hash, :expires_at, :single_use])
    |> unique_constraint(:token_hash)
  end

  def to_domain(%__MODULE__{} = record) do
    %InitialAccessToken{
      id: record.id,
      token_hash: record.token_hash,
      expires_at: record.expires_at,
      single_use: record.single_use,
      used_at: record.used_at,
      revoked_at: record.revoked_at,
      policy_overrides: record.policy_overrides,
      created_by: record.created_by,
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end
end
