defmodule Lockspire.Storage.Ecto.TokenRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.Token

  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_tokens" do
    field(:token_hash, :string)
    field(:token_type, Ecto.Enum, values: [:authorization_code, :access_token, :refresh_token])
    field(:jti, :string)
    field(:family_id, :string)
    field(:generation, :integer, default: 0)
    field(:parent_token_id, :integer)
    field(:client_id, :string)
    field(:account_id, :string)
    field(:interaction_id, :string)
    field(:redirect_uri, :string)
    field(:scopes, {:array, :string}, default: [])
    field(:audience, {:array, :string}, default: [])
    field(:cnf, :map)
    field(:code_challenge, :string)
    field(:code_challenge_method, Ecto.Enum, values: [:S256])
    field(:issued_at, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)
    field(:redeemed_at, :utc_datetime_usec)
    field(:revoked_at, :utc_datetime_usec)
    field(:reuse_detected_at, :utc_datetime_usec)

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
      :interaction_id,
      :redirect_uri,
      :scopes,
      :audience,
      :cnf,
      :code_challenge,
      :code_challenge_method,
      :issued_at,
      :expires_at,
      :redeemed_at,
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
      interaction_id: record.interaction_id,
      redirect_uri: record.redirect_uri,
      scopes: record.scopes,
      audience: record.audience,
      cnf: record.cnf,
      code_challenge: record.code_challenge,
      code_challenge_method: record.code_challenge_method,
      issued_at: record.issued_at,
      expires_at: record.expires_at,
      redeemed_at: record.redeemed_at,
      revoked_at: record.revoked_at,
      reuse_detected_at: record.reuse_detected_at,
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end
end
