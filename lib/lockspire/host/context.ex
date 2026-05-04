defmodule Lockspire.Host.Context do
  @moduledoc """
  Contextual information passed to host integration callbacks.
  """

  @type interaction_type ::
          :login | :consent | :logout | :refresh | :exchange | :userinfo | term()

  @type t :: %__MODULE__{
          interaction_type: interaction_type() | nil,
          interaction_id: String.t() | nil,
          client_id: String.t() | nil,
          scopes: [String.t()] | nil,
          return_to: String.t() | nil,
          tenant_id: String.t() | nil,
          metadata: map()
        }

  defstruct [
    :interaction_type,
    :interaction_id,
    :client_id,
    :scopes,
    :return_to,
    :tenant_id,
    metadata: %{}
  ]
end
