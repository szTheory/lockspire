defmodule Lockspire.Protocol.TokenExchange.Internal.GrantPersistence do
  @moduledoc false

  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenResult.Error

  @doc false
  @spec transact_with_audit(Dependencies.t(), (-> term())) :: {:ok, term()} | {:error, term()}
  def transact_with_audit(%Dependencies{} = dependencies, operation)
      when is_function(operation, 0) do
    dependencies.transaction_store.transact(fn ->
      operation.()
      |> append_audit_events(dependencies.audit_store)
    end)
    |> normalize_transaction()
  end

  @doc false
  @spec transact_with_audit(module(), module(), map(), (-> term())) :: term()
  def transact_with_audit(transaction_store, audit_store, audit_event, operation)
      when is_function(operation, 0) do
    transaction_store.transact(fn ->
      case operation.() do
        {:error, _reason} = error ->
          error

        result ->
          case audit_store.append_audit_event(audit_event) do
            {:ok, _event} -> result
            {:error, reason} -> {:error, reason}
          end
      end
    end)
  end

  defp append_audit_events({:error, reason}, _audit_store), do: {:error, reason}

  defp append_audit_events({tag, value, events}, audit_store) when tag in [:ok, :durable_error] do
    case append_all(audit_store, events) do
      :ok -> {tag, value}
      {:error, reason} -> {:error, reason}
    end
  end

  defp append_all(_audit_store, []), do: :ok

  defp append_all(audit_store, [event | rest]) do
    with {:ok, _} <- audit_store.append_audit_event(event) do
      append_all(audit_store, rest)
    end
  end

  defp normalize_transaction({:ok, {:durable_error, %Error{} = error}}), do: {:error, error}
  defp normalize_transaction({:ok, result}), do: {:ok, result}
  defp normalize_transaction({:error, %Error{} = error}), do: {:error, error}
  defp normalize_transaction({:error, reason}), do: {:error, reason}
end
