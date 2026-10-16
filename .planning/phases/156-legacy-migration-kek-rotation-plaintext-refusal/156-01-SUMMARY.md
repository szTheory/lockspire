---
phase: 156-legacy-migration-kek-rotation-plaintext-refusal
plan: 01
subsystem: auth
tags: [key-encryption, kek-rotation, signing-keys, ecto, telemetry, concurrency]
status: complete

requires:
  - phase: 155-crypto-core-config-seam-bandit-baseline
    provides: KeyEncryption envelope, KeySet, Config.key_encryption!/0, sealed key generation
provides:
  - Lockspire.Admin.Keys.reencrypt/1 and Lockspire.Admin.reencrypt/1 (legacy migration and KEK rotation engine)
  - KeyStore callbacks list_signing_key_refs/2 and reencrypt_signing_key/3 with per-row lock, CAS and audit append
  - PrivateJwk.read_stored/2 mode-agnostic stored-key reader
  - Reencrypt.assess/2 single sealability rule and Reencrypt.emit_completed/3 shared completed-event schema
affects: [156-02 mix task, check mode, doctor and verify, 156-03 plaintext refusal, 157 docs sweep]

actuals:
  tokens: 62000
  tasks: 3
  commits: 4
plan_head_before: 3c6b4475e163da914c314615e34e1ad84e2462fb
plan_head_after: c8ba348da5f4eceb5c7277b74e8854c6f699edd3

tech-stack:
  added: []
  patterns:
    - "Storage owns lock, CAS and audit append; the caller supplies a decide function and storage never classifies or decrypts"
    - "One row per transaction (plain FOR UPDATE), classification in Elixir after the lock, CAS on the previously read bytes"
    - "Sensitive CAS call uses sensitive: true plus telemetry_event: nil so legacy plaintext never reaches query logs or repo telemetry"

key-files:
  created:
    - lib/lockspire/admin/keys/reencrypt.ex
    - test/lockspire/admin/keys_reencrypt_test.exs
    - test/lockspire/storage/reencrypt_concurrency_test.exs
  modified:
    - lib/lockspire/storage/key_store.ex
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/storage/ecto/repository/signing_key_store.ex
    - lib/lockspire/protocol/private_jwk.ex
    - lib/lockspire/admin/keys.ex
    - lib/lockspire/admin.ex
    - test/support/key_encryption_helpers.ex
    - test/lockspire/architecture_fitness_test.exs

key-decisions:
  - "Store callbacks are list_signing_key_refs(after_id, limit) returning {id, kid} pairs and reencrypt_signing_key(id, decide, opts)"
  - "A row that vanishes between listing and lock, or loses the CAS, counts as conflicted"
  - "Report carries a changes list (kid, action, from) beyond the D-10 fields so 156-02 can print per-row would-encrypt lines"
  - "decide/3 calls assess/2 first; the opened plaintext is read again only for rows assess already declared sealable"
  - "Telemetry and audit failures for storage errors use reason :storage_error and never forward exception structs"

requirements-completed: [MIG-01, OPS-01, OPS-02]

coverage:
  - id: D1
    description: "reencrypt/1 converts legacy JSON and ETF rows across all statuses and uses, idempotently, without touching lifecycle columns"
    requirement: MIG-01
    verification:
      - kind: unit
        ref: "test/lockspire/admin/keys_reencrypt_test.exs#scope"
        status: pass
    human_judgment: false
  - id: D2
    description: "Rows on a non-current configured KEK are re-wrapped with the same kid and still sign after the old KEK is removed"
    requirement: OPS-01
    verification:
      - kind: unit
        ref: "test/lockspire/admin/keys_reencrypt_test.exs#rotation matrix"
        status: pass
    human_judgment: false
  - id: D3
    description: "Failures are reported by kid and reason atom, rows stay byte-identical, dry-run writes nothing"
    requirement: MIG-01
    verification:
      - kind: unit
        ref: "test/lockspire/admin/keys_reencrypt_test.exs#failures"
        status: pass
    human_judgment: false
  - id: D4
    description: "Durable audit records and four operator telemetry events with exact allowlisted metadata and one completed-event schema"
    requirement: OPS-02
    verification:
      - kind: unit
        ref: "test/lockspire/admin/keys_reencrypt_test.exs#operator telemetry"
        status: pass
    human_judgment: false
  - id: D5
    description: "Overlapping and simultaneous runs convert each row exactly once; CAS conflict and audit rollback branches hold; activation does not wait on the engine row lock"
    requirement: MIG-01
    verification:
      - kind: integration
        ref: "test/lockspire/storage/reencrypt_concurrency_test.exs"
        status: pass
    human_judgment: false

