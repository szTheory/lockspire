defmodule Lockspire.Domain.DeviceAuthorization do
  @moduledoc """
  Core domain model for OAuth 2.0 Device Authorization Grant (RFC 8628).
  """

  alias Lockspire.Security.Policy

  @statuses [:pending, :approved, :denied, :consumed, :expired]
  @verification_handle_bytes 32
  @enforce_keys [
    :device_code_hash,
    :user_code_hash,
    :verification_handle,
    :client_id,
    :status,
    :expires_at
  ]
  defstruct [
    :id,
    :device_code,
    :user_code,
    :device_code_hash,
    :user_code_hash,
    :verification_handle,
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
    :expires_at
  ]

  @type status :: :pending | :approved | :denied | :consumed | :expired

  @type t :: %__MODULE__{
          id: integer() | nil,
          device_code: String.t() | nil,
          user_code: String.t() | nil,
          device_code_hash: String.t(),
          user_code_hash: String.t(),
          verification_handle: String.t(),
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
          expires_at: DateTime.t()
        }

  # 5 minutes
  @default_ttl 300
  @default_poll_interval_seconds 5

  @doc """
  Issues a new Device Authorization struct.
  """
  def issue(attrs, opts \\ []) when is_map(attrs) and is_list(opts) do
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
    ttl = Keyword.get(opts, :ttl, @default_ttl)

    device_code = Map.fetch!(attrs, :device_code)
    user_code = Map.fetch!(attrs, :user_code)
    canonical_user_code = canonicalize_user_code(user_code)

    %__MODULE__{
      device_code: device_code,
      device_code_hash: Policy.hash_token(device_code),
      user_code: user_code,
      user_code_hash: Policy.hash_token(canonical_user_code),
      verification_handle: generate_verification_handle(),
      client_id: Map.fetch!(attrs, :client_id),
      scopes: List.wrap(Map.get(attrs, :scopes, [])),
      status: :pending,
      subject_id: nil,
      approved_at: nil,
      denied_at: nil,
      consumed_at: nil,
      expired_at: nil,
      effective_poll_interval_seconds: @default_poll_interval_seconds,
      next_poll_allowed_at: initial_next_poll_allowed_at(now),
      expires_at: DateTime.add(now, ttl, :second)
    }
  end

  @spec default_poll_interval_seconds() :: pos_integer()
  def default_poll_interval_seconds, do: @default_poll_interval_seconds

  @spec canonicalize_user_code(String.t()) :: String.t()
  def canonicalize_user_code(user_code) when is_binary(user_code) do
    # Canonicalize user codes by stripping separators and whitespace, then uppercase.
    user_code
    |> String.replace(~r/[^[:alnum:]]/u, "")
    |> String.upcase()
  end

  @spec hash_user_code(String.t()) :: String.t()
  def hash_user_code(user_code) when is_binary(user_code) do
    user_code
    |> canonicalize_user_code()
    |> Policy.hash_token()
  end

  @spec statuses() :: [status(), ...]
  def statuses, do: @statuses

  @spec initial_next_poll_allowed_at(DateTime.t()) :: DateTime.t()
  def initial_next_poll_allowed_at(%DateTime{} = issued_at) do
    DateTime.add(issued_at, @default_poll_interval_seconds, :second)
  end

  defp generate_verification_handle do
    @verification_handle_bytes
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
