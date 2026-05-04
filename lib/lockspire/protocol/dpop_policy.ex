defmodule Lockspire.Protocol.DpopPolicy do
  @moduledoc """
  Resolves effective DPoP policy from server-wide defaults and client overrides.
  """

  alias Lockspire.Domain.ServerPolicy

  @type mode :: :inherit | :bearer | :dpop

  defmodule Resolved do
    @moduledoc false

    @type t :: %__MODULE__{
            global_policy: ServerPolicy.dpop_policy(),
            client_policy: Lockspire.Protocol.DpopPolicy.mode(),
            effective_policy: ServerPolicy.dpop_policy(),
            dpop_required?: boolean()
          }

    defstruct global_policy: :bearer,
              client_policy: :inherit,
              effective_policy: :bearer,
              dpop_required?: false
  end

  @spec resolve_effective_policy(ServerPolicy.t(), struct() | map() | nil) ::
          {:ok, struct()} | {:error, :invalid_server_policy | :invalid_client_policy}
  def resolve_effective_policy(%ServerPolicy{} = server_policy, client) do
    with {:ok, global_policy} <- normalize_server_policy(server_policy.dpop_policy),
         {:ok, client_policy} <- normalize_client_policy(client) do
      effective_policy = effective_policy(global_policy, client_policy)

      {:ok,
       %Resolved{
         global_policy: global_policy,
         client_policy: client_policy,
         effective_policy: effective_policy,
         dpop_required?: effective_policy == :dpop
       }}
    end
  end

  defp normalize_server_policy(:bearer), do: {:ok, :bearer}
  defp normalize_server_policy(:dpop), do: {:ok, :dpop}
  defp normalize_server_policy(_other), do: {:error, :invalid_server_policy}

  defp normalize_client_policy(nil), do: {:ok, :inherit}

  defp normalize_client_policy(client) do
    case Map.get(client, :dpop_policy, :inherit) do
      :inherit -> {:ok, :inherit}
      :bearer -> {:ok, :bearer}
      :dpop -> {:ok, :dpop}
      _other -> {:error, :invalid_client_policy}
    end
  end

  defp effective_policy(global_policy, :inherit), do: global_policy
  defp effective_policy(_global_policy, :bearer), do: :bearer
  defp effective_policy(_global_policy, :dpop), do: :dpop
end
