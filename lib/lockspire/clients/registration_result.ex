defmodule Lockspire.Clients.RegistrationResult do
  @moduledoc """
  Result returned from client registration.
  """

  alias Lockspire.Domain.Client

  @type t :: %__MODULE__{
          client: Client.t(),
          client_secret: String.t() | nil
        }

  defstruct [:client, :client_secret]
end
