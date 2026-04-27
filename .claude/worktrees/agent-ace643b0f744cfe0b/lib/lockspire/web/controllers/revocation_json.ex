defmodule Lockspire.Web.RevocationJSON do
  @moduledoc false

  alias Lockspire.Protocol.Revocation.Error

  @spec success() :: map()
  def success, do: %{}

  @spec error_response(Error.t()) :: map()
  def error_response(%Error{} = error) do
    %{
      error: error.error,
      error_description: error.error_description
    }
  end
end
