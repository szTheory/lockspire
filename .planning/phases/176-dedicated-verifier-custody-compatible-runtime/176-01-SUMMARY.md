---
phase: 176-dedicated-verifier-custody-compatible-runtime
plan: "01"
subsystem: security
tags: [aes-256-gcm, base64url, client_secret_jwt, verifier-custody]

requires:
  - phase: 175-accepted-baseline-verifier-compatibility-contract
    provides: Frozen LSCV1 envelope, custody, and compatibility requirements
provides:
  - Complete explicit verifier context with safe validation and redacted inspection
  - Native LSCV1 sealing and opening bound to the final persisted client ID
  - Strict reserved-family parsing with canonical Base64URL and bounded inputs
affects: [176-02, 176-03, 176-04, client_secret_jwt]

actuals:
  tokens: 8211
  tasks: 2
  commits: 5
commits: 5
plan_head_before: c988c4b423abc4a029a4a8de23597a0dcfaa4d2d
plan_head_after: 2295b42521c823525bf131ba90983a8cc049780e

tech-stack:
  added: []
  patterns:
    - Explicit complete contexts keep verifier crypto independent from application configuration
    - Purpose and canonical persisted identity are bound as AES-GCM associated data

key-files:
  created:
    - lib/lockspire/security/client_secret_verifier.ex
    - lib/lockspire/security/client_secret_verifier/context.ex
    - test/integration/client_secret_verifier_tracer_test.exs
    - test/lockspire/security/client_secret_verifier_test.exs
  modified:
    - lib/lockspire/protocol/client_auth/client_secret_jwt.ex

key-decisions:
  - "Dedicated crypto receives an explicit complete context; absent overrides retain the existing legacy Policy path."
  - "Every LSCV-prefixed value is reserved for dedicated parsing and never retries through the legacy reader."

requirements-completed: [SEC-01, SEC-02, SEC-03, SEC-05]
coverage:
  - id: D1
    description: Persist and authenticate a native dedicated verifier for the final client identity.
    requirement: SEC-01
    verification:
      - kind: integration
        ref: test/integration/client_secret_verifier_tracer_test.exs#persists a native dedicated verifier and authenticates it against the final client ID
        status: pass
      - kind: integration
        ref: test/integration/client_secret_verifier_tracer_test.exs#a verifier sealed for a different identity fails before replay insertion
        status: pass
    human_judgment: false
  - id: D2
    description: Enforce strict envelope parsing, independent authentication vectors, and byte allocation bounds.
    requirement: SEC-03
    verification:
      - kind: unit
        ref: test/lockspire/security/client_secret_verifier_test.exs#ClientSecretVerifierTest
        status: pass
    human_judgment: false
  - id: D3
    description: Preserve the absent-context legacy client authentication path.
    requirement: SEC-05
    verification:
      - kind: integration
        ref: test/integration/client_secret_verifier_tracer_test.exs#absent dedicated context keeps the existing legacy authentication path
        status: pass
    human_judgment: false

duration: 12 min
completed: 2026-10-25
status: complete
---

# Phase 176 Plan 01: Dedicated Verifier Context and Native Envelope Summary

**A host-supplied verifier context seals native client secrets into identity-bound LSCV1 text and authenticates them after PostgreSQL reload.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-10-25T21:39:11Z
- **Completed:** 2026-10-25T21:51:04Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added a complete four-option context validator with safe configuration state, independent verifier keys, and redacted inspection.
- Added native AES-256-GCM sealing/opening with the frozen payload and AAD, fresh 12-byte IVs, 16-byte tags, and final-client-ID binding.
- Routed `ClientSecretJwt` through an explicit context while preserving the existing legacy path when no override is supplied.
- Added independently constructed crypto vectors, strict reserved-family rejection, dotted key ID support, canonical encoding checks, identity/secret byte caps, and persisted authentication coverage.

## Task Commits

