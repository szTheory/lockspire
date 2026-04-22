defmodule Lockspire.Domain.Token do
  @moduledoc """
  Durable token and token-family state owned by Lockspire.
  """

  @type token_type :: :authorization_code | :access_token | :refresh_token

  @type t :: %__MODULE__{
          id: integer() | nil,
          token_hash: String.t(),
          token_type: token_type(),
          jti: String.t() | nil,
          family_id: String.t() | nil,
          generation: non_neg_integer(),
          parent_token_id: integer() | nil,
          client_id: String.t(),
          account_id: String.t() | nil,
          scopes: [String.t()],
          audience: [String.t()],
          cnf: map() | nil,
          expires_at: DateTime.t(),
          revoked_at: DateTime.t() | nil,
          reuse_detected_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct [
    :id,
    :token_hash,
    :token_type,
    jti: nil,
    family_id: nil,
    generation: 0,
    parent_token_id: nil,
    :client_id,
    account_id: nil,
    scopes: [],
    audience: [],
    cnf: nil,
    :expires_at,
    revoked_at: nil,
    reuse_detected_at: nil,
    inserted_at: nil,
    updated_at: nil
  ]
end
