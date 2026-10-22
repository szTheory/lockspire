# Phase 164: Client-Secret Expiry & Atomic Rotation - Pattern Map

**Mapped:** 2026-10-20  
**Files analyzed:** 27 likely implementation and regression-test files  
**Analogs found:** 27 / 27

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/domain/client.ex` | model | transform | same file: `app_eligibility/3`, `credential_lifetime_changes/3` | exact |
| `lib/lockspire/client_metadata.ex` | utility | transform | same file: `build_dcr_client/4`, secret deadline helper | exact |
| `lib/lockspire/protocol/dcr_policy.ex` | service | request-response | same file: default app lifetime validator | exact |
| `lib/lockspire/storage/ecto/server_policy_record.ex` | model | transform | same file: DCR server policy changeset | exact |
| `lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex` | component | request-response | same file: DCR duration form validation | exact |
| `lib/lockspire/web/registration_json.ex` | utility | transform | same file: shared registration metadata payload | exact |
| `lib/lockspire/protocol/client_auth.ex` | service | request-response | same file: app eligibility and secret-method verification | exact |
| `lib/lockspire/protocol/client_auth/client_secret_jwt.ex` | service | request-response | same file: assertion verification and replay boundary | exact |
| `lib/lockspire/protocol/token_exchange/internal/client_authentication.ex` | model | transform | same file: `VerifiedIdentity` and fingerprint matching | exact |
| `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex` | service | CRUD | same file: locked final authorization-code/token issuance | exact |
| `lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex` | service | CRUD | same file: locked refresh-token rotation | exact |
| `lib/lockspire/storage/client_lifetime.ex` | service | request-response | same file: adapter declaration and lifetime-state validation | exact |
| `lib/lockspire/storage/client_store.ex` | service | CRUD | same file: callback contract | exact |
| `lib/lockspire/storage/ecto/repository/client_store.ex` | service | CRUD | same file: `rotate_client_secret/5` current-row lock | exact |
| `lib/lockspire/client_lifecycle.ex` | service | CRUD | same file: `transact_with_audit/2` | exact |
| `lib/lockspire/storage/ecto/repository/transaction_store.ex` | utility | CRUD | same file: transaction rollback wrapper | exact |
| `lib/lockspire/admin/clients.ex` | service | request-response | same file: host-authorized `rotate_client_secret/2` | exact |
| `test/lockspire/protocol/dcr_policy_test.exs` | test | transform | same file | exact |
| `test/lockspire/protocol/registration_test.exs` | test | request-response | same file | exact |
| `test/lockspire/protocol/client_auth_test.exs` | test | request-response | same file | exact |
| `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs` | test | request-response | same file | exact |
| `test/lockspire/web/registration_json_test.exs` | test | transform | same file | exact |
| `test/lockspire/storage/client_lifetime_promotion_test.exs` | test | CRUD | same file | exact |
| `test/lockspire/storage/client_lifetime_conformance_test.exs` | test | CRUD | same file | exact |
| `test/lockspire/storage/client_lifetime_rollback_test.exs` | test | CRUD | same file | exact |
| `test/lockspire/storage/client_lifetime_client_wait_test.exs` | test | CRUD | same file | exact |
| `test/lockspire/storage/client_lifetime_grant_wait_test.exs` | test | CRUD | same file | exact |
| `test/support/client_lifetime_race_helpers.ex` | utility | event-driven | same file: independent sessions, blocker probes and barrier clocks | exact |

All analog paths above were confirmed by `git ls-files`; each is tracked source. Phase 165 management-token lifecycle is out of scope. Existing management rotation code may inform shared adapter semantics, but do not map it as work to expand here.

## Pattern Assignments

### `lib/lockspire/domain/client.ex` (model, transform)

**Analog:** Existing eligibility and versioned replacement helpers in this file.

**Strict deadline pattern** (`app_eligibility/3`, lines 166-202):

```elixir
def app_eligibility(%__MODULE__{lifetime_version: 1, client_expires_at: deadline},
      %DateTime{} = now, _) do
  if utc_second?(deadline) do
    case DateTime.shift_zone(now, "Etc/UTC") do
      {:ok, instant} ->
        if DateTime.compare(instant, deadline) == :lt, do: :ok, else: {:error, :expired}
      :error -> {:error, :invalid_lifetime_state}
    end
  else
    {:error, :invalid_lifetime_state}
  end
