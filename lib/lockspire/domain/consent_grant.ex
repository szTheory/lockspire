defmodule Lockspire.Domain.ConsentGrant do
  @moduledoc """
  Durable consent state granted by an account to a client.
  """

  @type t :: %__MODULE__{
          id: integer() | nil,
          account_id: String.t(),
          client_id: String.t(),
          scopes: [String.t()],
          granted_at: DateTime.t(),
          revoked_at: DateTime.t() | nil,
          tenant_id: String.t() | nil,
          metadata: map(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct [
    :id,
    :account_id,
    :client_id,
    :granted_at,
    scopes: [],
    revoked_at: nil,
    tenant_id: nil,
    metadata: %{},
    inserted_at: nil,
    updated_at: nil
  ]
end
