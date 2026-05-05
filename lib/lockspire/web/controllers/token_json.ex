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
    |> maybe_put_refresh_token(success.refresh_token)
    |> maybe_put_id_token(success.id_token)
    |> maybe_put_issued_token_type(success.issued_token_type)
  end

  @spec error_response(Error.t()) :: map()
  def error_response(%Error{} = error) do
    %{
      error: error.error,
      error_description: error.error_description
    }
  end

  defp maybe_put_id_token(response, nil), do: response
  defp maybe_put_id_token(response, id_token), do: Map.put(response, :id_token, id_token)

  defp maybe_put_refresh_token(response, nil), do: response

  defp maybe_put_refresh_token(response, refresh_token),
    do: Map.put(response, :refresh_token, refresh_token)

  defp maybe_put_issued_token_type(response, nil), do: response

  defp maybe_put_issued_token_type(response, issued_token_type),
    do: Map.put(response, :issued_token_type, issued_token_type)
end