end
```

Use the strict `:lt` boundary and fail-closed malformed durable state for the secret eligibility sibling. Preserve version-0 advisory behavior until explicit replacement. `credential_lifetime_changes/3` (lines 204-240) is the canonical promotion rule: v0 clears app/secret/management deadlines then sets only the replacement kind; v1 changes only that credential's deadline.

### `lib/lockspire/client_metadata.ex` (utility, transform)

**Analog:** `build_dcr_client/4` (lines 41-109) and `client_secret_expires_at/3` (lines 283-297).

**Imports and construction:** `ClientRegistration.Shape` and `Domain.Client` are aliases (lines 4-5); issuance time is taken from `credentials.issued_at` and truncated to seconds (44-47). The DCR client explicitly sets `provenance: :self_registered` (83-87), auth method (51-66), then stores `client_secret_expires_at` and `lifetime_version` (103-106). Keep policy application tied to this provenance and issuance path; direct/operator registration uses a separate boundary.

Current helper behavior to replace (lines 283-297):

```elixir
defp client_secret_expires_at(_now, _resolved, %{client_secret_hash: nil}), do: nil

defp client_secret_expires_at(now, resolved, _credentials) do
  case Map.get(resolved, :default_client_secret_lifetime_seconds, 0) || 0 do
    seconds when is_integer(seconds) and seconds >= 0 -> DateTime.add(now, seconds, :second)
    _ -> now
  end
end
```

Preserve the issued-at snapshot and whole-second UTC construction, but resolve nil/zero as unlimited and reject malformed policy instead of silently treating it as a deadline.

### Policy validation: `lib/lockspire/protocol/dcr_policy.ex`, `lib/lockspire/storage/ecto/server_policy_record.ex`, `lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex`

**Role/data flow:** resolver/service and storage model are transform/request-response; LiveView form is request-response.

**Analogs:** `DcrPolicy.resolve/3` validates the app duration before returning a `Resolved` policy (lines 87-153); the Ecto record changeset is at `ServerPolicyRecord` lines 54-99; form fields and validations are in `PolicyForm` lines 11-68.

**Resolver excerpt** (`dcr_policy.ex:91-99,146-153`):

```elixir
with :ok <- validate_default_client_lifetime(server_policy.dcr_default_client_lifetime_seconds),
     {:ok, scopes} <- intersect_axis(...) do
  ...
end

defp validate_default_client_lifetime(value)
     when is_nil(value) or (is_integer(value) and value >= 0 and value <= 2_147_483_647),
     do: :ok

defp validate_default_client_lifetime(_value), do: {:error, :invalid_client_metadata, ...}
```

Use the same explicit nil-or-bounded-integer validation at every supported write/use boundary for secret duration. Follow the existing Ecto `changeset` validation style and form field validator; reject floats, negatives, and oversized values. Invalid durable configuration should surface as server/configuration error at use time, not as unlimited or bad client credentials.

### `lib/lockspire/web/registration_json.ex` (utility, transform)

**Analog:** This is already the shared serializer for success, read, and update payloads (`success_response/1`, `read_response/1`, `update_response/1`, lines 8-66).

**Plaintext boundary and current metadata shape** (lines 8-28, 41-66): success calls `maybe_put_client_secret/2`; read/update reuse a client metadata map and do not include plaintext secret. The current map serializes raw `client_secret_expires_at` to Unix time or zero (lines 41-59). Keep this shared payload path, but compute an effective method-aware value from validated lifetime version and auth method: omit for non-secret methods, zero for unlimited and v0 legacy state, Unix seconds for authoritative finite v1 state. Never surface advisory v0 dates.

### Authentication and final issuance: `client_auth.ex`, `client_secret_jwt.ex`, `client_authentication.ex`, `grant_persistence.ex`, `refresh_exchange.ex`

**Classification:** protocol services are request-response initially; grant and refresh persistence are CRUD inside a transaction. Verified identity is a transform/model value.

**Initial method/material gate:** `ClientAuth.authenticate/3` composes parse, client lookup, eligibility, method validation, and output in a `with` chain (`client_auth.ex:40-52`). Basic and post secret verification is handled together at lines 328-340; the supported method list at lines 11-21 distinguishes shared-secret methods from public/private-key and mTLS methods. Add secret expiry there without applying it to non-secret authentication methods; preserve existing generic invalid-client error mapping.

**JWT assertion separation:** `ClientSecretJwt.verify/3` validates assertion signing/claims and records replay before returning (see `client_secret_jwt.ex:19-33,163-182`). Retain this one-time assertion path; final guarded issuance checks current secret eligibility/identity only and does not re-consume JTI.

**Verified identity excerpt** (`client_authentication.ex:36-56`):

```elixir
def verified_identity(%Client{} = client) do
  method = client.token_endpoint_auth_method
  configuration = authentication_configuration(client, method)
  %VerifiedIdentity{
    client_id: client.client_id,
    method: method,
    fingerprint: :crypto.hash(:sha256, :erlang.term_to_binary(configuration, [:deterministic]))
  }
