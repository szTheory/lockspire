defmodule Lockspire.Storage.Ecto.Repository.ConsentStore do
  @moduledoc false

  import Ecto.Query

  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Storage.Ecto.ConsentGrantRecord
  alias Lockspire.Storage.Ecto.Repository.Support
  alias Lockspire.Storage.Ecto.Repository.TransactionStore

  @spec grant_consent(module(), ConsentGrant.t()) :: {:ok, ConsentGrant.t()} | {:error, term()}
  def grant_consent(repo, %ConsentGrant{} = grant) do
    %ConsentGrantRecord{}
    |> ConsentGrantRecord.changeset(grant)
    |> then(&Support.insert(repo, &1))
    |> map_one(&ConsentGrantRecord.to_domain/1)
  end

  @spec list_consents(module(), keyword()) :: {:ok, [ConsentGrant.t()]} | {:error, term()}
  def list_consents(repo, opts \\ []) when is_list(opts) do
    ConsentGrantRecord
    |> maybe_filter_account(Keyword.get(opts, :account_id))
    |> maybe_filter_client(Keyword.get(opts, :client_id))
    |> maybe_filter_status(Keyword.get(opts, :status))
    |> order_by([grant], desc: grant.granted_at, desc: grant.id)
    |> maybe_limit(Keyword.get(opts, :limit))
    |> then(&Support.all(repo, &1))
    |> then(fn records -> {:ok, Enum.map(records, &ConsentGrantRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec list_consents_for_account(module(), String.t()) ::
          {:ok, [ConsentGrant.t()]} | {:error, term()}
  def list_consents_for_account(repo, account_id) when is_binary(account_id),
    do: list_consents(repo, account_id: account_id)

  @spec fetch_consent_grant(module(), integer()) ::
          {:ok, ConsentGrant.t() | nil} | {:error, term()}
  def fetch_consent_grant(repo, grant_id) when is_integer(grant_id) do
    ConsentGrantRecord
    |> where([grant], grant.id == ^grant_id)
    |> then(&Support.one(repo, &1))
    |> then(fn record -> {:ok, maybe_map(record, &ConsentGrantRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec list_reusable_consents(module(), String.t(), String.t()) ::
          {:ok, [ConsentGrant.t()]} | {:error, term()}
  def list_reusable_consents(repo, account_id, client_id)
      when is_binary(account_id) and is_binary(client_id) do
    ConsentGrantRecord
    |> where([grant], grant.account_id == ^account_id and grant.client_id == ^client_id)
    |> where([grant], grant.kind == :remembered and grant.status == :active)
    |> where([grant], is_nil(grant.revoked_at))
    |> order_by([grant], desc: grant.granted_at, desc: grant.id)
    |> then(&Support.all(repo, &1))
    |> then(fn records -> {:ok, Enum.map(records, &ConsentGrantRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec revoke_consent_grant(module(), integer(), map()) ::
          {:ok, ConsentGrant.t()} | {:error, term()}
  def revoke_consent_grant(repo, grant_id, attrs) when is_integer(grant_id) and is_map(attrs) do
    TransactionStore.transact(repo, fn ->
      ConsentGrantRecord
      |> where([grant], grant.id == ^grant_id)
      |> lock("FOR UPDATE")
      |> then(&Support.one(repo, &1))
      |> revoke_record(repo, attrs)
    end)
  end

  defp revoke_record(nil, repo, _attrs), do: TransactionStore.rollback(repo, :not_found)

  defp revoke_record(%ConsentGrantRecord{revoked_at: %DateTime{}} = record, _repo, _attrs),
    do: ConsentGrantRecord.to_domain(record)

  defp revoke_record(%ConsentGrantRecord{} = record, repo, attrs) do
    record
    |> ConsentGrantRecord.update_changeset(
      attrs
      |> Map.put_new(:status, :revoked)
      |> Map.put(:updated_at, DateTime.utc_now())
    )
    |> then(&Support.update(repo, &1))
    |> map_one(&ConsentGrantRecord.to_domain/1)
    |> unwrap_or_rollback(repo)
  end

  defp maybe_filter_account(query, nil), do: query
  defp maybe_filter_account(query, ""), do: query

  defp maybe_filter_account(query, account_id) when is_binary(account_id),
    do: where(query, [grant], grant.account_id == ^account_id)

  defp maybe_filter_client(query, nil), do: query
  defp maybe_filter_client(query, ""), do: query

  defp maybe_filter_client(query, client_id) when is_binary(client_id),
    do: where(query, [grant], grant.client_id == ^client_id)

  defp maybe_filter_status(query, nil), do: query

  defp maybe_filter_status(query, status) when status in [:active, :revoked],
    do: where(query, [grant], grant.status == ^status)

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit) when is_integer(limit) and limit > 0, do: limit(query, ^limit)
  defp maybe_limit(query, _limit), do: query

  defp unwrap_or_rollback({:ok, result}, _repo), do: result
  defp unwrap_or_rollback({:error, reason}, repo), do: TransactionStore.rollback(repo, reason)
  defp map_one({:ok, record}, mapper), do: {:ok, mapper.(record)}
  defp map_one({:error, error}, _mapper), do: {:error, error}
  defp maybe_map(nil, _mapper), do: nil
  defp maybe_map(record, mapper), do: mapper.(record)
end
