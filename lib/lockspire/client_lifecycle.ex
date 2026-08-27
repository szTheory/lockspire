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
        Observability.emit(:dcr, :client_created, %{}, %{actor_type: actor[:type], actor_id: actor[:id], client_id: persisted.client_id, provenance: persisted.provenance})
        {:ok, persisted}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec persist_direct(Client.t()) :: {:ok, Client.t()} | {:error, term()}
  def persist_direct(%Client{} = client), do: Repository.register_client(client)
end
