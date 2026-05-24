---
phase: "33"
validation_type: "plan"
generated_at: "2026-04-28"
nyquist_compliant: true
wave_0_required: false
---

# Phase 33 Validation Plan

## Scope

Phase 33 validation must prove four truths before execution is considered complete:

1. DPoP proof parsing and JOSE/claim validation are correct for Lockspire-owned request context.
2. JWK thumbprints for validated proof keys are stable and later usable as `cnf.jkt`.
3. Replay detection is durable and deterministic across nodes/restarts for the supported replay window.
4. Bearer remains the default unless explicit server/client policy state opts a path into DPoP mode.

## Test Strategy

| Layer | Primary Files | Why |
|-------|---------------|-----|
| Protocol | `test/lockspire/protocol/dpop_test.exs`, `test/lockspire/protocol/token_exchange_test.exs`, `test/lockspire/protocol/dpop_policy_test.exs` | Proves proof parsing, JOSE checks, claim validation, replay rejection on a real token-path seam, and effective policy resolution. |
| Repository | `test/lockspire/storage/ecto/repository_dpop_replay_test.exs` | Proves durable replay acceptance/rejection and TTL-window behavior against real Ecto/Postgres paths. |
| Admin / Persistence | `test/lockspire/admin/clients_test.exs`, `test/lockspire/admin/server_policy_test.exs` | Proves explicit DPoP state can be validated and persisted without changing existing bearer defaults. |

## Command Matrix

| Plan | Fast Verification | Broader Verification |
|------|-------------------|----------------------|
| 33-01 | `MIX_ENV=test mix test test/lockspire/protocol/dpop_test.exs` | `MIX_ENV=test mix test test/lockspire/protocol/dpop_test.exs test/lockspire/protocol/token_exchange_test.exs` |
| 33-02 | `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_dpop_replay_test.exs test/lockspire/protocol/token_exchange_test.exs` | `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_dpop_replay_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/storage/ecto/repository_device_authorization_test.exs` |
| 33-03 | `MIX_ENV=test mix test test/lockspire/protocol/dpop_policy_test.exs test/lockspire/admin/clients_test.exs test/lockspire/admin/server_policy_test.exs` | same command plus any newly added record-specific tests |

## Sampling Plan

- After each task commit: run the plan's fast verification command.
- After each plan: rerun the plan's broader verification command.
- Before phase verification: run the union of all Phase 33 targeted commands.

## Per-Plan Verification Map

| Task ID | Plan | Requirement | Secure Behavior | Test Type | Automated Command |
|---------|------|-------------|-----------------|-----------|-------------------|
| 33-01-01 | 01 | DPoP-01 | valid proof JWTs are parsed and signatures verified with an asymmetric allowlist | protocol | `MIX_ENV=test mix test test/lockspire/protocol/dpop_test.exs` |
| 33-01-02 | 01 | DPoP-01 / DPoP-02 | `htm`, `htu`, `iat`, and `jti` are validated and public-key thumbprints are stable | protocol | `MIX_ENV=test mix test test/lockspire/protocol/dpop_test.exs` |
| 33-02-01 | 02 | DPoP-03 | replay state persists durably with unique replay identity and TTL | repository | `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_dpop_replay_test.exs` |
| 33-02-02 | 02 | DPoP-03 | duplicate proofs are rejected deterministically across repository calls and public token-path mapping | repository + protocol | `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_dpop_replay_test.exs test/lockspire/protocol/token_exchange_test.exs` |
| 33-03-01 | 03 | DPoP-04 | server and client DPoP mode fields persist explicitly with bearer-safe defaults | admin/persistence | `MIX_ENV=test mix test test/lockspire/admin/clients_test.exs test/lockspire/admin/server_policy_test.exs` |
| 33-03-02 | 03 | DPoP-04 | effective DPoP policy resolution preserves bearer default and supports explicit opt-in | protocol | `MIX_ENV=test mix test test/lockspire/protocol/dpop_policy_test.exs test/lockspire/admin/clients_test.exs test/lockspire/admin/server_policy_test.exs` |

## Wave 0 Requirements

No separate Wave 0 is required. Task `33-02-01` explicitly creates the replay-test scaffold before relying on it, and every planned task now has an immediate automated verification path.

## Manual-Only Verifications

None expected for Phase 33. The phase boundary is entirely repo-owned and should be executable through protocol, repository, and admin-layer tests.

## Final Phase Check

Before declaring Phase 33 execution-ready, the phase should have these commands available and passing:

```bash
MIX_ENV=test mix test \
  test/lockspire/protocol/dpop_test.exs \
  test/lockspire/storage/ecto/repository_dpop_replay_test.exs \
  test/lockspire/protocol/token_exchange_test.exs \
  test/lockspire/protocol/dpop_policy_test.exs \
  test/lockspire/admin/clients_test.exs \
  test/lockspire/admin/server_policy_test.exs
```

## Validation Sign-Off

- [x] Every task has an automated verification command
- [x] Verification focuses on repo-owned executable proof, not prose-only confidence
- [x] Bearer-default regression risk is covered explicitly
- [x] Replay durability is covered explicitly
- [x] `nyquist_compliant: true`
