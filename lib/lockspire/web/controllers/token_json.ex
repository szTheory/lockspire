defmodule Lockspire.Web.TokenJSON do
  @moduledoc false

  alias Lockspire.Protocol.TokenExchange.Error
  alias Lockspire.Protocol.TokenExchange.Success

  @spec access_token_response(Success.t()) :: map()
  def access_token_response(%Success{} = success) do
    %{
      access_token: success.access_token,
      token_type: success.token_type,
      expires_in: success.expires_in,
      scope: success.scope
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
