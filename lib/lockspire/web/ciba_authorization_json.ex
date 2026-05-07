defmodule Lockspire.Web.CibaAuthorizationJSON do
  @moduledoc false

  alias Lockspire.Protocol.BackchannelAuthentication.Error
  alias Lockspire.Protocol.BackchannelAuthentication.Success

  @spec success_response(Success.t()) :: map()
  def success_response(%Success{} = success) do
    # According to OIDC CIBA Section 7.3
    %{
      auth_req_id: success.auth_req_id,
      expires_in: success.expires_in
    }
    |> maybe_add_interval(success.interval)
  end

  @spec error_response(Error.t()) :: map()
  def error_response(%Error{} = error) do
    %{
      error: error.error,
      error_description: error.error_description
    }
    |> Map.reject(fn {_k, v} -> is_nil(v) end)
  end

  defp maybe_add_interval(response, nil), do: response
  defp maybe_add_interval(response, interval), do: Map.put(response, :interval, interval)
end
