defmodule Lockspire.Architecture.PublicCompatibilityManifest do
  @moduledoc false

  @modules [
    {Lockspire.Clients, :register_client, 1},
    {Lockspire.Admin.Clients, :create_client, 1},
    {Lockspire.Protocol.Registration, :register, 1},
    {Lockspire.Protocol.RegistrationManagement, :update, 2},
    {Lockspire.Protocol.RegistrationManagement, :delete, 2},
    {Lockspire.Protocol.Discovery, :openid_configuration, 0},
    {Lockspire.Config, :storage_prefix, 0},
    {Lockspire.Storage.Ecto.Prefix, :prefix_opts, 0},
    {Lockspire.Protocol.AuthorizationRequest, :validate, 1},
    {Lockspire.Protocol.RequestObject, :consume, 3},
    {Lockspire.Protocol.Userinfo, :fetch_claims, 1},
    {Lockspire.Protocol.ProtectedResourceDPoP, :validate_access, 2},
    {Lockspire.Protocol.TokenExchange, :exchange, 1}
  ]

  @structs [
    {Lockspire.Clients.RegistrationResult, [:client, :client_secret]},
    {Lockspire.Protocol.Registration.Success,
     [:client, :client_secret_plaintext, :registration_access_token_plaintext]},
    {Lockspire.Protocol.Registration.Error, [:code, :field, :reason, :allowed]},
    {Lockspire.Protocol.RegistrationManagement.UpdateSuccess,
     [:client, :registration_access_token_plaintext]},
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

  def modules, do: @modules
  def structs, do: @structs
end
