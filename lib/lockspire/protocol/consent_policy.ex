defmodule Lockspire.Protocol.ConsentPolicy do
  @moduledoc """
  Pure remembered-consent rules for authorization interactions.
  """

  alias Lockspire.Domain.ConsentGrant

  @spec reusable_grant([ConsentGrant.t()], [String.t()], [String.t()]) ::
          {:reuse, ConsentGrant.t()} | :consent_required
  def reusable_grant(grants, requested_scopes, prompt)
      when is_list(grants) and is_list(requested_scopes) and is_list(prompt) do
    if "consent" in prompt do
      :consent_required
    else
      requested = MapSet.new(requested_scopes)

      case Enum.find(grants, &reusable_grant?(&1, requested)) do
        nil -> :consent_required
        grant -> {:reuse, grant}
      end
    end
  end

  @spec approval_kind(boolean()) :: :remembered | :one_time
  def approval_kind(true), do: :remembered
  def approval_kind(false), do: :one_time

  defp reusable_grant?(
         %ConsentGrant{
           status: :active,
           kind: :remembered,
           revoked_at: nil,
           scopes: granted_scopes
         },
         requested
       ) do
    MapSet.subset?(requested, MapSet.new(granted_scopes))
  end

  defp reusable_grant?(_grant, _requested), do: false
end
