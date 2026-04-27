defmodule Lockspire.Domain.DeviceAuthorization do
  @moduledoc """
  Core domain model for OAuth 2.0 Device Authorization Grant (RFC 8628).
  """

  alias Lockspire.Security.Policy

  @enforce_keys [
    :device_code_hash,
    :user_code_hash,
    :client_id,
    :expires_at
  ]
  defstruct [
    :device_code,
    :user_code,
    :device_code_hash,
    :user_code_hash,
    :client_id,
    :scopes,
    :expires_at
  ]

  @type t :: %__MODULE__{
          device_code: String.t() | nil,
          user_code: String.t() | nil,
          device_code_hash: String.t(),
          user_code_hash: String.t(),
          client_id: String.t(),
          scopes: [String.t()],
          expires_at: DateTime.t()
        }

  @default_ttl 300 # 5 minutes

  @doc """
  Issues a new Device Authorization struct.
  """
  def issue(attrs, opts \\ []) when is_map(attrs) and is_list(opts) do
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
    ttl = Keyword.get(opts, :ttl, @default_ttl)

    device_code = Map.fetch!(attrs, :device_code)
    user_code = Map.fetch!(attrs, :user_code)

    %__MODULE__{
      device_code: device_code,
      device_code_hash: Policy.hash_token(device_code),
      user_code: user_code,
      user_code_hash: Policy.hash_token(user_code),
      client_id: Map.fetch!(attrs, :client_id),
      scopes: List.wrap(Map.get(attrs, :scopes, [])),
      expires_at: DateTime.add(now, ttl, :second)
    }
  end
end
