defmodule Lockspire.Storage.Ecto.Repository.TokenStore do
  @moduledoc false

  import Ecto.Query

  alias Lockspire.Domain.Token
  alias Lockspire.Storage.Ecto.Repository.Support
  alias Lockspire.Storage.Ecto.Repository.TransactionStore
  alias Lockspire.Storage.Ecto.TokenRecord

  def store_token(repo, %Token{} = token), do: store_record(repo, token)

  def list_lifecycle_tokens(repo, opts \\ []) do
    now = DateTime.utc_now()

    TokenRecord
    |> where([token], token.token_type in [:access_token, :refresh_token])
    |> maybe_filter_account(Keyword.get(opts, :account_id))
    |> maybe_filter_client(Keyword.get(opts, :client_id))
    |> maybe_filter_status(Keyword.get(opts, :status), now)
    |> order_by([token], desc: token.issued_at, desc: token.id)
    |> maybe_limit(Keyword.get(opts, :limit))
    |> then(&Support.all(repo, &1))
    |> then(fn records -> {:ok, Enum.map(records, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  def fetch_lifecycle_token_by_id(repo, id) when is_integer(id),
    do:
      fetch_one(
        repo,
        where(
          TokenRecord,
          [token],
          token.id == ^id and token.token_type in [:access_token, :refresh_token]
        )
      )

  def list_token_family(repo, family_id) when is_binary(family_id) do
    TokenRecord
    |> where(
      [token],
      token.family_id == ^family_id and token.token_type in [:access_token, :refresh_token]
    )
    |> order_by([token], asc: token.generation, asc: token.issued_at, asc: token.id)
    |> then(&Support.all(repo, &1, sensitive: true))
    |> then(fn records -> {:ok, Enum.map(records, &TokenRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  def revoke_token_family(repo, family_id) when is_binary(family_id),
    do: revoke_active_family(repo, family_id, DateTime.utc_now(), DateTime.utc_now())

  def revoke_by_sid(_repo, nil), do: {:ok, 0}

  def revoke_by_sid(repo, sid) when is_binary(sid) do
    {count, _} =
      TokenRecord
      |> where(
        [token],
        token.sid == ^sid and is_nil(token.revoked_at) and is_nil(token.redeemed_at)
      )
      |> then(
        &Support.update_all(
          repo,
          &1,
          [set: [revoked_at: DateTime.utc_now(), updated_at: DateTime.utc_now()]],
          sensitive: true
        )
      )

    {:ok, count}
  rescue
    error -> {:error, error}
  end

  def fetch_authorization_code(repo, hash), do: fetch_hash(repo, hash, :authorization_code)

  def fetch_lifecycle_token(repo, hash),
    do: fetch_hash(repo, hash, [:access_token, :refresh_token])

  def fetch_refresh_token(repo, hash), do: fetch_hash(repo, hash, :refresh_token)

  def fetch_active_authorization_code(repo, hash) when is_binary(hash) do
    now = DateTime.utc_now()

    fetch_one(
      repo,
      where(
        TokenRecord,
        [token],
        token.token_hash == ^hash and token.token_type == :authorization_code and
          is_nil(token.redeemed_at) and is_nil(token.revoked_at) and token.expires_at > ^now
      ),
      sensitive: true
    )
  end

  def fetch_active_access_token(repo, hash) when is_binary(hash) do
    now = DateTime.utc_now()

    fetch_one(
      repo,
      where(
        TokenRecord,
        [token],
        token.token_hash == ^hash and token.token_type == :access_token and
          is_nil(token.revoked_at) and token.expires_at > ^now
      ),
      sensitive: true
    )
  end

  def revoke_lifecycle_token(repo, hash, client_id, revoked_at) do
    TransactionStore.transact(repo, fn ->
      TokenRecord
      |> where(
        [token],
        token.token_hash == ^hash and token.token_type in [:access_token, :refresh_token]
      )
      |> lock("FOR UPDATE")
      |> then(&Support.one(repo, &1, sensitive: true))
      |> revoke_record(repo, client_id, revoked_at)
    end)
  end

  def mark_authorization_code_redeemed(repo, hash, redeemed_at) do
    TransactionStore.transact(repo, fn ->
      case TokenRecord
           |> where(
             [token],
             token.token_hash == ^hash and token.token_type == :authorization_code
           )
           |> lock("FOR UPDATE")
           |> then(&Support.one(repo, &1, sensitive: true)) do
        nil ->
          TransactionStore.rollback(repo, :not_found)

        %TokenRecord{redeemed_at: %DateTime{}} ->
          TransactionStore.rollback(repo, :already_redeemed)

        record ->
          record
          |> Ecto.Changeset.change(redeemed_at: redeemed_at, updated_at: DateTime.utc_now())
          |> then(&Support.update(repo, &1, sensitive: true))
          |> unwrap(repo)
      end
    end)
  end

  def redeem_authorization_code(repo, hash, redeemed_at, %Token{} = access_token) do
    TransactionStore.transact(repo, fn ->
      case TokenRecord
           |> where(
             [token],
             token.token_hash == ^hash and token.token_type == :authorization_code
           )
           |> lock("FOR UPDATE")
           |> then(&Support.one(repo, &1, sensitive: true)) do
        nil ->
          TransactionStore.rollback(repo, :not_found)

        %TokenRecord{redeemed_at: %DateTime{}} ->
          TransactionStore.rollback(repo, :already_redeemed)

        record ->
          with {:ok, code} <-
                 record
                 |> Ecto.Changeset.change(
                   redeemed_at: redeemed_at,
                   updated_at: DateTime.utc_now()
                 )
                 |> then(&Support.update(repo, &1, sensitive: true))
                 |> map_one(),
               {:ok, access} <- store_record(repo, access_token) do
            %{authorization_code: code, access_token: access}
          else
            {:error, reason} -> TransactionStore.rollback(repo, reason)
          end
      end
    end)
  end

  def rotate_refresh_token(repo, hash, client_id, rotated_at, refresh, access),
    do: rotate_refresh_token(repo, hash, client_id, rotated_at, refresh, access, nil)

  def rotate_refresh_token(
        repo,
        hash,
        client_id,
        rotated_at,
        %Token{} = refresh,
        %Token{} = access,
        expected_cnf
      ) do
    case repo.transaction(fn ->
           rotate(repo, hash, client_id, rotated_at, refresh, access, expected_cnf)
         end) do
      {:ok, {:ok, result}} -> {:ok, result}
      {:ok, {:error, reason}} -> {:error, reason}
      {:error, reason} -> {:error, reason}
    end
  rescue
    error -> {:error, error}
  end

  defp rotate(repo, hash, client_id, at, refresh, access, cnf) do
    case TokenRecord
         |> where([token], token.token_hash == ^hash and token.token_type == :refresh_token)
         |> lock("FOR UPDATE")
         |> then(&Support.one(repo, &1, sensitive: true)) do
      nil -> {:error, :not_found}
      record -> rotate_record(repo, record, client_id, at, refresh, access, cnf)
    end
  end

  defp rotate_record(_repo, %TokenRecord{client_id: stored}, client, _at, _r, _a, _cnf)
       when stored != client, do: {:error, :client_mismatch}

  defp rotate_record(_repo, %TokenRecord{family_id: nil}, _client, _at, _r, _a, _cnf),
    do: {:error, :missing_family_id}

  defp rotate_record(
         repo,
         %TokenRecord{expires_at: expires} = record,
         client,
         at,
         refresh,
         access,
         cnf
       ) do
    if DateTime.compare(expires, at) == :gt do
      rotate_unexpired_record(repo, record, client, at, refresh, access, cnf)
    else
      {:error, :expired}
    end
  end

  defp rotate_unexpired_record(
         repo,
         %TokenRecord{redeemed_at: redeemed, revoked_at: revoked} = record,
         _client,
         at,
         _r,
         _a,
         _cnf
       )
       when not is_nil(redeemed) or not is_nil(revoked) do
    now = DateTime.utc_now()

    with {:ok, _} <-
           record
           |> Ecto.Changeset.change(
             reuse_detected_at: record.reuse_detected_at || at,
             updated_at: now
           )
           |> then(&Support.update(repo, &1, sensitive: true)),
         {:ok, _} <- revoke_family(repo, record.family_id, at, now) do
      {:error, :reuse_detected}
    else
      {:error, reason} -> repo.rollback(reason)
    end
  end

  defp rotate_unexpired_record(_repo, %TokenRecord{cnf: actual}, _client, _at, _r, _a, expected)
       when actual != expected, do: {:error, :dpop_binding_mismatch}

  defp rotate_unexpired_record(repo, record, _client, at, refresh, access, cnf) do
    with {:ok, presented} <-
           record
           |> Ecto.Changeset.change(
             redeemed_at: at,
             revoked_at: at,
             updated_at: DateTime.utc_now()
           )
           |> then(&Support.update(repo, &1, sensitive: true))
           |> map_one(),
         {:ok, stored_refresh} <- store_record(repo, rotated_refresh(record, refresh, at, cnf)),
         {:ok, stored_access} <-
           store_record(repo, rotated_access(record, stored_refresh, access, at, cnf)) do
      {:ok,
       %{
         presented_refresh_token: presented,
         refresh_token: stored_refresh,
         access_token: stored_access
       }}
    else
      {:error, reason} -> repo.rollback(reason)
    end
  end

  defp rotated_refresh(record, %Token{} = token, at, cnf),
    do: %Token{
      token
      | family_id: record.family_id,
        generation: record.generation + 1,
        parent_token_id: record.id,
        client_id: record.client_id,
        account_id: token.account_id || record.account_id,
        interaction_id: token.interaction_id || record.interaction_id,
        scopes: if(token.scopes == [], do: record.scopes, else: token.scopes),
        audience: if(token.audience == [], do: record.audience, else: token.audience),
        cnf: cnf,
        issued_at: token.issued_at || at
    }

  defp rotated_access(record, refresh, %Token{} = token, at, cnf),
    do: %Token{
      token
      | family_id: record.family_id,
        generation: refresh.generation,
        parent_token_id: refresh.id,
        client_id: record.client_id,
        account_id: token.account_id || record.account_id,
        interaction_id: token.interaction_id || record.interaction_id,
        scopes: if(token.scopes == [], do: record.scopes, else: token.scopes),
        audience: if(token.audience == [], do: record.audience, else: token.audience),
        cnf: cnf,
        issued_at: token.issued_at || at
    }

  defp revoke_record(nil, _repo, _client, _at), do: nil

  defp revoke_record(%TokenRecord{client_id: id} = record, repo, id, at),
    do:
      if(is_nil(record.revoked_at),
        do:
          record
          |> Ecto.Changeset.change(revoked_at: at, updated_at: DateTime.utc_now())
          |> then(&Support.update(repo, &1, sensitive: true))
          |> unwrap(repo),
        else: TokenRecord.to_domain(record)
      )

  defp revoke_record(%TokenRecord{}, _repo, _client, _at), do: nil

  defp revoke_family(repo, family, at, updated) do
    {count, _} =
      TokenRecord
      |> where([token], token.family_id == ^family)
      |> then(
        &Support.update_all(repo, &1, [set: [revoked_at: at, updated_at: updated]],
          sensitive: true
        )
      )

    {:ok, count}
  rescue
    error -> {:error, error}
  end

  defp revoke_active_family(repo, family, at, updated) do
    {count, _} =
      TokenRecord
      |> where([token], token.family_id == ^family and is_nil(token.revoked_at))
      |> then(
        &Support.update_all(repo, &1, [set: [revoked_at: at, updated_at: updated]],
          sensitive: true
        )
      )

    {:ok, count}
  rescue
    error -> {:error, error}
  end

  defp fetch_hash(repo, hash, type) when is_binary(hash),
    do:
      fetch_one(
        repo,
        where(
          TokenRecord,
          [token],
          token.token_hash == ^hash and token.token_type in ^List.wrap(type)
        ),
        sensitive: true
      )

  defp fetch_one(repo, query, opts \\ []),
    do:
      query
      |> then(&Support.one(repo, &1, opts))
      |> then(fn record -> {:ok, if(record, do: TokenRecord.to_domain(record))} end)

  defp store_record(repo, %Token{} = token),
    do:
      %TokenRecord{}
      |> TokenRecord.changeset(token)
      |> then(&Support.insert(repo, &1, sensitive: true))
      |> map_one()

  defp map_one({:ok, record}), do: {:ok, TokenRecord.to_domain(record)}
  defp map_one({:error, error}), do: {:error, error}
  defp unwrap({:ok, record}, _repo), do: TokenRecord.to_domain(record)
  defp unwrap({:error, error}, repo), do: repo.rollback(error)

  defp maybe_filter_account(query, value) when is_binary(value) and value != "",
    do: where(query, [token], token.account_id == ^value)

  defp maybe_filter_account(query, _), do: query

  defp maybe_filter_client(query, value) when is_binary(value) and value != "",
    do: where(query, [token], token.client_id == ^value)

  defp maybe_filter_client(query, _), do: query

  defp maybe_filter_status(query, :active, now),
    do: where(query, [token], is_nil(token.revoked_at) and token.expires_at > ^now)

  defp maybe_filter_status(query, :revoked, _),
    do: where(query, [token], not is_nil(token.revoked_at))

  defp maybe_filter_status(query, :expired, now),
    do: where(query, [token], is_nil(token.revoked_at) and token.expires_at <= ^now)

  defp maybe_filter_status(query, :reuse_detected, _),
    do: where(query, [token], not is_nil(token.reuse_detected_at))

  defp maybe_filter_status(query, _, _), do: query
  defp maybe_limit(query, value) when is_integer(value) and value > 0, do: limit(query, ^value)
  defp maybe_limit(query, _), do: query
end
