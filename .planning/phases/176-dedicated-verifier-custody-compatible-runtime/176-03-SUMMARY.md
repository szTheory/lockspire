---
phase: 176-dedicated-verifier-custody-compatible-runtime
plan: "03"
subsystem: security
tags: [client-secret, verifier-custody, direct-registration, final-identity]

requires:
  - phase: 176-dedicated-verifier-custody-compatible-runtime
    provides: Validated verifier context and identity-bound native envelope from Plans 01–02
provides:
  - Fallible internal secret material generation with stable public helper contracts
  - Final-ID-bound coherent verifier/hash material for direct confidential-client registration
affects: [client-secret-jwt, direct-registration, verifier-custody]

actuals:
  tokens: 6286
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 6edb91b86cf0721b0814057df5618a94cb15262e
plan_head_after: 6cba78d115e69e0f390273fdfc589f7bb23da230

tech-stack:
  added: []
  patterns:
    - Hash-only secret generation remains independent from verifier configuration
    - Direct registration selects its persisted identity before generating credentials

key-files:
  created:
    - lib/lockspire/clients/secret_material.ex
    - test/lockspire/clients_secret_material_test.exs
    - test/integration/client_secret_verifier_direct_writer_test.exs
  modified:
    - lib/lockspire/clients.ex

key-decisions:
  - "The hash-only helper computes only the plaintext and its hash; verifier generation stays on the material path."
  - "Direct registration passes the exact final canonical client ID to dedicated sealing and rejects material failures before persistence."

requirements-completed: [SEC-01, SEC-02, SEC-04]

coverage:
  - id: D1
    description: "Public secret helpers preserve their success shapes while internal generation reports safe typed failures."
    requirement: SEC-01
    verification:
      - kind: unit
        ref: test/lockspire/clients_secret_material_test.exs#ClientSecretMaterialTest
        status: pass
      - kind: unit
        ref: test/lockspire/security/client_secret_verifier_compatibility_test.exs#exported hash and material helpers retain the legacy tuple, map, overloads, and error
        status: pass
    human_judgment: false
  - id: D2
    description: "Direct Basic, post, and JWT registration persists coherent credentials bound to the final client identity."
    requirement: SEC-04
    verification:
      - kind: integration
        ref: test/integration/client_secret_verifier_direct_writer_test.exs#direct Basic, post, and JWT registrations persist coherent final-ID pairs
        status: pass
      - kind: integration
        ref: test/integration/client_secret_verifier_direct_writer_test.exs#missing or invalid dedicated custody returns a typed error before persistence
        status: pass
      - kind: integration
        ref: test/integration/client_secret_verifier_direct_writer_test.exs#duplicate direct registration does not replace existing hash or verifier
        status: pass
    human_judgment: false

duration: 18 min
completed: 2026-10-25
status: complete
---

# Phase 176 Plan 03: Compatible Secret Material and Direct Writer Summary

**Hash-only secret generation no longer performs verifier work, while direct confidential-client registration seals one coherent credential pair against its final persisted ID.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-10-25T21:54:00Z
- **Completed:** 2026-10-25T22:12:49Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `Clients.SecretMaterial.generate/2` as a fallible internal path for legacy and dedicated verifier modes.
- Kept `rotate_secret_hash/0` independent of verifier configuration and endpoint secret availability; preserved the tuple return and three-key material map.
- Selected direct registration’s generated or caller-provided canonical ID before creating the hash/verifier pair, and returned bounded errors before persistence when custody is unavailable.
- Proved persistence, hash/opened-secret agreement, one-time plaintext handoff, Basic/post/JWT authentication, duplicate-ID preservation, and byte-distinct UTF-8 identity binding.

## Task Commits

