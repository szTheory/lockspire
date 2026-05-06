defmodule Lockspire.RAR.Fingerprint do
  @moduledoc """
  Computes a deterministic fingerprint for normalized RAR details.
  """

  @spec compute([map()]) :: binary() | nil
  def compute([]), do: nil

  def compute(authorization_details) when is_list(authorization_details) do
    authorization_details
    |> Jcs.encode()
    |> then(&:crypto.hash(:sha256, &1))
  end
end
