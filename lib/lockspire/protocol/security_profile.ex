defmodule Lockspire.Protocol.SecurityProfile do
  @moduledoc """
  Resolves effective security profile from server-wide defaults and client overrides.
  """

  alias Lockspire.Domain.ServerPolicy

  @type mode :: :inherit | :fapi_2_0_security | :none

  defmodule Resolved do
    @moduledoc false

    @type t :: %__MODULE__{
            global_profile: ServerPolicy.security_profile(),
            client_profile: Lockspire.Protocol.SecurityProfile.mode(),
            effective_profile: ServerPolicy.security_profile(),
            fapi_2_0_security?: boolean()
          }

    defstruct global_profile: :none,
              client_profile: :inherit,
              effective_profile: :none,
              fapi_2_0_security?: false
  end

  @spec resolve_effective_profile(ServerPolicy.t(), struct() | map() | nil) :: struct()
  def resolve_effective_profile(%ServerPolicy{} = server_policy, client) do
    client_profile = normalize_client_profile(client)
    effective_profile = effective_profile(server_policy.security_profile, client_profile)

    %Resolved{
      global_profile: server_policy.security_profile,
      client_profile: client_profile,
      effective_profile: effective_profile,
      fapi_2_0_security?: effective_profile == :fapi_2_0_security
    }
  end

  defp normalize_client_profile(nil), do: :inherit

  defp normalize_client_profile(client) do
    case Map.get(client, :security_profile, :inherit) do
      :fapi_2_0_security -> :fapi_2_0_security
      :none -> :none
      _other -> :inherit
    end
  end

  defp effective_profile(global_profile, :inherit), do: global_profile
  defp effective_profile(_global_profile, :fapi_2_0_security), do: :fapi_2_0_security
  defp effective_profile(_global_profile, :none), do: :none

  @spec allowed_signing_algorithms(ServerPolicy.security_profile()) :: [String.t()]
  def allowed_signing_algorithms(:fapi_2_0_security), do: ["ES256", "PS256"]
  def allowed_signing_algorithms(:none), do: ["RS256", "ES256", "PS256", "EdDSA"]
end
