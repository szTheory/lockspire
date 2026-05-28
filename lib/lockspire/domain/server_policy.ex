defmodule Lockspire.Domain.ServerPolicy do
  @moduledoc """
  Durable server-wide operator policy owned by Lockspire.
  """

  @type par_policy :: :optional | :required
  @type dpop_policy :: :bearer | :dpop
  @type security_profile :: :none | :fapi_2_0_security | :fapi_2_0_message_signing
  @type registration_policy :: :disabled | :initial_access_token | :open
  @type access_token_format :: :jwt | :opaque

  @type t :: %__MODULE__{
          id: integer() | nil,
          par_policy: par_policy(),
          dpop_policy: dpop_policy(),
          security_profile: security_profile(),
          registration_policy: registration_policy(),
          access_token_format: access_token_format(),
          dcr_allowed_scopes: [String.t()],
          dcr_allowed_grant_types: [String.t()],
          dcr_allowed_response_types: [String.t()],
          dcr_allowed_redirect_uri_schemes: [String.t()],
          dcr_allowed_redirect_uri_hosts: [String.t()],
          dcr_allowed_token_endpoint_auth_methods: [String.t()],
          dcr_default_client_lifetime_seconds: non_neg_integer() | nil,
          dcr_default_client_secret_lifetime_seconds: non_neg_integer() | nil,
          dcr_default_registration_access_token_lifetime_seconds: non_neg_integer() | nil,
          max_delegation_depth: non_neg_integer(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct id: nil,
            par_policy: :optional,
            dpop_policy: :bearer,
            security_profile: :none,
            registration_policy: :disabled,
            access_token_format: :jwt,
            dcr_allowed_scopes: [],
            dcr_allowed_grant_types: [],
            dcr_allowed_response_types: [],
            dcr_allowed_redirect_uri_schemes: [],
            dcr_allowed_redirect_uri_hosts: [],
            dcr_allowed_token_endpoint_auth_methods: [],
            dcr_default_client_lifetime_seconds: nil,
            dcr_default_client_secret_lifetime_seconds: nil,
            dcr_default_registration_access_token_lifetime_seconds: nil,
            max_delegation_depth: 3,
            inserted_at: nil,
            updated_at: nil
end
