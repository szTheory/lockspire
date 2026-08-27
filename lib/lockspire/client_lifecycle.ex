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
end
