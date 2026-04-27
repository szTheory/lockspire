defmodule Lockspire.Host.InteractionResult do
  @moduledoc """
  Structured login handoff returned by the host account resolver.
  """

  @type t :: %__MODULE__{
          login_path: String.t(),
          return_to: String.t() | nil,
          params: map()
        }

  defstruct login_path: nil, return_to: nil, params: %{}
end
