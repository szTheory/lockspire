defmodule Lockspire.Storage.Ecto.Repository.ClientStore do
  @moduledoc false

  import Ecto.Query

  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.Repository.AuditStore
  alias Lockspire.Storage.Ecto.Repository.ServerPolicyStore
  alias Lockspire.Storage.Ecto.Repository.Support
  alias Lockspire.Storage.Ecto.Repository.TransactionStore

  @spec lock_clients(module(), [String.t()]) :: {:ok, [Client.t()]} | {:error, term()}
  def lock_clients(repo, client_ids) when is_list(client_ids) do
    cond do
      not Enum.all?(client_ids, &is_binary/1) ->
        {:error, :invalid_client_ids}

      not repo.in_transaction?() ->
        {:error, :transaction_required}

      true ->
        ids = Enum.uniq(client_ids) |> Enum.sort()

        ClientRecord
        |> where([client], client.client_id in ^ids)
        |> order_by([client], asc: client.client_id)
        |> lock("FOR UPDATE")
        |> then(&Support.all(repo, &1, sensitive: true))
        |> then(fn records -> {:ok, Enum.map(records, &ClientRecord.to_domain/1)} end)
    end
  rescue
    error -> {:error, safe_storage_error(error)}
  end

  def lock_clients(_repo, _client_ids), do: {:error, :invalid_client_ids}

  @spec register_client(module(), Client.t()) :: {:ok, Client.t()} | {:error, term()}
  def register_client(repo, %Client{} = client) do
    %ClientRecord{}
    |> ClientRecord.changeset(client)
    |> then(&Support.insert(repo, &1, sensitive: true))
    |> safe_result()
    |> map_one(&ClientRecord.to_domain/1)
  rescue
    error -> {:error, safe_storage_error(error)}
  end

  @spec list_clients(module(), keyword()) :: {:ok, [Client.t()]} | {:error, term()}
  def list_clients(repo, opts \\ []) when is_list(opts) do
    ClientRecord
    |> maybe_filter_search(Keyword.get(opts, :search))
    |> maybe_filter_status(Keyword.get(opts, :active))
    |> maybe_filter_provenance(Keyword.get(opts, :provenance))
    |> order_by([client], asc: client.name, asc: client.client_id)
    |> maybe_limit(Keyword.get(opts, :limit))
    |> then(&Support.all(repo, &1, sensitive: true))
    |> then(fn records -> {:ok, Enum.map(records, &ClientRecord.to_domain/1)} end)
  rescue
    error -> {:error, safe_storage_error(error)}
  end

  @spec fetch_client_by_id(module(), String.t()) :: {:ok, Client.t() | nil} | {:error, term()}
  def fetch_client_by_id(repo, client_id) when is_binary(client_id) do
    ClientRecord
    |> where([client], client.client_id == ^client_id)
    |> then(&Support.one(repo, &1, sensitive: true))
    |> then(fn record -> {:ok, maybe_map(record, &ClientRecord.to_domain/1)} end)
  rescue
    error -> {:error, safe_storage_error(error)}
  end

  @spec get_client_by_registration_access_token_hash(module(), String.t()) ::
          {:ok, Client.t() | nil} | {:error, term()}
  def get_client_by_registration_access_token_hash(repo, rat_hash) when is_binary(rat_hash) do
    ClientRecord
    |> where([client], client.registration_access_token_hash == ^rat_hash)
    |> then(&Support.one(repo, &1, sensitive: true))
    |> then(fn record -> {:ok, maybe_map(record, &ClientRecord.to_domain/1)} end)
  rescue
    error -> {:error, safe_storage_error(error)}
  end

  @spec replace_client_registration(module(), Client.t(), Client.t(), String.t(), map()) ::
          {:ok, Client.t()} | {:error, term()}
  def replace_client_registration(
        repo,
        %Client{id: id} = client,
        %Client{} = replacement,
        new_rat_hash,
        audit_attrs
      )
      when is_integer(id) and is_binary(new_rat_hash) and is_map(audit_attrs) do
    TransactionStore.transact(repo, fn ->
      id
      |> locked_query()
      |> then(&Support.one(repo, &1, sensitive: true))
      |> case do
        nil ->
          TransactionStore.rollback(repo, :not_found)

        %ClientRecord{} = record ->
          current = ClientRecord.to_domain(record)

          with true <-
                 current.client_id == client.client_id and current.active and
                   current.registration_access_token_hash ==
                     client.registration_access_token_hash,
               {:ok, lifetime_changes} <-
                 Client.credential_lifetime_changes(
                   current,
                   :management,
                   replacement.registration_access_token_expires_at
                 ) do
            attrs =
              replacement
              |> Map.from_struct()
              |> Map.take(dcr_metadata_fields())
              |> Map.merge(lifetime_changes)
              |> Map.put(:registration_access_token_hash, new_rat_hash)
              |> Map.put(:updated_at, replacement.updated_at)

            record
            |> ClientRecord.dcr_management_changeset(attrs)
            |> then(&Support.update(repo, &1, sensitive: true))
            |> map_one(&ClientRecord.to_domain/1)
            |> append_audit_or_rollback(repo, audit_attrs)
          else
            {:error, :invalid_lifetime_state} ->
              TransactionStore.rollback(repo, :invalid_lifetime_state)

            _ ->
              TransactionStore.rollback(repo, :invalid_token)
          end
      end
    end)
    |> safe_result()
  end

  @spec rotate_registration_access_token(module(), Client.t(), String.t(), map()) ::
          {:ok, Client.t()} | {:error, term()}
  def rotate_registration_access_token(repo, %Client{id: id} = client, new_rat_hash, audit_attrs)
      when is_integer(id) and is_binary(new_rat_hash) and is_map(audit_attrs) do
    TransactionStore.transact(repo, fn ->
      id
      |> locked_query()
      |> then(&Support.one(repo, &1, sensitive: true))
      |> case do
        nil ->
          TransactionStore.rollback(repo, :not_found)

        %ClientRecord{} = record ->
          current = ClientRecord.to_domain(record)

          with true <-
                 current.registration_access_token_hash ==
                   client.registration_access_token_hash,
               {:ok, lifetime_changes} <-
                 Client.credential_lifetime_changes(
                   current,
                   :management,
                   client.registration_access_token_expires_at
                 ) do
            record
            |> ClientRecord.dcr_management_changeset(
              Map.merge(lifetime_changes, %{
                registration_access_token_hash: new_rat_hash,
                updated_at: client.updated_at
              })
            )
            |> then(&Support.update(repo, &1, sensitive: true))
            |> map_one(&ClientRecord.to_domain/1)
            |> append_audit_or_rollback(repo, audit_attrs)
          else
            {:error, :invalid_lifetime_state} ->
              TransactionStore.rollback(repo, :invalid_lifetime_state)

            _ ->
              TransactionStore.rollback(repo, :invalid_token)
          end
      end
    end)
    |> safe_result()
  end

  @spec update_client(module(), Client.t(), map()) :: {:ok, Client.t()} | {:error, term()}
  def update_client(repo, %Client{id: id}, attrs) when is_integer(id) and is_map(attrs) do
    update_record(repo, id, attrs, &ClientRecord.update_changeset/2)
  end

  @spec rotate_client_secret(
          module(),
          Client.t(),
          String.t(),
          String.t(),
          DateTime.t() | (-> DateTime.t())
        ) ::
          {:ok, Client.t()} | {:error, term()}
  def rotate_client_secret(repo, %Client{id: id}, secret_hash, verifier_encrypted, rotated_at)
      when is_integer(id) and is_binary(secret_hash) and is_binary(verifier_encrypted) and
             (is_struct(rotated_at, DateTime) or is_function(rotated_at, 0)) do
    TransactionStore.transact(repo, fn ->
      case id |> locked_query() |> then(&Support.one(repo, &1, sensitive: true)) do
        nil ->
          TransactionStore.rollback(repo, :not_found)

        %ClientRecord{} = record ->
          current = ClientRecord.to_domain(record)

          with {:ok, duration} <- secret_lifetime_duration(repo, current),
               {:ok, decision_time} <- rotation_decision_time(rotated_at),
               {:ok, deadline} <- Client.secret_deadline(current, decision_time, duration),
               {:ok, lifetime_changes} <-
                 Client.credential_lifetime_changes(current, :secret, deadline) do
            record
            |> ClientRecord.secret_rotation_changeset(
              Map.merge(lifetime_changes, %{
                client_secret_hash: secret_hash,
                client_secret_jwt_verifier_encrypted: verifier_encrypted,
                last_secret_rotated_at: decision_time,
                updated_at: decision_time
              })
            )
            |> then(&Support.update(repo, &1, sensitive: true))
            |> map_one(&ClientRecord.to_domain/1)
            |> unwrap_or_rollback(repo)
          else
            {:error, reason} -> TransactionStore.rollback(repo, reason)
          end
      end
    end)
    |> safe_result()
  end

  defp secret_lifetime_duration(_repo, %Client{
         provenance: provenance,
         token_endpoint_auth_method: method
       })
       when provenance != :self_registered or
              method not in [:client_secret_basic, :client_secret_post, :client_secret_jwt],
       do: {:ok, nil}

  defp secret_lifetime_duration(repo, %Client{}) do
    case ServerPolicyStore.get_server_policy(repo) do
      {:ok, policy} -> {:ok, policy.dcr_default_client_secret_lifetime_seconds}
      {:error, reason} -> {:error, reason}
    end
  end

  defp rotation_decision_time(%DateTime{} = time), do: {:ok, time}

  defp rotation_decision_time(clock) when is_function(clock, 0) do
    case clock.() do
      %DateTime{} = time -> {:ok, time}
      _other -> {:error, :invalid_lifetime_state}
    end
  rescue
    _error -> {:error, :invalid_lifetime_state}
  end

  defp rotation_decision_time(_time), do: {:error, :invalid_lifetime_state}

  @spec set_client_active(module(), Client.t(), boolean(), map()) ::
          {:ok, Client.t()} | {:error, term()}
  def set_client_active(repo, %Client{id: id}, active, attrs)
      when is_integer(id) and is_boolean(active) and is_map(attrs) do
    lifecycle_attrs =
      attrs
      |> Map.take([:disabled_at, :disabled_by])
      |> Map.put(:active, active)
      |> Map.put(:updated_at, DateTime.utc_now())

    update_record(repo, id, lifecycle_attrs, &ClientRecord.update_changeset/2)
  end

  defp update_record(repo, id, attrs, changeset, opts \\ [sensitive: true]) do
    opts = Keyword.put(opts, :sensitive, true)

    TransactionStore.transact(repo, fn ->
      id
      |> locked_query()
      |> then(&Support.one(repo, &1, opts))
      |> case do
        nil ->
          TransactionStore.rollback(repo, :not_found)

        %ClientRecord{} = record ->
          record
          |> changeset.(attrs)
          |> then(&Support.update(repo, &1, opts))
          |> map_one(&ClientRecord.to_domain/1)
          |> unwrap_or_rollback(repo)
      end
    end)
    |> safe_result()
  end

  defp locked_query(id),
    do: ClientRecord |> where([client], client.id == ^id) |> lock("FOR UPDATE")

  defp dcr_metadata_fields do
    [
      :name,
      :redirect_uris,
      :allowed_scopes,
      :allowed_grant_types,
      :allowed_response_types,
      :token_endpoint_auth_method,
      :token_endpoint_auth_signing_alg,
      :logo_uri,
      :tos_uri,
      :policy_uri,
      :contacts,
      :jwks,
      :jwks_uri,
      :id_token_signed_response_alg,
      :authorization_signed_response_alg,
      :authorization_encrypted_response_alg,
      :authorization_encrypted_response_enc,
      :security_profile,
      :dpop_policy,
      :backchannel_logout_uri,
      :backchannel_logout_session_required,
      :frontchannel_logout_uri,
      :frontchannel_logout_session_required,
      :metadata
    ]
  end

  defp append_audit_or_rollback({:ok, %Client{} = client}, repo, audit_attrs) do
    case AuditStore.append_audit_event(repo, audit_attrs) do
      {:ok, _event} -> client
      {:error, reason} -> TransactionStore.rollback(repo, reason)
    end
  end

  defp append_audit_or_rollback({:error, reason}, repo, _audit_attrs),
    do: TransactionStore.rollback(repo, reason)

  defp unwrap_or_rollback({:ok, result}, _repo), do: result
  defp unwrap_or_rollback({:error, reason}, repo), do: TransactionStore.rollback(repo, reason)

  defp map_one({:ok, record}, mapper), do: {:ok, mapper.(record)}
  defp map_one({:error, error}, _mapper), do: {:error, error}
  defp maybe_map(nil, _mapper), do: nil
  defp maybe_map(record, mapper), do: mapper.(record)

  defp safe_result({:error, %Postgrex.Error{} = error}),
    do: {:error, safe_storage_error(error)}

  defp safe_result({:error, %DBConnection.ConnectionError{} = error}),
    do: {:error, safe_storage_error(error)}

  defp safe_result(result), do: result

  defp safe_storage_error(%Postgrex.Error{}), do: :storage_error
  defp safe_storage_error(%DBConnection.ConnectionError{}), do: :storage_unavailable
  defp safe_storage_error(_error), do: :storage_error

  defp maybe_filter_search(query, nil), do: query
  defp maybe_filter_search(query, ""), do: query

  defp maybe_filter_search(query, search) when is_binary(search) do
    pattern = "%#{search}%"
    where(query, [client], ilike(client.client_id, ^pattern) or ilike(client.name, ^pattern))
  end

  defp maybe_filter_status(query, nil), do: query

  defp maybe_filter_status(query, active) when is_boolean(active),
    do: where(query, [client], client.active == ^active)

  defp maybe_filter_provenance(query, nil), do: query

  defp maybe_filter_provenance(query, provenance)
       when provenance in [:operator, :self_registered],
       do: where(query, [client], client.provenance == ^provenance)

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit) when is_integer(limit) and limit > 0, do: limit(query, ^limit)
  defp maybe_limit(query, _limit), do: query
end
