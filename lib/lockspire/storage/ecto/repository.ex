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
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.CibaAuthorizationRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.ConsentGrantRecord
  alias Lockspire.Storage.Ecto.DeviceAuthorizationRecord
  alias Lockspire.Storage.Ecto.DpopReplayRecord
  alias Lockspire.Storage.Ecto.InitialAccessTokenRecord
  alias Lockspire.Storage.Ecto.InteractionRecord
  alias Lockspire.Storage.Ecto.LogoutDeliveryRecord
  alias Lockspire.Storage.Ecto.LogoutEventRecord
  alias Lockspire.Storage.Ecto.PushedAuthorizationRequestRecord
  alias Lockspire.Storage.Ecto.ServerPolicyRecord
  alias Lockspire.Storage.Ecto.SigningKeyRecord
  alias Lockspire.Storage.Ecto.TokenRecord
  alias Lockspire.Storage.Ecto.UsedJtiRecord
  alias Lockspire.Storage.InteractionStore
  alias Lockspire.Storage.KeyStore
  alias Lockspire.Storage.LogoutStore
  alias Lockspire.Storage.PushedAuthorizationRequestStore
  alias Lockspire.Storage.ServerPolicyStore
  alias Lockspire.Storage.TokenStore
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

  @active_interaction_statuses InteractionRecord.active_statuses()

  @impl ClientStore
  def register_client(%Client{} = client) do
    %ClientRecord{}
    |> ClientRecord.changeset(client)
    |> repo_insert()
    |> map_one(&ClientRecord.to_domain/1)
  end

  @impl ClientStore
  def list_clients(opts \\ []) when is_list(opts) do
    ClientRecord
    |> maybe_filter_client_search(Keyword.get(opts, :search))
    |> maybe_filter_client_status(Keyword.get(opts, :active))
    |> maybe_filter_client_provenance(Keyword.get(opts, :provenance))
    |> order_by([client], asc: client.name, asc: client.client_id)
    |> maybe_limit_clients(Keyword.get(opts, :limit))
    |> repo().all()
    |> then(fn records -> {:ok, Enum.map(records, &ClientRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl ClientStore
  def fetch_client_by_id(client_id) when is_binary(client_id) do
    ClientRecord
    |> where([client], client.client_id == ^client_id)
    |> repo_one()
    |> then(fn record -> {:ok, maybe_map(record, &ClientRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec get_client_by_registration_access_token_hash(String.t()) ::
          {:ok, Lockspire.Domain.Client.t() | nil} | {:error, term()}
  def get_client_by_registration_access_token_hash(rat_hash) when is_binary(rat_hash) do
    ClientRecord
    |> where([client], client.registration_access_token_hash == ^rat_hash)
    |> repo_one(sensitive: true)
    |> then(fn record -> {:ok, maybe_map(record, &ClientRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl ClientStore
  def update_client(%Client{id: id}, attrs) when is_integer(id) and is_map(attrs) do
    transact(fn ->
      ClientRecord
      |> where([client], client.id == ^id)
      |> lock("FOR UPDATE")
      |> repo().one()
      |> case do
        nil ->
          repo().rollback(:not_found)

        %ClientRecord{} = record ->
          record
          |> ClientRecord.update_changeset(Map.put(attrs, :updated_at, DateTime.utc_now()))
          |> repo().update()
          |> map_one(&ClientRecord.to_domain/1)
          |> unwrap_or_rollback()
      end
    end)
  end

  @impl ServerPolicyStore
  def get_server_policy do
    ServerPolicyRecord
    |> where([policy], policy.id == ^ServerPolicyRecord.singleton_id())
    |> repo_one()
    |> then(fn
      nil -> {:ok, %ServerPolicy{}}
      %ServerPolicyRecord{} = record -> {:ok, ServerPolicyRecord.to_domain(record)}
    end)
  rescue
    error -> {:error, error}
  end

  @impl ServerPolicyStore
  def put_server_policy(%ServerPolicy{} = policy) do
    update_server_policy(fn _current -> policy end)
  end

  @impl ServerPolicyStore
  def update_server_policy(mutator) when is_function(mutator, 1) do
    transact(fn ->
      singleton_id = ServerPolicyRecord.singleton_id()

      current_record =
        ServerPolicyRecord
        |> where([stored_policy], stored_policy.id == ^singleton_id)
        |> lock("FOR UPDATE")
        |> repo().one()

      current =
        case current_record do
          nil -> %ServerPolicy{id: singleton_id}
          %ServerPolicyRecord{} = record -> ServerPolicyRecord.to_domain(record)
        end

      %ServerPolicy{} = new_policy = mutator.(current)

      case current_record do
        nil ->
          %ServerPolicyRecord{}
          |> ServerPolicyRecord.changeset(%ServerPolicy{new_policy | id: singleton_id})
          |> repo_insert()
          |> map_one(&ServerPolicyRecord.to_domain/1)
          |> unwrap_or_rollback()

        %ServerPolicyRecord{} = record ->
          record
          |> ServerPolicyRecord.changeset(%ServerPolicy{new_policy | id: singleton_id})
          |> repo_update([])
          |> map_one(&ServerPolicyRecord.to_domain/1)
          |> unwrap_or_rollback()
      end
    end)
  end

  @impl ClientStore
  def rotate_client_secret(%Client{id: id}, secret_hash, rotated_at)
      when is_integer(id) and is_binary(secret_hash) and is_struct(rotated_at, DateTime) do
    update_client_record(
      id,
      %{
        client_secret_hash: secret_hash,
        last_secret_rotated_at: rotated_at,
        updated_at: DateTime.utc_now()
      },
      sensitive: true
    )
  end

  @impl ClientStore
  def set_client_active(%Client{id: id}, active, attrs)
      when is_integer(id) and is_boolean(active) and is_map(attrs) do
    lifecycle_attrs =
      attrs
      |> Map.take([:disabled_at, :disabled_by])
      |> Map.put(:active, active)
      |> Map.put(:updated_at, DateTime.utc_now())

    update_client_record(id, lifecycle_attrs)
  end

  @impl InteractionStore
  def put_interaction(%Interaction{} = interaction) do
    %InteractionRecord{}
    |> InteractionRecord.changeset(interaction)
    |> repo().insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:interaction_id]
    )
    |> map_one(&InteractionRecord.to_domain/1)
  end

  @impl InteractionStore
  def fetch_interaction(interaction_id) when is_binary(interaction_id) do
    InteractionRecord
    |> where([interaction], interaction.interaction_id == ^interaction_id)
    |> repo().one()
    |> then(fn record -> {:ok, maybe_map(record, &InteractionRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl InteractionStore
  def fetch_active_interaction(interaction_id) when is_binary(interaction_id) do
    now = DateTime.utc_now()

    InteractionRecord
    |> where([interaction], interaction.interaction_id == ^interaction_id)
    |> where([interaction], interaction.status in ^@active_interaction_statuses)
    |> where([interaction], interaction.expires_at > ^now)
    |> repo().one()
    |> then(fn record -> {:ok, maybe_map(record, &InteractionRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl InteractionStore
  def list_interactions(_opts \\ []) do
    InteractionRecord
    |> order_by(desc: :inserted_at)
    |> repo().all()
    |> then(fn records -> {:ok, Enum.map(records, &InteractionRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl InteractionStore
  def transition_interaction(interaction_id, expected_statuses, attrs)
      when is_binary(interaction_id) and is_list(expected_statuses) and is_map(attrs) do
    transact(fn ->
      interaction_id
      |> locked_interaction_query()
      |> repo().one()
      |> transition_interaction_record(expected_statuses, attrs)
    end)
  end

  @impl InteractionStore
  def transact(fun) when is_function(fun, 0) do
    case repo().transaction(fn -> run_transaction_fun(fun) end) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  rescue
    error -> {:error, error}
  end

  @impl PushedAuthorizationRequestStore
  def put_pushed_authorization_request(%PushedAuthorizationRequest{} = request) do
    %PushedAuthorizationRequestRecord{}
    |> PushedAuthorizationRequestRecord.changeset(request)
    |> repo().insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:request_uri_hash]
    )
    |> map_one(&PushedAuthorizationRequestRecord.to_domain(&1, request_uri: request.request_uri))
  end

  @impl PushedAuthorizationRequestStore
  def fetch_active_pushed_authorization_request(request_uri_hash)
      when is_binary(request_uri_hash) do
    now = DateTime.utc_now()

    PushedAuthorizationRequestRecord
    |> where([request], request.request_uri_hash == ^request_uri_hash)
    |> where([request], request.expires_at > ^now)
    |> repo_one(sensitive: true)
    |> then(fn record ->
      {:ok, maybe_map(record, &PushedAuthorizationRequestRecord.to_domain/1)}
    end)
  rescue
    error -> {:error, error}
  end

  @impl PushedAuthorizationRequestStore
  def consume_pushed_authorization_request(request_uri_hash, client_id)
      when is_binary(request_uri_hash) and is_binary(client_id) do
    transact(fn ->
      now = DateTime.utc_now()

      PushedAuthorizationRequestRecord
      |> where([request], request.request_uri_hash == ^request_uri_hash)
      |> lock("FOR UPDATE")
      |> repo_one(sensitive: true)
      |> consume_pushed_authorization_request_record(client_id, now)
    end)
    |> case do
      {:ok, %PushedAuthorizationRequest{} = request} -> {:ok, request}
      {:ok, nil} -> {:ok, nil}
      {:error, :not_found} -> {:ok, nil}
      {:error, :invalid_client_binding} -> {:ok, nil}
      {:error, reason} -> {:error, reason}
    end
  end

  def list_device_authorizations(opts \\ []) when is_list(opts) do
    DeviceAuthorizationRecord
    |> order_by([auth], desc: auth.inserted_at)
    |> repo().all()
    |> then(fn records -> {:ok, Enum.map(records, &DeviceAuthorizationRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl DeviceAuthorizationStore
  def put_device_authorization(%DeviceAuthorization{} = auth) do
    %DeviceAuthorizationRecord{}
    |> DeviceAuthorizationRecord.changeset(auth)
    |> repo_insert()
    |> map_one(&DeviceAuthorizationRecord.to_domain/1)
  end

  @impl DeviceAuthorizationStore
  def fetch_device_authorization_by_user_code_hash(user_code_hash)
      when is_binary(user_code_hash) do
    DeviceAuthorizationRecord
    |> where([authorization], authorization.user_code_hash == ^user_code_hash)
    |> repo_one(sensitive: true)
    |> then(fn record -> {:ok, maybe_map(record, &DeviceAuthorizationRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl DeviceAuthorizationStore
  def fetch_device_authorization_by_device_code_hash(device_code_hash)
      when is_binary(device_code_hash) do
    DeviceAuthorizationRecord
    |> where([authorization], authorization.device_code_hash == ^device_code_hash)
    |> repo_one(sensitive: true)
    |> then(fn record -> {:ok, maybe_map(record, &DeviceAuthorizationRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl DeviceAuthorizationStore
  def fetch_device_authorization_by_verification_handle(verification_handle)
      when is_binary(verification_handle) do
    DeviceAuthorizationRecord
    |> where([authorization], authorization.verification_handle == ^verification_handle)
    |> repo_one(sensitive: true)
    |> then(fn record -> {:ok, maybe_map(record, &DeviceAuthorizationRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl DeviceAuthorizationStore
  def record_device_poll(device_code_hash, client_id, now)
      when is_binary(device_code_hash) and is_binary(client_id) and is_struct(now, DateTime) do
    transact(fn ->
      device_code_hash
      |> locked_device_authorization_by_device_code_query()
      |> repo_one(sensitive: true)
      |> evaluate_device_poll(client_id, now)
    end)
  end

  @impl DeviceAuthorizationStore
  def consume_device_authorization(verification_handle, client_id, now)
      when is_binary(verification_handle) and is_binary(client_id) and is_struct(now, DateTime) do
    transact(fn ->
      verification_handle
      |> locked_device_authorization_query()
      |> repo().one()
      |> consume_device_authorization_record(client_id, now)
    end)
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
      repo().insert_all(
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
        repo().insert_all(
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
    transact(fn ->
      verification_handle
      |> locked_device_authorization_query()
      |> repo().one()
      |> transition_device_authorization_record(expected_statuses, attrs)
    end)
  end

  @impl CibaAuthorizationStore
  def put_ciba_authorization(%CibaAuthorization{} = auth) do
    %CibaAuthorizationRecord{}
    |> CibaAuthorizationRecord.changeset(auth)
    |> repo_insert()
    |> map_one(&CibaAuthorizationRecord.to_domain/1)
  end

  @impl CibaAuthorizationStore
  def fetch_ciba_authorization_by_auth_req_id_hash(auth_req_id_hash)
      when is_binary(auth_req_id_hash) do
    CibaAuthorizationRecord
    |> where([authorization], authorization.auth_req_id_hash == ^auth_req_id_hash)
    |> repo_one(sensitive: true)
    |> then(fn record -> {:ok, maybe_map(record, &CibaAuthorizationRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl CibaAuthorizationStore
  def record_ciba_poll(auth_req_id_hash, client_id, now)
      when is_binary(auth_req_id_hash) and is_binary(client_id) and is_struct(now, DateTime) do
    transact(fn ->
      auth_req_id_hash
      |> locked_ciba_authorization_query()
      |> repo_one(sensitive: true)
      |> evaluate_ciba_poll(client_id, now)
    end)
  end

  @impl CibaAuthorizationStore
  def transition_ciba_authorization(auth_req_id_hash, expected_statuses, attrs)
      when is_binary(auth_req_id_hash) and is_list(expected_statuses) and is_map(attrs) do
    transact(fn ->
      auth_req_id_hash
      |> locked_ciba_authorization_query()
      |> repo().one()
      |> transition_ciba_authorization_record(expected_statuses, attrs)
    end)
  end

  @spec append_audit_event(Event.t() | map()) :: {:ok, Event.t()} | {:error, term()}
  def append_audit_event(%Event{} = event) do
    %AuditEventRecord{}
    |> AuditEventRecord.changeset(event)
    |> repo_insert(sensitive: true)
    |> map_one(&AuditEventRecord.to_domain/1)
  end

  def append_audit_event(attrs) when is_map(attrs) do
    attrs
    |> Event.normalize()
    |> append_audit_event()
  rescue
    error -> {:error, error}
  end

  @spec transact_with_audit(Event.t() | map(), (-> term())) ::
          {:ok, term()} | {:error, term()}
  def transact_with_audit(audit_event, fun) when is_function(fun, 0) do
    transact(fn ->
      result =
        case fun.() do
          {:ok, value} -> value
          {:error, reason} -> repo().rollback(reason)
          value -> value
        end

      case append_audit_event(audit_event) do
        {:ok, _event} -> result
        {:error, reason} -> repo().rollback(reason)
      end
    end)
  end

  @impl ConsentStore
  def grant_consent(%ConsentGrant{} = grant) do
    %ConsentGrantRecord{}
    |> ConsentGrantRecord.changeset(grant)
    |> repo().insert()
    |> map_one(&ConsentGrantRecord.to_domain/1)
  end

  @impl ConsentStore
  def list_consents(opts \\ []) when is_list(opts) do
    ConsentGrantRecord
    |> maybe_filter_consent_account(Keyword.get(opts, :account_id))
    |> maybe_filter_consent_client(Keyword.get(opts, :client_id))
    |> maybe_filter_consent_status(Keyword.get(opts, :status))
    |> order_by([grant], desc: grant.granted_at, desc: grant.id)
    |> maybe_limit_consents(Keyword.get(opts, :limit))
    |> repo().all()
    |> then(fn records -> {:ok, Enum.map(records, &ConsentGrantRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl ConsentStore
  def list_consents_for_account(account_id) when is_binary(account_id) do
    list_consents(account_id: account_id)
  end

  @impl ConsentStore
  def fetch_consent_grant(grant_id) when is_integer(grant_id) do
    ConsentGrantRecord
    |> where([grant], grant.id == ^grant_id)
    |> repo().one()
    |> then(fn record -> {:ok, maybe_map(record, &ConsentGrantRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl ConsentStore
  def list_reusable_consents(account_id, client_id)
      when is_binary(account_id) and is_binary(client_id) do
    ConsentGrantRecord
    |> where([grant], grant.account_id == ^account_id and grant.client_id == ^client_id)
    |> where([grant], grant.kind == :remembered and grant.status == :active)
    |> where([grant], is_nil(grant.revoked_at))
    |> order_by([grant], desc: grant.granted_at, desc: grant.id)
    |> repo().all()
    |> then(fn records -> {:ok, Enum.map(records, &ConsentGrantRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl ConsentStore
  def revoke_consent_grant(grant_id, attrs) when is_integer(grant_id) and is_map(attrs) do
    transact(fn ->
      ConsentGrantRecord
      |> where([grant], grant.id == ^grant_id)
      |> lock("FOR UPDATE")
      |> repo().one()
      |> case do
        nil ->
          repo().rollback(:not_found)

        %ConsentGrantRecord{revoked_at: %DateTime{}} = record ->
          ConsentGrantRecord.to_domain(record)

        %ConsentGrantRecord{} = record ->
          record
          |> ConsentGrantRecord.update_changeset(
            attrs
            |> Map.put_new(:status, :revoked)
            |> Map.put(:updated_at, DateTime.utc_now())
          )
          |> repo().update()
          |> map_one(&ConsentGrantRecord.to_domain/1)
          |> unwrap_or_rollback()
      end
    end)
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
    |> repo().all()
    |> then(fn records -> {:ok, Enum.map(records, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @impl TokenStore
  def fetch_lifecycle_token_by_id(token_id) when is_integer(token_id) do
    TokenRecord
    |> where([token], token.id == ^token_id)
    |> where([token], token.token_type in [:access_token, :refresh_token])
    |> repo().one()
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
    |> repo().all(repo_log_options(sensitive: true))
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

  @spec fetch_logout_event_by_event_id(String.t()) ::
          {:ok, Lockspire.Domain.LogoutEvent.t() | nil} | {:error, term()}
  def fetch_logout_event_by_event_id(event_id) when is_binary(event_id) do
    LogoutEventRecord
    |> where([event], event.event_id == ^event_id)
    |> repo_one()
    |> then(fn record -> {:ok, maybe_map(record, &LogoutEventRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec list_all_logout_deliveries() ::
          {:ok, [Lockspire.Domain.LogoutDelivery.t()]} | {:error, term()}
  def list_all_logout_deliveries do
    LogoutDeliveryRecord
    |> order_by(desc: :inserted_at)
    |> repo().all()
    |> then(fn records -> {:ok, Enum.map(records, &LogoutDeliveryRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec list_logout_deliveries(integer()) ::
          {:ok, [Lockspire.Domain.LogoutDelivery.t()]} | {:error, term()}
  def list_logout_deliveries(logout_event_id) when is_integer(logout_event_id) do
    LogoutDeliveryRecord
    |> where([delivery], delivery.logout_event_id == ^logout_event_id)
    |> order_by([delivery], asc: delivery.id)
    |> repo().all()
    |> then(fn records -> {:ok, Enum.map(records, &LogoutDeliveryRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec mark_logout_delivery_enqueued(integer(), integer()) ::
          {:ok, Lockspire.Domain.LogoutDelivery.t()} | {:error, term()}
  def mark_logout_delivery_enqueued(logout_delivery_id, oban_job_id)
      when is_integer(logout_delivery_id) and is_integer(oban_job_id) do
    LogoutDeliveryRecord
    |> where([delivery], delivery.id == ^logout_delivery_id)
    |> lock("FOR UPDATE")
    |> repo().one()
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
        |> repo().update()
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

  def list_initial_access_tokens(_opts \\ []) do
    InitialAccessTokenRecord
    |> order_by([iat], desc: iat.inserted_at)
    |> repo().all()
    |> Enum.map(&InitialAccessTokenRecord.to_domain/1)
    |> then(&{:ok, &1})
  end

  def save_initial_access_token(%Lockspire.Domain.InitialAccessToken{} = iat) do
    %InitialAccessTokenRecord{}
    |> InitialAccessTokenRecord.changeset(iat)
    |> repo().insert()
    |> map_one(&InitialAccessTokenRecord.to_domain/1)
  end

  def revoke_initial_access_token(id, revoked_at)
      when is_integer(id) and is_struct(revoked_at, DateTime) do
    InitialAccessTokenRecord
    |> where([iat], iat.id == ^id)
    |> repo().update_all(set: [revoked_at: revoked_at, updated_at: DateTime.utc_now()])
    |> case do
      {1, _} -> :ok
      {0, _} -> {:error, :not_found}
    end
  end

  @impl KeyStore
  def publish_key(%SigningKey{} = key) do
    %SigningKeyRecord{}
    |> SigningKeyRecord.changeset(key)
    |> repo().insert(
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
    |> repo().all()
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
    |> repo().all()
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
    |> repo().all()
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
    |> repo().all()
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
    |> repo().all()
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
    |> repo().one()
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
      |> repo().one()
      |> case do
        nil ->
          repo().rollback(:not_found)

        %SigningKeyRecord{status: :upcoming, published_at: nil} = record ->
          record
          |> SigningKeyRecord.update_changeset(%{published_at: published_at})
          |> repo().update()
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
      |> repo().one()
      |> activate_signing_key_record(activated_at)
    end)
  end

  @impl KeyStore
  def retire_signing_key(id, retired_at)
      when is_integer(id) and is_struct(retired_at, DateTime) do
    transact(fn ->
      id
      |> locked_signing_key_query()
      |> repo().one()
      |> case do
        nil ->
          repo().rollback(:not_found)

        %SigningKeyRecord{status: :retiring} = record ->
          record
          |> SigningKeyRecord.update_changeset(%{
            status: :retired,
            retired_at: retired_at
          })
          |> repo().update()
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

  # Acceptance marker: def rotate_refresh_token(... expected_cnf
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

  defp update_client_record(id, attrs, opts \\ []) do
    transact(fn ->
      ClientRecord
      |> where([client], client.id == ^id)
      |> lock("FOR UPDATE")
      |> repo_one(opts)
      |> case do
        nil ->
          repo().rollback(:not_found)

        %ClientRecord{} = record ->
          record
          |> ClientRecord.update_changeset(attrs)
          |> repo_update(opts)
          |> map_one(&ClientRecord.to_domain/1)
          |> unwrap_or_rollback()
      end
    end)
  end

  defp map_one({:ok, record}, mapper), do: {:ok, mapper.(record)}
  defp map_one({:error, error}, _mapper), do: {:error, error}

  defp maybe_map(nil, _mapper), do: nil
  defp maybe_map(record, mapper), do: mapper.(record)

  defp maybe_filter_client_search(query, nil), do: query
  defp maybe_filter_client_search(query, ""), do: query

  defp maybe_filter_client_search(query, search) when is_binary(search) do
    pattern = "%#{search}%"

    where(
      query,
      [client],
      ilike(client.client_id, ^pattern) or ilike(client.name, ^pattern)
    )
  end

  defp maybe_filter_client_status(query, nil), do: query

  defp maybe_filter_client_status(query, active) when is_boolean(active) do
    where(query, [client], client.active == ^active)
  end

  defp maybe_filter_client_provenance(query, nil), do: query

  defp maybe_filter_client_provenance(query, provenance)
       when provenance in [:operator, :self_registered] do
    where(query, [client], client.provenance == ^provenance)
  end

  defp maybe_filter_consent_account(query, nil), do: query
  defp maybe_filter_consent_account(query, ""), do: query

  defp maybe_filter_consent_account(query, account_id) when is_binary(account_id) do
    where(query, [grant], grant.account_id == ^account_id)
  end

  defp maybe_filter_consent_client(query, nil), do: query
  defp maybe_filter_consent_client(query, ""), do: query

  defp maybe_filter_consent_client(query, client_id) when is_binary(client_id) do
    where(query, [grant], grant.client_id == ^client_id)
  end

  defp maybe_filter_consent_status(query, nil), do: query

  defp maybe_filter_consent_status(query, status) when status in [:active, :revoked] do
    where(query, [grant], grant.status == ^status)
  end

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

  defp consume_pushed_authorization_request_record(nil, _client_id, _now) do
    repo().rollback(:not_found)
  end

  defp consume_pushed_authorization_request_record(
         %PushedAuthorizationRequestRecord{} = record,
         client_id,
         now
       ) do
    case repo().delete(record, repo_log_options(sensitive: true))
         |> map_one(&PushedAuthorizationRequestRecord.to_domain(&1)) do
      {:ok, %PushedAuthorizationRequest{} = consumed} ->
        cond do
          not active_pushed_authorization_request?(consumed, now) ->
            nil

          consumed.client_id != client_id ->
            nil

          true ->
            consumed
        end

      {:error, reason} ->
        repo().rollback(reason)
    end
  end

  defp active_pushed_authorization_request?(
         %PushedAuthorizationRequest{expires_at: %DateTime{} = expires_at},
         now
       ),
       do: DateTime.compare(expires_at, now) == :gt

  defp maybe_filter_signing_key_status(query, nil), do: query

  defp maybe_filter_signing_key_status(query, status)
       when status in [:upcoming, :active, :retiring, :retired] do
    where(query, [key], key.status == ^status)
  end

  defp maybe_filter_signing_key_status(query, _status), do: query

  defp maybe_limit_clients(query, nil), do: query

  defp maybe_limit_clients(query, limit) when is_integer(limit) and limit > 0,
    do: limit(query, ^limit)

  defp maybe_limit_clients(query, _limit), do: query

  defp maybe_limit_consents(query, nil), do: query

  defp maybe_limit_consents(query, limit) when is_integer(limit) and limit > 0,
    do: limit(query, ^limit)

  defp maybe_limit_consents(query, _limit), do: query

  defp maybe_limit_tokens(query, nil), do: query

  defp maybe_limit_tokens(query, limit) when is_integer(limit) and limit > 0,
    do: limit(query, ^limit)

  defp maybe_limit_tokens(query, _limit), do: query

  defp locked_interaction_query(interaction_id) do
    InteractionRecord
    |> where([interaction], interaction.interaction_id == ^interaction_id)
    |> lock("FOR UPDATE")
  end

  defp locked_device_authorization_query(verification_handle) do
    DeviceAuthorizationRecord
    |> where([authorization], authorization.verification_handle == ^verification_handle)
    |> lock("FOR UPDATE")
  end

  defp locked_device_authorization_by_device_code_query(device_code_hash) do
    DeviceAuthorizationRecord
    |> where([authorization], authorization.device_code_hash == ^device_code_hash)
    |> lock("FOR UPDATE")
  end

  defp locked_ciba_authorization_query(auth_req_id_hash) do
    CibaAuthorizationRecord
    |> where([authorization], authorization.auth_req_id_hash == ^auth_req_id_hash)
    |> lock("FOR UPDATE")
  end

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

  defp transition_interaction_record(nil, _expected_statuses, _attrs),
    do: repo().rollback(:not_found)

  defp transition_interaction_record(%InteractionRecord{} = record, expected_statuses, attrs) do
    if record.status in expected_statuses do
      record
      |> InteractionRecord.update_changeset(Map.put(attrs, :updated_at, DateTime.utc_now()))
      |> repo().update()
      |> map_one(&InteractionRecord.to_domain/1)
      |> unwrap_or_rollback()
    else
      repo().rollback(:invalid_state)
    end
  end

  defp transition_device_authorization_record(nil, _expected_statuses, _attrs),
    do: repo().rollback(:not_found)

  defp transition_device_authorization_record(
         %DeviceAuthorizationRecord{} = record,
         expected_statuses,
         attrs
       ) do
    if record.status in expected_statuses do
      record
      |> DeviceAuthorizationRecord.update_changeset(
        Map.put(attrs, :updated_at, DateTime.utc_now())
      )
      |> repo().update()
      |> map_one(&DeviceAuthorizationRecord.to_domain/1)
      |> unwrap_or_rollback()
    else
      repo().rollback(:invalid_state)
    end
  end

  defp transition_ciba_authorization_record(nil, _expected_statuses, _attrs),
    do: repo().rollback(:not_found)

  defp transition_ciba_authorization_record(
         %CibaAuthorizationRecord{} = record,
         expected_statuses,
         attrs
       ) do
    if record.status in expected_statuses do
      record
      |> CibaAuthorizationRecord.update_changeset(
        Map.put(attrs, :updated_at, DateTime.utc_now())
      )
      |> repo().update()
      |> map_one(&CibaAuthorizationRecord.to_domain/1)
      |> unwrap_or_rollback()
    else
      repo().rollback(:invalid_state)
    end
  end

  defp evaluate_device_poll(nil, _client_id, _now) do
    %{result: :invalid_grant}
  end

  defp evaluate_device_poll(
         %DeviceAuthorizationRecord{client_id: stored_client_id},
         client_id,
         _now
       )
       when stored_client_id != client_id do
    %{result: :client_mismatch}
  end

  defp evaluate_device_poll(
         %DeviceAuthorizationRecord{status: :denied} = record,
         _client_id,
         _now
       ),
       do: device_poll_outcome(:denied, record)

  defp evaluate_device_poll(
         %DeviceAuthorizationRecord{status: :expired} = record,
         _client_id,
         _now
       ),
       do: device_poll_outcome(:expired, record)

  defp evaluate_device_poll(
         %DeviceAuthorizationRecord{status: :consumed} = record,
         _client_id,
         _now
       ),
       do: device_poll_outcome(:consumed, record)

  defp evaluate_device_poll(
         %DeviceAuthorizationRecord{status: :approved} = record,
         _client_id,
         now
       ) do
    if DateTime.compare(record.expires_at, now) != :gt do
      expire_device_authorization(record, now)
    else
      device_poll_outcome(:approved_ready, record)
    end
  end

  defp evaluate_device_poll(
         %DeviceAuthorizationRecord{status: :pending} = record,
         _client_id,
         now
       ) do
    cond do
      DateTime.compare(record.expires_at, now) != :gt ->
        expire_device_authorization(record, now)

      DateTime.compare(now, record.next_poll_allowed_at) == :lt ->
        slow_down_device_authorization(record, now)

      true ->
        continue_pending_device_authorization(record, now)
    end
  end

  defp evaluate_device_poll(%DeviceAuthorizationRecord{status: status}, client_id, _now) do
    %{result: :invalid_grant, reason: {:unexpected_status, status, client_id}}
  end

  defp expire_device_authorization(record, now) do
    record
    |> DeviceAuthorizationRecord.update_changeset(%{
      status: :expired,
      expired_at: now,
      updated_at: DateTime.utc_now()
    })
    |> repo_update(sensitive: true)
    |> map_one(&DeviceAuthorizationRecord.to_domain/1)
    |> unwrap_or_rollback()
    |> then(&device_poll_outcome(:expired, &1))
  end

  defp slow_down_device_authorization(record, _now) do
    next_interval = record.effective_poll_interval_seconds + 5
    next_poll_allowed_at = DateTime.add(record.next_poll_allowed_at, next_interval, :second)

    record
    |> DeviceAuthorizationRecord.update_changeset(%{
      effective_poll_interval_seconds: next_interval,
      next_poll_allowed_at: next_poll_allowed_at,
      updated_at: DateTime.utc_now()
    })
    |> repo_update(sensitive: true)
    |> map_one(&DeviceAuthorizationRecord.to_domain/1)
    |> unwrap_or_rollback()
    |> then(&device_poll_outcome(:slow_down, &1))
  end

  defp continue_pending_device_authorization(record, now) do
    next_poll_allowed_at = DateTime.add(now, record.effective_poll_interval_seconds, :second)

    record
    |> DeviceAuthorizationRecord.update_changeset(%{
      next_poll_allowed_at: next_poll_allowed_at,
      updated_at: DateTime.utc_now()
    })
    |> repo_update(sensitive: true)
    |> map_one(&DeviceAuthorizationRecord.to_domain/1)
    |> unwrap_or_rollback()
    |> then(&device_poll_outcome(:pending, &1))
  end

  defp evaluate_ciba_poll(nil, _client_id, _now) do
    %{result: :invalid_grant}
  end

  defp evaluate_ciba_poll(
         %CibaAuthorizationRecord{client_id: stored_client_id},
         client_id,
         _now
       )
       when stored_client_id != client_id do
    %{result: :client_mismatch}
  end

  defp evaluate_ciba_poll(%CibaAuthorizationRecord{status: :denied} = record, _client_id, _now),
    do: ciba_poll_outcome(:denied, record)

  defp evaluate_ciba_poll(%CibaAuthorizationRecord{status: :expired} = record, _client_id, _now),
    do: ciba_poll_outcome(:expired, record)

  defp evaluate_ciba_poll(%CibaAuthorizationRecord{status: :consumed} = record, _client_id, _now),
    do: ciba_poll_outcome(:consumed, record)

  defp evaluate_ciba_poll(%CibaAuthorizationRecord{status: :approved} = record, _client_id, now) do
    if DateTime.compare(record.expires_at, now) != :gt do
      expire_ciba_authorization(record, now)
    else
      ciba_poll_outcome(:approved_ready, record)
    end
  end

  defp evaluate_ciba_poll(%CibaAuthorizationRecord{status: :pending} = record, _client_id, now) do
    cond do
      DateTime.compare(record.expires_at, now) != :gt ->
        expire_ciba_authorization(record, now)

      DateTime.compare(now, record.next_poll_allowed_at) == :lt ->
        slow_down_ciba_authorization(record, now)

      true ->
        continue_pending_ciba_authorization(record, now)
    end
  end

  defp evaluate_ciba_poll(%CibaAuthorizationRecord{status: status}, client_id, _now) do
    %{result: :invalid_grant, reason: {:unexpected_status, status, client_id}}
  end

  defp expire_ciba_authorization(record, now) do
    record
    |> CibaAuthorizationRecord.update_changeset(%{
      status: :expired,
      expired_at: now,
      updated_at: DateTime.utc_now()
    })
    |> repo_update(sensitive: true)
    |> map_one(&CibaAuthorizationRecord.to_domain/1)
    |> unwrap_or_rollback()
    |> then(&ciba_poll_outcome(:expired, &1))
  end

  defp slow_down_ciba_authorization(record, _now) do
    next_interval = record.effective_poll_interval_seconds + 5
    next_poll_allowed_at = DateTime.add(record.next_poll_allowed_at, next_interval, :second)

    record
    |> CibaAuthorizationRecord.update_changeset(%{
      effective_poll_interval_seconds: next_interval,
      next_poll_allowed_at: next_poll_allowed_at,
      updated_at: DateTime.utc_now()
    })
    |> repo_update(sensitive: true)
    |> map_one(&CibaAuthorizationRecord.to_domain/1)
    |> unwrap_or_rollback()
    |> then(&ciba_poll_outcome(:slow_down, &1))
  end

  defp continue_pending_ciba_authorization(record, now) do
    next_poll_allowed_at = DateTime.add(now, record.effective_poll_interval_seconds, :second)

    record
    |> CibaAuthorizationRecord.update_changeset(%{
      next_poll_allowed_at: next_poll_allowed_at,
      updated_at: DateTime.utc_now()
    })
    |> repo_update(sensitive: true)
    |> map_one(&CibaAuthorizationRecord.to_domain/1)
    |> unwrap_or_rollback()
    |> then(&ciba_poll_outcome(:pending, &1))
  end

  defp consume_device_authorization_record(nil, _client_id, _now),
    do: repo().rollback(:invalid_state)

  defp consume_device_authorization_record(
         %DeviceAuthorizationRecord{client_id: stored_client_id},
         client_id,
         _now
       )
       when stored_client_id != client_id,
       do: repo().rollback(:invalid_state)

  defp consume_device_authorization_record(
         %DeviceAuthorizationRecord{status: :approved} = record,
         _client_id,
         now
       ) do
    if DateTime.compare(record.expires_at, now) == :gt do
      record
      |> DeviceAuthorizationRecord.update_changeset(%{
        status: :consumed,
        consumed_at: now,
        updated_at: DateTime.utc_now()
      })
      |> repo_update(sensitive: true)
      |> map_one(&DeviceAuthorizationRecord.to_domain/1)
      |> unwrap_or_rollback()
    else
      repo().rollback(:invalid_state)
    end
  end

  defp consume_device_authorization_record(%DeviceAuthorizationRecord{}, _client_id, _now),
    do: repo().rollback(:invalid_state)

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
      |> repo().all(log: false)

    if ids == [] do
      count
    else
      {deleted, _} =
        schema
        |> where([r], r.id in ^ids)
        |> repo().delete_all(log: false)

      prune_expired_records(schema, now, count + deleted)
    end
  end

  defp prune_expired_dpop_replay_records(%DateTime{} = seen_at) do
    DpopReplayRecord
    |> where([replay], replay.expires_at <= ^seen_at)
    |> repo().delete_all(log: false)

    :ok
  end

  defp device_poll_outcome(result, %DeviceAuthorizationRecord{} = record) do
    result
    |> device_poll_outcome(DeviceAuthorizationRecord.to_domain(record))
  end

  defp device_poll_outcome(result, %DeviceAuthorization{} = device_authorization) do
    %{
      result: result,
      device_authorization: device_authorization,
      effective_poll_interval_seconds: device_authorization.effective_poll_interval_seconds,
      next_poll_allowed_at: device_authorization.next_poll_allowed_at
    }
  end

  defp ciba_poll_outcome(result, %CibaAuthorizationRecord{} = record) do
    result
    |> ciba_poll_outcome(CibaAuthorizationRecord.to_domain(record))
  end

  defp ciba_poll_outcome(result, %CibaAuthorization{} = ciba_authorization) do
    %{
      result: result,
      ciba_authorization: ciba_authorization,
      effective_poll_interval_seconds: ciba_authorization.effective_poll_interval_seconds,
      next_poll_allowed_at: ciba_authorization.next_poll_allowed_at
    }
  end

  defp run_transaction_fun(fun) do
    case fun.() do
      {:ok, result} -> result
      {:error, reason} -> repo().rollback(reason)
      result -> result
    end
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
    |> repo().all()
  end

  defp activate_selected_signing_key(%SigningKeyRecord{} = record, activated_at) do
    record
    |> SigningKeyRecord.update_changeset(%{
      status: :active,
      activated_at: activated_at,
      retiring_at: nil,
      retired_at: nil
    })
    |> repo().update()
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
    |> repo().update()
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
    |> repo().one()
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
      |> repo().all(repo_log_options(sensitive: true))

    ClientRecord
    |> where([client], client.client_id in ^client_ids)
    |> where(
      [client],
      not is_nil(client.backchannel_logout_uri) or not is_nil(client.frontchannel_logout_uri)
    )
    |> order_by([client], asc: client.client_id)
    |> repo().all()
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

  defp repo_one(query, opts \\ []) do
    repo().one(query, repo_log_options(opts))
  end

  defp repo_insert(changeset, opts \\ []) do
    repo().insert(changeset, repo_log_options(opts))
  end

  defp repo_update(changeset, opts) do
    repo().update(changeset, repo_log_options(opts))
  end

  defp repo_update_all(query, updates, opts, keyword_opts \\ []) do
    repo().update_all(query, Keyword.merge(updates, keyword_opts), repo_log_options(opts))
  end

  defp repo_log_options(opts) do
    if Keyword.get(opts, :sensitive, false), do: [log: false], else: []
  end

  defp strip_private_key_material(%SigningKey{} = key) do
    %SigningKey{key | private_jwk_encrypted: nil}
  end
end
