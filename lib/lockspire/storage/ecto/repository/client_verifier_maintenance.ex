defmodule Lockspire.Storage.Ecto.Repository.ClientVerifierMaintenance do
  @moduledoc false

  import Ecto.Query

  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.Repository.Support

  @page_min 1
  @page_max 500
  @safe_error :client_secret_verifier_maintenance_failed

  @spec verifier_maintenance_contract(module()) :: {:ok, map()}
  def verifier_maintenance_contract(repository) do
    authority = repository.transaction_authority()

    {:ok,
     %{
       version: 1,
       transaction_authority: authority,
       participants: %{
         client_store: repository,
         transaction_store: repository,
         audit_store: repository
       }
     }}
  rescue
    _ -> {:error, :client_secret_verifier_maintenance_authority_mismatch}
  end

  @spec verifier_inventory_page(module(), nil | String.t(), integer()) ::
          {:ok, %{clients: [Client.t()], next_cursor: String.t() | nil, complete?: boolean()}}
          | {:error, atom()}
  def verifier_inventory_page(repository, after_client_id, limit) do
    with :ok <- validate_cursor(after_client_id),
         :ok <- validate_limit(limit),
         :ok <- ensure_utf8_database(repository) do
      query =
        from(client in ClientRecord,
          order_by: fragment("? COLLATE \"C\"", client.client_id),
          limit: ^(limit + 1)
        )
        |> after_cursor(after_client_id)

      rows = Support.all(repository, query, sensitive: true)
      {page, remainder} = Enum.split(rows, limit)
      has_more? = remainder != []
      clients = Enum.map(page, &ClientRecord.to_domain/1)
      next_cursor = if has_more?, do: List.last(clients).client_id, else: nil

      {:ok, %{clients: clients, next_cursor: next_cursor, complete?: not has_more?}}
    else
      {:error, reason} -> {:error, reason}
    end
  rescue
    _ -> {:error, :client_secret_verifier_inventory_unreadable}
  catch
    _, _ -> {:error, :client_secret_verifier_inventory_unreadable}
  end

  @spec compare_and_rewrap(module(), String.t(), String.t(), String.t(), String.t(), map()) ::
          {:ok, :changed | :already_current | :material_conflict} | {:error, atom()}
  def compare_and_rewrap(
        repository,
        client_id,
        expected_hash,
        expected_verifier,
        replacement,
        audit_attrs
      ) do
    cond do
      not repository.in_transaction?() ->
        {:error, @safe_error}

      not valid_inputs?(client_id, expected_hash, expected_verifier, replacement, audit_attrs) ->
        {:error, @safe_error}

      true ->
        compare_locked_row(
          repository,
          client_id,
          expected_hash,
          expected_verifier,
          replacement,
          audit_attrs
        )
    end
  rescue
    _ -> {:error, @safe_error}
  catch
    _, _ -> {:error, @safe_error}
  end

  defp compare_locked_row(
         repository,
         client_id,
         expected_hash,
         expected_verifier,
         replacement,
         audit_attrs
       ) do
    query =
      from(client in ClientRecord,
        where: client.client_id == ^client_id,
        lock: "FOR UPDATE"
      )

    case Support.one(repository, query, sensitive: true) do
      nil ->
        {:error, :client_secret_verifier_client_not_found}

      %ClientRecord{} = current
      when current.client_secret_hash == expected_hash and
             current.client_secret_jwt_verifier_encrypted == replacement ->
        {:ok, :already_current}

      %ClientRecord{} = current
      when current.client_secret_hash == expected_hash and
             current.client_secret_jwt_verifier_encrypted == expected_verifier ->
        update_and_audit(
          repository,
          current,
          expected_hash,
          expected_verifier,
          replacement,
          audit_attrs
        )

      %ClientRecord{} ->
        {:ok, :material_conflict}
    end
  rescue
    _ -> {:error, @safe_error}
  end

  defp update_and_audit(
         repository,
         current,
         expected_hash,
         expected_verifier,
         replacement,
         audit_attrs
       ) do
    query =
      from(client in ClientRecord,
        where:
          client.id == ^current.id and client.client_secret_hash == ^expected_hash and
            client.client_secret_jwt_verifier_encrypted == ^expected_verifier
      )

    case Support.update_all(
           repository,
           query,
           [set: [client_secret_jwt_verifier_encrypted: replacement]],
           sensitive: true
         ) do
      {1, _} ->
        case Lockspire.Storage.Ecto.Repository.append_audit_event(audit_attrs) do
          {:ok, _event} -> {:ok, :changed}
          {:error, _reason} -> {:error, @safe_error}
          _ -> {:error, @safe_error}
        end

      {0, _} ->
        {:ok, :material_conflict}

      _ ->
        {:error, @safe_error}
    end
  end

  defp after_cursor(query, nil), do: query

  defp after_cursor(query, cursor) do
    from(client in query,
      where: fragment(~s|? COLLATE "C" > ? COLLATE "C"|, client.client_id, ^cursor)
    )
  end

  defp ensure_utf8_database(repository) do
    case Ecto.Adapters.SQL.query(
           repository,
           "SELECT current_setting('server_encoding')",
           [],
           log: false,
           telemetry_event: nil
         ) do
      {:ok, %{rows: [["UTF8"]]}} -> :ok
      {:ok, _result} -> {:error, :client_secret_verifier_inventory_unreadable}
      {:error, _reason} -> {:error, :client_secret_verifier_inventory_unreadable}
    end
  rescue
    _ -> {:error, :client_secret_verifier_inventory_unreadable}
  catch
    _, _ -> {:error, :client_secret_verifier_inventory_unreadable}
  end

  defp validate_cursor(nil), do: :ok

  defp validate_cursor(cursor)
       when is_binary(cursor) and cursor != "" do
    if String.valid?(cursor),
      do: :ok,
      else: {:error, :client_secret_verifier_inventory_invalid_cursor}
  end

  defp validate_cursor(_),
    do: {:error, :client_secret_verifier_inventory_invalid_cursor}

  defp validate_limit(limit) when is_integer(limit) and limit >= @page_min and limit <= @page_max,
    do: :ok

  defp validate_limit(_),
    do: {:error, :client_secret_verifier_inventory_invalid_limit}

  defp valid_inputs?(client_id, hash, expected, replacement, attrs) do
    valid_rewrap_values?(client_id, hash, expected, replacement) and valid_audit_attrs?(attrs)
  end

  defp valid_rewrap_values?(client_id, hash, expected, replacement) do
    Enum.all?([client_id, hash, expected, replacement], &is_binary/1)
  end

  defp valid_audit_attrs?(attrs) when is_map(attrs) do
    allowed = [:action, :outcome, :actor, :resource, :metadata]

    Map.take(attrs, allowed) == attrs and attrs[:action] == :client_secret_verifier_rewrapped and
      attrs[:outcome] == :succeeded and valid_audit_metadata?(attrs[:metadata])
  end

  defp valid_audit_attrs?(_attrs), do: false

  defp valid_audit_metadata?(metadata) when is_map(metadata) do
    Map.keys(metadata) -- [:old_key_id, :new_key_id, :maintenance_at] == []
  end

  defp valid_audit_metadata?(_metadata), do: false
end
