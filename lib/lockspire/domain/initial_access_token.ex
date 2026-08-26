defmodule Lockspire.Domain.InitialAccessToken do
  @moduledoc """
  Durable initial access token used to gate `POST /register` when
  `Lockspire.Domain.ServerPolicy.registration_policy == :initial_access_token`.

  Hash-at-rest reuses `Lockspire.Security.Policy.hash_token/1` (SHA-256 lowercase hex).
  Plaintext is shown once at mint time only. Redemption is atomic because the token hash
  is unique and the storage adapter locks the row before updating its lifecycle state.

  ## `policy_overrides` boundary

  This struct's `policy_overrides` field carries operator-controlled JSON narrowing the
  effective DCR allowlists for any registration that uses this IAT. The admin mint path
  validates that overrides narrow the server allowlist. The
  `Lockspire.Protocol.DcrPolicy.resolve/3` resolver also remains fail-closed: if a stale override
  carries an out-of-allowlist value (e.g., policy was tightened after IAT mint),
  `MapSet.intersection/2` naturally drops it — never widens.
  """

  @typedoc """
  Operator-controlled per-IAT narrowing of the resolver's effective DCR allowlists.

  String-keyed map (the resolver's `override_for/2` looks up string keys) where each value
  is a list of strings (the resolver's `intersect_axis/4` only lets list values pass
  through; non-list values are treated as "no override"). Known keys mirror the
  `dcr_allowed_*` axes:

    - "allowed_scopes"
    - "allowed_grant_types"
    - "allowed_response_types"
    - "allowed_redirect_uri_schemes"
    - "allowed_redirect_uri_hosts"
    - "allowed_token_endpoint_auth_methods"

  Pinning the shape here lets Dialyzer catch drift between admin minting and
  `Lockspire.Protocol.DcrPolicy.resolve/3`. A malformed
  `%{atom_key: "string"}` would silently bypass every override under the looser
  `map() | nil` typespec.
  """
  @type policy_overrides :: %{optional(String.t()) => [String.t()]}

  @type t :: %__MODULE__{
          id: integer() | nil,
          token_hash: String.t() | nil,
          expires_at: DateTime.t() | nil,
          single_use: boolean(),
          used_at: DateTime.t() | nil,
          revoked_at: DateTime.t() | nil,
          policy_overrides: policy_overrides() | nil,
          created_by: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct id: nil,
            token_hash: nil,
            expires_at: nil,
            single_use: true,
            used_at: nil,
            revoked_at: nil,
            policy_overrides: nil,
            created_by: nil,
            inserted_at: nil,
            updated_at: nil
end
