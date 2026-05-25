defmodule Lockspire.Storage.Ecto.ClientRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.Client

  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_clients" do
    field(:client_id, :string)
    field(:client_secret_hash, :string)
    field(:client_secret_jwt_verifier_encrypted, :string)
    field(:client_type, Ecto.Enum, values: [:public, :confidential])
    field(:name, :string)
    field(:redirect_uris, {:array, :string}, default: [])
    field(:post_logout_redirect_uris, {:array, :string}, default: [])
    field(:backchannel_logout_uri, :string)
    field(:backchannel_logout_session_required, :boolean, default: false)
    field(:frontchannel_logout_uri, :string)
    field(:frontchannel_logout_session_required, :boolean, default: false)
    field(:allowed_scopes, {:array, :string}, default: [])
    field(:allowed_grant_types, {:array, :string}, default: [])
    field(:allowed_response_types, {:array, :string}, default: [])

    field(
      :token_endpoint_auth_method,
      Ecto.Enum,
      values: [
        :client_secret_basic,
        :client_secret_post,
        :client_secret_jwt,
        :private_key_jwt,
        :tls_client_auth,
        :self_signed_tls_client_auth,
        :none
      ]
    )
    field(:token_endpoint_auth_signing_alg, Ecto.Enum, values: [:HS256, :RS256, :ES256, :PS256, :EdDSA])

    field(:pkce_required, :boolean, default: true)
    field(:par_policy, Ecto.Enum, values: [:inherit, :required, :optional], default: :inherit)
    field(:dpop_policy, Ecto.Enum, values: [:inherit, :bearer, :dpop], default: :inherit)

    field(:security_profile, Ecto.Enum,
      values: [:inherit, :fapi_2_0_security, :fapi_2_0_message_signing, :none],
      default: :inherit
    )

    field(:subject_type, Ecto.Enum, values: [:public, :pairwise])
    field(:sector_identifier_uri, :string)
    field(:id_token_signed_response_alg, Ecto.Enum, values: [:RS256, :ES256, :PS256, :EdDSA])

    field(:authorization_signed_response_alg, Ecto.Enum, values: [:RS256, :ES256, :PS256, :EdDSA])
    field(:authorization_encrypted_response_alg, Ecto.Enum, values: [:RSA_OAEP_256, :ECDH_ES])
    field(:authorization_encrypted_response_enc, Ecto.Enum, values: [:A256GCM, :A128GCM])
    field(:tls_client_auth_subject_dn, :string)
    field(:tls_client_auth_san_dns, :string)
    field(:tls_client_auth_san_uri, :string)
    field(:tls_client_auth_san_ip, :string)
    field(:tls_client_auth_san_email, :string)
    field(:jwks, :map)
    field(:jwks_uri, :string)
    field(:logo_uri, :string)
    field(:tos_uri, :string)
    field(:policy_uri, :string)
    field(:contacts, {:array, :string}, default: [])
    field(:tenant_id, :string)
    field(:created_by, :string)
    field(:created_at, :utc_datetime_usec)
    field(:active, :boolean, default: true)
    field(:disabled_at, :utc_datetime_usec)
    field(:disabled_by, :string)
    field(:last_secret_rotated_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})

    # D-08 + D-09: provenance Ecto.Enum cast against the text column from Plan 05 migration.
    # Two-value form (:operator | :self_registered); the 3-value form is deferred.
    # Pitfall 4: text column + Ecto.Enum cast pairing is mandatory.
    field(:provenance, Ecto.Enum, values: [:operator, :self_registered], default: :operator)
    field(:registration_access_token_hash, :string)
    field(:registration_client_uri, :string)
    field(:initial_access_token_id, :integer)
    field(:client_id_issued_at, :utc_datetime_usec)
    field(:client_secret_expires_at, :utc_datetime_usec)
    field(:backchannel_user_code_parameter, :boolean, default: false)

    field(:backchannel_token_delivery_mode, Ecto.Enum,
      values: [:poll, :ping, :push],
      default: :poll
    )

    field(:backchannel_client_notification_endpoint, :string)
    field(:max_delegation_depth, :integer)

    timestamps()
  end

  def changeset(record, %Client{} = client) do
    record
    |> cast(Map.from_struct(client), [
      :client_id,
      :client_secret_hash,
      :client_secret_jwt_verifier_encrypted,
      :client_type,
      :name,
      :redirect_uris,
      :post_logout_redirect_uris,
      :backchannel_logout_uri,
      :backchannel_logout_session_required,
      :frontchannel_logout_uri,
      :frontchannel_logout_session_required,
      :allowed_scopes,
      :allowed_grant_types,
      :allowed_response_types,
      :token_endpoint_auth_method,
      :token_endpoint_auth_signing_alg,
      :pkce_required,
      :par_policy,
      :dpop_policy,
      :security_profile,
      :subject_type,
      :sector_identifier_uri,
      :id_token_signed_response_alg,
      :authorization_signed_response_alg,
      :authorization_encrypted_response_alg,
      :authorization_encrypted_response_enc,
      :tls_client_auth_subject_dn,
      :tls_client_auth_san_dns,
      :tls_client_auth_san_uri,
      :tls_client_auth_san_ip,
      :tls_client_auth_san_email,
      :jwks,
      :jwks_uri,
      :logo_uri,
      :tos_uri,
      :policy_uri,
      :contacts,
      :tenant_id,
      :created_by,
      :created_at,
      :active,
      :disabled_at,
      :disabled_by,
      :last_secret_rotated_at,
      :metadata,
      :provenance,
      :registration_access_token_hash,
      :registration_client_uri,
      :initial_access_token_id,
      :client_id_issued_at,
      :client_secret_expires_at,
      :backchannel_user_code_parameter,
      :backchannel_token_delivery_mode,
      :backchannel_client_notification_endpoint,
      :max_delegation_depth
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
      :subject_type,
      :active,
      :provenance
    ])
    |> validate_number(:max_delegation_depth,
      less_than_or_equal_to: 5,
      greater_than_or_equal_to: 0
    )
    |> validate_fapi_metadata()
    |> unique_constraint(:client_id)
  end

  # Phase 25 note: DCR-related fields are deliberately excluded from update_changeset/2.
  #
  #   :provenance — D-09: create-time-only; covered by client_record_test.exs:87-124.
  #   :registration_access_token_hash
  #   :registration_client_uri
  #   :initial_access_token_id
  #   :client_id_issued_at
  #   :client_secret_expires_at
  #
  # Phase 26 will introduce a separate `dcr_management_changeset/2` for RAT rotation and
  # client_secret rotation under the `:self_registered` provenance (RFC 7592 management).
  # Do NOT add these fields to update_changeset/2 — that would expose them to the
  # operator-admin path (set_client_active, list_clients update flows), which must remain
  # unable to mutate RFC 7592 management state.
  def update_changeset(record, attrs) do
    record
    |> cast(attrs, [
      :name,
      :redirect_uris,
      :post_logout_redirect_uris,
      :backchannel_logout_uri,
      :backchannel_logout_session_required,
      :frontchannel_logout_uri,
      :frontchannel_logout_session_required,
      :allowed_scopes,
      :logo_uri,
      :tos_uri,
      :policy_uri,
      :contacts,
      :par_policy,
      :dpop_policy,
      :security_profile,
      :jwks,
      :jwks_uri,
      :id_token_signed_response_alg,
      :authorization_signed_response_alg,
      :authorization_encrypted_response_alg,
      :authorization_encrypted_response_enc,
      :sector_identifier_uri,
      :metadata,
      :active,
      :disabled_at,
      :disabled_by,
      :client_secret_hash,
      :client_secret_jwt_verifier_encrypted,
      :last_secret_rotated_at,
      :backchannel_user_code_parameter,
      :backchannel_token_delivery_mode,
      :backchannel_client_notification_endpoint,
      :max_delegation_depth
    ])
    |> validate_required([
      :redirect_uris,
      :allowed_scopes,
      :active
    ])
    |> validate_number(:max_delegation_depth,
      less_than_or_equal_to: 5,
      greater_than_or_equal_to: 0
    )
    |> validate_fapi_metadata()
  end

  defp validate_fapi_metadata(changeset) do
    profile = get_field(changeset, :security_profile)
    alg = get_field(changeset, :id_token_signed_response_alg)

    if profile in [:fapi_2_0_security, :fapi_2_0_message_signing] and
         alg not in [nil, :ES256, :PS256] do
      add_error(
        changeset,
        :id_token_signed_response_alg,
        "is incompatible with FAPI 2.0 security profile"
      )
    else
      changeset
    end
  end

  def to_domain(%__MODULE__{} = record) do
    %Client{
      id: record.id,
      client_id: record.client_id,
      client_secret_hash: record.client_secret_hash,
      client_secret_jwt_verifier_encrypted: record.client_secret_jwt_verifier_encrypted,
      client_type: record.client_type,
      name: record.name,
      redirect_uris: record.redirect_uris,
      post_logout_redirect_uris: record.post_logout_redirect_uris,
      backchannel_logout_uri: record.backchannel_logout_uri,
      backchannel_logout_session_required: record.backchannel_logout_session_required,
      frontchannel_logout_uri: record.frontchannel_logout_uri,
      frontchannel_logout_session_required: record.frontchannel_logout_session_required,
      allowed_scopes: record.allowed_scopes,
      allowed_grant_types: record.allowed_grant_types,
      allowed_response_types: record.allowed_response_types,
      token_endpoint_auth_method: record.token_endpoint_auth_method,
      token_endpoint_auth_signing_alg: record.token_endpoint_auth_signing_alg,
      pkce_required: record.pkce_required,
      par_policy: record.par_policy,
      dpop_policy: record.dpop_policy,
      security_profile: record.security_profile,
      subject_type: record.subject_type,
      sector_identifier_uri: record.sector_identifier_uri,
      id_token_signed_response_alg: record.id_token_signed_response_alg,
      authorization_signed_response_alg: record.authorization_signed_response_alg,
      authorization_encrypted_response_alg: record.authorization_encrypted_response_alg,
      authorization_encrypted_response_enc: record.authorization_encrypted_response_enc,
      tls_client_auth_subject_dn: record.tls_client_auth_subject_dn,
      tls_client_auth_san_dns: record.tls_client_auth_san_dns,
      tls_client_auth_san_uri: record.tls_client_auth_san_uri,
      tls_client_auth_san_ip: record.tls_client_auth_san_ip,
      tls_client_auth_san_email: record.tls_client_auth_san_email,
      jwks: record.jwks,
      jwks_uri: record.jwks_uri,
      logo_uri: record.logo_uri,
      tos_uri: record.tos_uri,
      policy_uri: record.policy_uri,
      contacts: record.contacts,
      tenant_id: record.tenant_id,
      created_by: record.created_by,
      created_at: record.created_at,
      active: record.active,
      disabled_at: record.disabled_at,
      disabled_by: record.disabled_by,
      last_secret_rotated_at: record.last_secret_rotated_at,
      metadata: record.metadata || %{},
      provenance: record.provenance,
      registration_access_token_hash: record.registration_access_token_hash,
      registration_client_uri: record.registration_client_uri,
      initial_access_token_id: record.initial_access_token_id,
      client_id_issued_at: record.client_id_issued_at,
      client_secret_expires_at: record.client_secret_expires_at,
      backchannel_user_code_parameter: record.backchannel_user_code_parameter,
      backchannel_token_delivery_mode: record.backchannel_token_delivery_mode,
      backchannel_client_notification_endpoint: record.backchannel_client_notification_endpoint,
      max_delegation_depth: record.max_delegation_depth,
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end
end
