defmodule Lockspire.Protocol.ProtectedResourceError do
  @moduledoc false

  @type t :: %__MODULE__{
          status: pos_integer(),
          error: String.t(),
          error_description: String.t(),
          reason_code: atom(),
          dpop_nonce: String.t() | nil
        }

  defstruct [:status, :error, :error_description, :reason_code, :dpop_nonce]
end
