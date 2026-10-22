---
phase: 164-client-secret-expiry-atomic-rotation
plan: "05"
subsystem: testing
tags: [elixir, postgres, oauth, client-secrets, concurrency]
requires:
  - phase: 164-03
    provides: Atomic operator secret replacement and current-row policy behavior
  - phase: 164-04
    provides: Final issuance guards for code, refresh, device, CIBA, and RFC 8693 flows
provides:
  - Independent PostgreSQL proof for expired and replaced preverified client secrets
  - Later-lock expiry proof for each authenticated issuance finalizer
  - Serialized operator rotation, current-row promotion, and contended rollback evidence
affects: [164-06, client-secret, token-exchange, client-lifetime]
actuals:
  tokens: 12917.25
  tasks: 3
  commits: 3
commits: 3
plan_head_before: 8953e5703dd964f21f1465864d95f537649eea78
plan_head_after: 44da8b90ef941344ba3e2f13af393e088efad718
tech-stack:
  added: []
  patterns:
    - Independent Sandbox.unboxed_run sessions with distinct backend PID assertions
    - Injected barrier clocks advanced only after exact pg_blocking_pids and NOWAIT proof
    - Test-only delegating poll store preserves the shared repository transaction authority
key-files:
  created:
    - test/lockspire/storage/client_secret_lifetime_client_wait_test.exs
    - test/lockspire/storage/client_secret_lifetime_grant_wait_test.exs
    - test/lockspire/storage/client_secret_lifetime_rotation_race_test.exs
  modified:
    - test/lockspire/storage/client_secret_lifetime_rotation_race_test.exs
key-decisions:
  - "Use exact PostgreSQL blocker and NOWAIT evidence as the ordering gate before advancing the injected secret clock."
  - "For device and CIBA, let the real preliminary poll complete before a holder locks the row used by the final transition."
  - "Compare durable grant, token, credential, lifecycle, and audit rows after the relevant success or rollback boundary."
  - "Restore the exact prior durable singleton policy after rotation race fixtures, deleting the row only when the test created it."
patterns-established:
  - "Race tests use unique committed fixtures, bounded waits, actual PostgreSQL sessions, and deterministic cleanup."
  - "An operator command may return a secret that a later serialized commit supersedes; only the last committed secret is current."
requirements-completed: [DCR-08, DCR-09]
coverage:
  - id: D1
    description: Preverified Basic and secret-JWT identities cannot issue after the client lock wait ends in expiry or committed rotation.
    requirement: DCR-08
    verification:
      - kind: integration
        ref: test/lockspire/storage/client_secret_lifetime_client_wait_test.exs#a preverified secret is rejected at equality after a confirmed client-row wait
        status: pass
      - kind: integration
        ref: test/lockspire/storage/client_secret_lifetime_client_wait_test.exs#a committed operator rotation invalidates preverified Basic and secret-JWT identities
        status: pass
    human_judgment: false
  - id: D2
    description: Code, refresh, device, CIBA, and RFC 8693 finalizers recheck secret eligibility after their actual later-row waits and preserve denied durable state.
    requirement: DCR-08
    verification:
      - kind: integration
        ref: test/lockspire/storage/client_secret_lifetime_grant_wait_test.exs#five later-lock route schedules
        status: pass
    human_judgment: false
  - id: D3
    description: Contended operator rotations use current policy, provenance, and time; write or audit failure leaves durable state unchanged.
    requirement: DCR-09
    verification:
      - kind: integration
        ref: test/lockspire/storage/client_secret_lifetime_rotation_race_test.exs#four PostgreSQL rotation schedules
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-10-21
status: complete
---

# Phase 164 Plan 05: Real PostgreSQL Secret Race Proof Summary

**Independent PostgreSQL sessions prove secret expiry after client and grant waits, serialized operator rotation, and atomic rollback.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-10-21T14:55:25Z
- **Completed:** 2026-10-21T15:04:01Z
- **Tasks:** 3/3
- **Files modified:** 3 test modules

## Accomplishments

- Preverified Basic requests reject at secret equality after a confirmed client-row wait. Actual Admin.Clients replacement also invalidates preverified Basic and secret-JWT credentials; the JTI remains consumed once, and rejection reports the changed credential identity rather than replay.
- Five separate later-lock schedules cover authorization code, refresh family, device authorization, CIBA authorization, and RFC 8693 input token. Each verifies distinct PostgreSQL backends, the expected blocker, the contender-held client row, equality-time denial, and unchanged grant/token/audit state.
- Competing operator rotations prove each committed result's current row, then prove the later commit supersedes the first. Additional schedules prove post-wait policy, provenance, decision time, v0 deadline canonicalization, v1 unrelated deadline preservation, and complete rollback after client-write and audit failures.

## Task Commits

