defmodule Lockspire.Domain.SigningKey do
  @moduledoc """
  Durable signing-key lifecycle state for JWKS publication and rotation.
  """

  @type key_type :: :RSA | :EC | :OKP
  @type use_type :: :sig
  @type status :: :upcoming | :active | :retiring | :retired

  @type t :: %__MODULE__{
          id: integer() | nil,
          kid: String.t(),
          kty: key_type(),
          alg: String.t(),
          use: use_type(),
          public_jwk: map(),
          private_jwk_encrypted: binary() | nil,
          status: status(),
          published_at: DateTime.t() | nil,
          activated_at: DateTime.t() | nil,
          retiring_at: DateTime.t() | nil,
          retired_at: DateTime.t() | nil,
          tenant_id: String.t() | nil,
          metadata: map(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct [
    :id,
    :kid,
    :kty,
    :alg,
    use: :sig,
    public_jwk: %{},
    private_jwk_encrypted: nil,
    status: :upcoming,
    published_at: nil,
    activated_at: nil,
    retiring_at: nil,
    retired_at: nil,
    tenant_id: nil,
    metadata: %{},
    inserted_at: nil,
    updated_at: nil
  ]
end
