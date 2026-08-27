defmodule Lockspire.Architecture.PublicCompatibilityManifest do
  @moduledoc false

  # Literal v1.x surface captured from the Phase 134 base commit (76cf872).
  # Do not derive this from loaded modules: that would bless a regression.
  @modules %{
    Lockspire.Clients => [
      frontchannel_logout_origin_matches_redirect_uri?: 2,
      generate_client_id: 0,
      register_client: 1,
      rotate_secret_hash: 0,
      rotate_secret_material: 0,
      rotate_secret_material: 1,
      validate_allowed_scopes: 1,
      validate_logout_uri: 1,
      validate_redirect_uris: 1
    ],
    Lockspire.Admin.Clients => [
      check_fapi_signing_readiness: 2,
      create_client: 1,
      create_dcr_client: 1,
      disable_client: 1,
      disable_client: 2,
      enable_client: 1,
      enable_client: 2,
      get_client: 1,
      list_clients: 0,
      list_clients: 1,
      normalize_logout_metadata: 1,
      remote_jwks_summary: 1,
      rotate_client_secret: 1,
      rotate_client_secret: 2,
      update_client: 2,
      validate_logout_metadata: 2,
      validate_logout_metadata: 3
    ],
    Lockspire.Protocol.Registration => [
      register: 1,
      validate_intake_metadata: 3,
      validate_intake_metadata: 4
    ],
    Lockspire.Protocol.RegistrationManagement => [
      delete: 2,
      read: 2,
      rotate_registration_access_token: 1,
      update: 2
    ],
    Lockspire.Protocol.Discovery => [
      openid_configuration: 0,
      openid_configuration: 1,
      published_token_endpoint_auth_methods_supported: 0,
      published_token_endpoint_auth_methods_supported: 1,
      token_endpoint_auth_methods_supported: 0
    ],
    Lockspire.Config => [
      account_resolver!: 0,
      backchannel_notification: 0,
      device_verification_uri: 0,
      issuer!: 0,
      jar_max_age_seconds: 0,
      jwks_fetcher: 0,
      jwks_fetcher_opts: 0,
      known_scopes: 0,
      logout_path: 0,
      mount_path: 0,
      mtls_issuer: 0,
      oban_config: 0,
      oban_prefix: 0,
      pruner_schedule: 0,
      rar_types_supported: 0,
      rar_validators: 0,
      repo!: 0,
      secret_key_base: 0,
      security_profile: 0,
      storage_prefix: 0,
      token_exchange_validator: 0
    ],
    Lockspire.Storage.Ecto.Prefix => [
      normalize: 1,
      oban_opts: 0,
      oban_opts: 1,
      prefix_opts: 0,
      prefix_opts: 1,
      quoted_identifier: 1,
      repo_opts: 0,
      repo_opts: 1
    ],
    Lockspire.Protocol.AuthorizationRequest => [validate: 1, validate_pushed: 2],
    Lockspire.Protocol.RequestObject => [consume: 2, consume: 3],
    Lockspire.Protocol.Userinfo => [fetch_claims: 1],
    Lockspire.Protocol.ProtectedResourceDPoP => [validate_access: 2, validate_userinfo_access: 2],
    Lockspire.Protocol.TokenExchange => [
      exchange: 1,
      exchange_authorization_code: 1,
      issue_ciba_tokens: 4,
      validate_grant_resources_for_test: 2
    ],
    Lockspire.Protocol.AccessTokenSigner => [issue: 3, issue_exchange: 4],
    Lockspire.Protocol.TokenEndpointDPoP => [resolve_context: 2, resolve_refresh_context: 3],
    Lockspire.Protocol.RefreshExchange => [exchange_refresh_token: 2],
    Lockspire.Protocol.Rfc8693Exchange => [exchange: 2],
    Lockspire.Protocol.TokenExchange.AuthorizationCodeGrant => [exchange: 1],
    Lockspire.Protocol.TokenExchange.CibaGrant => [exchange: 1, issue_tokens: 4],
    Lockspire.Protocol.TokenExchange.DeviceCodeGrant => [exchange: 1],
    Lockspire.Protocol.TokenExchange.GrantSupport => [
      authenticate_client: 3,
      emit_failure: 3,
      fetch_authorization_code: 2,
      fetch_ciba_authorization_for_exchange: 3,
      fetch_device_authorization_for_exchange: 3,
      handle_code_exchange: 6,
      redeem_ciba_authorization: 4,
      redeem_device_authorization: 4,
      validate_grant_resources_for_test: 2
    ]
  }

  @structs [
    {Lockspire.Clients.RegistrationResult, [:client, :client_secret]},
    {Lockspire.Protocol.Registration.Success,
     [:client, :client_secret_plaintext, :registration_access_token_plaintext]},
    {Lockspire.Protocol.Registration.Error, [:code, :field, :reason, :allowed]},
    {Lockspire.Protocol.RegistrationManagement.UpdateSuccess,
     [:client, :registration_access_token_plaintext]},
    {Lockspire.Protocol.AuthorizationRequest.Validated,
     [
       :client,
       :client_id,
       :redirect_uri,
       :nonce,
       :state,
       :max_age,
       :code_challenge,
       :code_challenge_method,
       :response_mode,
       :scopes,
       :resources,
       :authorization_details,
       :prompt,
       :auth_time_requested?
     ]},
    {Lockspire.Protocol.AuthorizationRequest.Error,
     [:error, :error_description, :reason_code, :state, :redirect_uri]},
    {Lockspire.Protocol.Userinfo.Error,
     [:status, :error, :error_description, :reason_code, :dpop_nonce]},
    {Lockspire.Protocol.TokenExchange.Error,
     [:status, :error, :error_description, :reason_code, :dpop_nonce]},
    {Lockspire.Protocol.TokenExchange.Success,
     [
       :access_token,
       :refresh_token,
       :id_token,
       :token_type,
       :issued_token_type,
       :expires_in,
       :scope
     ]}
  ]

  @result_contracts [
    {:authorization_request, [:ok, :browser_error, :redirect_error],
     [
       Lockspire.Protocol.AuthorizationRequest.Validated,
       Lockspire.Protocol.AuthorizationRequest.Error
     ]},
    {:request_object, [:ok, :browser_error, :redirect_error],
     [Lockspire.Protocol.AuthorizationRequest.Error]},
    {:userinfo, [:ok, :error], [Lockspire.Protocol.Userinfo.Error]},
    {:protected_resource_dpop, [:ok, :error], [Lockspire.Protocol.Userinfo.Error]},
    {:token_exchange, [:ok, :error],
     [Lockspire.Protocol.TokenExchange.Success, Lockspire.Protocol.TokenExchange.Error]},
    {:token_helpers, [:ok, :error],
     [Lockspire.Protocol.TokenExchange.Success, Lockspire.Protocol.TokenExchange.Error]}
  ]

  def modules, do: @modules
  def structs, do: @structs
  def result_contracts, do: @result_contracts
end
