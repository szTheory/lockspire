defmodule Lockspire.Host.TokenExchangeContext do
  @moduledoc """
  Context data carrier for the token exchange flow.
  """

  @enforce_keys [:client_id, :subject_token, :requested_scopes]
  defstruct [:client_id, :subject_token, :requested_scopes, actor_token: nil]

  @type t :: %__MODULE__{
          client_id: String.t(),
          subject_token: map(),
          actor_token: map() | nil,
          requested_scopes: [String.t()]
        }
end
