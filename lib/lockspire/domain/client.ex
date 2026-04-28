defmodule Lockspire.Domain.Client do
  @moduledoc """
  Durable client registration state owned by Lockspire.
  """

  @type client_type :: :public | :confidential
  @type token_endpoint_auth_method ::
          :client_secret_basic | :client_secret_post | :private_key_jwt | :none
  @type subject_type :: :public | :pairwise
  @type signing_alg :: :RS256 | :ES256 | :EdDSA
  @type par_policy :: :inherit | :required | :optional
  @type dpop_policy :: :inherit | :bearer | :dpop
  @type provenance :: :operator | :self_registered

  @type t :: %__MODULE__{
          id: integer() | nil,
          client_id: String.t(),
          client_secret_hash: String.t() | nil,
          client_type: client_type(),
          name: String.t() | nil,
          redirect_uris: [String.t()],
          post_logout_redirect_uris: [String.t()],
          allowed_scopes: [String.t()],
          allowed_grant_types: [String.t()],
          allowed_response_types: [String.t()],
          token_endpoint_auth_method: token_endpoint_auth_method(),
          pkce_required: boolean(),
          par_policy: par_policy(),
          dpop_policy: dpop_policy(),
          subject_type: subject_type(),
          sector_identifier_uri: String.t() | nil,
          id_token_signed_response_alg: signing_alg() | nil,
          jwks: map() | nil,
          jwks_uri: String.t() | nil,
          logo_uri: String.t() | nil,
          tos_uri: String.t() | nil,
          policy_uri: String.t() | nil,
          contacts: [String.t()],
          tenant_id: String.t() | nil,
          created_by: String.t() | nil,
          created_at: DateTime.t() | nil,
          active: boolean(),
          disabled_at: DateTime.t() | nil,
          disabled_by: String.t() | nil,
          last_secret_rotated_at: DateTime.t() | nil,
          metadata: map(),
          provenance: provenance(),
          registration_access_token_hash: String.t() | nil,
          registration_client_uri: String.t() | nil,
          initial_access_token_id: integer() | nil,
          client_id_issued_at: DateTime.t() | nil,
          client_secret_expires_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  # credo:disable-for-next-line
  defstruct [
    :id,
    :client_id,
    :client_secret_hash,
    :client_type,
    :name,
    redirect_uris: [],
    post_logout_redirect_uris: [],
    allowed_scopes: [],
    allowed_grant_types: [],
    allowed_response_types: [],
    token_endpoint_auth_method: :client_secret_basic,
    pkce_required: true,
    par_policy: :inherit,
    dpop_policy: :inherit,
    subject_type: :public,
    sector_identifier_uri: nil,
    id_token_signed_response_alg: nil,
    jwks: nil,
    jwks_uri: nil,
    logo_uri: nil,
    tos_uri: nil,
    policy_uri: nil,
    contacts: [],
    tenant_id: nil,
    created_by: nil,
    created_at: nil,
    active: true,
    disabled_at: nil,
    disabled_by: nil,
    last_secret_rotated_at: nil,
    metadata: %{},
    provenance: :operator,
    registration_access_token_hash: nil,
    registration_client_uri: nil,
    initial_access_token_id: nil,
    client_id_issued_at: nil,
    client_secret_expires_at: nil,
    inserted_at: nil,
    updated_at: nil
  ]
end