1. **Task 1: RED** - `3baafc84` — test(176-01): add native verifier authentication tracer
2. **Task 1: GREEN** - `55565221` — feat(176-01): add dedicated client verifier path
3. **Task 2: RED** - `35300eb6` — test(176-01): cover adversarial verifier envelopes
4. **Task 2: GREEN** - `600ae224` — feat(176-01): enforce verifier envelope bounds
5. **Task 1: fixture correction** - `2295b425` — fix(176-01): bind tracer hash to sealed secret

## Files Created/Modified

- `lib/lockspire/security/client_secret_verifier/context.ex` — validated complete context and redacted inspection.
- `lib/lockspire/security/client_secret_verifier.ex` — dedicated native seal/open and strict bounded envelope parser.
- `lib/lockspire/protocol/client_auth/client_secret_jwt.ex` — explicit-context dispatch using the persisted client ID.
- `test/integration/client_secret_verifier_tracer_test.exs` — persisted native authentication, identity-binding, and legacy-path proof.
- `test/lockspire/security/client_secret_verifier_test.exs` — independent vectors and parser/adversarial coverage.

## TDD Gate Compliance

- **Task 1 RED:** `gsd-tools check tdd-red-evidence` returned `RED_EVIDENCE_OK` for the persisted authentication tracer. The target assertion failed because the dedicated context/sealing capability was absent; the test was discovered and the legacy control passed. A temporary ExUnit event formatter emitted the actual test results as TAP for the gate.
- **Task 1 GREEN:** The tracer passed with 3 tests and 0 failures. After commit `55565221`, the exact planned tracer command passed again with 3 tests and 0 failures before Task 2 began.
- **Final tracer correction:** The test now hashes the same secret that it seals and asserts the persisted hash matches; the tracer passed again with 3 tests and 0 failures.
- **Task 2 RED:** The same machine gate returned `RED_EVIDENCE_OK` for the dotted-key-ID round-trip test. Its assertion failed because the parser split at the wrong separator. The report contained 7 discovered tests and no fixture/load failures.
- **Task 2 GREEN:** The focused unit suite passed with 8 tests and 0 failures after parser implementation. No refactor-only commit was needed.

## Verification

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_tracer_test.exs` — passed, 3 tests, 0 failures; rerun after Task 1 commit and again after Task 2 changes.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_test.exs` — passed, 8 tests, 0 failures.
- All 13 frozen Phase 175 input digests matched before implementation and remained untouched.
- `git diff --check` passed for the plan changes.

## Decisions Made

Dedicated verifier crypto uses only the complete context passed by its caller. Legacy unsealing remains an explicit integration-boundary operation, and reserved `LSCV` input cannot fall back to it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Keep the tracer's client hash and verifier secret paired**
- **Found during:** Final review after Task 2
- **Issue:** The tracer initially generated its hash from a different secret than the verifier contained.
- **Fix:** Use the `rotate_secret_hash/0` hash and returned secret together, and assert the persisted hash matches that secret.
- **Files modified:** `test/integration/client_secret_verifier_tracer_test.exs`
- **Verification:** Focused tracer passed with 3 tests and 0 failures.
- **Committed in:** `2295b425`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** Corrected the test fixture so the persisted client material is internally coherent; no product scope changed.

## Issues Encountered

The GSD RED-evidence parser does not natively parse ExUnit output. A temporary ExUnit `GenServer` formatter emitted TAP directly from the run's test events; that reporter output passed the canonical classifier. No package or dependency was added.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Plan 02 can resolve and cache application-level contexts while reusing the complete-context API. This plan intentionally implements native age kind 0 only; migrated age handling remains owned by the later Phase 176 reader expansion.

## Self-Check: PASSED

All five declared files exist, all five task commits are ancestors of the plan head, and the measured plan commit count is five.

---
*Phase: 176-dedicated-verifier-custody-compatible-runtime*
*Completed: 2026-10-25*
