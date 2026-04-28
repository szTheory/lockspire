defmodule Lockspire.Domain.DpopReplay do
  @moduledoc """
  Durable DPoP proof replay state for the supported acceptance window.
  """

  @enforce_keys [:replay_key, :jti, :htm, :htu, :jkt, :seen_at, :expires_at]
  defstruct [
    :id,
    :replay_key,
    :jti,
    :htm,
    :htu,
    :jkt,
    :seen_at,
    :expires_at,
    :inserted_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
          id: integer() | nil,
          replay_key: String.t(),
          jti: String.t(),
          htm: String.t(),
          htu: String.t(),
          jkt: String.t(),
          seen_at: DateTime.t(),
          expires_at: DateTime.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
end
