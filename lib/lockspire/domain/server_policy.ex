defmodule Lockspire.Domain.ServerPolicy do
  @moduledoc """
  Durable server-wide operator policy owned by Lockspire.
  """

  @type par_policy :: :optional | :required
  @type dpop_policy :: :bearer | :dpop
  @type registration_policy :: :disabled | :initial_access_token | :open

  @type t :: %__MODULE__{
          id: integer() | nil,
          par_policy: par_policy(),
          dpop_policy: dpop_policy(),
          registration_policy: registration_policy(),
          dcr_allowed_scopes: [String.t()],
          dcr_allowed_grant_types: [String.t()],
          dcr_allowed_response_types: [String.t()],
          dcr_allowed_redirect_uri_schemes: [String.t()],
          dcr_allowed_redirect_uri_hosts: [String.t()],
          dcr_allowed_token_endpoint_auth_methods: [String.t()],
          dcr_default_client_lifetime_seconds: non_neg_integer() | nil,
          dcr_default_client_secret_lifetime_seconds: non_neg_integer() | nil,
          dcr_default_registration_access_token_lifetime_seconds: non_neg_integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct id: nil,
            par_policy: :optional,
            dpop_policy: :bearer,
            registration_policy: :disabled,
            dcr_allowed_scopes: [],
            dcr_allowed_grant_types: [],
            dcr_allowed_response_types: [],
            dcr_allowed_redirect_uri_schemes: [],
            dcr_allowed_redirect_uri_hosts: [],
            dcr_allowed_token_endpoint_auth_methods: [],
            dcr_default_client_lifetime_seconds: nil,
            dcr_default_client_secret_lifetime_seconds: nil,
            dcr_default_registration_access_token_lifetime_seconds: nil,
            inserted_at: nil,
            updated_at: nil
end