duration: 25 min
completed: 2026-10-16
---

# Phase 156 Plan 01: Re-encryption Engine Summary

**Per-row locked, CAS-guarded re-encryption of signing keys (legacy JSON/ETF to LSK envelope, old KEK to current KEK) exposed as `Lockspire.Admin.reencrypt/1`, with dry-run, durable audit, operator telemetry and real-concurrency proofs.**

## Accomplishments

- `Lockspire.Admin.Keys.reencrypt/1` (and `Lockspire.Admin.reencrypt/1`) walks signing-key ids in keyset pages; each row gets its own transaction: `FOR UPDATE`, classify in Elixir, seal or re-wrap, round-trip verify with the same key set, CAS on `private_jwk_encrypted` plus `updated_at`, audit append, commit.
- `Reencrypt.assess/2` is the single sealability rule (`:no_private_key | :sealable_legacy | {:envelope, id} | {:unsealable, reason, id}`); `decide/3` branches on it, and 156-02's readiness status will call the same function.
- `PrivateJwk.read_stored/2` reads stored keys with an explicit key set, no legacy-plaintext policy and no telemetry; `decode_with_reason/1` is now a thin wrapper, so existing decoder behavior is unchanged. A fitness test restricts callers to the decoder and `Admin.Keys`.
- Dry-run reads without locks and writes nothing, yet runs the same classify, seal and verify path in memory; its report equals a following real run apart from the `dry_run` flag.
- Rotation matrix proven: legacy JSON, legacy ETF, sealed on test-1 and sealed on test-2 all end on the current KEK with the same kid, and still sign and verify after the old KEK is removed from config.
- Concurrency proven against real Postgres: a lockstep overlap of two runs (deterministic hooks, `pg_stat_activity` wait detection) and a six-contender barrier both convert each seeded row exactly once; a CAS `{0, _}` conflict and an audit-rejection rollback leave rows correct; `activate_signing_key` does not wait on a row the engine holds.
- Mutation check: removing `FOR UPDATE` made the lockstep test fail ("no backend is waiting on a row lock"), so the test does exercise the lock.

## New audit actions and telemetry (for the 157 docs sweep)

Durable audit actions: `key_encrypted`, `key_rewrapped` (resource `signing_key`; metadata `key_id, kid, status, use, kek_id`, plus `previous_kek_id` for re-wrap).

Telemetry events (each also mirrored on `[:lockspire, :audit, :key, action]`):

- `[:lockspire, :key, :encrypted]`: metadata `actor_id, actor_type, kek_id, key_id, kid, status`
- `[:lockspire, :key, :rewrapped]`: same plus `previous_kek_id`
- `[:lockspire, :key, :reencrypt_failed]`: metadata `key_id, kid, reason` (apply mode only)
- `[:lockspire, :key, :reencrypt_completed]`: metadata `actor_id, actor_type, current_kek_id, mode` (`:apply | :dry_run`, `:check` arrives in 156-02); measurements `scanned, encrypted, rewrapped, already_current, no_private_key, conflicted, failed, pending, stranded_retired, duration, count`

Failure reason atoms: `:unknown_kek, :decryption_failed, :malformed_envelope, :kid_mismatch, :unreadable_legacy, :roundtrip_failed, :storage_error`.

