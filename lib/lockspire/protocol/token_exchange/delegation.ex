defmodule Lockspire.Protocol.TokenExchange.Delegation do
  @moduledoc """
  Handles token exchange delegation logic, including depth limits.
  """

  @doc """
  Checks if adding another delegation layer would exceed the maximum depth.
  Returns `:ok` or `{:error, "invalid_request", "max_delegation_depth_exceeded"}`.
  """
  def check_depth(actor_token_claims, client, policy) do
    max_depth = resolve_max_depth(client, policy)
    current_depth = count_act_depth(actor_token_claims)

    if current_depth + 1 > max_depth do
      {:error, "invalid_request", "max_delegation_depth_exceeded"}
    else
      :ok
    end
  end

  defp resolve_max_depth(client, policy) do
    client_depth = Map.get(client || %{}, :max_delegation_depth)
    policy_depth = Map.get(policy || %{}, :max_delegation_depth)

    client_depth || policy_depth || 3
  end

  defp count_act_depth(claims) when is_map(claims) do
    case Map.get(claims, "act") do
      nil -> 0
      nested_act when is_map(nested_act) -> 1 + count_act_depth(nested_act)
      _ -> 0 # invalid act claim, shouldn't increase depth but validator should handle format
    end
  end

  defp count_act_depth(_), do: 0
end
