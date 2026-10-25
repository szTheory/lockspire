---
phase: 176-dedicated-verifier-custody-compatible-runtime
plan: "05"
subsystem: security
tags: [oauth, postgres, client-secret, verifier-custody, dcr, rotation]

requires:
  - phase: 176-dedicated-verifier-custody-compatible-runtime
    provides: Fallible identity-bound secret material generation and verifier compatibility readers
  - phase: 175-accepted-baseline-verifier-compatibility-contract
    provides: Frozen writer behavior, supported methods, lifetime policy, and persistence authority
provides:
  - Final-ID-bound shared-secret material for Basic, post, and JWT DCR clients
  - Typed pre-persistence DCR errors for unavailable verifier custody
  - Operator rotation material sealed against the unchanged persisted client ID
  - PostgreSQL proof for coherent pairs, one-time handoff, rollback, lifetimes, audit, and selected-store delegation
affects: [176-06, 176-07, verifier-maintenance, client-secret-rotation]

actuals:
  tokens: 5324
  tasks: 2
  commits: 6
commits: 6
plan_head_before: 525b4f38c5a8c9728db8c29fb58d76a9775fa0fe
plan_head_after: 49652f6454ca987554d9122ce4bb32dcc3204b46

tech-stack:
  added: []
  patterns:
    - Select the final DCR client ID before calling fallible secret material generation
    - Generate operator rotation material for the existing client ID before entering the established lifecycle transaction
    - Preserve selected store and transaction authority by retaining existing lifecycle writer callbacks

key-files:
  created:
    - test/integration/client_secret_verifier_dcr_writer_test.exs
    - test/integration/client_secret_verifier_rotation_test.exs
  modified:
    - lib/lockspire/protocol/registration.ex
    - lib/lockspire/admin/clients.ex

key-decisions:
  - "DCR and operator rotation use SecretMaterial.generate/2 with the final persisted client ID; failures travel through existing bounded result shapes before persistence."
  - "ClientLifecycle remains responsible for the configured transaction, locked update, and audit atomicity; plaintext stays on the existing one-time handoff."

patterns-established:
  - "DCR credential generation returns a tagged material result before generating the registration access token or calling persistence."
  - "Operator rotation prepares a coherent hash/verifier pair, then delegates mutation and audit to the existing ClientLifecycle path."

requirements-completed: [SEC-01, SEC-02, SEC-04]

coverage:
  - id: D1
    description: "DCR Basic, post, and JWT clients persist coherent material bound to their final ID, retain configured secret lifetimes, and reveal plaintext only in the registration response."
    requirement: SEC-04
    verification:
      - kind: integration
        ref: test/integration/client_secret_verifier_dcr_writer_test.exs#basic, post, and JWT DCR clients persist coherent final-ID pairs and hand plaintext off once
        status: pass
      - kind: integration
        ref: test/integration/client_secret_verifier_dcr_writer_test.exs#nil, zero, and positive configured secret lifetimes retain their exact DCR deadlines
        status: pass
      - kind: integration
        ref: test/integration/client_secret_lifetime_registration_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: "Operator rotation seals the replacement for the existing ID, preserves unrelated client fields, rejects old credentials, accepts new credentials, and rolls back both fields on custody or audit failure."
    requirement: SEC-04
    verification:
      - kind: integration
        ref: test/integration/client_secret_verifier_rotation_test.exs#Basic, post, and JWT rotation keeps the client identity and returns one coherent replacement
        status: pass
      - kind: integration
        ref: test/integration/client_secret_verifier_rotation_test.exs#audit failure rolls back both replacement fields and returns no plaintext
        status: pass
      - kind: integration
        ref: test/integration/client_secret_lifetime_rotation_test.exs
        status: pass
      - kind: integration
        ref: test/integration/client_lifetime_selected_store_test.exs
        status: pass
    human_judgment: false

duration: 7 min
completed: 2026-10-25
status: complete
---

# Phase 176 Plan 05: Final-ID DCR and Operator Rotation Summary

**DCR and operator rotation now persist coherent hash/verifier pairs sealed to the final client identity while preserving lifetime, audit, store authority, and one-time plaintext handoff behavior.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-10-25T22:23:00Z
- **Completed:** 2026-10-25T22:30:11Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- DCR selects its generated client ID before material generation for Basic, post, and JWT clients. Persisted hashes match the returned secret, verifier opening recovers that secret under the stored ID, and JWT authentication succeeds.
- DCR custody failures return the existing `Registration.Error` server-error shape before client or success-audit persistence. Configured `nil`, zero, and positive secret lifetimes retain their existing behavior.
- Operator rotation generates a replacement for the unchanged client ID and preserves the existing lifecycle's selected stores, transaction, row lock, audit, timestamp, and one-time plaintext handoff behavior.
- PostgreSQL tests prove old credentials fail, new credentials succeed, audit failure rolls back both persisted credential fields without a handoff, and existing lifetime and configured-store regressions pass.

