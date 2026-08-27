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

  @doc """
  Finds an existing active grant that a new approval would merely duplicate.

  Distinct from `reusable_grant/3`, which decides whether consent can be
  skipped. This runs *after* the subject has approved — `prompt=consent`
  deliberately re-shows the consent screen, so an approval for a client the
  account already remembers is an ordinary occurrence, not a skipped one.

  Only exact duplicates match: same account and client, already-granted scopes
  covering the requested set, and identical authorization details. A broader
  scope set or different RAR details is a genuinely new grant.
  """
  @spec duplicate_grant([ConsentGrant.t()], ConsentGrant.t()) ::
          {:reuse, ConsentGrant.t()} | :none
  def duplicate_grant(grants, %ConsentGrant{} = candidate) when is_list(grants) do
    case Enum.find(grants, &duplicate_grant?(&1, candidate)) do
      nil -> :none
      grant -> {:reuse, grant}
    end
  end

  defp duplicate_grant?(
         %ConsentGrant{status: :active, kind: :remembered, revoked_at: nil} = existing,
         %ConsentGrant{kind: :remembered} = candidate
       ) do
    existing.account_id == candidate.account_id and
      existing.client_id == candidate.client_id and
      existing.authorization_details == candidate.authorization_details and
      MapSet.subset?(MapSet.new(candidate.scopes), MapSet.new(existing.scopes))
  end

  defp duplicate_grant?(_existing, _candidate), do: false

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
