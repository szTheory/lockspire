defmodule Lockspire.Storage.Ecto.Repository.TransactionStore do
  @moduledoc false

  @spec transact(module(), (-> term())) :: {:ok, term()} | {:error, term()}
  def transact(repo, fun) when is_function(fun, 0) do
    case repo.transaction(fn -> run(repo, fun) end) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  rescue
    error -> {:error, error}
  end

  @spec rollback(module(), term()) :: no_return()
  def rollback(repo, reason), do: repo.rollback(reason)

  defp run(repo, fun) do
    case fun.() do
      {:ok, result} -> result
      {:error, reason} -> rollback(repo, reason)
      result -> result
    end
  end
end
