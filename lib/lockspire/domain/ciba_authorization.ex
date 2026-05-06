defmodule Lockspire.Domain.CibaAuthorization do
  @moduledoc """
  Core domain model for OpenID Connect Client-Initiated Backchannel Authentication (CIBA).
  """

  alias Lockspire.Security.Policy

  @statuses [:pending, :approved, :denied, :consumed, :expired]
  @enforce_keys [
    :auth_req_id_hash,
    :client_id,
    :status,
    :expires_at
  ]
  defstruct [
    :id,
    :auth_req_id,
    :auth_req_id_hash,
    :client_id,
    :scopes,
    :status,
    :subject_id,
    :approved_at,
    :denied_at,
    :consumed_at,
    :expired_at,
    :effective_poll_interval_seconds,
    :next_poll_allowed_at,
    :expires_at,
    :binding_message,
    :delivery_mode,
    :client_notification_endpoint,
    :client_notification_token_encrypted,
    :auth_req_id_encrypted
  ]

  @type status :: :pending | :approved | :denied | :consumed | :expired
  @type delivery_mode :: :poll | :ping | :push

  @type t :: %__MODULE__{
          id: integer() | nil,
          auth_req_id: String.t() | nil,
          auth_req_id_hash: String.t(),
          client_id: String.t(),
          scopes: [String.t()],
          status: status(),
          subject_id: String.t() | nil,
          approved_at: DateTime.t() | nil,
          denied_at: DateTime.t() | nil,
          consumed_at: DateTime.t() | nil,
          expired_at: DateTime.t() | nil,
          effective_poll_interval_seconds: pos_integer(),
          next_poll_allowed_at: DateTime.t(),
          expires_at: DateTime.t(),
          binding_message: String.t() | nil,
          delivery_mode: delivery_mode(),
          client_notification_endpoint: String.t() | nil,
          client_notification_token_encrypted: binary() | nil,
          auth_req_id_encrypted: binary() | nil
        }

  # 10 minutes
  @default_ttl 600
  @default_poll_interval_seconds 5

  @doc """
  Issues a new CIBA Authorization struct.
  """
  def issue(attrs, opts \\ []) when is_map(attrs) and is_list(opts) do
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
    ttl = Keyword.get(opts, :ttl, @default_ttl)

    auth_req_id = Map.fetch!(attrs, :auth_req_id)

    %__MODULE__{
      auth_req_id: auth_req_id,
      auth_req_id_hash: Policy.hash_token(auth_req_id),
      client_id: Map.fetch!(attrs, :client_id),
      scopes: List.wrap(Map.get(attrs, :scopes, [])),
      status: :pending,
      subject_id: Map.get(attrs, :subject_id),
      approved_at: nil,
      denied_at: nil,
      consumed_at: nil,
      expired_at: nil,
      effective_poll_interval_seconds: @default_poll_interval_seconds,
      next_poll_allowed_at: initial_next_poll_allowed_at(now),
      expires_at: DateTime.add(now, ttl, :second),
      binding_message: Map.get(attrs, :binding_message),
      delivery_mode: Map.get(attrs, :delivery_mode, :poll),
      client_notification_endpoint: Map.get(attrs, :client_notification_endpoint),
      client_notification_token_encrypted: Map.get(attrs, :client_notification_token_encrypted),
      auth_req_id_encrypted: Map.get(attrs, :auth_req_id_encrypted)
    }
  end

  @spec default_poll_interval_seconds() :: pos_integer()
  def default_poll_interval_seconds, do: @default_poll_interval_seconds

  @spec statuses() :: [status(), ...]
  def statuses, do: @statuses

  @spec initial_next_poll_allowed_at(DateTime.t()) :: DateTime.t()
  def initial_next_poll_allowed_at(%DateTime{} = issued_at) do
    DateTime.add(issued_at, @default_poll_interval_seconds, :second)
  end
end
