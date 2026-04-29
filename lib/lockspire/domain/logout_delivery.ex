defmodule Lockspire.Domain.LogoutDelivery do
  @moduledoc """
  Durable per-client, per-channel logout propagation snapshot state.
  """

  @type channel :: :backchannel | :frontchannel
  @type status ::
          :pending
          | :enqueued
          | :attempted
          | :succeeded
          | :retryable
          | :discarded
          | :rendered
          | :skipped

  @type t :: %__MODULE__{
          id: integer() | nil,
          delivery_id: String.t() | nil,
          logout_event_id: integer() | nil,
          client_id: String.t(),
          channel: channel(),
          target_uri: String.t(),
          session_required: boolean(),
          status: status(),
          attempt_count: non_neg_integer(),
          last_attempted_at: DateTime.t() | nil,
          delivered_at: DateTime.t() | nil,
          rendered_at: DateTime.t() | nil,
          finalized_at: DateTime.t() | nil,
          http_status: non_neg_integer() | nil,
          failure_reason: String.t() | nil,
          logout_token_jti: String.t() | nil,
          oban_job_id: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct [
    :id,
    :delivery_id,
    :logout_event_id,
    :client_id,
    :channel,
    :target_uri,
    :last_attempted_at,
    :delivered_at,
    :rendered_at,
    :finalized_at,
    :http_status,
    :failure_reason,
    :logout_token_jti,
    :oban_job_id,
    :inserted_at,
    :updated_at,
    session_required: false,
    status: :pending,
    attempt_count: 0
  ]
end
