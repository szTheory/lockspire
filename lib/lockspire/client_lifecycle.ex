defmodule Lockspire.ClientLifecycle do
  @moduledoc false

  alias Lockspire.Domain.Client
  alias Lockspire.Observability
  alias Lockspire.Storage.ClientLifetime
  alias Lockspire.Storage.Ecto.Repository

  @type result :: {:ok, Client.t()} | {:error, term()}

  @spec create_dcr(%{required(:client) => Client.t(), required(:actor) => map()}) ::
          result()
  def create_dcr(%{client: %Client{} = client, actor: actor}) when is_map(actor) do
    audit_event = %{
      action: :dcr_client_created,
      outcome: :succeeded,
      reason_code: :dcr_client_created,
      actor: actor,
      resource: %{type: :client, id: client.client_id},
      metadata: %{client_id: client.client_id, provenance: client.provenance}
    }

    result =
      with {:ok, stores} <- ClientLifetime.configured() do
        stores.transaction_store.transact(fn ->
          with {:ok, persisted} <- stores.client_store.register_client(client),
               {:ok, _event} <- Repository.append_audit_event(audit_event) do
            {:ok, persisted}
          else
            {:error, reason} -> stores.transaction_store.rollback(reason)
          end
        end)
      end

    case result do
      {:ok, %Client{} = persisted} ->
        Observability.emit(:dcr, :client_created, %{}, %{
          actor_type: actor[:type],
          actor_id: actor[:id],
          client_id: persisted.client_id,
          provenance: persisted.provenance
        })

        {:ok, persisted}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec persist_direct(Client.t()) :: result()
  def persist_direct(%Client{} = client), do: Repository.register_client(client)

  @doc false
  @spec update_operator(Client.t(), map()) :: result()
  def update_operator(%Client{} = client, attrs) when is_map(attrs),
    do: Repository.update_client(client, attrs)

  @doc false
  @spec enable_operator(Client.t()) :: result()
  def enable_operator(%Client{} = client),
    do: Repository.set_client_active(client, true, %{disabled_at: nil, disabled_by: nil})

  @doc false
  @spec rotate_operator_secret(
          Client.t(),
          map(),
          DateTime.t() | (-> DateTime.t()),
          map() | (Client.t() -> map())
        ) ::
          result()
  def rotate_operator_secret(
        %Client{} = client,
        secret_material,
        rotated_at,
        build_audit_event
      )
      when is_map(secret_material) and
             (is_struct(rotated_at, DateTime) or is_function(rotated_at, 0)) and
             (is_map(build_audit_event) or is_function(build_audit_event, 1)) do
    with {:ok, stores} <- ClientLifetime.configured(),
         :ok <- ClientLifetime.ensure_secret_rotation_available(stores.client_store) do
      rotate_with_stores(stores, client, secret_material, rotated_at, build_audit_event)
    end
  end

  defp rotate_with_stores(stores, client, secret_material, rotated_at, build_audit_event) do
    stores.transaction_store.transact(fn ->
      case stores.client_store.rotate_client_secret(
             client,
             secret_material.client_secret_hash,
             secret_material.client_secret_jwt_verifier_encrypted,
             rotated_at
           ) do
        {:ok, %Client{} = updated} ->
          audit_event = build_secret_rotation_audit_event(build_audit_event, updated)

          case Repository.append_audit_event(audit_event) do
            {:ok, _event} -> {:ok, updated}
            {:error, reason} -> stores.transaction_store.rollback(reason)
          end

        {:error, reason} ->
          stores.transaction_store.rollback(reason)
      end
    end)
  end

  defp build_secret_rotation_audit_event(event, _updated) when is_map(event), do: event
  defp build_secret_rotation_audit_event(builder, updated), do: builder.(updated)

  @doc false
  @spec disable_operator(Client.t(), DateTime.t(), String.t() | nil, map()) ::
          result()
  def disable_operator(%Client{} = client, %DateTime{} = disabled_at, disabled_by, audit_event)
      when (is_binary(disabled_by) or is_nil(disabled_by)) and is_map(audit_event) do
    transact_with_audit(
      fn ->
        Repository.set_client_active(client, false, %{
          disabled_at: disabled_at,
          disabled_by: disabled_by
        })
      end,
      fn _updated_client -> audit_event end
    )
  end

  @doc false
  @spec rotate_registration_access_token(Client.t(), String.t(), map()) ::
          result()
  def rotate_registration_access_token(%Client{} = client, new_rat_hash, audit_event)
      when is_binary(new_rat_hash) and is_map(audit_event) do
    with {:ok, stores} <- ClientLifetime.configured() do
      stores.client_store.rotate_registration_access_token(client, new_rat_hash, audit_event)
    end
  end

  @doc false
  @spec transact_with_audit((-> {:ok, term()} | {:error, term()}), (term() -> map())) ::
          {:ok, term()} | {:error, term()}
  def transact_with_audit(fun, build_audit_event)
      when is_function(fun, 0) and is_function(build_audit_event, 1) do
    Repository.transact(fn ->
      case fun.() do
        {:ok, result} -> append_audit_event(build_audit_event, result)
        {:error, reason} -> {:error, reason}
      end
    end)
  end

  @spec replace_dcr(Client.t(), map(), String.t()) :: result()
  def replace_dcr(%Client{} = client, metadata, new_rat_hash)
      when is_map(metadata) and is_binary(new_rat_hash) do
    replace_dcr(
      client,
      metadata,
      new_rat_hash,
      client.registration_access_token_expires_at,
      client.updated_at || DateTime.utc_now() |> DateTime.truncate(:second)
    )
  end

  @doc false
  @spec replace_dcr(Client.t(), map(), String.t(), DateTime.t() | nil, DateTime.t()) :: result()
  def replace_dcr(%Client{} = client, metadata, new_rat_hash, deadline, %DateTime{} = updated_at)
      when is_map(metadata) and is_binary(new_rat_hash) and
             (is_nil(deadline) or is_struct(deadline, DateTime)) do
    updated_client = Lockspire.ClientMetadata.apply_dcr_metadata(client, metadata)

    updated_client = %{
      updated_client
      | registration_access_token_expires_at: deadline,
        updated_at: updated_at
    }

    with {:ok, stores} <- ClientLifetime.configured() do
      stores.client_store.replace_client_registration(client, updated_client, new_rat_hash, %{
        action: :dcr_management_updated,
        outcome: :success,
        actor: %{type: :self_registered_client, id: client.client_id},
        resource: %{type: :client, id: client.client_id},
        metadata: %{rotated_at: updated_at}
      })
    end
  end

  @spec disable_dcr(Client.t()) :: result()
  def disable_dcr(%Client{} = client),
    do: disable_dcr(client, DateTime.utc_now())

  @spec disable_dcr(Client.t(), DateTime.t()) :: result()
  def disable_dcr(%Client{} = client, %DateTime{} = disabled_at) do
    audit_event = %{
      action: :client_disabled,
      outcome: :succeeded,
      reason_code: :client_disabled,
      actor: %{type: :self_registered_client, id: client.client_id},
      resource: %{type: :client, id: client.client_id},
      metadata: %{disabled_by: "dcr_self_delete", disabled_at: disabled_at}
    }

    with {:ok, stores} <- ClientLifetime.configured() do
      stores.transaction_store.transact(fn ->
        with {:ok, updated} <-
               stores.client_store.set_client_active(client, false, %{
                 disabled_at: disabled_at,
                 disabled_by: "dcr_self_delete"
               }),
             {:ok, _event} <- Repository.append_audit_event(audit_event) do
          {:ok, updated}
        else
          {:error, reason} -> stores.transaction_store.rollback(reason)
        end
      end)
    end
  end

  defp append_audit_event(build_audit_event, result) do
    case Repository.append_audit_event(build_audit_event.(result)) do
      {:ok, _event} -> result
      {:error, reason} -> {:error, reason}
    end
  end
end
