defmodule Lockspire.Protocol.Discovery.AuthorizationResponseCapabilities do
  @moduledoc """
  Publishes truthful authorization-response discovery metadata from mounted surfaces
  and the effective issuer signing posture.
  """

  alias Lockspire.Protocol.SecurityProfile

  @base_response_modes ["query", "fragment", "form_post"]
  @jarm_response_modes ["jwt", "query.jwt", "fragment.jwt", "form_post.jwt"]
  @authorization_encryption_alg_values_supported ["RSA-OAEP-256", "ECDH-ES"]
  @authorization_encryption_enc_values_supported ["A256GCM", "A128GCM"]

  @spec metadata(map(), atom()) :: map()
  def metadata(endpoint_metadata, security_profile) when is_map(endpoint_metadata) do
    if authorization_surface_mounted?(endpoint_metadata) do
      %{
        "response_modes_supported" => @base_response_modes ++ @jarm_response_modes,
        "authorization_signing_alg_values_supported" =>
          SecurityProfile.allowed_signing_algorithms(security_profile),
        "authorization_encryption_alg_values_supported" =>
          @authorization_encryption_alg_values_supported,
        "authorization_encryption_enc_values_supported" =>
          @authorization_encryption_enc_values_supported
      }
    else
      %{"response_modes_supported" => @base_response_modes}
    end
  end

  defp authorization_surface_mounted?(endpoint_metadata) do
    Map.has_key?(endpoint_metadata, "authorization_endpoint")
  end
end
