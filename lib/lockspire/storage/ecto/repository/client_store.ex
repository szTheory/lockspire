defmodule Lockspire.Storage.Ecto.Repository.ClientStore do
  @moduledoc false

  import Ecto.Query

  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.Repository.AuditStore
  alias Lockspire.Storage.Ecto.Repository.Support
  alias Lockspire.Storage.Ecto.Repository.TransactionStore

  @spec register_client(module(), Client.t()) :: {:ok, Client.t()} | {:error, term()}
  def register_client(repo, %Client{} = client) do
    %ClientRecord{}
    |> ClientRecord.changeset(client)
    |> then(&Support.insert(repo, &1))
    |> map_one(&ClientRecord.to_domain/1)
  end

  @spec list_clients(module(), keyword()) :: {:ok, [Client.t()]} | {:error, term()}
  def list_clients(repo, opts \\ []) when is_list(opts) do
    ClientRecord
    |> maybe_filter_search(Keyword.get(opts, :search))
    |> maybe_filter_status(Keyword.get(opts, :active))
    |> maybe_filter_provenance(Keyword.get(opts, :provenance))
    |> order_by([client], asc: client.name, asc: client.client_id)
    |> maybe_limit(Keyword.get(opts, :limit))
    |> then(&Support.all(repo, &1))
    |> then(fn records -> {:ok, Enum.map(records, &ClientRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec fetch_client_by_id(module(), String.t()) :: {:ok, Client.t() | nil} | {:error, term()}
  def fetch_client_by_id(repo, client_id) when is_binary(client_id) do
    ClientRecord
    |> where([client], client.client_id == ^client_id)
    |> then(&Support.one(repo, &1))
    |> then(fn record -> {:ok, maybe_map(record, &ClientRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec get_client_by_registration_access_token_hash(module(), String.t()) ::
          {:ok, Client.t() | nil} | {:error, term()}
  def get_client_by_registration_access_token_hash(repo, rat_hash) when is_binary(rat_hash) do
    ClientRecord
    |> where([client], client.registration_access_token_hash == ^rat_hash)
    |> then(&Support.one(repo, &1, sensitive: true))
    |> then(fn record -> {:ok, maybe_map(record, &ClientRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec replace_client_registration(module(), Client.t(), Client.t(), String.t(), map()) ::
          {:ok, Client.t()} | {:error, term()}
  def replace_client_registration(
        repo,
        %Client{id: id},
        %Client{} = replacement,
        new_rat_hash,
        audit_attrs
      )
      when is_integer(id) and is_binary(new_rat_hash) and is_map(audit_attrs) do
    TransactionStore.transact(repo, fn ->
      id
      |> locked_query()
      |> then(&Support.one(repo, &1))
      |> case do
        nil ->
          TransactionStore.rollback(repo, :not_found)

        %ClientRecord{} = record ->
          record
          |> ClientRecord.changeset(replacement)
          |> Ecto.Changeset.change(
            registration_access_token_hash: new_rat_hash,
            updated_at: DateTime.utc_now()
          )
          |> then(&Support.update(repo, &1))
          |> map_one(&ClientRecord.to_domain/1)
          |> append_audit_or_rollback(repo, audit_attrs)
      end
    end)
  end

  @spec rotate_registration_access_token(module(), Client.t(), String.t(), map()) ::
          {:ok, Client.t()} | {:error, term()}
  def rotate_registration_access_token(repo, %Client{id: id}, new_rat_hash, audit_attrs)
      when is_integer(id) and is_binary(new_rat_hash) and is_map(audit_attrs) do
    TransactionStore.transact(repo, fn ->
      id
      |> locked_query()
      |> then(&Support.one(repo, &1))
      |> case do
        nil ->
          TransactionStore.rollback(repo, :not_found)

        %ClientRecord{} = record ->
          record
          |> Ecto.Changeset.change(
            registration_access_token_hash: new_rat_hash,
            updated_at: DateTime.utc_now()
          )
          |> then(&Support.update(repo, &1))
          |> map_one(&ClientRecord.to_domain/1)
          |> append_audit_or_rollback(repo, audit_attrs)
      end
    end)
  end

  @spec update_client(module(), Client.t(), map()) :: {:ok, Client.t()} | {:error, term()}
  def update_client(repo, %Client{id: id}, attrs) when is_integer(id) and is_map(attrs) do
    update_record(repo, id, attrs, &ClientRecord.update_changeset/2)
  end

  @spec rotate_client_secret(module(), Client.t(), String.t(), String.t(), DateTime.t()) ::
          {:ok, Client.t()} | {:error, term()}
  def rotate_client_secret(repo, %Client{id: id}, secret_hash, verifier_encrypted, rotated_at)
      when is_integer(id) and is_binary(secret_hash) and is_binary(verifier_encrypted) and
             is_struct(rotated_at, DateTime) do
    update_record(
      repo,
      id,
      %{
        client_secret_hash: secret_hash,
        client_secret_jwt_verifier_encrypted: verifier_encrypted,
        last_secret_rotated_at: rotated_at,
        updated_at: DateTime.utc_now()
      },
      &ClientRecord.update_changeset/2,
      sensitive: true
    )
  end

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

  defp update_record(repo, id, attrs, changeset, opts \\ []) do
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
  end

  defp locked_query(id),
    do: ClientRecord |> where([client], client.id == ^id) |> lock("FOR UPDATE")

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
