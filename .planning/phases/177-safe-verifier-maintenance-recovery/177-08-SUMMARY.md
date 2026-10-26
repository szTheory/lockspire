---
phase: 177-safe-verifier-maintenance-recovery
plan: "08"
subsystem: auth-storage
tags: [elixir, postgresql, client-secret-jwt, verifier-maintenance, disclosure, operations]
requires:
  - phase: 177-safe-verifier-maintenance-recovery
    provides: Selected maintenance APIs, sensitive client storage, and recovery behavior from Plans 04–07.
provides:
  - Persisted disclosure sentinels for maintenance success, malformed material, missing schema, audit rollback, unavailable PostgreSQL connection pool, and serialized client_secret_jwt protocol failure.
  - Hostile newline and terminal-control identifier coverage for Admin reports and CLI argument errors.
  - Operator guidance for local maintenance, reader-first rollout, retirement, task-local versus release configuration, and recovery.
  - Executable documentation contracts tied to task help and verifier recovery behavior.
affects: [verifier-maintenance, credential-disclosure, phase-178-delivery]
actuals:
  tokens: 9332.5
  tasks: 2
  commits: 4
plan_head_before: 1cacbf7b5cfd26cd51f77284b18d9593105cd5d5
plan_head_after: 35023033049c153567e8bc1e5807164f477318f4
commits: 4
tech-stack:
  added: []
  patterns: [real persisted sentinel capture, bounded pool failure capture, reader-first key retirement, fresh local custody check]
key-files:
  created:
    - test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs
  modified:
    - test/integration/client_secret_verifier_maintenance_disclosure_test.exs
    - test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs
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
    description: "Real persisted maintenance success, malformed verifier, missing-schema, audit rollback, refused pool connection, serialized client_secret_jwt invalid_client response, hostile identifiers, Logger, query telemetry, audit, CLI, and report surfaces are checked with sentinels and capture controls."
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

- **Duration:** 25 min including required evidence continuation
- **Started:** 2026-10-26T02:44:00Z
- **Completed:** 2026-10-26T02:53:56Z
- **Tasks:** 2
- **Files modified:** 6 implementation, test, and guide artifacts

## Accomplishments

- Extended the PostgreSQL disclosure test with distinguishable real plaintext, key bytes, encoded keys, and full ciphertext. It checks maintenance apply reports, audit rows, Logger output, and captured query telemetry while retaining an active query-channel positive control.
- Added forced malformed-verifier, missing client-table, and audit-trigger failure cases. Reports and driver-error logs stay bounded, and audit failure leaves the original verifier unchanged with no audit row.
- Updated the verifier configuration, `client_secret_jwt` host, and supported-surface guides with the implemented Mix and release RPC commands, local-versus-fleet limits, reader-first retirement sequence, configuration snapshot behavior, and separate restoration and secret-replacement consequences.
- Added executable guidance tests using the task's help text and core verifier/hash behavior.

## Task Commits

1. **177-08-01: Close success and forced-failure disclosure matrix** — `391687a0` (test).
2. **177-08-02: Document verified maintenance, retirement and recovery operations** — `a42684fc` (docs).
3. **Continuation: Cover connection and protocol disclosure failures** — `35023033` (test).

Prior Plan metadata commit: `dbf0f7cc` (summary, state, roadmap). Current measured ledger count: 4 from `1cacbf7b5cfd26cd51f77284b18d9593105cd5d5` through `35023033049c153567e8bc1e5807164f477318f4`.

## Files Created and Modified

- `test/integration/client_secret_verifier_maintenance_disclosure_test.exs` — real success, malformed material, missing schema, forced audit error and refused pool connection, serialized HTTP `invalid_client`, hostile Admin identifier, and query-channel sentinels.
- `test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs` — hostile CLI argument coverage includes ESC and BEL terminal controls.
- `test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs` — task, docs, runtime-context, and key-recovery behavior contract.
- `docs/client-secret-verifier-configuration.md` — maintenance command, check, activation, retirement, recovery, and logging runbook.
- `docs/client-secret-jwt-host-guide.md` — verifier-key and partner-secret recovery guidance.
- `docs/supported-surface.md` — bounded source-level maintenance support contract and Phase 178 boundary.

## Verification

| Command | Result |
|---|---|
| `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' LOCKSPIRE_TEST_DB_NAME=lockspire_phase177_20261026_owned MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_disclosure_test.exs test/lockspire/security/client_secret_verifier_inspection_test.exs test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs` | Passed; 27 tests, 0 failures. Includes refused connection, CLI `--check`, serialized `invalid_client`, and hostile Admin/CLI cases. |
| `mix format` on the disclosure and CLI tests; `git diff --check` | Passed. |
| `git diff --check` | Passed. |

All database runs used the plan-owned `lockspire_phase177_20261026_owned` database. No broad suite was rerun; Plan 09 owns final full-CI verification.

## TDD Gate Compliance

Task 1 was marked TDD-applicable, but the production behavior already passed once the initial Logger capture was narrowed to exclude the test's own trigger-creation SQL. That first failure was test-fixture output, not a product disclosure. The continuation adds test-only evidence without fabricating a RED phase. No production defect remained.

## Decisions Made

- Kept the public handoff map, stored material shape, and existing protocol behavior unchanged.
- Documented Ecto query suppression separately from host telemetry handlers and PostgreSQL server logging.
- Documented the fresh `--check` as local evidence, followed by host-owned fleet, backup, and rollback verification before live key retirement.

## Deviations from Plan

The continuation closes the planned pool/connection and protocol-response gaps with a task-owned Repo configured to refuse a local connection, and a real serialized token request using unavailable verifier key material. There are no production changes, dependencies, schema changes, protocol changes, or new public return shapes.

## Issues Encountered

- An early Logger assertion also captured the test's SQL function definition, which intentionally contained the sentinel. The test was corrected to capture only the client-store failure operation; the bounded failure result and captured logger output then passed.
- The sandbox denied Git index and `.git` ledger writes on the first commit attempt. The same scoped task commit succeeded with the authorized Git escalation and normal hooks.

## User Setup Required

None.

## Next Phase Readiness

Plan 08's sentinel and guidance changes are committed. The latest focused run passed 27 tests with 0 failures. Evidence includes a refused connection from an isolated one-connection pool, a bounded maintenance report and failing CLI check, generic HTTP 401 `invalid_client`, and hostile newline/ESC/BEL handling. Phase 177 remains in progress; Plan 09 owns final phase verification and full CI. Phase 178 remains the package-installed composition and delivery boundary.

---
*Phase: 177-safe-verifier-maintenance-recovery*
*Completed: 2026-10-26*

## Self-Check: PASSED

- All six code, test, and documentation artifacts and this summary exist.
- Task commits `391687a0`, `a42684fc`, and `35023033` are ancestors of the current plan head.
- The persisted plan ledger measures four commits from `1cacbf7b5cfd26cd51f77284b18d9593105cd5d5` through `35023033049c153567e8bc1e5807164f477318f4` (including the prior summary/state/roadmap commit).
