defmodule Lockspire.ClientLifecycle do
  @moduledoc false

  alias Lockspire.Domain.Client
  alias Lockspire.Observability
  alias Lockspire.Storage.Ecto.Repository

  @spec create_dcr(%{required(:client) => Client.t(), required(:actor) => map()}) ::
          {:ok, Client.t()} | {:error, term()}
  def create_dcr(%{client: %Client{} = client, actor: actor}) when is_map(actor) do
    audit_event = %{
      action: :dcr_client_created,
      outcome: :succeeded,
      reason_code: :dcr_client_created,
      actor: actor,
      resource: %{type: :client, id: client.client_id},
      metadata: %{client_id: client.client_id, provenance: client.provenance}
    }

    case Repository.transact_with_audit(audit_event, fn -> Repository.register_client(client) end) do
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

  @spec persist_direct(Client.t()) :: {:ok, Client.t()} | {:error, term()}
  def persist_direct(%Client{} = client), do: Repository.register_client(client)

  @doc false
  @spec update_operator(Client.t(), map()) :: {:ok, Client.t()} | {:error, term()}
  def update_operator(%Client{} = client, attrs) when is_map(attrs),
    do: Repository.update_client(client, attrs)

  @doc false
  @spec enable_operator(Client.t()) :: {:ok, Client.t()} | {:error, term()}
  def enable_operator(%Client{} = client),
    do: Repository.set_client_active(client, true, %{disabled_at: nil, disabled_by: nil})

  @doc false
  @spec rotate_operator_secret(Client.t(), map(), DateTime.t(), map()) ::
          {:ok, Client.t()} | {:error, term()}
  def rotate_operator_secret(
        %Client{} = client,
        secret_material,
        %DateTime{} = rotated_at,
        audit_event
      )
      when is_map(secret_material) and is_map(audit_event) do
    transact_with_audit(
      fn ->
        Repository.rotate_client_secret(
          client,
          secret_material.client_secret_hash,
          secret_material.client_secret_jwt_verifier_encrypted,
          rotated_at
        )
      end,
      fn _updated_client -> audit_event end
    )
  end

  @doc false
  @spec disable_operator(Client.t(), DateTime.t(), String.t() | nil, map()) ::
          {:ok, Client.t()} | {:error, term()}
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
          {:ok, Client.t()} | {:error, term()}
  def rotate_registration_access_token(%Client{} = client, new_rat_hash, audit_event)
      when is_binary(new_rat_hash) and is_map(audit_event) do
    Repository.rotate_registration_access_token(client, new_rat_hash, audit_event)
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

  @spec replace_dcr(Client.t(), map(), String.t()) :: {:ok, Client.t()} | {:error, term()}
  def replace_dcr(%Client{} = client, metadata, new_rat_hash)
      when is_map(metadata) and is_binary(new_rat_hash) do
    updated_client = Lockspire.ClientMetadata.apply_dcr_metadata(client, metadata)

    Repository.replace_client_registration(client, updated_client, new_rat_hash, %{
      action: :dcr_management_updated,
      outcome: :success,
      actor: %{type: :self_registered_client, id: client.client_id},
      resource: %{type: :client, id: client.client_id},
      metadata: %{}
    })
  end

  @spec disable_dcr(Client.t()) :: {:ok, Client.t()} | {:error, term()}
  def disable_dcr(%Client{} = client) do
    audit_event = %{
      action: :client_disabled,
      outcome: :succeeded,
      reason_code: :client_disabled,
      actor: %{type: :self_registered_client, id: client.client_id},
      resource: %{type: :client, id: client.client_id},
      metadata: %{disabled_by: "dcr_self_delete"}
    }

    Repository.transact_with_audit(audit_event, fn ->
      Repository.set_client_active(client, false, %{
        disabled_at: DateTime.utc_now(),
        disabled_by: "dcr_self_delete"
      })
    end)
  end

  defp append_audit_event(build_audit_event, result) do
    case Repository.append_audit_event(build_audit_event.(result)) do
      {:ok, _event} -> result
      {:error, reason} -> {:error, reason}
    end
  end
end
