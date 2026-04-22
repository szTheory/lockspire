defmodule Lockspire.Host.Claims do
  @moduledoc """
  Structured claim material returned by the host account resolver.
  """

  @type claim_set :: map()

  @type t :: %__MODULE__{
          subject: String.t(),
          id_token: claim_set(),
          userinfo: claim_set()
        }

  defstruct subject: nil, id_token: %{}, userinfo: %{}
end
