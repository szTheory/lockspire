---
phase: 177-safe-verifier-maintenance-recovery
plan: "08"
subsystem: auth-storage
tags: [elixir, postgresql, client-secret-jwt, verifier-maintenance, disclosure, operations]
requires:
  - phase: 177-safe-verifier-maintenance-recovery
    provides: Selected maintenance APIs, sensitive client storage, and recovery behavior from Plans 04–07.
provides:
  - Expanded persisted disclosure sentinels for maintenance success, malformed material, missing schema, and audit rollback.
  - Operator guidance for local maintenance, reader-first rollout, retirement, task-local versus release configuration, and recovery.
  - Executable documentation contracts tied to task help and verifier recovery behavior.
affects: [verifier-maintenance, credential-disclosure, phase-178-delivery]
actuals:
  tokens: 6897.5
  tasks: 2
  commits: 2
plan_head_before: 1cacbf7b5cfd26cd51f77284b18d9593105cd5d5
plan_head_after: a42684fc7af1e2b4c5bb1cf27f477df4785d6d37
commits: 2
tech-stack:
  added: []
  patterns: [real persisted sentinel capture, reader-first key retirement, fresh local custody check]
key-files:
  created:
    - test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs
  modified:
    - test/integration/client_secret_verifier_maintenance_disclosure_test.exs
    - docs/client-secret-verifier-configuration.md
    - docs/client-secret-jwt-host-guide.md
    - docs/supported-surface.md
key-decisions:
  - "Preserve the existing public one-time plaintext handoff and client/report shapes; no production change was needed after the forced disclosure cases passed."
  - "Treat a successful fresh check as local store evidence only; fleet parity, quiescence, backups, and rollback remain host-owned."
  - "Keep original-key restoration distinct from authorized partner-secret replacement and its one-time handoff."
requirements-completed: [VUP-03, VOPS-01, VOPS-03, VOPS-04, VPROOF-01]
coverage:
  - id: D1
    description: "Real persisted maintenance success, malformed verifier, missing-schema, audit rollback, Logger, query telemetry, audit, and report surfaces are checked with sentinels and positive controls."
    requirement: VPROOF-01
    verification:
      - kind: integration
        ref: "test/integration/client_secret_verifier_maintenance_disclosure_test.exs"
        status: pass
      - kind: unit
        ref: "test/lockspire/security/client_secret_verifier_inspection_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Documented task modes, release RPC context, retirement limits, logging boundaries, and recovery consequences match executable behavior."
    requirement: VOPS-01
    verification:
      - kind: unit
        ref: "test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs"
        status: pass
      - kind: integration
        ref: "test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs"
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-10-26
status: complete
---

# Phase 177 Plan 08: Verifier Maintenance Disclosure and Recovery Guidance Summary

**Persisted sentinels cover real maintenance success and forced storage failures, while operator guides separate local custody checks from host fleet decisions and partner-secret recovery.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-10-26T02:44:00Z
- **Completed:** 2026-10-26T02:53:56Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Extended the PostgreSQL disclosure test with distinguishable real plaintext, key bytes, encoded keys, and full ciphertext. It checks maintenance apply reports, audit rows, Logger output, and captured query telemetry while retaining an active query-channel positive control.
- Added forced malformed-verifier, missing client-table, and audit-trigger failure cases. Reports and driver-error logs stay bounded, and audit failure leaves the original verifier unchanged with no audit row.
- Updated the verifier configuration, `client_secret_jwt` host, and supported-surface guides with the implemented Mix and release RPC commands, local-versus-fleet limits, reader-first retirement sequence, configuration snapshot behavior, and separate restoration and secret-replacement consequences.
- Added executable guidance tests using the task's help text and core verifier/hash behavior.

## Task Commits

1. **177-08-01: Close success and forced-failure disclosure matrix** — `391687a0` (test).
2. **177-08-02: Document verified maintenance, retirement and recovery operations** — `a42684fc` (docs).

Measured task commit count: 2 from `1cacbf7b5cfd26cd51f77284b18d9593105cd5d5` through `a42684fc7af1e2b4c5bb1cf27f477df4785d6d37`.

## Files Created and Modified

- `test/integration/client_secret_verifier_maintenance_disclosure_test.exs` — real success, malformed material, missing schema, query-channel, and forced audit-error sentinels.
- `test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs` — task, docs, runtime-context, and key-recovery behavior contract.
- `docs/client-secret-verifier-configuration.md` — maintenance command, check, activation, retirement, recovery, and logging runbook.
- `docs/client-secret-jwt-host-guide.md` — verifier-key and partner-secret recovery guidance.
- `docs/supported-surface.md` — bounded source-level maintenance support contract and Phase 178 boundary.

## Verification

| Command | Result |
|---|---|
| `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' LOCKSPIRE_TEST_DB_NAME=lockspire_phase177_20261026_owned MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_disclosure_test.exs test/lockspire/security/client_secret_verifier_inspection_test.exs` | Passed; 7 tests, 0 failures. |
| `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' LOCKSPIRE_TEST_DB_NAME=lockspire_phase177_20261026_owned MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs` | Passed; 18 tests, 0 failures. |
| `mix format --check-formatted` on both changed ExUnit files | Passed. |
| `git diff --check` | Passed. |

All database runs used the plan-owned `lockspire_phase177_20261026_owned` database. No broad suite was rerun; Plan 09 owns final full-CI verification.

## TDD Gate Compliance

Task 1 was marked TDD-applicable, but the production behavior already passed once the initial Logger capture was narrowed to exclude the test's own trigger-creation SQL. That first failure was test-fixture output, not a product disclosure. No production defect remained, so no RED/GREEN sequence or evidence was manufactured. Task 1 committed additional regression evidence; Task 2 is documentation and contract coverage.

## Decisions Made

- Kept the public handoff map, stored material shape, and existing protocol behavior unchanged.
- Documented Ecto query suppression separately from host telemetry handlers and PostgreSQL server logging.
- Documented the fresh `--check` as local evidence, followed by host-owned fleet, backup, and rollback verification before live key retirement.

## Deviations from Plan

None. No production changes, dependencies, schema changes, protocol changes, or new public return shapes were required.

## Issues Encountered

- An early Logger assertion also captured the test's SQL function definition, which intentionally contained the sentinel. The test was corrected to capture only the client-store failure operation; the bounded failure result and captured logger output then passed.
- The sandbox denied Git index and `.git` ledger writes on the first commit attempt. The same scoped task commit succeeded with the authorized Git escalation and normal hooks.

## User Setup Required

None.

## Next Phase Readiness

Plan 08's sentinel and guidance changes are committed. Phase 177 remains in progress; Plan 09 owns the final phase verification and full CI gate. Phase 178 remains the package-installed composition and delivery boundary.

---
*Phase: 177-safe-verifier-maintenance-recovery*
*Completed: 2026-10-26*

## Self-Check: PASSED

- All five changed artifacts and this summary exist.
- Task commits `391687a0` and `a42684fc` are ancestors of the current plan head.
- The persisted plan ledger measures exactly two task commits from `1cacbf7b5cfd26cd51f77284b18d9593105cd5d5` through `a42684fc7af1e2b4c5bb1cf27f477df4785d6d37`.