end

def verified_identity_matches?(%VerifiedIdentity{} = identity, %Client{} = current_client) do
  current = verified_identity(current_client)
  identity.client_id == current.client_id and identity.method == current.method and
    identity.fingerprint == current.fingerprint
end
```

Use this existing method/material fingerprint for final current-row identity comparison; do not invent a second fingerprint.

**Guarded issuance analog:** `grant_persistence.ex:228-339` locks/reloads client state and grant rows, then checks verified identity and samples `dependencies.now.()` after the relevant waits (lines 280-323). Place the secret check alongside `Client.app_eligibility/3` using that same fresh instant and current locked client. Refresh analog is `refresh_exchange.ex:113-211`; its locked path samples time at lines 177-178 before app eligibility and rotating token state. Maintain lock ordering and rollback boundaries, and retain the distinction that secret expiry affects requester authentication, not already-issued access/refresh token validity or queued work.

### Rotation and adapter transaction: `client_lifetime.ex`, `client_store.ex`, repository `client_store.ex`, `client_lifecycle.ex`, `transaction_store.ex`, `admin/clients.ex`

**Classification:** adapter/model services are CRUD; admin is request-response; transaction helpers are CRUD.

**Adapter contract:** `ClientStore.lifetime_contract/0` declares the shared transaction authority and `lock_clients/1` promises stable sorted locking (lines 10-25). `ClientLifetime.adapt/2` validates contract version, callback presence, and authority match once at the host boundary (lines 20-57); `validate_client/1` rejects malformed authoritative deadlines (59-89). Extend the declared `rotate_client_secret` callback (currently `client_store.ex:40-41`) to carry replacement lifetime state explicitly. Keep authority validation here instead of ad hoc protocol capability probes.

**Current-row replacement:** repository `ClientStore.rotate_client_secret/5` (lines 169-202) opens `TransactionStore.transact/2`, locks current `ClientRecord` using `FOR UPDATE` (174-180), computes credential lifetime changes on the current domain row (182), and writes hash, encrypted verifier, rotation timestamp, and lifecycle fields in one changeset (184-195). Derive fresh time and policy-based secret deadline after this lock; merge only secret lifecycle fields so v1 app and management deadlines survive, while v0 canonicalizes all legacy deadlines and promotes to v1. The ordinary update helper at lines 217-237 confirms transaction + locked-query convention.

**Atomic audit and error rollback:** `ClientLifecycle.transact_with_audit/2` wraps mutation and audit (lines 99-109); repository `TransactionStore.transact/2` converts error tuples into `repo.rollback/1` (lines 4-23). In repository client store, `append_audit_or_rollback/3` rolls back when audit append fails (`client_store.ex:268-279`). Preserve this boundary so admin returns generated plaintext only after full successful commit.

**Operator facade:** `Admin.Clients.rotate_client_secret/2` keeps host authorization and public behavior (lines 157-192). It currently samples `rotated_at` before client lookup/lock (168-169); move authoritative timestamp/deadline choice to the guarded current-row callback while preserving authorization, expired-secret replacement, serialized last-commit winner, no app renewal, and plaintext returned only on success.

### Independent PostgreSQL blockers: `test/support/client_lifetime_race_helpers.ex` and existing race tests

**Classification:** support utility is event-driven; integration tests are CRUD.

**Analog helper:** `start_session/4` uses `Sandbox.unboxed_run/2` and reports task/backend PIDs (lines 9-17); `await_blocker!/4` confirms `pg_blocking_pids` (34-38, 87-107); `barrier_clock/2` lets a test advance injected time only after the blocker is proven (72-77). `assert_locked_nowait!/3` provides an independent lock probe (48-68).

**Client wait excerpt** (`client_lifetime_client_wait_test.exs:41-52,79-99`): one session holds the client row lock; contender runs a real exchange; test observes the exact PostgreSQL blocker, advances the barrier clock, releases holder, then asserts error, unchanged durable counts, and unredeemed authorization code. **Grant wait analog:** `client_lifetime_grant_wait_test.exs:57-119` locks the grant/token row first and uses a NOWAIT query to prove client lock is not the blocking row. Extend these deterministic shapes for secret expiry/rotation after client and later grant/token waits; assert no unintended code consumption or token rotation. Use separate DB sessions, observable blockers and injected clocks, not elapsed sleeps as proof.

### Rollback, conformance, and unit test analogs

- `test/lockspire/storage/client_lifetime_rollback_test.exs`: use existing transaction-failure injection to assert durable row and audit rollback; rotation failure must not yield successful plaintext.
- `test/lockspire/storage/client_lifetime_conformance_test.exs:13-31`: adapter conformance executes through declared adapter authority and checks lifetime round-trip; extend to secret deadline/version/hash/verifier and same-transaction audit.
- `test/lockspire/storage/client_lifetime_promotion_test.exs`: use legacy v0 fixtures to prove old deadlines remain advisory until replacement; then verify only the replacement secret deadline is set and v1 app/management fields follow version-specific rules.
- `test/lockspire/protocol/client_auth_test.exs` and `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs`: test Basic/post/secret-JWT expiry equality, malformed state, non-secret exemption and independent assertion controls.
- `test/lockspire/protocol/dcr_policy_test.exs`, `registration_test.exs`, and `test/lockspire/web/registration_json_test.exs:26-99`: test nil/zero/positive snapshots, policy edit stability, registration provenance, no-secret omission, legacy v0 zero, method-aware omission, and plaintext omission on read/update.

## Shared Patterns

### Current credential authority

**Source:** `lib/lockspire/protocol/token_exchange/internal/client_authentication.ex:36-56` and `lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex:280-323`  
**Apply to:** all final code and refresh token issuance paths using shared-secret auth.

Compare `VerifiedIdentity` to the locked current client, then sample one fresh decision time after required blocking locks. Use that same time for app and secret eligibility. Expired or replaced authority must fail inside the transaction before grant/token mutation commits.

### Whole-second durable lifetime state

**Source:** `lib/lockspire/domain/client.ex:166-202,204-244`; `lib/lockspire/client_metadata.ex:44-47`  
**Apply to:** DCR issuance, replacement, eligibility, adapter validation and metadata serialization.

Store UTC deadlines truncated to whole seconds. Nil and zero policy are unlimited; equality is expired. Validate durable v1 dates fail-closed. Do not recompute issuance snapshots after policy edits.

### Shared transaction authority and rollback

**Source:** `lib/lockspire/client_lifecycle.ex:99-109`; `lib/lockspire/storage/ecto/repository/transaction_store.ex:4-23`; `lib/lockspire/storage/ecto/repository/client_store.ex:169-202,268-279`  
**Apply to:** secret replacement, lifecycle fields and audit.

Hash, verifier, issuance time, deadline, lifetime version and audit must commit together. Convert any write/audit error tuple into transaction rollback; expose plaintext only after success.

### PostgreSQL race evidence

**Source:** `test/support/client_lifetime_race_helpers.ex:9-107`; `client_lifetime_client_wait_test.exs:41-99`; `client_lifetime_grant_wait_test.exs:57-119`  
**Apply to:** stale preverified identity, expiry during blocking waits and competing rotations.

Use independent sandbox sessions and backend PIDs; prove the blocker with `pg_blocking_pids`, control the decision instant with a barrier clock, and assert durable state after release.

## No Analog Found

None. Existing source and tests provide close patterns for every likely Phase 164 file. New test cases should extend those files rather than introduce new infrastructure. Do not add Phase 165 management-token expiry behavior.

## Metadata

**Analog search scope:** `lib/lockspire`, `test/lockspire`, and `test/support`; phase scope and required regression cases from `164-CONTEXT.md` and `164-RESEARCH.md`.  
**Files scanned:** 27 named candidates plus related source sections.  
**Tracked-source gate:** all cited source/test analogs confirmed with `git ls-files`.  
**Pattern extraction date:** 2026-10-20
