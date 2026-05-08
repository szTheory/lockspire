defmodule Lockspire.Protocol.MessageSigningProfile do
  @moduledoc """
  Canonical readiness and transition rules for the strict message-signing profile.
  """

  alias Lockspire.Storage.Ecto.Repository

  @type prerequisite_reason ::
          :missing_compliant_active_key | :missing_compliant_publishable_key

  @type readiness :: %{
          ready?: boolean(),
          profile: :fapi_2_0_message_signing,
          prerequisite_reasons: [prerequisite_reason()],
          remediation: [String.t()]
        }

  @strict_profile :fapi_2_0_message_signing

  @spec readiness() :: readiness() | {:error, term()}
  def readiness do
    case Repository.validate_message_signing_readiness() do
      :ok ->
        %{
          ready?: true,
          profile: @strict_profile,
          prerequisite_reasons: [],
          remediation: []
        }

      {:error, reason}
      when reason in [:missing_compliant_active_key, :missing_compliant_publishable_key] ->
        %{
          ready?: false,
          profile: @strict_profile,
          prerequisite_reasons: [reason],
          remediation: remediation(reason)
        }

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec validate_transition(atom(), atom()) ::
          :ok | {:error, prerequisite_reason()} | {:error, term()}
  def validate_transition(@strict_profile, @strict_profile), do: :ok

  def validate_transition(_old_profile, @strict_profile) do
    case readiness() do
      %{ready?: true} -> :ok
      %{prerequisite_reasons: [reason | _]} -> {:error, reason}
      {:error, reason} -> {:error, reason}
    end
  end

  def validate_transition(_old_profile, _new_profile), do: :ok

  defp remediation(:missing_compliant_active_key) do
    ["Activate an ES256 or PS256 issuer signing key before enabling strict message signing."]
  end

  defp remediation(:missing_compliant_publishable_key) do
    ["Publish an ES256 or PS256 issuer signing key before enabling strict message signing."]
  end
end