## Task Commits

1. **Task 1: RED** - `9ab988b5` — `test(176-05): add failing DCR verifier writer tests`
2. **Task 1: GREEN** - `0042d4c1` — `feat(176-05): bind DCR verifier material to final ID`
3. **Task 1: response boundary refinement** - `3d237de5` — `test(176-05): verify DCR plaintext handoff boundary`
4. **Task 2: RED** - `4421ee65` — `test(176-05): add failing operator rotation verifier tests`
5. **Task 2: test refinement** - `c5cd2579` — `test(176-05): tighten operator rotation assertions`
6. **Task 2: GREEN** - `49652f64` — `feat(176-05): rotate operator verifier for persisted ID`

## Files Created/Modified

- `lib/lockspire/protocol/registration.ex` — selects the final ID first, calls the fallible helper, and maps typed generation failures to the existing bounded DCR error shape.
- `lib/lockspire/admin/clients.ex` — prepares replacement material against the persisted ID and passes it to the existing lifecycle writer.
- `test/integration/client_secret_verifier_dcr_writer_test.exs` — covers Basic/post/JWT pairs, ID binding, JWT use, response versus subsequent read, lifetimes, and no-persistence custody failure.
- `test/integration/client_secret_verifier_rotation_test.exs` — covers replacement identity and pair, old/new credentials, unchanged fields, custody failure, and audit rollback.

## TDD Gate Compliance

- **Task 176-05-01 RED:** The target DCR integration test failed because the old implementation called the helper before selecting the final ID. `gsd-tools check tdd-red-evidence` returned `RED_EVIDENCE_OK`; semantic inspection confirmed the intended identity-missing failure and the typed-error path's unhandled exception.
- **Task 176-05-01 GREEN:** The new DCR suite and existing registration lifetime suite passed with 6 tests and 0 failures.
- **Task 176-05-02 RED:** The target rotation test failed because the old operator path supplied no client ID. `gsd-tools check tdd-red-evidence` returned `RED_EVIDENCE_OK`; semantic inspection confirmed the missing identity was the planned failure.
- **Task 176-05-02 GREEN:** The new rotation suite and existing rotation lifetime suite passed with 4 tests and 0 failures.
- No refactor-only commit was needed. Test-only refinement commits added explicit response/read and timestamp/error assertions after each implementation was green.

## Verification

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_dcr_writer_test.exs test/integration/client_secret_lifetime_registration_test.exs test/integration/client_secret_verifier_rotation_test.exs test/integration/client_secret_lifetime_rotation_test.exs test/integration/client_lifetime_selected_store_test.exs` — passed, 18 tests, 0 failures.
- `git diff --check` — passed.
- The selected-store regression verifies the existing configured adapter callbacks and transaction authority declarations; no default Repository mutation route was introduced.
- No package, schema, protocol-support, signing, maintenance, or frozen Phase 175 contract changes were made.

## Decisions Made

- Material generation failures remain typed atoms and flow through existing protocol/admin error branches before persistence.
- Existing `ClientLifecycle` remains the sole writer authority for DCR and operator rotation, preserving transaction and audit behavior.

## Deviations from Plan

None — the planned writer behavior and persistence boundaries were preserved.

## Issues Encountered

- The sandbox initially denied Git index-lock creation. The dispatch authorized Git metadata escalation; all six scoped commits then completed with the root pin and protected-branch checks in place.
- One initial formatter invocation lacked the selected ASDF BEAM pair; rerunning with the process-local Elixir 1.19.5 / OTP 28.5 pair succeeded without modifying toolchain configuration.

## User Setup Required

None — PostgreSQL was available and no external configuration was required.

## Next Phase Readiness

The DCR and operator credential writers now consume the fallible final-ID helper while preserving existing lifecycle authority. No maintenance CAS, rewrap, schema, or fleet-rollout behavior is claimed; those remain with their planned owners.

## Self-Check: PASSED

- Both created test files and both modified production files exist.
- All six task commits are ancestors of `plan_head_after` (`49652f6454ca987554d9122ce4bb32dcc3204b46`).
- The measured task commit count is 6; diff size is 21,294 characters (5,324 chars/4 actuals tokens).
- Scoped files contain no placeholder stubs; `git diff --check` passes.

---
*Phase: 176-dedicated-verifier-custody-compatible-runtime*
*Completed: 2026-10-25*
