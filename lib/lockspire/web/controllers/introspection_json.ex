defmodule Lockspire.Web.IntrospectionJSON do
  @moduledoc false

  alias Lockspire.Protocol.Introspection.Error

  @spec response(map()) :: map()
  def response(body) when is_map(body), do: body

  @spec error_response(Error.t()) :: map()
  def error_response(%Error{} = error) do
    %{
      error: error.error,
      error_description: error.error_description
    }
  end
end
