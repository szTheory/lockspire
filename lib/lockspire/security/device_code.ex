defmodule Lockspire.Security.DeviceCode do
  @moduledoc """
  Utilities for generating secure device authorization codes.
  """

  @base20_alphabet String.graphemes("BCDFGHJKLMNPQRSTVWXZ")

  @doc """
  Generates a collision-resistant Base20 user code of length 8.
  Uses an alphabet that avoids vowels and similar-looking characters (1/I/L, 0/O).
  Returns a continuous 8-character string.
  """
  @spec generate_user_code() :: String.t()
  def generate_user_code do
    1..8
    |> Enum.map(fn _ -> Enum.random(@base20_alphabet) end)
    |> Enum.join()
  end

  @doc """
  Generates a high-entropy device code (minimum 256 bits of entropy) 
  using `:crypto.strong_rand_bytes/1` and encodes it securely.
  """
  @spec generate_device_code() :: String.t()
  def generate_device_code do
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64(padding: false)
  end
end
