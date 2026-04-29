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
          interaction_id: String.t() | nil,
          sid: String.t() | nil,
          redirect_uri: String.t() | nil,
          scopes: [String.t()],
          audience: [String.t()],
          cnf: map() | nil,
          code_challenge: String.t() | nil,
          code_challenge_method: :S256 | nil,
          issued_at: DateTime.t() | nil,
          expires_at: DateTime.t(),
          redeemed_at: DateTime.t() | nil,
          revoked_at: DateTime.t() | nil,
          reuse_detected_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct [
    :id,
    :token_hash,
    :token_type,
    :client_id,
    :expires_at,
    jti: nil,
    family_id: nil,
    generation: 0,
    parent_token_id: nil,
    account_id: nil,
    interaction_id: nil,
    sid: nil,
    redirect_uri: nil,
    scopes: [],
    audience: [],
    cnf: nil,
    code_challenge: nil,
    code_challenge_method: nil,
    issued_at: nil,
    redeemed_at: nil,
    revoked_at: nil,
    reuse_detected_at: nil,
    inserted_at: nil,
    updated_at: nil
  ]
end
