defmodule Lockspire.Storage.Ecto.Repository do
  @moduledoc """
  Default Ecto-backed implementation for Lockspire's domain storage contracts.
  """

  import Ecto.Query

  alias Lockspire.Audit.Event
  alias Lockspire.Config
  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Domain.DpopReplay
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.LogoutDelivery
  alias Lockspire.Domain.LogoutEvent
  alias Lockspire.Domain.PushedAuthorizationRequest
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.Domain.UsedJti
  alias Lockspire.Security.Policy
  alias Lockspire.Protocol.SecurityProfile
  alias Lockspire.Storage.CibaAuthorizationStore
  alias Lockspire.Storage.ClientStore
  alias Lockspire.Storage.ConsentStore
  alias Lockspire.Storage.DeviceAuthorizationStore
  alias Lockspire.Storage.DpopReplayStore
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.DpopReplayRecord
  alias Lockspire.Storage.Ecto.InitialAccessTokenRecord
  alias Lockspire.Storage.Ecto.LogoutDeliveryRecord
  alias Lockspire.Storage.Ecto.LogoutEventRecord
  alias Lockspire.Storage.Ecto.SigningKeyRecord
  alias Lockspire.Storage.Ecto.TokenRecord
  alias Lockspire.Storage.Ecto.UsedJtiRecord
  alias Lockspire.Storage.Ecto.Repository.AuditStore, as: EctoAuditStore
  alias Lockspire.Storage.Ecto.Repository.ClientStore, as: EctoClientStore
  alias Lockspire.Storage.Ecto.Repository.ConsentStore, as: EctoConsentStore
  alias Lockspire.Storage.Ecto.Repository.CibaAuthorizationStore, as: EctoCibaAuthorizationStore

  alias Lockspire.Storage.Ecto.Repository.DeviceAuthorizationStore,
    as: EctoDeviceAuthorizationStore

  alias Lockspire.Storage.Ecto.Repository.InteractionStore, as: EctoInteractionStore

  alias Lockspire.Storage.Ecto.Repository.PushedAuthorizationRequestStore,
    as: EctoPushedAuthorizationRequestStore

  alias Lockspire.Storage.Ecto.Repository.ServerPolicyStore, as: EctoServerPolicyStore
  alias Lockspire.Storage.Ecto.Repository.Support
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
    transact(fn ->
      prune_expired_dpop_replay_records(replay.seen_at)

      changeset = DpopReplayRecord.changeset(%DpopReplayRecord{}, replay)

      if changeset.valid? do
        case insert_dpop_replay_record(replay) do
          1 ->
            :accepted

          0 ->
            :replay

          _other ->
            repo().rollback(:dpop_replay_insert_failed)
        end
      else
        repo().rollback(changeset)
      end
    end)
  end

  defp insert_dpop_replay_record(%DpopReplay{} = replay) do
    now = DateTime.utc_now()
    seen_at = DateTime.truncate(replay.seen_at, :microsecond)
    expires_at = DateTime.truncate(replay.expires_at, :microsecond)

    {count, _rows} =
      repo_insert_all(
        DpopReplayRecord,
        [
          %{
            replay_key: replay.replay_key,
            jti: replay.jti,
            htm: replay.htm,
            htu: replay.htu,
            jkt: replay.jkt,
            seen_at: seen_at,
            expires_at: expires_at,
            inserted_at: now,
            updated_at: now
          }
        ],
        on_conflict: :nothing,
        conflict_target: [:replay_key],
        log: false
      )

    count
  end

  @impl UsedJtiStore
  def record_used_jti(%UsedJti{} = used_jti) do
    now = DateTime.utc_now()
    expires_at = DateTime.truncate(used_jti.expires_at, :microsecond)

    changeset =
      UsedJtiRecord.changeset(%UsedJtiRecord{}, %{
        client_id: used_jti.client_id,
        jti: used_jti.jti,
        expires_at: expires_at
      })

    if changeset.valid? do
      {count, _rows} =
        repo_insert_all(
          UsedJtiRecord,
          [
            %{
              client_id: used_jti.client_id,
              jti: used_jti.jti,
              expires_at: expires_at,
              inserted_at: now,
              updated_at: now
            }
          ],
          on_conflict: :nothing,
          conflict_target: [:client_id, :jti],
          log: false
        )

      case count do
        1 -> {:ok, :accepted}
        0 -> {:ok, :replay}
      end
    else
      {:error, changeset}
    end
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
    %TokenRecord{}
    |> TokenRecord.changeset(token)
    |> repo_insert(sensitive: true)
    |> map_one(&TokenRecord.to_domain/1)
  end

  @impl TokenStore
  def list_lifecycle_tokens(opts \\ []) when is_list(opts) do
    now = DateTime.utc_now()

    TokenRecord
    |> where([token], token.token_type in [:access_token, :refresh_token])
    |> maybe_filter_token_account(Keyword.get(opts, :account_id))
    |> maybe_filter_token_client(Keyword.get(opts, :client_id))
    |> maybe_filter_token_status(Keyword.get(opts, :status), now)
    |> order_by([token], desc: token.issued_at, desc: token.id)
    |> maybe_limit_tokens(Keyword.get(opts, :limit))
    |> repo_all()
    |> then(fn records -> {:ok, Enum.map(records, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def fetch_lifecycle_token_by_id(token_id) when is_integer(token_id) do
    TokenRecord
    |> where([token], token.id == ^token_id)
    |> where([token], token.token_type in [:access_token, :refresh_token])
    |> repo_one()
    |> then(fn record -> {:ok, maybe_map(record, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def list_token_family(family_id) when is_binary(family_id) do
    TokenRecord
    |> where([token], token.family_id == ^family_id)
    |> where([token], token.token_type in [:access_token, :refresh_token])
    |> order_by([token], asc: token.generation, asc: token.issued_at, asc: token.id)
    |> repo_all(sensitive: true)
    |> then(fn records -> {:ok, Enum.map(records, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def revoke_token_family(family_id) when is_binary(family_id) do
    {count, _records} =
      TokenRecord
      |> where([token], token.family_id == ^family_id)
      |> where([token], is_nil(token.revoked_at))
      |> repo_update_all(
        [set: [revoked_at: DateTime.utc_now(), updated_at: DateTime.utc_now()]],
        sensitive: true
      )

    {:ok, count}
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def revoke_by_sid(nil), do: {:ok, 0}

  def revoke_by_sid(sid) when is_binary(sid) do
    {count, _records} =
      TokenRecord
      |> where([token], token.sid == ^sid)
      |> where([token], is_nil(token.revoked_at))
      |> where([token], is_nil(token.redeemed_at))
      |> repo_update_all(
        [set: [revoked_at: DateTime.utc_now(), updated_at: DateTime.utc_now()]],
        sensitive: true
      )

    {:ok, count}
  rescue
    error -> {:error, error}
  end

  @impl LogoutStore
  def persist_logout_propagation(%LogoutEvent{} = event, opts \\ []) do
    if Keyword.get(opts, :transact?, true) do
      transact(fn -> persist_logout_propagation!(event) end)
    else
      {:ok, persist_logout_propagation!(event)}
    end
  rescue
    error -> {:error, error}
  end

  @impl LogoutStore
  def fetch_logout_event_by_event_id(event_id) when is_binary(event_id) do
    LogoutEventRecord
    |> where([event], event.event_id == ^event_id)
    |> repo_one()
    |> then(fn record -> {:ok, maybe_map(record, &LogoutEventRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl LogoutStore
  def list_all_logout_deliveries do
    LogoutDeliveryRecord
    |> order_by(desc: :inserted_at)
    |> repo_all()
    |> then(fn records -> {:ok, Enum.map(records, &LogoutDeliveryRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl LogoutStore
  def list_logout_deliveries(logout_event_id) when is_integer(logout_event_id) do
    LogoutDeliveryRecord
    |> where([delivery], delivery.logout_event_id == ^logout_event_id)
    |> order_by([delivery], asc: delivery.id)
    |> repo_all()
    |> then(fn records -> {:ok, Enum.map(records, &LogoutDeliveryRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl LogoutStore
  def mark_logout_delivery_enqueued(logout_delivery_id, oban_job_id)
      when is_integer(logout_delivery_id) and is_integer(oban_job_id) do
    LogoutDeliveryRecord
    |> where([delivery], delivery.id == ^logout_delivery_id)
    |> lock("FOR UPDATE")
    |> repo_one()
    |> case do
      nil ->
        {:error, :not_found}

      %LogoutDeliveryRecord{} = record ->
        record
        |> Ecto.Changeset.change(
          status: :enqueued,
          oban_job_id: oban_job_id,
          updated_at: DateTime.utc_now()
        )
        |> repo_update()
        |> map_one(&LogoutDeliveryRecord.to_domain/1)
    end
  end

  @impl TokenStore
  def fetch_authorization_code(token_hash) when is_binary(token_hash) do
    TokenRecord
    |> where([token], token.token_hash == ^token_hash)
    |> where([token], token.token_type == :authorization_code)
    |> repo_one(sensitive: true)
    |> then(fn record -> {:ok, maybe_map(record, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def fetch_lifecycle_token(token_hash) when is_binary(token_hash) do
    TokenRecord
    |> where([token], token.token_hash == ^token_hash)
    |> where([token], token.token_type in [:access_token, :refresh_token])
    |> repo_one(sensitive: true)
    |> then(fn record -> {:ok, maybe_map(record, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def fetch_refresh_token(token_hash) when is_binary(token_hash) do
    TokenRecord
    |> where([token], token.token_hash == ^token_hash)
    |> where([token], token.token_type == :refresh_token)
    |> repo_one(sensitive: true)
    |> then(fn record -> {:ok, maybe_map(record, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def fetch_active_authorization_code(token_hash) when is_binary(token_hash) do
    now = DateTime.utc_now()

    TokenRecord
    |> where([token], token.token_hash == ^token_hash)
    |> where([token], token.token_type == :authorization_code)
    |> where([token], is_nil(token.redeemed_at) and is_nil(token.revoked_at))
    |> where([token], token.expires_at > ^now)
    |> repo_one(sensitive: true)
    |> then(fn record -> {:ok, maybe_map(record, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def fetch_active_access_token(token_hash) when is_binary(token_hash) do
    now = DateTime.utc_now()

    TokenRecord
    |> where([token], token.token_hash == ^token_hash)
    |> where([token], token.token_type == :access_token)
    |> where([token], is_nil(token.revoked_at))
    |> where([token], token.expires_at > ^now)
    |> repo_one(sensitive: true)
    |> then(fn record -> {:ok, maybe_map(record, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def revoke_lifecycle_token(token_hash, client_id, revoked_at)
      when is_binary(token_hash) and is_binary(client_id) and is_struct(revoked_at, DateTime) do
    transact(fn ->
      TokenRecord
      |> where([token], token.token_hash == ^token_hash)
      |> where([token], token.token_type in [:access_token, :refresh_token])
      |> lock("FOR UPDATE")
      |> repo_one(sensitive: true)
      |> revoke_lifecycle_token_record(client_id, revoked_at)
    end)
  end

  @impl TokenStore
  def mark_authorization_code_redeemed(token_hash, redeemed_at)
      when is_binary(token_hash) and is_struct(redeemed_at, DateTime) do
    transact(fn ->
      TokenRecord
      |> where([token], token.token_hash == ^token_hash)
      |> where([token], token.token_type == :authorization_code)
      |> lock("FOR UPDATE")
      |> repo_one(sensitive: true)
      |> case do
        nil ->
          repo().rollback(:not_found)

        %TokenRecord{redeemed_at: %DateTime{}} ->
          repo().rollback(:already_redeemed)

        %TokenRecord{} = record ->
          record
          |> Ecto.Changeset.change(redeemed_at: redeemed_at, updated_at: DateTime.utc_now())
          |> repo_update(sensitive: true)
          |> map_one(&TokenRecord.to_domain/1)
          |> unwrap_or_rollback()
      end
    end)
  end

  @impl InitialAccessTokenStore
  def redeem_initial_access_token(token_hash, redeemed_at)
      when is_binary(token_hash) and is_struct(redeemed_at, DateTime) do
    transact(fn ->
      InitialAccessTokenRecord
      |> where([iat], iat.token_hash == ^token_hash)
      |> lock("FOR UPDATE")
      |> repo_one(sensitive: true)
      |> case do
        nil ->
          repo().rollback(:not_found)

        record ->
          cond do
            record.revoked_at != nil ->
              repo().rollback(:revoked)

            record.expires_at != nil and DateTime.compare(record.expires_at, redeemed_at) != :gt ->
              repo().rollback(:expired)

            record.used_at != nil ->
              repo().rollback(:already_used)

            true ->
              record
              |> Ecto.Changeset.change(used_at: redeemed_at, updated_at: DateTime.utc_now())
              |> repo_update(sensitive: true)
              |> map_one(&InitialAccessTokenRecord.to_domain/1)
              |> unwrap_or_rollback()
          end
      end
    end)
  end

  @impl InitialAccessTokenStore
  def list_initial_access_tokens(_opts \\ []) do
    InitialAccessTokenRecord
    |> order_by([iat], desc: iat.inserted_at)
    |> repo_all()
    |> Enum.map(&InitialAccessTokenRecord.to_domain/1)
    |> then(&{:ok, &1})
  end

  @impl InitialAccessTokenStore
  def save_initial_access_token(%Lockspire.Domain.InitialAccessToken{} = iat) do
    %InitialAccessTokenRecord{}
    |> InitialAccessTokenRecord.changeset(iat)
    |> repo_insert()
    |> map_one(&InitialAccessTokenRecord.to_domain/1)
  end

  @impl InitialAccessTokenStore
  def revoke_initial_access_token(id, revoked_at)
      when is_integer(id) and is_struct(revoked_at, DateTime) do
    InitialAccessTokenRecord
    |> where([iat], iat.id == ^id)
    |> repo_update_all(set: [revoked_at: revoked_at, updated_at: DateTime.utc_now()])
    |> case do
      {1, _} -> :ok
      {0, _} -> {:error, :not_found}
    end
  end

  @impl KeyStore
  def publish_key(%SigningKey{} = key) do
    %SigningKeyRecord{}
    |> SigningKeyRecord.changeset(key)
    |> repo_insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:kid]
    )
    |> map_one(&SigningKeyRecord.to_domain/1)
  end

  @impl KeyStore
  def list_active_keys do
    SigningKeyRecord
    |> where([key], key.status in [:active, :retiring])
    |> order_by([key], asc: key.inserted_at)
    |> repo_all()
    |> then(fn records ->
      {:ok, Enum.map(records, &(SigningKeyRecord.to_domain(&1) |> strip_private_key_material()))}
    end)
  rescue
    error -> {:error, error}
  end

  @impl KeyStore
  def list_signing_keys(opts \\ []) when is_list(opts) do
    SigningKeyRecord
    |> maybe_filter_signing_key_status(Keyword.get(opts, :status))
    |> order_by([key], desc: key.inserted_at, desc: key.id)
    |> repo_all()
    |> then(fn records -> {:ok, Enum.map(records, &SigningKeyRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl KeyStore
  def list_publishable_keys(opts \\ []) when is_list(opts) do
    SigningKeyRecord
    |> where(
      [key],
      key.status in [:active, :retiring] or
        (key.status == :upcoming and not is_nil(key.published_at))
    )
    |> order_by([key], asc: key.inserted_at)
    |> repo_all()
    |> then(fn records ->
      records
      |> Enum.map(&(SigningKeyRecord.to_domain(&1) |> strip_private_key_material()))
      |> filter_keys_for_security_profile(Keyword.get(opts, :security_profile, :none))
      |> then(&{:ok, &1})
    end)
  rescue
    error -> {:error, error}
  end

  @impl KeyStore
  def list_decryption_keys do
    SigningKeyRecord
    |> where([key], key.use == :enc)
    |> where([key], key.status in [:active, :retiring])
    |> order_by([key], asc: key.inserted_at)
    |> repo_all()
    |> then(fn records ->
      {:ok, Enum.map(records, &SigningKeyRecord.to_domain/1)}
    end)
  rescue
    error -> {:error, error}
  end

  @spec validate_fapi_signing_readiness() ::
          :ok
          | {:error, :missing_compliant_active_key | :missing_compliant_publishable_key | term()}
  def validate_fapi_signing_readiness do
    validate_message_signing_readiness()
  end

  @spec validate_message_signing_readiness() ::
          :ok
          | {:error, :missing_compliant_active_key | :missing_compliant_publishable_key | term()}
  def validate_message_signing_readiness do
    with {:publishable, {:ok, [_ | _]}} <-
           {:publishable, list_publishable_keys(security_profile: :fapi_2_0_security)},
         {:active, {:ok, %SigningKey{}}} <-
           {:active, fetch_active_signing_key(security_profile: :fapi_2_0_security)} do
      :ok
    else
      {:publishable, {:ok, []}} -> {:error, :missing_compliant_publishable_key}
      {:active, {:ok, nil}} -> {:error, :missing_compliant_active_key}
      {_, {:error, reason}} -> {:error, reason}
    end
  end

  @impl KeyStore
  def fetch_active_signing_key(opts \\ []) when is_list(opts) do
    SigningKeyRecord
    |> where([key], key.status == :active)
    |> where([key], key.use == :sig)
    |> order_by([key], asc: key.inserted_at)
    |> repo_all()
    |> Enum.map(&SigningKeyRecord.to_domain/1)
    |> filter_keys_for_security_profile(Keyword.get(opts, :security_profile, :none))
    |> filter_keys_for_alg(Keyword.get(opts, :alg))
    |> List.first()
    |> then(&{:ok, &1})
  rescue
    error -> {:error, error}
  end

  defp filter_keys_for_alg(keys, nil), do: keys

  defp filter_keys_for_alg(keys, alg) when is_binary(alg) do
    Enum.filter(keys, &(&1.alg == alg))
  end

  defp filter_keys_for_security_profile(keys, :fapi_2_0_security) do
    allowed_algs = SecurityProfile.allowed_signing_algorithms(:fapi_2_0_security)

    Enum.filter(keys, fn %SigningKey{alg: alg, use: use} = key ->
      use == :sig and alg in allowed_algs and
        Policy.validate_key_compliance(key, :fapi_2_0_security) == :ok
    end)
  end

  defp filter_keys_for_security_profile(keys, _profile), do: keys

  @impl KeyStore
  def fetch_signing_key_by_id(id) when is_integer(id) do
    SigningKeyRecord
    |> where([key], key.id == ^id)
    |> repo_one()
    |> then(fn record -> {:ok, maybe_map(record, &SigningKeyRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl KeyStore
  def publish_signing_key(id, published_at)
      when is_integer(id) and is_struct(published_at, DateTime) do
    transact(fn ->
      id
      |> locked_signing_key_query()
      |> repo_one()
      |> case do
        nil ->
          repo().rollback(:not_found)

        %SigningKeyRecord{status: :upcoming, published_at: nil} = record ->
          record
          |> SigningKeyRecord.update_changeset(%{published_at: published_at})
          |> repo_update()
          |> map_one(&SigningKeyRecord.to_domain/1)
          |> unwrap_or_rollback()

        %SigningKeyRecord{status: :upcoming} ->
          repo().rollback(:already_published)

        %SigningKeyRecord{} ->
          repo().rollback(:invalid_state)
      end
    end)
  end

  @impl KeyStore
  def activate_signing_key(id, activated_at)
      when is_integer(id) and is_struct(activated_at, DateTime) do
    transact(fn ->
      id
      |> locked_signing_key_query()
      |> repo_one()
      |> activate_signing_key_record(activated_at)
    end)
  end

  @impl KeyStore
  def retire_signing_key(id, retired_at)
      when is_integer(id) and is_struct(retired_at, DateTime) do
    transact(fn ->
      id
      |> locked_signing_key_query()
      |> repo_one()
      |> case do
        nil ->
          repo().rollback(:not_found)

        %SigningKeyRecord{status: :retiring} = record ->
          record
          |> SigningKeyRecord.update_changeset(%{
            status: :retired,
            retired_at: retired_at
          })
          |> repo_update()
          |> map_one(&SigningKeyRecord.to_domain/1)
          |> unwrap_or_rollback()

        %SigningKeyRecord{status: :retired} ->
          repo().rollback(:already_retired)

        %SigningKeyRecord{} ->
          repo().rollback(:invalid_state)
      end
    end)
  end

  @impl TokenStore
  def redeem_authorization_code(token_hash, redeemed_at, %Token{} = access_token)
      when is_binary(token_hash) and is_struct(redeemed_at, DateTime) do
    transact(fn ->
      TokenRecord
      |> where([token], token.token_hash == ^token_hash)
      |> where([token], token.token_type == :authorization_code)
      |> lock("FOR UPDATE")
      |> repo_one(sensitive: true)
      |> redeem_authorization_code_record(redeemed_at, access_token)
    end)
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
    rotate_refresh_token(token_hash, client_id, rotated_at, refresh_token, access_token, nil)
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
    case repo().transaction(fn ->
           run_rotate_refresh_token(
             token_hash,
             client_id,
             rotated_at,
             refresh_token,
             access_token,
             expected_cnf
           )
         end) do
      {:ok, {:ok, result}} -> {:ok, result}
      {:ok, {:error, reason}} -> {:error, reason}
      {:error, reason} -> {:error, reason}
    end
  rescue
    error -> {:error, error}
  end

  defp repo do
    Config.repo!()
  end

  defp map_one({:ok, record}, mapper), do: {:ok, mapper.(record)}
  defp map_one({:error, error}, _mapper), do: {:error, error}

  defp maybe_map(nil, _mapper), do: nil
  defp maybe_map(record, mapper), do: mapper.(record)

  defp maybe_filter_token_account(query, nil), do: query
  defp maybe_filter_token_account(query, ""), do: query

  defp maybe_filter_token_account(query, account_id) when is_binary(account_id) do
    where(query, [token], token.account_id == ^account_id)
  end

  defp maybe_filter_token_client(query, nil), do: query
  defp maybe_filter_token_client(query, ""), do: query

  defp maybe_filter_token_client(query, client_id) when is_binary(client_id) do
    where(query, [token], token.client_id == ^client_id)
  end

  defp maybe_filter_token_status(query, nil, _now), do: query

  defp maybe_filter_token_status(query, :active, now) do
    where(query, [token], is_nil(token.revoked_at) and token.expires_at > ^now)
  end

  defp maybe_filter_token_status(query, :revoked, _now) do
    where(query, [token], not is_nil(token.revoked_at))
  end

  defp maybe_filter_token_status(query, :expired, now) do
    where(query, [token], is_nil(token.revoked_at) and token.expires_at <= ^now)
  end

  defp maybe_filter_token_status(query, :reuse_detected, _now) do
    where(query, [token], not is_nil(token.reuse_detected_at))
  end

  defp maybe_filter_token_status(query, _status, _now), do: query

  defp maybe_filter_signing_key_status(query, nil), do: query

  defp maybe_filter_signing_key_status(query, status)
       when status in [:upcoming, :active, :retiring, :retired] do
    where(query, [key], key.status == ^status)
  end

  defp maybe_filter_signing_key_status(query, _status), do: query

  defp maybe_limit_tokens(query, nil), do: query

  defp maybe_limit_tokens(query, limit) when is_integer(limit) and limit > 0,
    do: limit(query, ^limit)

  defp maybe_limit_tokens(query, _limit), do: query

  defp locked_refresh_token_query(token_hash) do
    TokenRecord
    |> where([token], token.token_hash == ^token_hash)
    |> where([token], token.token_type == :refresh_token)
    |> lock("FOR UPDATE")
  end

  defp locked_signing_key_query(id) do
    SigningKeyRecord
    |> where([key], key.id == ^id)
    |> lock("FOR UPDATE")
  end

  defp unwrap_or_rollback({:ok, result}), do: result
  defp unwrap_or_rollback({:error, reason}), do: repo().rollback(reason)

  @doc """
  Deletes expired records in chunks of 1000 to prevent table locking.
  """
  @spec prune_expired_records(module(), DateTime.t(), non_neg_integer()) :: non_neg_integer()
  def prune_expired_records(schema, now \\ DateTime.utc_now(), count \\ 0) do
    ids =
      schema
      |> where([r], r.expires_at < ^now)
      |> select([r], r.id)
      |> limit(1000)
      |> repo_all(log: false)

    if ids == [] do
      count
    else
      {deleted, _} =
        schema
        |> where([r], r.id in ^ids)
        |> repo_delete_all(log: false)

      prune_expired_records(schema, now, count + deleted)
    end
  end

  defp prune_expired_dpop_replay_records(%DateTime{} = seen_at) do
    DpopReplayRecord
    |> where([replay], replay.expires_at <= ^seen_at)
    |> repo_delete_all(log: false)

    :ok
  end

  defp redeem_code_record(%TokenRecord{} = record, redeemed_at) do
    record
    |> Ecto.Changeset.change(redeemed_at: redeemed_at, updated_at: DateTime.utc_now())
    |> repo_update(sensitive: true)
    |> map_one(&TokenRecord.to_domain/1)
  end

  defp rotate_refresh_token_record(
         %TokenRecord{} = record,
         client_id,
         rotated_at,
         %Token{} = refresh_token,
         %Token{} = access_token,
         expected_cnf
       ) do
    now = DateTime.utc_now()

    cond do
      record.client_id != client_id ->
        {:error, :client_mismatch}

      is_nil(record.family_id) ->
        {:error, :missing_family_id}

      DateTime.compare(record.expires_at, rotated_at) != :gt ->
        {:error, :expired}

      not is_nil(record.redeemed_at) or not is_nil(record.revoked_at) ->
        with {:ok, _presented} <- mark_refresh_token_reuse(record, rotated_at, now),
             {:ok, _count} <- revoke_token_family_records(record.family_id, rotated_at, now) do
          {:error, :reuse_detected}
        else
          {:error, reason} -> repo().rollback(reason)
        end

      record.cnf != expected_cnf ->
        {:error, :dpop_binding_mismatch}

      true ->
        with {:ok, presented_refresh_token} <- revoke_presented_refresh_token(record, rotated_at),
             {:ok, stored_refresh_token} <-
               store_rotated_refresh_token(record, refresh_token, rotated_at, expected_cnf),
             {:ok, stored_access_token} <-
               store_rotated_access_token(
                 record,
                 stored_refresh_token,
                 access_token,
                 rotated_at,
                 expected_cnf
               ) do
          {:ok,
           %{
             presented_refresh_token: presented_refresh_token,
             refresh_token: stored_refresh_token,
             access_token: stored_access_token
           }}
        else
          {:error, reason} -> repo().rollback(reason)
        end
    end
  end

  defp revoke_lifecycle_token_record(nil, _client_id, _revoked_at), do: nil

  defp revoke_lifecycle_token_record(
         %TokenRecord{client_id: client_id} = record,
         client_id,
         revoked_at
       ) do
    if is_nil(record.revoked_at) do
      record
      |> Ecto.Changeset.change(revoked_at: revoked_at, updated_at: DateTime.utc_now())
      |> repo_update(sensitive: true)
      |> map_one(&TokenRecord.to_domain/1)
      |> unwrap_or_rollback()
    else
      TokenRecord.to_domain(record)
    end
  end

  defp revoke_lifecycle_token_record(%TokenRecord{}, _client_id, _revoked_at), do: nil

  defp activate_signing_key_record(nil, _activated_at), do: repo().rollback(:not_found)

  defp activate_signing_key_record(%SigningKeyRecord{status: status}, _activated_at)
       when status != :upcoming,
       do: repo().rollback(:invalid_state)

  defp activate_signing_key_record(%SigningKeyRecord{published_at: nil}, _activated_at),
    do: repo().rollback(:not_published)

  defp activate_signing_key_record(%SigningKeyRecord{} = selected_record, activated_at) do
    case fetch_active_signing_key_records(selected_record.use) do
      [] ->
        %{
          activated_key: activate_selected_signing_key(selected_record, activated_at),
          retiring_key: nil
        }

      [%SigningKeyRecord{} = active_record] ->
        %{
          activated_key: activate_selected_signing_key(selected_record, activated_at),
          retiring_key: retire_active_signing_key(active_record, activated_at)
        }

      _multiple ->
        repo().rollback(:multiple_active_keys)
    end
  end

  defp fetch_active_signing_key_records(use) do
    SigningKeyRecord
    |> where([key], key.status == :active)
    |> where([key], key.use == ^use)
    |> lock("FOR UPDATE")
    |> repo_all()
  end

  defp activate_selected_signing_key(%SigningKeyRecord{} = record, activated_at) do
    record
    |> SigningKeyRecord.update_changeset(%{
      status: :active,
      activated_at: activated_at,
      retiring_at: nil,
      retired_at: nil
    })
    |> repo_update()
    |> map_one(&SigningKeyRecord.to_domain/1)
    |> unwrap_or_rollback()
  end

  defp retire_active_signing_key(%SigningKeyRecord{} = record, activated_at) do
    record
    |> SigningKeyRecord.update_changeset(%{
      status: :retiring,
      retiring_at: activated_at,
      retired_at: nil
    })
    |> repo_update()
    |> map_one(&SigningKeyRecord.to_domain/1)
    |> unwrap_or_rollback()
  end

  defp redeem_authorization_code_record(nil, _redeemed_at, _access_token),
    do: repo().rollback(:not_found)

  defp redeem_authorization_code_record(
         %TokenRecord{redeemed_at: %DateTime{}},
         _redeemed_at,
         _access_token
       ),
       do: repo().rollback(:already_redeemed)

  defp redeem_authorization_code_record(
         %TokenRecord{} = record,
         redeemed_at,
         %Token{} = access_token
       ) do
    with {:ok, redeemed_code} <- redeem_code_record(record, redeemed_at),
         {:ok, stored_access_token} <- store_token_record(access_token) do
      %{authorization_code: redeemed_code, access_token: stored_access_token}
    else
      {:error, reason} -> repo().rollback(reason)
    end
  end

  defp run_rotate_refresh_token(
         token_hash,
         client_id,
         rotated_at,
         refresh_token,
         access_token,
         expected_cnf
       ) do
    case token_hash |> locked_refresh_token_query() |> repo_one(sensitive: true) do
      nil ->
        {:error, :not_found}

      %TokenRecord{} = record ->
        rotate_refresh_token_record(
          record,
          client_id,
          rotated_at,
          refresh_token,
          access_token,
          expected_cnf
        )
    end
  end

  defp revoke_presented_refresh_token(%TokenRecord{} = record, rotated_at) do
    record
    |> Ecto.Changeset.change(
      redeemed_at: rotated_at,
      revoked_at: rotated_at,
      updated_at: DateTime.utc_now()
    )
    |> repo_update(sensitive: true)
    |> map_one(&TokenRecord.to_domain/1)
  end

  defp mark_refresh_token_reuse(%TokenRecord{} = record, detected_at, updated_at) do
    record
    |> Ecto.Changeset.change(
      reuse_detected_at: record.reuse_detected_at || detected_at,
      updated_at: updated_at
    )
    |> repo_update(sensitive: true)
    |> map_one(&TokenRecord.to_domain/1)
  end

  defp revoke_token_family_records(family_id, revoked_at, updated_at) do
    {count, _records} =
      TokenRecord
      |> where([token], token.family_id == ^family_id)
      |> repo_update_all(
        [set: [revoked_at: revoked_at, updated_at: updated_at]],
        [sensitive: true],
        inc: []
      )

    {:ok, count}
  rescue
    error -> {:error, error}
  end

  defp store_rotated_refresh_token(
         %TokenRecord{} = record,
         %Token{} = refresh_token,
         rotated_at,
         expected_cnf
       ) do
    %Token{
      refresh_token
      | family_id: record.family_id,
        generation: record.generation + 1,
        parent_token_id: record.id,
        client_id: record.client_id,
        account_id: refresh_token.account_id || record.account_id,
        interaction_id: refresh_token.interaction_id || record.interaction_id,
        scopes: if(refresh_token.scopes == [], do: record.scopes, else: refresh_token.scopes),
        audience:
          if(refresh_token.audience == [], do: record.audience, else: refresh_token.audience),
        cnf: expected_cnf,
        issued_at: refresh_token.issued_at || rotated_at
    }
    |> store_token_record()
  end

  defp store_rotated_access_token(
         %TokenRecord{} = record,
         %Token{} = stored_refresh_token,
         %Token{} = access_token,
         rotated_at,
         expected_cnf
       ) do
    %Token{
      access_token
      | family_id: record.family_id,
        generation: stored_refresh_token.generation,
        parent_token_id: stored_refresh_token.id,
        client_id: record.client_id,
        account_id: access_token.account_id || record.account_id,
        interaction_id: access_token.interaction_id || record.interaction_id,
        scopes: if(access_token.scopes == [], do: record.scopes, else: access_token.scopes),
        audience:
          if(access_token.audience == [], do: record.audience, else: access_token.audience),
        cnf: expected_cnf,
        issued_at: access_token.issued_at || rotated_at
    }
    |> store_token_record()
  end

  defp store_token_record(%Token{} = token) do
    %TokenRecord{}
    |> TokenRecord.changeset(token)
    |> repo_insert(sensitive: true)
    |> map_one(&TokenRecord.to_domain/1)
  end

  defp store_logout_event_record(%LogoutEvent{} = event) do
    %LogoutEventRecord{}
    |> LogoutEventRecord.changeset(event)
    |> repo_insert()
    |> map_one(&LogoutEventRecord.to_domain/1)
  end

  defp store_logout_delivery_record(%LogoutDelivery{} = delivery) do
    %LogoutDeliveryRecord{}
    |> LogoutDeliveryRecord.changeset(delivery)
    |> repo_insert()
    |> map_one(&LogoutDeliveryRecord.to_domain/1)
  end

  defp persist_logout_propagation!(%LogoutEvent{} = event) do
    normalized_event = normalize_logout_event(event)

    case fetch_existing_logout_event(normalized_event.event_id) do
      %LogoutEventRecord{} = existing_event ->
        %{
          event: LogoutEventRecord.to_domain(existing_event),
          deliveries: list_logout_deliveries!(existing_event.id),
          inserted?: false
        }

      nil ->
        stored_event =
          normalized_event
          |> store_logout_event_record()
          |> unwrap_or_fetch_existing_logout_event(normalized_event.event_id)

        deliveries =
          normalized_event.sid
          |> snapshot_logout_clients()
          |> build_logout_deliveries(stored_event.id)
          |> Enum.map(fn delivery ->
            delivery
            |> store_logout_delivery_record()
            |> unwrap_or_rollback()
          end)

        %{event: stored_event, deliveries: deliveries, inserted?: true}
    end
  end

  defp fetch_existing_logout_event(event_id) when is_binary(event_id) do
    LogoutEventRecord
    |> where([event], event.event_id == ^event_id)
    |> lock("FOR UPDATE")
    |> repo_one()
  end

  defp list_logout_deliveries!(logout_event_id) do
    case list_logout_deliveries(logout_event_id) do
      {:ok, deliveries} -> deliveries
      {:error, reason} -> repo().rollback(reason)
    end
  end

  defp unwrap_or_fetch_existing_logout_event({:ok, event}, _event_id), do: event

  defp unwrap_or_fetch_existing_logout_event({:error, %Ecto.Changeset{} = changeset}, event_id) do
    if unique_constraint_error?(changeset, :event_id) do
      case fetch_existing_logout_event(event_id) do
        %LogoutEventRecord{} = event -> LogoutEventRecord.to_domain(event)
        nil -> repo().rollback(changeset)
      end
    else
      repo().rollback(changeset)
    end
  end

  defp unwrap_or_fetch_existing_logout_event({:error, reason}, _event_id),
    do: repo().rollback(reason)

  defp normalize_logout_event(%LogoutEvent{} = event) do
    %LogoutEvent{
      event
      | event_id: event.event_id || Ecto.UUID.generate(),
        completed_at: event.completed_at || DateTime.utc_now()
    }
  end

  defp snapshot_logout_clients(nil), do: []

  defp snapshot_logout_clients(sid) when is_binary(sid) do
    client_ids =
      TokenRecord
      |> where([token], token.sid == ^sid)
      |> where([token], token.token_type in [:access_token, :refresh_token])
      |> where([token], is_nil(token.revoked_at))
      |> select([token], token.client_id)
      |> distinct(true)
      |> repo_all(sensitive: true)

    ClientRecord
    |> where([client], client.client_id in ^client_ids)
    |> where(
      [client],
      not is_nil(client.backchannel_logout_uri) or not is_nil(client.frontchannel_logout_uri)
    )
    |> order_by([client], asc: client.client_id)
    |> repo_all()
  end

  defp build_logout_deliveries(client_records, logout_event_id) when is_list(client_records) do
    Enum.flat_map(client_records, fn client ->
      []
      |> maybe_append_logout_delivery(
        client.client_id,
        logout_event_id,
        :backchannel,
        client.backchannel_logout_uri,
        client.backchannel_logout_session_required
      )
      |> maybe_append_logout_delivery(
        client.client_id,
        logout_event_id,
        :frontchannel,
        client.frontchannel_logout_uri,
        client.frontchannel_logout_session_required
      )
    end)
  end

  defp maybe_append_logout_delivery(
         deliveries,
         _client_id,
         _logout_event_id,
         _channel,
         nil,
         _session_required
       ),
       do: deliveries

  defp maybe_append_logout_delivery(
         deliveries,
         client_id,
         logout_event_id,
         channel,
         target_uri,
         session_required
       )
       when is_binary(target_uri) do
    deliveries ++
      [
        %LogoutDelivery{
          delivery_id: Ecto.UUID.generate(),
          logout_event_id: logout_event_id,
          client_id: client_id,
          channel: channel,
          target_uri: target_uri,
          session_required: session_required
        }
      ]
  end

  defp unique_constraint_error?(%Ecto.Changeset{errors: errors}, field) when is_list(errors) do
    Enum.any?(errors, fn
      {^field, {_message, details}} -> details[:constraint] == :unique
      _other -> false
    end)
  end

  defp repo_all(query, opts \\ []) do
    Support.all(repo(), query, opts)
  end

  defp repo_one(query, opts \\ []) do
    Support.one(repo(), query, opts)
  end

  defp repo_insert(changeset, opts \\ []) do
    Support.insert(repo(), changeset, opts)
  end

  defp repo_insert_all(schema_or_source, entries, opts) do
    Support.insert_all(repo(), schema_or_source, entries, opts)
  end

  defp repo_update(changeset, opts \\ []) do
    Support.update(repo(), changeset, opts)
  end

  defp repo_update_all(query, updates, opts \\ [], keyword_opts \\ []) do
    Support.update_all(repo(), query, updates, opts, keyword_opts)
  end

  defp repo_delete_all(query, opts) do
    Support.delete_all(repo(), query, opts)
  end

  defp strip_private_key_material(%SigningKey{} = key) do
    %SigningKey{key | private_jwk_encrypted: nil}
  end
end
