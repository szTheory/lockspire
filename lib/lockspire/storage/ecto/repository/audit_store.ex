defmodule Lockspire.Storage.Ecto.Repository.AuditStore do
  @moduledoc false

  alias Lockspire.Audit.Event
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository.Support
  alias Lockspire.Storage.Ecto.Repository.TransactionStore

  @spec append_audit_event(module(), Event.t() | map()) :: {:ok, Event.t()} | {:error, term()}
  def append_audit_event(repo, %Event{} = event) do
    %AuditEventRecord{}
    |> AuditEventRecord.changeset(event)
    |> then(&Support.insert(repo, &1, sensitive: true))
    |> map_one(&AuditEventRecord.to_domain/1)
  end

  def append_audit_event(repo, attrs) when is_map(attrs) do
    attrs
    |> Event.normalize()
    |> then(&append_audit_event(repo, &1))
  rescue
    error -> {:error, error}
  end

  @spec transact_with_audit(module(), Event.t() | map(), (-> term())) ::
          {:ok, term()} | {:error, term()}
  def transact_with_audit(repo, audit_event, fun) when is_function(fun, 0) do
    TransactionStore.transact(repo, fn ->
      result =
        case fun.() do
          {:ok, value} -> value
          {:error, reason} -> TransactionStore.rollback(repo, reason)
          value -> value
        end

      case append_audit_event(repo, audit_event) do
        {:ok, _event} -> result
        {:error, reason} -> TransactionStore.rollback(repo, reason)
      end
    end)
  end

  defp map_one({:ok, record}, mapper), do: {:ok, mapper.(record)}
  defp map_one({:error, error}, _mapper), do: {:error, error}
end
