defmodule Lockspire.Protocol.Jar do
  @moduledoc """
  JWT Secured Authorization Request (JAR) foundation.

  Provides unverified decoding of RFC 9101 request objects.
  """

  defstruct [:claims, :header]

  @type t :: %__MODULE__{
          claims: map(),
          header: map()
        }

  @doc """
  Decodes a JWT string without signature verification.
  """
  @spec decode(String.t()) :: {:ok, t()} | {:error, :invalid_jwt}
  def decode(jwt) when is_binary(jwt) do
    try do
      # JOSE.JWT.peek_payload and peek_protected raise ArgumentError if malformed
      payload_struct = JOSE.JWT.peek_payload(jwt)
      protected_struct = JOSE.JWT.peek_protected(jwt)

      # to_map returns {modules_map, fields_map}
      {_modules, claims} = JOSE.JWT.to_map(payload_struct)
      {_modules, header} = JOSE.JWS.to_map(protected_struct)

      {:ok, %__MODULE__{claims: claims, header: header}}
    rescue
      _ -> {:error, :invalid_jwt}
    end
  end

  def decode(_), do: {:error, :invalid_jwt}
end
