defmodule Lockspire.Domain.InitialAccessToken do
  @moduledoc """
  Durable initial access token used to gate `POST /register` when
  `Lockspire.Domain.ServerPolicy.registration_policy == :initial_access_token`.

  Hash-at-rest reuses `Lockspire.Security.Policy.hash_token/1` (sha256 lowercase hex).
  Plaintext is shown once at mint time only (Phase 28 admin LiveView; out of scope for Phase 25).

  Phase 25 ships **schema + struct only** — `Lockspire.Protocol.InitialAccessToken.redeem/1`
  is Phase 26 (DCR-11). Atomicity for redemption depends on the `unique_index([:token_hash])`
  shipped in Plan 03's `lockspire_initial_access_tokens` migration.

  ## `policy_overrides` boundary (T-25-05)

  This struct's `policy_overrides` field carries operator-controlled JSON narrowing the
  effective DCR allowlists for any registration that uses this IAT. Phase 25 ships the
  field as opaque storage — narrowing-at-mint validation (override ⊆ server allowlist)
  is a Phase 28 admin-path concern. The `Lockspire.Protocol.DcrPolicy.resolve/3` resolver
  (Plan 07) does NOT re-validate widening at resolve time per D-18: if a stale override
  carries an out-of-allowlist value (e.g., policy was tightened after IAT mint),
  `MapSet.intersection/2` naturally drops it — never widens.
  """

  @type t :: %__MODULE__{
          id: integer() | nil,
          token_hash: String.t() | nil,
          expires_at: DateTime.t() | nil,
          single_use: boolean(),
          used_at: DateTime.t() | nil,
          revoked_at: DateTime.t() | nil,
          policy_overrides: map() | nil,
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
