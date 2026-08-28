---
phase: 131-executable-installation
plan: "06"
subsystem: installation
tags: [installation, diagnostics, phoenix, ecto, oauth, oidc, docs]
requires:
  - phase: 131-01
    provides: executable generated router, config, and consent seams
  - phase: 131-04
    provides: atomic migration delivery into the host project
  - phase: 131-05
    provides: default and opt-in generated smoke proof
provides:
  - aggregate install verification with independent actionable diagnostics
  - compiled Phoenix router and host migration inventory validation
  - truthful packaged-host onboarding and upgrade instructions
affects: [installation, onboarding, release-readiness]
tech-stack:
  added: []
  patterns: [aggregate fail-closed diagnostics, compiled route verification, host-path migration verification]
key-files:
  created: []
  modified:
    - lib/lockspire/install/verify.ex
    - test/lockspire/install/verify_test.exs
    - test/mix/tasks/lockspire_verify_test.exs
    - test/integration/phase57_rar_introspection_verification_e2e_test.exs
    - docs/install-and-onboard.md
key-decisions:
  - "Install verification emits one safe, actionable result for every required runtime key and generated host seam rather than aborting at the first missing configuration value."
  - "The verifier accepts only the compiled Phoenix route order and the host-owned priv/repo/migrations inventory before declaring an embedded installation ready."
  - "Consent rendering exposes normalized authorization-detail types only; raw authorization details remain in protocol storage and introspection surfaces."
requirements-completed: [INST-04]
coverage:
  - id: D1
    description: "Missing runtime keys, seam modules, router routes/order, and host migration delivery are independently reported with executable remediation."
    requirement: INST-04
    verification:
      - kind: test
        ref: "mix test test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Onboarding commands use generated host artifacts, ordinary host migrations, aggregate verification, default smoke proof, and explicit FAPI opt-in only."
    requirement: INST-04
    verification:
      - kind: docs
        ref: "mix docs.verify"
        status: pass
    human_judgment: false
duration: 30 min
completed: 2026-08-26
status: complete
---

# Phase 131 Plan 06: Executable Installation Verification Summary

**Lockspire installation now diagnoses every required embedded-host seam in one safe run and documents only the generated, host-native migration and smoke workflow.**

## Tasks Completed

1. **Report every required host seam and ordered route independently** — Split runtime validation into safe per-key checks for repo, account resolver, issuer, mount path, logout path, and Oban; split generated seam checks; inspect `Phoenix.Router.routes/1` for host verification, authorized-app, consent, guarded admin, and public-forwarding order; and validate the packaged migration inventory against host `priv/repo/migrations` plus database status.
2. **Publish only the now-executable onboarding path** — Updated installation and upgrade instructions to use copied host migrations with ordinary `mix ecto.migrate`, the imported generated router macro and host-owned operator pipeline, generated consent completion, aggregate `mix lockspire.verify`, default smoke, and explicit FAPI opt-in evidence.

## Verification

- `mix test test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs` — passed (9 tests).
- `mix docs.verify` — passed.
- `mix test test/integration/install_generator_test.exs test/integration/install_upgrade_test.exs test/lockspire/install/verify_test.exs test/mix/tasks/lockspire_verify_test.exs` — passed (32 tests).
- `mix test --include integration test/integration/phase57_rar_introspection_verification_e2e_test.exs` — passed.
- `mix test.fast` — passed (1,319 tests; 252 integration tests excluded).
- `mix test.integration` — passed (252 tests; 1,319 tests excluded).
- `mix qa` — passed; Credo reported no issues and Sobelow completed with its existing no-router informational warning.

The ASVS evidence named for router fail-closed behavior, independent configuration diagnostics, and redaction-safe output is green through the focused verifier suite.

## Decisions Made

- A bad configuration key never prevents verification from reporting other inspectable host defects.
- Router validation is based on the compiled route table, not source text or a substitute router.
- Host migrations are verified at `priv/repo/migrations`; remediation remains the normal host `mix ecto.migrate` command after installer delivery.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Regression proof] Updated the RAR consent integration assertion to match the Phase 131 redaction boundary.**
   - **Found during:** Task 2 full integration gate.
   - **Issue:** The pre-Phase-131 test expected raw `authorization_details` in the consent socket and HTML after `ConsentContext` was intentionally narrowed to safe type labels.
   - **Fix:** Asserted the requested type remains visible while raw details are absent from the consent render; retained the downstream storage and introspection assertions.
   - **Files modified:** `test/integration/phase57_rar_introspection_verification_e2e_test.exs`
   - **Verification:** Focused RAR integration test and full fast/integration suites pass.
   - **Commit:** `e259e0f`

2. **[Rule 1 - Static analysis] Simplified the router-safe result branch.**
   - **Found during:** Task 2 quality gate.
   - **Issue:** Credo rejected a single-clause `with` used to unwrap compiled router routes.
   - **Fix:** Replaced it with a direct `case` while retaining aggregate error behavior.
   - **Files modified:** `lib/lockspire/install/verify.ex`
   - **Verification:** Focused verifier tests, `mix qa`, and complete fast/integration suites pass.
   - **Commit:** `91b4618`

**Total deviations:** 2 auto-fixed (2 Rule 1). **Impact:** The phase preserves the narrowed redaction contract and keeps static analysis fail-closed.

## Known Stubs

None.

## Issues Encountered

None.

## Next Phase Readiness

The embedded-provider path now has a generated, compiled, migration-aware, and independently diagnosable installation contract. Phase 132 can build additive public API truth on this verified host seam, while Phase 133 can consume it as the provider side of the clean-room SaaS journey.

## Self-Check: PASSED

- `lib/lockspire/install/verify.ex` and the focused verifier tests exist and are committed.
- Task commits `de63513`, `e259e0f`, `8a8670b`, and `91b4618` exist in git history.
- Focused install, documentation, fast, integration, QA, and documentation gates passed on the final committed code.
