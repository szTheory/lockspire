defmodule Lockspire.Domain.UsedJti do
  @moduledoc """
  Domain struct representing a used JTI (JWT ID) to prevent replay attacks.
  """

  @enforce_keys [:client_id, :jti, :expires_at]
  defstruct [:id, :client_id, :jti, :expires_at]

  @type t :: %__MODULE__{
          id: integer() | nil,
          client_id: String.t(),
          jti: String.t(),
          expires_at: DateTime.t()
        }
end
