defmodule Lockspire.Web.UserinfoJSON do
  @moduledoc false

  alias Lockspire.Protocol.Userinfo.Error

  @spec response(map()) :: map()
  def response(claims) when is_map(claims), do: claims

  @spec error_response(Error.t()) :: map()
  def error_response(%Error{} = error) do
    %{
      error: error.error,
      error_description: error.error_description
    }
  end
end
