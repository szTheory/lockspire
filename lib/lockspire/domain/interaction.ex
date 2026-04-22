defmodule Lockspire.Domain.Interaction do
  @moduledoc """
  Ephemeral-but-durable authorization interaction state.
  """

  @type prompt :: String.t() | [String.t()] | nil
  @type code_challenge_method :: :S256 | nil

  @type t :: %__MODULE__{
          id: integer() | nil,
          interaction_id: String.t(),
          client_id: String.t(),
          account_id: String.t() | nil,
          scopes_requested: [String.t()],
          prompt: prompt(),
          nonce: String.t() | nil,
          redirect_uri: String.t() | nil,
          return_to: String.t(),
          state: String.t() | nil,
          code_challenge: String.t() | nil,
          code_challenge_method: code_challenge_method(),
          expires_at: DateTime.t(),
          tenant_id: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct [
    :id,
    :interaction_id,
    :client_id,
    :account_id,
    :return_to,
    :expires_at,
    scopes_requested: [],
    prompt: nil,
    nonce: nil,
    redirect_uri: nil,
    state: nil,
    code_challenge: nil,
    code_challenge_method: :S256,
    tenant_id: nil,
    inserted_at: nil,
    updated_at: nil
  ]
end