1. **Task 1: RED** - `a2527135` — test(176-03): add failing helper compatibility tests
2. **Task 1: GREEN** - `333e80d1` — feat(176-03): preserve helper contracts with fallible generation
3. **Task 2: RED** - `9f8d3421` — test(176-03): add direct writer identity integration tests
4. **Task 2: GREEN** - `6cba78d1` — feat(176-03): bind direct verifier material to final client ID

## Files Created/Modified

- `lib/lockspire/clients/secret_material.ex` — typed internal generation and the legacy/dedicated sealing boundary.
- `lib/lockspire/clients.ex` — hash-only helper independence, stable public error handling, and final-ID-first direct registration.
- `test/lockspire/clients_secret_material_test.exs` — helper contract, redaction, freshness, endpoint independence, and UTF-8 identity tests.
- `test/integration/client_secret_verifier_direct_writer_test.exs` — persisted direct writer, failure, duplicate, and authentication coverage.

## TDD Gate Compliance

- **Task 1 RED:** The new helper tests failed on the intended gaps: hash-only generation touched the endpoint verifier secret, dedicated generation ignored the explicit identity, and missing identity did not fail. `gsd-tools check tdd-red-evidence` returned `RED_EVIDENCE_OK` for the hash-only target; its TAP report had 14 discovered tests, 11 passing and 3 failing, with no load or compile failures.
- **Task 1 GREEN:** The helper and frozen Phase 175 compatibility suites passed with 16 tests and 0 failures after final edge coverage was added.
- **Task 2 RED:** Direct writer tests failed on their registration-success and pre-persistence error assertions because direct registration did not yet supply the final ID or return typed generation failures. The classifier returned `RED_EVIDENCE_OK` for the direct registration target; its TAP report had 3 discovered tests and 3 assertion failures, with no setup or compile failures.
- **Task 2 GREEN:** The planned direct-writer PostgreSQL integration command passed with 3 tests and 0 failures.
- No refactor-only commit was needed.

## Verification

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/lockspire/clients_secret_material_test.exs test/lockspire/security/client_secret_verifier_compatibility_test.exs` — passed, 16 tests, 0 failures.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_direct_writer_test.exs` — passed, 3 tests, 0 failures.
- `git diff --check` — passed.
- The original frozen Phase 175 compatibility suite was run unchanged.

## Decisions Made

- Legacy endpoint-secret resolution remains inside the `Policy` compatibility wrapper used at the generation boundary; dedicated sealing receives the explicit complete context and final ID.
- Registration metadata validation and ID canonicalization complete before material generation, and persistence remains on the existing `ClientLifecycle.persist_direct/1` path.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve the legacy missing endpoint-secret error**
- **Found during:** Task 1 verification
- **Issue:** Routing legacy helper failures through typed internal generation would otherwise replace the existing actionable endpoint-secret error with a generic verifier reason.
- **Fix:** Added a bounded internal legacy-key-missing reason and kept the public helper’s prior fixed `ArgumentError` message.
- **Files modified:** `lib/lockspire/clients/secret_material.ex`, `lib/lockspire/clients.ex`, `test/lockspire/clients_secret_material_test.exs`
- **Verification:** The helper suite asserts the legacy error text; all 16 helper/compatibility tests pass.
- **Committed in:** `6cba78d1`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** Retained the existing legacy helper failure clarity without changing public arities, success shapes, or accepted legacy inputs.

## Issues Encountered

The ExUnit runner did not emit a format accepted by the TDD evidence classifier. A temporary local ExUnit TAP formatter was used to capture the actual target failures, and its source and evidence records were removed before task commits.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

The direct writer path is ready for subsequent phase plans. DCR and operator rotation remain owned by their later Phase 176 plans.

## Self-Check: PASSED

- All declared created and modified files exist.
- All four task commits are ancestors of the recorded plan head.
- The plan commit count is measured as four from the persisted pre-plan ledger.
- No stubs, skipped tests, or unrun verification commands were found in the owned files.

---
*Phase: 176-dedicated-verifier-custody-compatible-runtime*
*Completed: 2026-10-25*
