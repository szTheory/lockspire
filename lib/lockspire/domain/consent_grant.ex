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
          status: :active | :revoked,
          kind: :remembered | :one_time,
          authorization_details: [map()],
          authorization_details_fingerprint: binary() | nil,
          revoked_at: DateTime.t() | nil,
          revoked_by: String.t() | nil,
          revoked_reason: String.t() | nil,
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
    :authorization_details_fingerprint,
    scopes: [],
    status: :active,
    kind: :remembered,
    authorization_details: [],
    revoked_at: nil,
    revoked_by: nil,
    revoked_reason: nil,
    tenant_id: nil,
    metadata: %{},
    inserted_at: nil,
    updated_at: nil
  ]
end
