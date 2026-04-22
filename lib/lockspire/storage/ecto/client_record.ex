defmodule Lockspire.Storage.Ecto.ClientRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.Client

  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_clients" do
    field :client_id, :string
    field :client_secret_hash, :string
    field :client_type, Ecto.Enum, values: [:public, :confidential]
    field :name, :string
    field :redirect_uris, {:array, :string}, default: []
    field :post_logout_redirect_uris, {:array, :string}, default: []
    field :allowed_scopes, {:array, :string}, default: []
    field :allowed_grant_types, {:array, :string}, default: []
    field :allowed_response_types, {:array, :string}, default: []
    field :token_endpoint_auth_method,
          Ecto.Enum,
          values: [:client_secret_basic, :client_secret_post, :private_key_jwt, :none]

    field :pkce_required, :boolean, default: true
    field :subject_type, Ecto.Enum, values: [:public, :pairwise]
    field :sector_identifier_uri, :string
    field :id_token_signed_response_alg, Ecto.Enum, values: [:RS256, :ES256, :EdDSA]
    field :jwks, :map
    field :jwks_uri, :string
    field :logo_uri, :string
    field :tos_uri, :string
    field :policy_uri, :string
    field :contacts, {:array, :string}, default: []
    field :tenant_id, :string
    field :created_by, :string
    field :created_at, :utc_datetime_usec
    field :metadata, :map, default: %{}

    timestamps()
  end

  def changeset(record, %Client{} = client) do
    record
    |> cast(Map.from_struct(client), [
      :client_id,
      :client_secret_hash,
      :client_type,
      :name,
      :redirect_uris,
      :post_logout_redirect_uris,
      :allowed_scopes,
      :allowed_grant_types,
      :allowed_response_types,
      :token_endpoint_auth_method,
      :pkce_required,
      :subject_type,
      :sector_identifier_uri,
      :id_token_signed_response_alg,
      :jwks,
      :jwks_uri,
      :logo_uri,
      :tos_uri,
      :policy_uri,
      :contacts,
      :tenant_id,
      :created_by,
      :created_at,
      :metadata
    ])
    |> validate_required([
      :client_id,
      :client_type,
      :redirect_uris,
      :allowed_scopes,
      :allowed_grant_types,
      :allowed_response_types,
      :token_endpoint_auth_method,
      :pkce_required,
      :subject_type
    ])
    |> unique_constraint(:client_id)
  end

  def to_domain(%__MODULE__{} = record) do
    %Client{
      id: record.id,
      client_id: record.client_id,
      client_secret_hash: record.client_secret_hash,
      client_type: record.client_type,
      name: record.name,
      redirect_uris: record.redirect_uris,
      post_logout_redirect_uris: record.post_logout_redirect_uris,
      allowed_scopes: record.allowed_scopes,
      allowed_grant_types: record.allowed_grant_types,
      allowed_response_types: record.allowed_response_types,
      token_endpoint_auth_method: record.token_endpoint_auth_method,
      pkce_required: record.pkce_required,
      subject_type: record.subject_type,
      sector_identifier_uri: record.sector_identifier_uri,
      id_token_signed_response_alg: record.id_token_signed_response_alg,
      jwks: record.jwks,
      jwks_uri: record.jwks_uri,
      logo_uri: record.logo_uri,
      tos_uri: record.tos_uri,
      policy_uri: record.policy_uri,
      contacts: record.contacts,
      tenant_id: record.tenant_id,
      created_by: record.created_by,
      created_at: record.created_at,
      metadata: record.metadata || %{},
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end
end
