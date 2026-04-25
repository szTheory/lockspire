defmodule Lockspire.Protocol.ParPolicy do
  @moduledoc """
  Resolves effective PAR policy from server-wide defaults and client overrides.
  """

  alias Lockspire.Domain.ServerPolicy

  @type mode :: :inherit | :optional | :required

  defmodule Resolved do
    @moduledoc false

    @type t :: %__MODULE__{
            global_policy: ServerPolicy.par_policy(),
            client_policy: Lockspire.Protocol.ParPolicy.mode(),
            effective_policy: ServerPolicy.par_policy(),
            par_required?: boolean()
          }

    defstruct global_policy: :optional,
              client_policy: :inherit,
              effective_policy: :optional,
              par_required?: false
  end

  @spec resolve_effective_policy(ServerPolicy.t(), struct() | map() | nil) :: Resolved.t()
  def resolve_effective_policy(%ServerPolicy{} = server_policy, client) do
    client_policy = normalize_client_policy(client)
    effective_policy = effective_policy(server_policy.par_policy, client_policy)

    %Resolved{
      global_policy: server_policy.par_policy,
      client_policy: client_policy,
      effective_policy: effective_policy,
      par_required?: effective_policy == :required
    }
  end

  defp normalize_client_policy(nil), do: :inherit

  defp normalize_client_policy(client) do
    case Map.get(client, :par_policy, :inherit) do
      :required -> :required
      :optional -> :optional
      _other -> :inherit
    end
  end

  defp effective_policy(global_policy, :inherit), do: global_policy
  defp effective_policy(_global_policy, :required), do: :required
  defp effective_policy(_global_policy, :optional), do: :optional
end
