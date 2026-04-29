defmodule Lockspire.Domain.Interaction do
  @moduledoc """
  Ephemeral-but-durable authorization interaction state.
  """

  @type prompt :: String.t() | [String.t()] | nil
  @type code_challenge_method :: :S256 | nil
  @type status :: :pending_login | :pending_consent | :completed | :denied | :expired

  @type t :: %__MODULE__{
          id: integer() | nil,
          interaction_id: String.t(),
          sid: String.t() | nil,
          client_id: String.t(),
          account_id: String.t() | nil,
          scopes_requested: [String.t()],
          prompt: prompt(),
          nonce: String.t() | nil,
          auth_time: DateTime.t() | nil,
          max_age: non_neg_integer() | nil,
          auth_time_requested: boolean(),
          redirect_uri: String.t() | nil,
          return_to: String.t(),
          state: String.t() | nil,
          code_challenge: String.t() | nil,
          code_challenge_method: code_challenge_method(),
          status: status(),
          login_required_at: DateTime.t() | nil,
          consent_requested_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil,
          denied_at: DateTime.t() | nil,
          expired_at: DateTime.t() | nil,
          denial_reason: String.t() | nil,
          expires_at: DateTime.t(),
          tenant_id: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct [
    :id,
    :interaction_id,
    :sid,
    :client_id,
    :account_id,
    :return_to,
    :expires_at,
    scopes_requested: [],
    prompt: nil,
    nonce: nil,
    auth_time: nil,
    max_age: nil,
    auth_time_requested: false,
    redirect_uri: nil,
    state: nil,
    code_challenge: nil,
    code_challenge_method: nil,
    status: :pending_login,
    login_required_at: nil,
    consent_requested_at: nil,
    completed_at: nil,
    denied_at: nil,
    expired_at: nil,
    denial_reason: nil,
    tenant_id: nil,
    inserted_at: nil,
    updated_at: nil
  ]
end