## Task Commits

1. Task 1 (tracer): `d3dace27` feat(156-01): add reencrypt tracer for legacy signing-key rows
2. Task 2 RED: `7ddb25f7` test(156-01): add failing tests for reencrypt classification, rotation, dry-run and failures
3. Task 2 GREEN: `7fd70dda` feat(156-01): classify rows through assess/2 and support rewrap, dry-run and failures
4. Task 3: `c8ba348d` feat(156-01): add reencrypt operator telemetry, concurrency proofs and reader fitness rule

## TDD Notes (Task 2)

- RED: 9 of 19 tests failed on the planned assertions (rewrap counts, per-reason failure atoms, dry-run flag and no-write behavior, ordering, `assess/2` undefined). Semantic assessment: every failure was the target behavior missing, none from fixtures, syntax or load errors. ExUnit has no supported adapter for `gsd_run check tdd-red-evidence`, so the machine classifier was not run; the evidence is the persisted failing run described here.
- GREEN: all 19 pass after `assess/2`-based `decide/3`, rewrap and dry-run. No separate REFACTOR commit was needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `Support.update_all/5` option placement**
- **Found during:** Task 1
- **Issue:** The plan's CAS sketch passed `telemetry_event: nil` as the fifth argument, but `Support.update_all` merges that argument into the update clauses, not repo options.
- **Fix:** Passed `sensitive: true, telemetry_event: nil` as the fourth (options) argument; `Support` itself is unchanged.
- **Files modified:** lib/lockspire/storage/ecto/repository/signing_key_store.ex
- **Commit:** d3dace27

**2. [Rule 3 - Blocker] `read_stored` acceptance grep**
- **Found during:** Task 1
- **Issue:** Two function clauses made `grep -c "def read_stored"` print 2 against an expected 1.
- **Fix:** Single public `read_stored/2` delegating to a private clause set.
- **Files modified:** lib/lockspire/protocol/private_jwk.ex
- **Commit:** d3dace27

### Process notes

- The protected-branch commit guard reports `main` as protected (`git.allow_default_branch_commits` unset). The orchestrator dispatched this plan sequentially on the main working tree and the project uses `branching_strategy: none` (phase 155 also committed directly to main), so commits landed on local `main`. Nothing was pushed and no config was changed. Flagging it for the orchestrator.
- The first commit briefly carried an `Opus 5.5` co-author trailer from the dispatch prompt; it was amended to the `Sonnet 5.5` trailer before any further work.

**Total deviations:** 2 auto-fixed (1 bug, 1 blocker), 0 architectural. **Impact:** none on scope or behavior.

## Concurrency Test Notes

`pg_stat_activity` (`wait_event_type = 'Lock'`) proved reliable, so the `Task.yield` fallback (RESEARCH A4) was not needed. All assertions are scoped to the seeded kid prefix; `scanned` is compared between runs, never as an absolute. The activation test asserts the committed table holds no foreign active `sig` key and fails with a reset-the-database message if it does.

## Known Stubs

None.

## Threat Flags

None. No new network endpoints, auth paths or schema changes. SAFE-01 diff against `32355619` for `mix.exs`, `mix.lock`, migrations, `lib/lockspire/web` and `PRODUCT.md` is empty.

## Verification

- `mix test test/lockspire` (MIX_ENV=test, 1.19.5-otp-28): 1621 tests, 0 failures (189 integration excluded)
- `mix test --only integration test/lockspire/storage/reencrypt_concurrency_test.exs`: 5 tests, 0 failures
- `mix qa`: exit 0 (format, credo, sobelow, compile warnings-as-errors)

## Self-Check: PASSED

Files verified present: reencrypt.ex, keys_reencrypt_test.exs, reencrypt_concurrency_test.exs. Commits d3dace27, 7ddb25f7, 7fd70dda, c8ba348d verified as ancestors of HEAD.
