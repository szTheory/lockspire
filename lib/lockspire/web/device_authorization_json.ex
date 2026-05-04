defmodule Lockspire.Web.DeviceAuthorizationJSON do
  @moduledoc false

  alias Lockspire.Protocol.DeviceAuthorization.Error
  alias Lockspire.Protocol.DeviceAuthorization.Success

  @spec success_response(Success.t()) :: map()
  def success_response(%Success{} = success) do
    # According to RFC 8628 Section 3.2
    %{
      device_code: success.device_code,
      user_code: success.user_code,
      verification_uri: success.verification_uri,
      expires_in: success.expires_in
    }
    |> maybe_add_verification_uri_complete(success.verification_uri_complete)
    |> maybe_add_interval(success.interval)
  end

  @spec error_response(Error.t()) :: map()
  def error_response(%Error{} = error) do
    %{
      error: error.error,
      error_description: error.error_description
    }
  end

  defp maybe_add_verification_uri_complete(response, nil), do: response

  defp maybe_add_verification_uri_complete(response, uri),
    do: Map.put(response, :verification_uri_complete, uri)

  defp maybe_add_interval(response, nil), do: response
  defp maybe_add_interval(response, interval), do: Map.put(response, :interval, interval)
end
