defmodule Lockspire.Storage.Ecto.InitialAccessTokenRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.InitialAccessToken

  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_initial_access_tokens" do
    # Hash at rest only; plaintext is never stored. Hash is SHA-256 lowercase hex
    # via Lockspire.Security.Policy.hash_token/1 (the only sanctioned IAT hash primitive).
    field(:token_hash, :string)

    field(:expires_at, :utc_datetime_usec)

    # A boolean, not a uses-remaining counter: IATs are single-use.
    field(:single_use, :boolean, default: true)

    # Nullable lifecycle timestamps: used_at means consumed; revoked_at means operator-revoked.
    field(:used_at, :utc_datetime_usec)
    field(:revoked_at, :utc_datetime_usec)

    # JSONB on disk, decoded as a map. The mint path enforces that overrides narrow
    # the server allowlist.
    field(:policy_overrides, :map)

    # Nullable operator ID for audit attribution.
    field(:created_by, :string)

    timestamps()
  end

  # `:id` is intentionally NOT cast here. `lockspire_initial_access_tokens` uses Postgres
  # autoincrement IDs (unlike the singleton `lockspire_server_policies` row, where ID is
  # fixed at 1 and ServerPolicyRecord.changeset/2 must cast it). Letting a caller pass a
  # `%InitialAccessToken{id: 5}` through the cast list would allow fixtures or admin code
  # to silently override the generated ID and collide with an existing row, surfacing as a
  # unique-constraint violation that is hard to diagnose.
  def changeset(record, %InitialAccessToken{} = iat) do
    record
    |> cast(Map.from_struct(iat), [
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
