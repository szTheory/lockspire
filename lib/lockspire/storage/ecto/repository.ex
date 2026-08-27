defmodule Lockspire.Storage.Ecto.Repository do
  @moduledoc """
  Default Ecto-backed implementation for Lockspire's domain storage contracts.
  """

  alias Lockspire.Audit.Event
  alias Lockspire.Config
  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Domain.DpopReplay
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.LogoutEvent
  alias Lockspire.Domain.PushedAuthorizationRequest
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.Domain.UsedJti
  alias Lockspire.Storage.CibaAuthorizationStore
  alias Lockspire.Storage.ClientStore
  alias Lockspire.Storage.ConsentStore
  alias Lockspire.Storage.DeviceAuthorizationStore
  alias Lockspire.Storage.DpopReplayStore
  alias Lockspire.Storage.Ecto.Repository.AuditStore, as: EctoAuditStore
  alias Lockspire.Storage.Ecto.Repository.ClientStore, as: EctoClientStore
  alias Lockspire.Storage.Ecto.Repository.ConsentStore, as: EctoConsentStore
  alias Lockspire.Storage.Ecto.Repository.CibaAuthorizationStore, as: EctoCibaAuthorizationStore

  alias Lockspire.Storage.Ecto.Repository.DeviceAuthorizationStore,
    as: EctoDeviceAuthorizationStore

  alias Lockspire.Storage.Ecto.Repository.InteractionStore, as: EctoInteractionStore
  alias Lockspire.Storage.Ecto.Repository.InitialAccessTokenStore, as: EctoInitialAccessTokenStore
  alias Lockspire.Storage.Ecto.Repository.LogoutStore, as: EctoLogoutStore

  alias Lockspire.Storage.Ecto.Repository.PushedAuthorizationRequestStore,
    as: EctoPushedAuthorizationRequestStore

  alias Lockspire.Storage.Ecto.Repository.ReplayStore, as: EctoReplayStore
  alias Lockspire.Storage.Ecto.Repository.TokenStore, as: EctoTokenStore
  alias Lockspire.Storage.Ecto.Repository.SigningKeyStore, as: EctoSigningKeyStore

  alias Lockspire.Storage.Ecto.Repository.ServerPolicyStore, as: EctoServerPolicyStore
  alias Lockspire.Storage.Ecto.Repository.PruningStore, as: EctoPruningStore
  alias Lockspire.Storage.Ecto.Repository.TransactionStore, as: EctoTransactionStore
  alias Lockspire.Storage.InteractionStore
  alias Lockspire.Storage.InitialAccessTokenStore
  alias Lockspire.Storage.KeyStore
  alias Lockspire.Storage.LogoutStore
  alias Lockspire.Storage.PushedAuthorizationRequestStore
  alias Lockspire.Storage.ServerPolicyStore
  alias Lockspire.Storage.TokenStore
  alias Lockspire.Storage.TransactionStore
  alias Lockspire.Storage.AuditStore
  alias Lockspire.Storage.UsedJtiStore

  @behaviour ClientStore
  @behaviour InteractionStore
  @behaviour ConsentStore
  @behaviour TokenStore
  @behaviour KeyStore
  @behaviour PushedAuthorizationRequestStore
  @behaviour DeviceAuthorizationStore
  @behaviour CibaAuthorizationStore
  @behaviour DpopReplayStore
  @behaviour ServerPolicyStore
  @behaviour LogoutStore
  @behaviour UsedJtiStore
  @behaviour InitialAccessTokenStore
  @behaviour TransactionStore
  @behaviour AuditStore

  @impl ClientStore
  def register_client(%Client{} = client) do
    EctoClientStore.register_client(repo(), client)
  end

  @impl ClientStore
  def list_clients(opts \\ []) when is_list(opts) do
    EctoClientStore.list_clients(repo(), opts)
  end

  @impl ClientStore
  def fetch_client_by_id(client_id) when is_binary(client_id) do
    EctoClientStore.fetch_client_by_id(repo(), client_id)
  end

  @impl ClientStore
  def get_client_by_registration_access_token_hash(rat_hash) when is_binary(rat_hash) do
    EctoClientStore.get_client_by_registration_access_token_hash(repo(), rat_hash)
  end

  @impl ClientStore
  def replace_client_registration(
        %Client{id: id},
        %Client{} = replacement,
        new_rat_hash,
        audit_attrs
      )
      when is_integer(id) and is_binary(new_rat_hash) and is_map(audit_attrs) do
    EctoClientStore.replace_client_registration(
      repo(),
      %Client{id: id},
      replacement,
      new_rat_hash,
      audit_attrs
    )
  end

  @impl ClientStore
  def rotate_registration_access_token(%Client{id: id}, new_rat_hash, audit_attrs)
      when is_integer(id) and is_binary(new_rat_hash) and is_map(audit_attrs) do
    EctoClientStore.rotate_registration_access_token(
      repo(),
      %Client{id: id},
      new_rat_hash,
      audit_attrs
    )
  end

  @impl ClientStore
  def update_client(%Client{id: id}, attrs) when is_integer(id) and is_map(attrs) do
    EctoClientStore.update_client(repo(), %Client{id: id}, attrs)
  end

  @impl ServerPolicyStore
  def get_server_policy do
    EctoServerPolicyStore.get_server_policy(repo())
  end

  @impl ServerPolicyStore
  def put_server_policy(%ServerPolicy{} = policy) do
    EctoServerPolicyStore.put_server_policy(repo(), policy)
  end

  @impl ServerPolicyStore
  def update_server_policy(mutator) when is_function(mutator, 1) do
    EctoServerPolicyStore.update_server_policy(repo(), mutator)
  end

  @impl ClientStore
  def rotate_client_secret(%Client{id: id}, secret_hash, verifier_encrypted, rotated_at)
      when is_integer(id) and is_binary(secret_hash) and is_binary(verifier_encrypted) and
             is_struct(rotated_at, DateTime) do
    EctoClientStore.rotate_client_secret(
      repo(),
      %Client{id: id},
      secret_hash,
      verifier_encrypted,
      rotated_at
    )
  end

  @impl ClientStore
  def set_client_active(%Client{id: id}, active, attrs)
      when is_integer(id) and is_boolean(active) and is_map(attrs) do
    EctoClientStore.set_client_active(repo(), %Client{id: id}, active, attrs)
  end

  @impl InteractionStore
  def put_interaction(%Interaction{} = interaction) do
    EctoInteractionStore.put_interaction(repo(), interaction)
  end

  @impl InteractionStore
  def fetch_interaction(interaction_id) when is_binary(interaction_id) do
    EctoInteractionStore.fetch_interaction(repo(), interaction_id)
  end

  @impl InteractionStore
  def fetch_active_interaction(interaction_id) when is_binary(interaction_id) do
    EctoInteractionStore.fetch_active_interaction(repo(), interaction_id)
  end

  @impl InteractionStore
  def list_interactions(_opts \\ []) do
    EctoInteractionStore.list_interactions(repo())
  end

  @impl InteractionStore
  def transition_interaction(interaction_id, expected_statuses, attrs)
      when is_binary(interaction_id) and is_list(expected_statuses) and is_map(attrs) do
    EctoInteractionStore.transition_interaction(repo(), interaction_id, expected_statuses, attrs)
  end

  @impl TransactionStore
  def transact(fun) when is_function(fun, 0) do
    EctoTransactionStore.transact(repo(), fun)
  end

  @impl TransactionStore
  def rollback(reason), do: EctoTransactionStore.rollback(repo(), reason)

  @impl PushedAuthorizationRequestStore
  def put_pushed_authorization_request(%PushedAuthorizationRequest{} = request) do
    EctoPushedAuthorizationRequestStore.put_pushed_authorization_request(repo(), request)
  end

  @impl PushedAuthorizationRequestStore
  def fetch_active_pushed_authorization_request(request_uri_hash)
      when is_binary(request_uri_hash) do
    EctoPushedAuthorizationRequestStore.fetch_active_pushed_authorization_request(
      repo(),
      request_uri_hash
    )
  end

  @impl PushedAuthorizationRequestStore
  def consume_pushed_authorization_request(request_uri_hash, client_id)
      when is_binary(request_uri_hash) and is_binary(client_id) do
    EctoPushedAuthorizationRequestStore.consume_pushed_authorization_request(
      repo(),
      request_uri_hash,
      client_id
    )
  end

  def list_device_authorizations(opts \\ []) when is_list(opts) do
    EctoDeviceAuthorizationStore.list_device_authorizations(repo(), opts)
  end

  @impl DeviceAuthorizationStore
  def put_device_authorization(%DeviceAuthorization{} = auth) do
    EctoDeviceAuthorizationStore.put_device_authorization(repo(), auth)
  end

  @impl DeviceAuthorizationStore
  def fetch_device_authorization_by_user_code_hash(user_code_hash)
      when is_binary(user_code_hash) do
    EctoDeviceAuthorizationStore.fetch_device_authorization_by_user_code_hash(
      repo(),
      user_code_hash
    )
  end

  @impl DeviceAuthorizationStore
  def fetch_device_authorization_by_device_code_hash(device_code_hash)
      when is_binary(device_code_hash) do
    EctoDeviceAuthorizationStore.fetch_device_authorization_by_device_code_hash(
      repo(),
      device_code_hash
    )
  end

  @impl DeviceAuthorizationStore
  def fetch_device_authorization_by_verification_handle(verification_handle)
      when is_binary(verification_handle) do
    EctoDeviceAuthorizationStore.fetch_device_authorization_by_verification_handle(
      repo(),
      verification_handle
    )
  end

  @impl DeviceAuthorizationStore
  def record_device_poll(device_code_hash, client_id, now)
      when is_binary(device_code_hash) and is_binary(client_id) and is_struct(now, DateTime) do
    EctoDeviceAuthorizationStore.record_device_poll(repo(), device_code_hash, client_id, now)
  end

  @impl DeviceAuthorizationStore
  def consume_device_authorization(verification_handle, client_id, now)
      when is_binary(verification_handle) and is_binary(client_id) and is_struct(now, DateTime) do
    EctoDeviceAuthorizationStore.consume_device_authorization(
      repo(),
      verification_handle,
      client_id,
      now
    )
  end

  @impl DpopReplayStore
  def record_dpop_proof(%DpopReplay{} = replay) do
    EctoReplayStore.record_dpop_proof(repo(), replay)
  end

  @impl UsedJtiStore
  def record_used_jti(%UsedJti{} = used_jti) do
    EctoReplayStore.record_used_jti(repo(), used_jti)
  end

  @impl DeviceAuthorizationStore
  def transition_device_authorization(verification_handle, expected_statuses, attrs)
      when is_binary(verification_handle) and is_list(expected_statuses) and is_map(attrs) do
    EctoDeviceAuthorizationStore.transition_device_authorization(
      repo(),
      verification_handle,
      expected_statuses,
      attrs
    )
  end

  @impl CibaAuthorizationStore
  def put_ciba_authorization(%CibaAuthorization{} = auth) do
    EctoCibaAuthorizationStore.put_ciba_authorization(repo(), auth)
  end

  @impl CibaAuthorizationStore
  def fetch_ciba_authorization_by_auth_req_id_hash(auth_req_id_hash)
      when is_binary(auth_req_id_hash) do
    EctoCibaAuthorizationStore.fetch_ciba_authorization_by_auth_req_id_hash(
      repo(),
      auth_req_id_hash
    )
  end

  @impl CibaAuthorizationStore
  def record_ciba_poll(auth_req_id_hash, client_id, now)
      when is_binary(auth_req_id_hash) and is_binary(client_id) and is_struct(now, DateTime) do
    EctoCibaAuthorizationStore.record_ciba_poll(repo(), auth_req_id_hash, client_id, now)
  end

  @impl CibaAuthorizationStore
  def transition_ciba_authorization(auth_req_id_hash, expected_statuses, attrs)
      when is_binary(auth_req_id_hash) and is_list(expected_statuses) and is_map(attrs) do
    EctoCibaAuthorizationStore.transition_ciba_authorization(
      repo(),
      auth_req_id_hash,
      expected_statuses,
      attrs
    )
  end

  @impl AuditStore
  def append_audit_event(%Event{} = event) do
    EctoAuditStore.append_audit_event(repo(), event)
  end

  def append_audit_event(attrs) when is_map(attrs) do
    EctoAuditStore.append_audit_event(repo(), attrs)
  end

  @impl AuditStore
  def transact_with_audit(audit_event, fun) when is_function(fun, 0) do
    EctoAuditStore.transact_with_audit(repo(), audit_event, fun)
  end

  @impl ConsentStore
  def grant_consent(%ConsentGrant{} = grant) do
    EctoConsentStore.grant_consent(repo(), grant)
  end

  @impl ConsentStore
  def list_consents(opts \\ []) when is_list(opts) do
    EctoConsentStore.list_consents(repo(), opts)
  end

  @impl ConsentStore
  def list_consents_for_account(account_id) when is_binary(account_id) do
    EctoConsentStore.list_consents_for_account(repo(), account_id)
  end

  @impl ConsentStore
  def fetch_consent_grant(grant_id) when is_integer(grant_id) do
    EctoConsentStore.fetch_consent_grant(repo(), grant_id)
  end

  @impl ConsentStore
  def list_reusable_consents(account_id, client_id)
      when is_binary(account_id) and is_binary(client_id) do
    EctoConsentStore.list_reusable_consents(repo(), account_id, client_id)
  end

  @impl ConsentStore
  def revoke_consent_grant(grant_id, attrs) when is_integer(grant_id) and is_map(attrs) do
    EctoConsentStore.revoke_consent_grant(repo(), grant_id, attrs)
  end

  @impl TokenStore
  def store_token(%Token{} = token) do
    EctoTokenStore.store_token(repo(), token)
  end

  @impl TokenStore
  def list_lifecycle_tokens(opts \\ []) when is_list(opts) do
    EctoTokenStore.list_lifecycle_tokens(repo(), opts)
  end

  @impl TokenStore
  def fetch_lifecycle_token_by_id(token_id) when is_integer(token_id) do
    EctoTokenStore.fetch_lifecycle_token_by_id(repo(), token_id)
  end

  @impl TokenStore
  def list_token_family(family_id) when is_binary(family_id) do
    EctoTokenStore.list_token_family(repo(), family_id)
  end

  @impl TokenStore
  def revoke_token_family(family_id) when is_binary(family_id) do
    EctoTokenStore.revoke_token_family(repo(), family_id)
  end

  @impl TokenStore
  def revoke_by_sid(sid), do: EctoTokenStore.revoke_by_sid(repo(), sid)

  @impl LogoutStore
  def persist_logout_propagation(%LogoutEvent{} = event, opts \\ []) do
    EctoLogoutStore.persist(repo(), event, opts)
  end

  @impl LogoutStore
  def fetch_logout_event_by_event_id(event_id) when is_binary(event_id) do
    EctoLogoutStore.fetch_event(repo(), event_id)
  end

  @impl LogoutStore
  def list_all_logout_deliveries do
    EctoLogoutStore.list_all(repo())
  end

  @impl LogoutStore
  def list_logout_deliveries(logout_event_id) when is_integer(logout_event_id) do
    EctoLogoutStore.list(repo(), logout_event_id)
  end

  @impl LogoutStore
  def mark_logout_delivery_enqueued(logout_delivery_id, oban_job_id)
      when is_integer(logout_delivery_id) and is_integer(oban_job_id) do
    EctoLogoutStore.enqueue(repo(), logout_delivery_id, oban_job_id)
  end

  @impl TokenStore
  def fetch_authorization_code(token_hash) when is_binary(token_hash) do
    EctoTokenStore.fetch_authorization_code(repo(), token_hash)
  end

  @impl TokenStore
  def fetch_lifecycle_token(token_hash) when is_binary(token_hash) do
    EctoTokenStore.fetch_lifecycle_token(repo(), token_hash)
  end

  @impl TokenStore
  def fetch_refresh_token(token_hash) when is_binary(token_hash) do
    EctoTokenStore.fetch_refresh_token(repo(), token_hash)
  end

  @impl TokenStore
  def fetch_active_authorization_code(token_hash) when is_binary(token_hash) do
    EctoTokenStore.fetch_active_authorization_code(repo(), token_hash)
  end

  @impl TokenStore
  def fetch_active_access_token(token_hash) when is_binary(token_hash) do
    EctoTokenStore.fetch_active_access_token(repo(), token_hash)
  end

  @impl TokenStore
  def revoke_lifecycle_token(token_hash, client_id, revoked_at)
      when is_binary(token_hash) and is_binary(client_id) and is_struct(revoked_at, DateTime) do
    EctoTokenStore.revoke_lifecycle_token(repo(), token_hash, client_id, revoked_at)
  end

  @impl TokenStore
  def mark_authorization_code_redeemed(token_hash, redeemed_at)
      when is_binary(token_hash) and is_struct(redeemed_at, DateTime) do
    EctoTokenStore.mark_authorization_code_redeemed(repo(), token_hash, redeemed_at)
  end

  @impl InitialAccessTokenStore
  def redeem_initial_access_token(token_hash, redeemed_at)
      when is_binary(token_hash) and is_struct(redeemed_at, DateTime) do
    EctoInitialAccessTokenStore.redeem(repo(), token_hash, redeemed_at)
  end

  @impl InitialAccessTokenStore
  def list_initial_access_tokens(_opts \\ []) do
    EctoInitialAccessTokenStore.list(repo())
  end

  @impl InitialAccessTokenStore
  def save_initial_access_token(%Lockspire.Domain.InitialAccessToken{} = iat) do
    EctoInitialAccessTokenStore.save(repo(), iat)
  end

  @impl InitialAccessTokenStore
  def revoke_initial_access_token(id, revoked_at)
      when is_integer(id) and is_struct(revoked_at, DateTime) do
    EctoInitialAccessTokenStore.revoke(repo(), id, revoked_at)
  end

  @impl KeyStore
  def publish_key(%SigningKey{} = key), do: EctoSigningKeyStore.publish_key(repo(), key)

  @impl KeyStore
  def list_active_keys, do: EctoSigningKeyStore.list_active_keys(repo())

  @impl KeyStore
  def list_signing_keys(opts \\ []) when is_list(opts),
    do: EctoSigningKeyStore.list_signing_keys(repo(), opts)

  @impl KeyStore
  def list_publishable_keys(opts \\ []) when is_list(opts),
    do: EctoSigningKeyStore.list_publishable_keys(repo(), opts)

  @impl KeyStore
  def list_decryption_keys, do: EctoSigningKeyStore.list_decryption_keys(repo())

  @spec validate_fapi_signing_readiness() ::
          :ok
          | {:error, :missing_compliant_active_key | :missing_compliant_publishable_key | term()}
  def validate_fapi_signing_readiness,
    do: EctoSigningKeyStore.validate_fapi_signing_readiness(repo())

  @spec validate_message_signing_readiness() ::
          :ok
          | {:error, :missing_compliant_active_key | :missing_compliant_publishable_key | term()}
  def validate_message_signing_readiness,
    do: EctoSigningKeyStore.validate_message_signing_readiness(repo())

  @impl KeyStore
  def fetch_active_signing_key(opts \\ []) when is_list(opts),
    do: EctoSigningKeyStore.fetch_active_signing_key(repo(), opts)

  @impl KeyStore
  def fetch_signing_key_by_id(id) when is_integer(id),
    do: EctoSigningKeyStore.fetch_signing_key_by_id(repo(), id)

  @impl KeyStore
  def publish_signing_key(id, published_at)
      when is_integer(id) and is_struct(published_at, DateTime),
      do: EctoSigningKeyStore.publish_signing_key(repo(), id, published_at)

  @impl KeyStore
  def activate_signing_key(id, activated_at)
      when is_integer(id) and is_struct(activated_at, DateTime),
      do: EctoSigningKeyStore.activate_signing_key(repo(), id, activated_at)

  @impl KeyStore
  def retire_signing_key(id, retired_at)
      when is_integer(id) and is_struct(retired_at, DateTime),
      do: EctoSigningKeyStore.retire_signing_key(repo(), id, retired_at)

  @impl TokenStore
  def redeem_authorization_code(token_hash, redeemed_at, %Token{} = access_token)
      when is_binary(token_hash) and is_struct(redeemed_at, DateTime) do
    EctoTokenStore.redeem_authorization_code(repo(), token_hash, redeemed_at, access_token)
  end

  @impl false
  def rotate_refresh_token(
        token_hash,
        client_id,
        rotated_at,
        %Token{} = refresh_token,
        %Token{} = access_token
      )
      when is_binary(token_hash) and is_binary(client_id) and is_struct(rotated_at, DateTime) do
    EctoTokenStore.rotate_refresh_token(
      repo(),
      token_hash,
      client_id,
      rotated_at,
      refresh_token,
      access_token
    )
  end

  @impl TokenStore
  def rotate_refresh_token(
        token_hash,
        client_id,
        rotated_at,
        %Token{} = refresh_token,
        %Token{} = access_token,
        expected_cnf
      )
      when is_binary(token_hash) and is_binary(client_id) and is_struct(rotated_at, DateTime) do
    EctoTokenStore.rotate_refresh_token(
      repo(),
      token_hash,
      client_id,
      rotated_at,
      refresh_token,
      access_token,
      expected_cnf
    )
  end

  @doc """
  Deletes expired records in chunks of 1000 to prevent table locking.
  """
  @spec prune_expired_records(module(), DateTime.t(), non_neg_integer()) :: non_neg_integer()
  def prune_expired_records(schema, now \\ DateTime.utc_now(), count \\ 0),
    do: EctoPruningStore.prune_expired_records(repo(), schema, now, count)

  defp repo, do: Config.repo!()
end
