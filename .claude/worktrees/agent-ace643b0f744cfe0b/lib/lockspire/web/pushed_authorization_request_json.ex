defmodule Lockspire.Web.PushedAuthorizationRequestJSON do
  @moduledoc false

  alias Lockspire.Protocol.PushedAuthorizationRequest.Error
  alias Lockspire.Protocol.PushedAuthorizationRequest.Success

  @spec success_response(Success.t()) :: map()
  def success_response(%Success{} = success) do
    %{
      request_uri: success.request_uri,
      expires_in: success.expires_in
    }
  end

  @spec error_response(Error.t()) :: map()
  def error_response(%Error{} = error) do
    %{
      error: error.error,
      error_description: error.error_description
    }
  end
end