Each task was committed atomically:

1. **Prove expiry and committed replacement during a client-row wait** - `4939c3bf` (`test`)
2. **Prove expiry during every later grant or token wait** - `c80e9168` (`test`)
3. **Prove serialized operator winners, post-wait truth and rollback** - `44da8b90` (`test`)

## Files Created

- `test/lockspire/storage/client_secret_lifetime_client_wait_test.exs` - Client expiry and real operator replacement while preverified Basic and secret-JWT requests wait.
- `test/lockspire/storage/client_secret_lifetime_grant_wait_test.exs` - Five later-lock issuance races, including poll preflight coordination for device and CIBA.
- `test/lockspire/storage/client_secret_lifetime_rotation_race_test.exs` - Competing rotations, post-wait current-row semantics, and write/audit rollback.

## Verification

The final explicit selection used the pinned Elixir/OTP, Mix/Hex homes, and dedicated `lockspire_phase164_validation` database:

```sh
env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation mix test --include postgres_race test/lockspire/storage/client_secret_lifetime_client_wait_test.exs test/lockspire/storage/client_secret_lifetime_grant_wait_test.exs test/lockspire/storage/client_secret_lifetime_rotation_race_test.exs --max-failures 1 --timeout 55000
```

Result: **11 tests, 0 failures** across the three named modules; no tests in the requested explicit selection were excluded. `mix format` completed successfully for all three files, and `git diff --check` passed before commits. The blocker assertions used exact `pg_blocking_pids` results and NOWAIT probes; expiry was advanced through injected clocks, without elapsed sleeps as ordering evidence. Durable assertions verified denied code/request/family/input-token state, committed replacement credentials and audits, and complete rollback after injected write/audit failures.

## Durable Fixture Cleanup Follow-up

Wave validation found that the rotation race tests committed singleton server-policy changes without restoring the prior durable row. The tests now snapshot the row before changing policy and restore it after each race; an absent row is deleted only when the test created it, while an existing row is restored from its exact prior record. Client/audit cleanup remains scoped to each test's unique client ID.

On the dedicated `lockspire_phase164_validation` database, the prior run's identified rollback client and singleton policy row (`id = 1`, secret lifetime `37`) were removed by exact predicates. Before and after the rerun, durable counts were zero for `secret-%` clients and related audits, tokens, used JTIs, interactions, device authorizations, and CIBA authorizations, and zero singleton policy rows. The post-run query confirmed `current_database() = 'lockspire_phase164_validation'`.

The explicit PostgreSQL race selection was rerun with `--include postgres_race`: **11 tests, 0 failures, 0 excluded**. The required `mix test.fast` gate passed: **2 properties, 2,344 tests, 0 failures, 440 excluded, 6 skipped**. The tagged PostgreSQL races were independently included and run above.

## TDD Evidence

These tasks add PostgreSQL regression coverage for behavior implemented by plans 164-02 through 164-04. No production mutation or synthetic production RED claim was introduced. Test compilation and fixture feedback were corrected before the passing explicit selection; this summary makes no phase-wide strict TDD claim.

## Decisions Made

- Device and CIBA have a preliminary poll lock before the final client→authorization transition. A test-only delegating store pauses after the real preflight completes, then delegates the final transition to the real repository while a separate session owns the row. Its transaction authority remains consistent with the configured repository participants.
- The final decision clock advances only after backend identity, exact blocker, and client NOWAIT evidence establish the wait under test.
- Rotation semantics remain serialized last-commit-winner behavior; no CAS or stale-command API is introduced.

## Deviations from Plan

None. The test-only poll adapter and barriers coordinate the planned real PostgreSQL schedules without changing production code or global test configuration.

## Issues Encountered

- Device/CIBA preliminary polling acquires the authorization row before final issuance. The tests therefore coordinate after the real preliminary poll and block the later transition row, proving the required client-held final wait without changing production lock ordering.
- Snapshot comparison initially included the successful rotation audit, which is expected to change during a committed replacement. The assertions now compare issuance audit state separately and explicitly verify the committed rotation event.

## Known Stubs

None found in the files created by this plan.

## Threat Flags

None. The added surface is test-only and exercises existing transaction, audit, and credential boundaries.

## Next Phase Readiness

Plan 164-05's independent-session race proof is complete. Plan 164-06 owns the full suite and cross-phase evidence. This plan does not claim Phase 164's overall acceptance, DCR-07 completion, or any Phase 165/166 requirement.

---
*Phase: 164-client-secret-expiry-atomic-rotation*
*Completed: 2026-10-21*

## Self-Check: PASSED

All three test modules and this summary exist; task commits `4939c3bf`, `c80e9168`, and `44da8b90` are ancestors of HEAD. The persisted plan ledger measured exactly three task commits, and the committed diff check is clean.
