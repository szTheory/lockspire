defmodule Lockspire.Admin.ServerPolicy do
  @moduledoc """
  Query and command boundary for Lockspire server policy.
  """

  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Storage.Ecto.Repository

  @type error_detail :: %{field: atom(), reason: atom(), detail: term()}

  @spec get_server_policy() :: {:ok, ServerPolicy.t()} | {:error, term()}
  def get_server_policy do
    Repository.get_server_policy()
  end

  @spec put_server_policy(atom() | String.t()) ::
          {:ok, ServerPolicy.t()} | {:error, [error_detail()]} | {:error, term()}
  def put_server_policy(mode) do
    with {:ok, normalized_mode} <- normalize_par_policy(mode) do
      Repository.put_server_policy(%ServerPolicy{par_policy: normalized_mode})
    end
  end

  defp normalize_par_policy(:optional), do: {:ok, :optional}
  defp normalize_par_policy(:required), do: {:ok, :required}

  defp normalize_par_policy(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "optional" -> {:ok, :optional}
      "required" -> {:ok, :required}
      _other -> invalid_par_policy(value)
    end
  end

  defp normalize_par_policy(value), do: invalid_par_policy(value)

  defp invalid_par_policy(value) do
    {:error, [%{field: :par_policy, reason: :invalid_par_policy, detail: value}]}
  end
end
