defmodule Lockspire.Storage.Ecto.TokenRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.Token

  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_tokens" do
    field :token_hash, :string
    field :token_type, Ecto.Enum, values: [:authorization_code, :access_token, :refresh_token]
    field :jti, :string
    field :family_id, :string
    field :generation, :integer, default: 0
    field :parent_token_id, :integer
    field :client_id, :string
    field :account_id, :string
    field :scopes, {:array, :string}, default: []
    field :audience, {:array, :string}, default: []
    field :cnf, :map
    field :expires_at, :utc_datetime_usec
    field :revoked_at, :utc_datetime_usec
    field :reuse_detected_at, :utc_datetime_usec

    timestamps()
  end

  def changeset(record, %Token{} = token) do
    record
    |> cast(Map.from_struct(token), [
      :token_hash,
      :token_type,
      :jti,
      :family_id,
      :generation,
      :parent_token_id,
      :client_id,
      :account_id,
      :scopes,
      :audience,
      :cnf,
      :expires_at,
      :revoked_at,
      :reuse_detected_at
    ])
    |> validate_required([:token_hash, :token_type, :client_id, :expires_at])
    |> unique_constraint(:token_hash)
  end

  def to_domain(%__MODULE__{} = record) do
    %Token{
      id: record.id,
      token_hash: record.token_hash,
      token_type: record.token_type,
      jti: record.jti,
      family_id: record.family_id,
      generation: record.generation || 0,
      parent_token_id: record.parent_token_id,
      client_id: record.client_id,
      account_id: record.account_id,
      scopes: record.scopes,
      audience: record.audience,
      cnf: record.cnf,
      expires_at: record.expires_at,
      revoked_at: record.revoked_at,
      reuse_detected_at: record.reuse_detected_at,
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end
end
